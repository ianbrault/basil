# Scripts

To set up the virtual environment and install required packages:

```bash
$ python3 -m venv .venv
$ source .venv/bin/activate
$ pip install -r requirements.txt
```

## Basil Recipe Exporter

Used to export recipes from `Notes.app` on Mac OS X systems.

To build:

```bash
$ cd "Basil Recipe Exporter"
$ ../.venv/bin/pyside6-deploy -c pysidedeploy.spec
```
