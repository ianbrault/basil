#!/usr/bin/env python3
#
# Basil Recipe Exporter: main.py
# Export recipes from Apple Notes to Basil

from __future__ import annotations

import csv
import re
import subprocess
import sys
import tempfile
import typing
import uuid

import bs4
import requests

from PySide6 import QtCore
from PySide6 import QtWidgets

BASE_URL = "https://brault.dev/basil/v2"

QUERY_SCRIPT = """\
script NotesIterator
    property AllFolders : missing value
    property AllNotes : missing value
end script

tell application "Notes"
    -- This reads folders/notes into memory to speed things up
    set NotesIterator's AllFolders to folders
    set NotesIterator's AllNotes to notes
    set output to ""

    -- Ignore items in the Recently Deleted folder
    set deletedFolder to first folder whose name is "Recently Deleted"
    set deletedFolderId to id of deletedFolder

    repeat with f in NotesIterator's AllFolders
        set fId to id of f
        if fId is not equal to deletedFolderId then
            set fName to name of f
            set fContainer to container of f
            set fContainerId to id of fContainer
            set entry to "folder," & fId & ",\\"" & fName & "\\"," & fContainerId
            set output to output & entry & linefeed
        end if
    end repeat

    repeat with n in NotesIterator's AllNotes
        set nContainer to container of n
        set nContainerId to id of nContainer
        if nContainerId is not equal to deletedFolderId then
            set nId to id of n
            set nName to name of n
            set entry to "note," & nId & ",\\"" & nName & "\\"," & nContainerId
            set output to output & entry & linefeed
        end if
    end repeat

    return output
end tell
"""

READ_SCRIPT = """\
tell application "Notes"
    set n to first note whose id is "{note_id}"
    return body of n
end tell
"""


#
# Helper functions
#


def execute_applescript(contents: str, **kwargs) -> str:
    _, path = tempfile.mkstemp()
    with open(path, "w") as f:
        if kwargs:
            contents = contents.format(**kwargs)
        f.write(contents)
    proc = subprocess.run(["osascript", path], capture_output=True, check=True)
    return proc.stdout.decode("utf-8")


#
# Utility classes
#


class Folder:
    def __init__(self, id: str, name: str, parent: str):
        self.id = id
        self.name = name
        self.parent = parent
        self.children = []

    def is_root(self) -> bool:
        return "ICAccount" in self.parent

    def key(self) -> str:
        return self.name


class Note:
    def __init__(self, id: str, name: str, parent: str):
        self.id = id
        self.name = name
        self.parent = parent

    def key(self) -> str:
        return self.name


class RecipeParseError(ValueError):
    def __init__(self, message: str):
        super().__init__(message)


class Recipe:
    format_tag_re = re.compile(r"<(b|i|u|em)>(.*?)</\1>")
    header_tag_re = re.compile(r"<(h\d)>(.*?)</\1>")
    list_start_re = re.compile(r"^(?:-|\*|\+|\d+\.)\s*(.+)")

    def __init__(self, title: str, ingredients: list[str], instructions: list[str]):
        self.uuid = str(uuid.uuid4()).upper()
        self.title = title
        self.ingredients = ingredients
        self.instructions = instructions

    def to_json(self, parent_folder: str) -> object:
        return {
            "uuid": self.uuid,
            "folderId": parent_folder,
            "title": self.title,
            "ingredients": self.ingredients,
            "instructions": self.instructions,
        }

    @staticmethod
    def parse(title: str, body: str) -> Recipe | None:
        # remove the line break tags
        body = body.replace("<br>", "")
        body = body.replace("<div></div>\n", "")
        # remove formatting tags that have no impact for recipe parsing
        body = re.sub(Recipe.format_tag_re, r"\2", body)
        # remove header tags to make it easier to find sections
        body = re.sub(Recipe.header_tag_re, r"\2", body)
        # then parse the cleaned-up HTML body
        soup = bs4.BeautifulSoup(body, "html.parser")

        ingredients = []
        instructions = []
        in_ingredients = False
        in_instructions = False
        ingredients_headings = ["ingredients"]
        instructions_headings = ["instructions", "directions"]
        for item in soup.children:
            item = typing.cast(bs4.element.Tag, item)
            if not item or not item.name:
                continue
            if item.name == "div":
                if not item.string:
                    continue
                contents = item.string.strip()
                if any(contents.lower().startswith(h) for h in ingredients_headings):
                    in_ingredients = True
                    in_instructions = False
                    continue
                if any(contents.lower().startswith(h) for h in instructions_headings):
                    in_ingredients = False
                    in_instructions = True
                    continue
                match = re.search(Recipe.list_start_re, contents)
                if in_ingredients:
                    if match:
                        ingredients.append(match.group(1))
                    else:
                        ingredients.append(f"__SECTION__ {contents}")
                elif in_instructions:
                    if match:
                        instructions.append(match.group(1))
            elif item.name == "ul" or item.name == "ol":
                list_items = []
                for list_item in item.find_all("li"):
                    list_item = typing.cast(bs4.element.Tag, list_item)
                    if list_item.string:
                        list_items.append(list_item.string.strip())
                if in_ingredients:
                    ingredients.extend(list_items)
                elif in_instructions:
                    instructions.extend(list_items)
            elif item.name == "li":
                if item.string:
                    if in_ingredients:
                        ingredients.append(item.string.strip())
                    elif in_instructions:
                        instructions.append(item.string.strip())

        if not ingredients:
            raise RecipeParseError("Failed to find recipe ingredients")
        if not instructions:
            raise RecipeParseError("Failed to find recipe instructions")
        return Recipe(title, ingredients, instructions)


#
# QThread-based utility classes
#


class NotesLoader(QtCore.QThread):
    loaded = QtCore.Signal(list, list)

    def run(self):
        output = ""
        try:
            output = execute_applescript(QUERY_SCRIPT)
        except Exception as ex:
            alert = Alert("Failed to execute AppleScript", str(ex))
            alert.exec()
            QtWidgets.QApplication.quit()

        folders = []
        notes = []
        reader = csv.reader(output.split("\n"))
        for row in reader:
            if not row:
                continue
            item_type, item_id, item_name, parent_id = row
            if "IMAPAccount" in parent_id:
                continue
            if item_type == "folder":
                folders.append(Folder(item_id, item_name, parent_id))
            elif item_type == "note":
                notes.append(Note(item_id, item_name, parent_id))

        # assign children to parent folders
        folder_map = {f.id: f for f in folders}
        for folder in folders:
            if not folder.is_root():
                folder_map[folder.parent].children.append(folder.id)

        self.loaded.emit(folders, notes)


class NotesReader(QtCore.QThread):
    note_read = QtCore.Signal(str)

    def __init__(self, notes: list[Note]):
        super().__init__()
        self.notes = notes

    def run(self):
        for note in self.notes:
            try:
                output = execute_applescript(READ_SCRIPT, note_id=note.id)
                self.note_read.emit(output)
            except Exception as ex:
                alert = Alert("Failed to execute AppleScript", str(ex))
                alert.exec()
                QtWidgets.QApplication.quit()


class NotesUploader(QtCore.QThread):
    done = QtCore.Signal()
    error = QtCore.Signal(str)

    def __init__(self, email: str, password: str, recipes: list[Recipe]):
        super().__init__()
        self.email = email
        self.password = password
        self.recipes = recipes

    def run(self):
        # authenticate with the server
        url = BASE_URL + "/user/authenticate"
        body = {
            "email": self.email,
            "password": self.password,
        }
        response = requests.post(url, json=body)
        if response.status_code != 200:
            self.error.emit(response.text)
            return
        info = response.json()

        # apply updates, adding recipes to the root folder
        # TODO: prevent duplicates from being added
        root = info["root"]
        recipes = info["recipes"]
        recipes.extend(recipe.to_json(root) for recipe in self.recipes)
        folders = info["folders"]
        root_folder = [f for f in folders if f["uuid"] == root]
        if not root_folder:
            self.error.emit("Root folder missing from response")
            return
        root_folder[0]["recipes"].extend(recipe.uuid for recipe in self.recipes)
        # and send updated state to the server
        url = BASE_URL + "/user/update"
        body = {
            "userId": info["id"],
            "token": info["token"],
            "root": root,
            "recipes": recipes,
            "folders": folders,
        }
        response = requests.post(url, json=body)
        if response.status_code != 200:
            self.error.emit(response.text)
            return
        else:
            self.done.emit()


#
# UI widgets
#


class Alert(QtWidgets.QMessageBox):
    def __init__(self, title: str, message: str):
        super().__init__()
        self.setIcon(QtWidgets.QMessageBox.Icon.Critical)
        self.setText(title)
        self.setInformativeText(message)


class TreeItem(QtWidgets.QTreeWidgetItem):
    def __init__(self, item_type: str, id: str, name: str):
        super().__init__([name])
        self.item_type = item_type
        self.id = id
        self.name = name
        self.setCheckState(0, QtCore.Qt.CheckState.Unchecked)


class LoginForm(QtWidgets.QWidget):
    submitted = QtCore.Signal(str, str)

    def __init__(self, parent: QtWidgets.QWidget):
        super().__init__(parent, QtCore.Qt.WindowType.Window)
        self.init_ui()

    def init_ui(self):
        self.email_input = QtWidgets.QLineEdit()
        self.email_input.setPlaceholderText("Email")

        self.password_input = QtWidgets.QLineEdit()
        self.password_input.setEchoMode(QtWidgets.QLineEdit.EchoMode.Password)
        self.password_input.setPlaceholderText("Password")

        self.submit_button = QtWidgets.QPushButton("Submit")
        self.submit_button.clicked.connect(self.button_pushed)

        layout = QtWidgets.QVBoxLayout()
        layout.addWidget(self.email_input)
        layout.addWidget(self.password_input)
        layout.addWidget(self.submit_button)
        self.setLayout(layout)

    @QtCore.Slot()
    def button_pushed(self):
        email = self.email_input.text()
        password = self.password_input.text()
        self.submitted.emit(email, password)
        self.close()


class RecipeExporter(QtWidgets.QWidget):
    def __init__(self, parent: QtWidgets.QWidget, notes: list[Note]):
        super().__init__(parent, QtCore.Qt.WindowType.Window)

        self.notes = notes
        self.index = 0
        self.recipes = []

        self.notes_reader = NotesReader(notes)
        self.notes_reader.note_read.connect(self.note_read)

        self.init_ui()
        self.notes_reader.start()

    def init_ui(self):
        self.label = QtWidgets.QLabel(
            f"Exporting {len(self.notes)} recipes...",
            alignment=QtCore.Qt.AlignmentFlag.AlignCenter
        )

        self.progress = QtWidgets.QProgressBar()
        self.progress.setAlignment(QtCore.Qt.AlignmentFlag.AlignCenter)
        self.progress.setRange(0, len(self.notes))
        self.progress.setTextVisible(True)

        layout = QtWidgets.QVBoxLayout()
        layout.addWidget(self.label)
        layout.addWidget(self.progress)
        self.setLayout(layout)

    @QtCore.Slot(list)
    def note_read(self, contents: str):
        title = self.notes[self.index].name
        try:
            recipe = Recipe.parse(title, contents)
        except RecipeParseError as ex:
            alert = Alert(f"Failed to parse '{title}'", str(ex))
            alert.exec()
        else:
            self.recipes.append(recipe)
        self.index += 1
        self.progress.setValue(self.index)

        if self.index == len(self.notes):
            self.form = LoginForm(self)
            self.form.submitted.connect(self.login_info_submitted)
            self.form.resize(240, 120)
            self.form.show()

    @QtCore.Slot(str, str)
    def login_info_submitted(self, email: str, password: str):
        self.label.setText("Uploading recipes...")

        self.uploader = NotesUploader(email, password, self.recipes)
        self.uploader.done.connect(self.upload_done)
        self.uploader.error.connect(self.upload_error)
        self.uploader.start()

    @QtCore.Slot()
    def upload_done(self):
        self.close()

    @QtCore.Slot(str)
    def upload_error(self, error: str):
        alert = Alert("Failed to upload recipes", error)
        alert.exec()
        self.close()


class MainWindow(QtWidgets.QWidget):
    def __init__(self):
        super().__init__()

        self.folders = []
        self.notes = []

        self.notes_loader = NotesLoader()
        self.notes_loader.loaded.connect(self.loaded)

        self.init_ui()
        self.notes_loader.start()

    def init_ui(self):
        self.setWindowTitle("Basil Recipe Exporter")

        self.label = QtWidgets.QLabel(
            "Select recipes from the view below:",
            alignment=QtCore.Qt.AlignmentFlag.AlignLeft
        )

        self.tree = QtWidgets.QTreeWidget()
        self.tree.setHeaderHidden(True)
        self.tree.setFrameShape(QtWidgets.QFrame.Shape.NoFrame)
        self.tree.itemChanged.connect(self.item_toggled)
        self.tree.insertTopLevelItem(0, QtWidgets.QTreeWidgetItem(["Loading notes... this may take a few minutes"]))

        self.quitButton = QtWidgets.QPushButton("Quit")
        self.quitButton.clicked.connect(self.quit)

        self.exportButton = QtWidgets.QPushButton("Export")
        self.exportButton.setDefault(True)
        self.exportButton.clicked.connect(self.export)

        button_layout = QtWidgets.QHBoxLayout()
        button_layout.setSpacing(16)
        button_layout.setContentsMargins(16, 0, 16, 0)
        button_layout.addWidget(self.quitButton)
        button_layout.addWidget(self.exportButton)

        layout = QtWidgets.QVBoxLayout()
        layout.addWidget(self.label)
        layout.addWidget(self.tree)
        layout.addLayout(button_layout)
        self.setLayout(layout)

    def populate_tree_children(self, folder: Folder, item: TreeItem):
        subfolders = sorted([f for f in self.folders if f.parent == folder.id], key=Folder.key)
        for subfolder in subfolders:
            subitem = TreeItem("folder", subfolder.id, subfolder.name)
            item.addChild(subitem)
            self.populate_tree_children(subfolder, subitem)
        notes = sorted([n for n in self.notes if n.parent == folder.id], key=Note.key)
        for note in notes:
            subitem = TreeItem("note", note.id, note.name)
            item.addChild(subitem)

    def populate_tree(self):
        tree_items = []
        top_folders = sorted([f for f in self.folders if f.is_root()], key=Folder.key)
        for folder in top_folders:
            if folder.name == "Recently Deleted":
                continue
            item = TreeItem("folder", folder.id, folder.name)
            self.populate_tree_children(folder, item)
            tree_items.append(item)
        self.tree.insertTopLevelItems(0, tree_items)

    @QtCore.Slot(bool)
    def quit(self, _: bool):
        QtWidgets.QApplication.quit()

    @QtCore.Slot(list, list)
    def loaded(self, folders: list[Folder], notes: list[Note]):
        self.folders = folders
        self.notes = notes
        self.tree.clear()
        self.populate_tree()

    @QtCore.Slot(TreeItem, int)
    def item_toggled(self, item: TreeItem, _: int):
        for i in range(item.childCount()):
            subitem = typing.cast(TreeItem, item.child(i))
            subitem.setCheckState(0, item.checkState(0))

    @QtCore.Slot(bool)
    def export(self, _: bool):
        # TODO: can be improved by exporting selected folders as well
        selected = []
        queue = [self.tree.topLevelItem(i) for i in range(self.tree.topLevelItemCount())]

        while len(queue) > 0:
            item = typing.cast(TreeItem, queue.pop(0))
            if item.item_type == "folder":
                queue.extend(item.child(i) for i in range(item.childCount()))
            elif item.item_type == "note":
                if item.checkState(0) == QtCore.Qt.CheckState.Checked:
                    selected.append(item.id)

        if not selected:
            return
        note_map = {n.id: n for n in self.notes}
        selected_notes = [note_map[id] for id in selected]

        self.exporter = RecipeExporter(self, selected_notes)
        self.exporter.resize(256, 64)
        self.exporter.show()


if __name__ == "__main__":
    app = QtWidgets.QApplication(sys.argv)
    if not sys.platform.startswith("darwin"):
       alert = Alert("Wrong Platform", "This tool must be run on Mac OS X")
       alert.show()
    else:
        window = MainWindow()
        window.resize(480, 600)
        window.show()

    sys.exit(app.exec())
