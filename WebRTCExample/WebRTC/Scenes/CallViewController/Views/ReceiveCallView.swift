//
//  ReceiveCallView.swift
//  WebRTCExample
//
//  Created by Baran Karaoğuz on 19.10.2024.
//

import Foundation
import UIKit
import AtomicDesignSystem

final class ReceiveCallView: UIView {
    
    private var callerNameLabel = UILabel()
    private var callerIpAddress = UILabel()
    private var rejectButton = ReceiveCallActionButton(type: .reject)
    private var acceptButton = ReceiveCallActionButton(type: .accept)
    
    private var didTapRejectButtonCallback: CallbackVoid?
    private var didTapAcceptButtonCallback: CallbackVoid?
    
    init() {
        super.init(frame: .zero)
        backgroundColor = Colors.primary.value
        prepare()
        draw()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func prepare() {
        backgroundColor = Colors.primary.value
        
        callerNameLabel.font = FontStyles.heading1.value
        callerNameLabel.textColor = Colors.text.value
        callerNameLabel.textAlignment = .center
  
        callerIpAddress.font = FontStyles.heading2.value
        callerIpAddress.textColor = Colors.textSecondary.value
        callerIpAddress.textAlignment = .center
        
        rejectButton.button.addTarget(self, action: #selector(rejectButtonTapped), for: .touchUpInside)
        acceptButton.button.addTarget(self, action: #selector(acceptButtonTapped), for: .touchUpInside)
        
        
        callerNameLabel.text = "Baran Karaoğuz"
        callerIpAddress.text = "192.163.20.10"
    }
    
    @objc private func rejectButtonTapped() {
        print("Buttona tıklandı!")
        didTapRejectButtonCallback?()
    }
    
    @objc private func acceptButtonTapped() {
        print("Buttona tıklandı!")
        didTapAcceptButtonCallback?()
    }
    
    //MARK: - Public Methods
    
    public func configure(with callerName: String, callerIpAddress: String) {
        self.callerNameLabel.text = callerName
        self.callerIpAddress.text = callerIpAddress
    }
    
    public func didTapRejectButton(_ callback: @escaping CallbackVoid) {
        self.didTapRejectButtonCallback = callback
    }
    
    public func didTapAcceptButton(_ callback: @escaping CallbackVoid) {
        self.didTapAcceptButtonCallback = callback
    }
    
}

//MARK: - For Drawing

extension ReceiveCallView {
    
    private func draw() {
        addSubview(callerNameLabel)
        callerNameLabel.translatesAutoresizingMaskIntoConstraints = false
        callerNameLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        callerNameLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 32).isActive = true
        callerNameLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        
        addSubview(callerIpAddress)
        callerIpAddress.translatesAutoresizingMaskIntoConstraints = false
        callerIpAddress.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor).isActive = true
        callerIpAddress.topAnchor.constraint(equalTo: callerNameLabel.bottomAnchor, constant: 8).isActive = true
        callerIpAddress.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor).isActive = true
        
       
        addSubview(rejectButton)
        rejectButton.translatesAutoresizingMaskIntoConstraints = false
        rejectButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 44).isActive = true
        rejectButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -28).isActive = true
        
        addSubview(acceptButton)
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        acceptButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -44).isActive = true
        acceptButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -28).isActive = true
    }
}
