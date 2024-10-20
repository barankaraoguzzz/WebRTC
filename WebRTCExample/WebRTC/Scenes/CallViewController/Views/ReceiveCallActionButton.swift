//
//  ReceiveCallActionButton.swift
//  WebRTCExample
//
//  Created by Baran Karaoğuz on 20.10.2024.
//

import Foundation
import UIKit
import AtomicDesignSystem

final class ReceiveCallActionButton: UIView {
    
    enum ButtonType {
        case accept
        case reject
        
        var text: String {
            switch self {
            case .accept:
                return "Accept"
            case .reject:
                return "Reject"
            }
        }
        
        var color: UIColor {
            switch self {
            case .accept:
                return Colors.success.value
            case .reject:
                return Colors.error.value
            }
        }
        
        var image: UIImage? {
            switch self {
            case .accept:
                return UIImage.init(systemName: "phone.down.fill")
            case .reject:
                return UIImage.init(systemName: "phone.fill")
            }
        }
    }
    
    let containerView = UIStackView()
    let button = UIButton()
    let bottomLabel = UILabel()
    
    let type: ButtonType!
    
    init(type: ButtonType) {
        self.type = type
        super.init(frame: .zero)
        prepare()
        draw()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func prepare() {
        containerView.axis = .vertical
        containerView.spacing = 4
        
        button.layer.cornerRadius = 32
        button.backgroundColor = type.color
        button.tintColor = Colors.primary.value
        button.setImage(type.image, for: .normal)
        
        bottomLabel.font = FontStyles.bodySecondary.value
        bottomLabel.textColor = Colors.text.value
        bottomLabel.textAlignment = .center
        bottomLabel.text = type.text
    }
    
    private func draw() {
        addSubview(containerView)
        containerView.fit(to: self)
        
        button.setSize(width: 64, height: 64)
        
        containerView.addArrangedSubview(button)
        containerView.addArrangedSubview(bottomLabel)
    }
    
    public func bottomTextIsHidden(_ isHidden: Bool) {
        bottomLabel.isHidden = isHidden
    }
    
}
