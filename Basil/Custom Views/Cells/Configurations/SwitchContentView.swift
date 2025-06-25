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

    private let stackView = UIStackView()
    private let label = UILabel()
    private let toggle = UISwitch()

    var onChange: ((Bool) -> Void)?

    override var intrinsicContentSize: CGSize {
        CGSize(width: 0, height: StyleGuide.tableCellHeightInteractive)
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

        self.label.text = configuration.text
        self.label.font = StyleGuide.fonts.body

        self.toggle.isOn = configuration.isOn
        self.toggle.tintColor = StyleGuide.colors.primary
        self.toggle.addTarget(self, action: #selector(self.switchToggled), for: .valueChanged)

        self.stackView.axis = .horizontal
        self.stackView.alignment = .center
        self.stackView.distribution = .equalSpacing
        self.stackView.isLayoutMarginsRelativeArrangement = true
        self.stackView.layoutMargins = UIEdgeInsets(top: 0, left: configuration.contentInset, bottom: 0, right: configuration.contentInset)

        self.stackView.removeAllArrangedSubviews()
        self.stackView.addArrangedSubview(self.label)
        self.stackView.addArrangedSubview(self.toggle)

        self.addPinnedSubview(self.stackView)
    }

    @objc func switchToggled(_ sender: UITextField) {
        guard let configuration = self.configuration as? SwitchContentConfiguration else { return }
        configuration.onChange?(self.toggle.isOn)
    }
}
