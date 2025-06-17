//
//  SwitchContentView.swift
//  Basil
//
//  Created by Ian Brault on 6/14/25.
//

import UIKit

struct SwitchContentConfiguration: UIContentConfiguration {

    var text: String = ""
    var isOn: Bool = false
    var contentInset: CGFloat = 16

    var onChange: ((Bool) -> Void)?

    func makeContentView() -> UIView & UIContentView {
        return SwitchContentView(configuration: self)
    }

    func updated(for state: UIConfigurationState) -> Self {
        return self
    }
}

class SwitchContentView: UIView, UIContentView {

    var configuration: UIContentConfiguration {
        didSet {
            self.configure()
        }
    }

    let label = BodyLabel()
    let toggle = UISwitch()

    var onChange: ((Bool) -> Void)?

    override var intrinsicContentSize: CGSize {
        CGSize(width: 0, height: StyleGuide.tableCellHeight)
    }

    init(configuration: SwitchContentConfiguration) {
        self.configuration = configuration
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure() {
        guard let configuration = self.configuration as? SwitchContentConfiguration else { return }
        self.onChange = configuration.onChange

        self.addSubview(self.label)
        self.addSubview(self.toggle)

        self.label.text = configuration.text

        self.toggle.translatesAutoresizingMaskIntoConstraints = false
        self.toggle.isOn = configuration.isOn
        self.toggle.tintColor = StyleGuide.colors.primary
        self.toggle.addTarget(self, action: #selector(self.switchToggled), for: .valueChanged)

        self.label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: configuration.contentInset).isActive = true
        self.label.trailingAnchor.constraint(equalTo: self.toggle.leadingAnchor).isActive = true
        self.label.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        self.label.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true

        self.toggle.leadingAnchor.constraint(equalTo: self.label.trailingAnchor).isActive = true
        self.toggle.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -configuration.contentInset).isActive = true
        self.toggle.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }

    @objc func switchToggled(_ sender: UITextField) {
        guard let configuration = self.configuration as? SwitchContentConfiguration else { return }
        configuration.onChange?(self.toggle.isOn)
    }
}
