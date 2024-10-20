//
//  CallView.swift
//  WebRTCExample
//
//  Created by Baran Karaoğuz on 19.10.2024.
//

import Foundation
import UIKit
import AtomicDesignSystem

final class CallView: UIView {
    
    private var headerLabel = UILabel()
    private var headerSeparator = UIView()
    private var yourIpAddressLabel = UILabel()
    private var aliasLabel = UILabel()
    private var aliasTextField = UITextField()
    private var ipAddressLabel = UILabel()
    private var ipAddressTextField = UITextField()
    private var callButton = UIButton()
    
    private var receiveCallView: ReceiveCallView?
    private var meetingView: MeetingView?
    
    /// Callbacks
    var didTapCallButtonCallback: CallbackVoid?
    var didChangeTextForAliasTextFieldCallback: Callback<String>?
    var didChangeTextForIpAddressTextFieldCallback: Callback<String>?
    var didTapAcceptButtonCallback: CallbackVoid?
    var didTapRejectButtonCallback: CallbackVoid?
    var meetingViewActionCallback: Callback<MeetingView.ButtonType>?
    
    init() {
        super.init(frame: .zero)
        backgroundColor = Colors.primary.value
        prepare()
        draw()
        observeAllViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func prepare() {
        headerLabel.font = FontStyles.heading1.value
        headerLabel.textColor = Colors.text.value
        headerLabel.textAlignment = .left
        
        
        headerSeparator.backgroundColor = Colors.textTertiary.value.withAlphaComponent(0.6)
        
        [yourIpAddressLabel, aliasLabel, ipAddressLabel].forEach { label in
            label.font = FontStyles.body.value
            label.textColor = Colors.text.value
            label.textAlignment = .left
        }
        
        [aliasTextField, ipAddressTextField].forEach { textField in
            textField.layer.cornerRadius = 6
            textField.layer.borderColor = Colors.textTertiary.value.cgColor
            textField.layer.borderWidth = 1
            textField.textColor = Colors.textSecondary.value
            textField.font = FontStyles.bodySecondary.value
            textField.backgroundColor = .clear
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: textField.frame.height))
            textField.leftView = paddingView
            textField.leftViewMode = .always
        }
        
        callButton.backgroundColor = Colors.secondary.value
        callButton.layer.cornerRadius = 28
        callButton.setTitleColor(Colors.primary.value, for: .normal)
        callButton.titleLabel?.font = FontStyles.body.value
        
        updateButtonState(false)
    }
    
    private func observeAllViews() {
        callButton.addTarget(self, action: #selector(didTapCallButton), for: .touchUpInside)
        aliasTextField.addTarget(self, action: #selector(didChangeTextAliasTextField), for: .editingChanged)
        ipAddressTextField.addTarget(self, action: #selector(didChangeTextIpAddressTextField), for: .editingChanged)
    }
    
    @objc private func didTapCallButton() {
        didTapCallButtonCallback?()
    }
    
    @objc private func didChangeTextAliasTextField() {
        didChangeTextForAliasTextFieldCallback?(aliasTextField.text ?? "")
    }
    
    @objc private func didChangeTextIpAddressTextField() {
        didChangeTextForIpAddressTextFieldCallback?(ipAddressTextField.text ?? "")
    }
    
    //MARK: - Public methods
    public func setPresentationModel(_ presentationModel: CallViewModel.PresentationModel) {
        headerLabel.text = presentationModel.headerText
        yourIpAddressLabel.text = presentationModel.yourIpAddressText
        aliasLabel.text = presentationModel.aliasLabelText
        ipAddressLabel.text = presentationModel.ipaaddressLabelText
        callButton.setTitle(presentationModel.callButtonText, for: .normal)
    }
    
    public func showReceiveCallView(isShow: Bool, ipAddress: String, alias: String) {
        func observeReceiveCallView() {
            receiveCallView!.didTapRejectButton { [weak self] in
                guard let self else { return }
                self.didTapRejectButtonCallback?()
            }
            
            receiveCallView!.didTapAcceptButton { [weak self] in
                guard let self else { return }
                self.didTapAcceptButtonCallback?()
            }
        }
        
        if isShow {
            receiveCallView = ReceiveCallView()
            receiveCallView!.configure(with: alias, callerIpAddress: ipAddress)
            observeReceiveCallView()
            addSubview(receiveCallView!)
            receiveCallView!.fit(to: self)
        } else {
            receiveCallView?.removeFromSuperview()
            receiveCallView = nil
        }
    }
    
    public func showMeetingView(isShow: Bool, presentationModel: MeetingView.PresentationModel?) {
        if isShow {
            meetingView = MeetingView()
            meetingView?.configure(presentationModel)
            meetingView?.observeAction({ [weak self] type in
                guard let self else { return }
                self.meetingViewActionCallback?(type)
            })
            addSubview(meetingView!)
            meetingView!.fit(to: self)
        } else {
            meetingView?.removeFromSuperview()
            meetingView = nil
        }
    }
    
    public func updateButtonState(_ isEnable: Bool) {
        callButton.isEnabled = isEnable
        callButton.isUserInteractionEnabled = isEnable
        callButton.alpha = isEnable ? 1 : 0.5
    }
    
}

//MARK: - For Drawing

extension CallView {
    
    private func draw() {
        addSubview(headerLabel)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        headerLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 16).isActive = true
        headerLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        
        addSubview(headerSeparator)
        headerSeparator.translatesAutoresizingMaskIntoConstraints = false
        headerSeparator.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor).isActive = true
        headerSeparator.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8).isActive = true
        headerSeparator.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor).isActive = true
        headerSeparator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        addSubview(yourIpAddressLabel)
        yourIpAddressLabel.translatesAutoresizingMaskIntoConstraints = false
        yourIpAddressLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        yourIpAddressLabel.topAnchor.constraint(equalTo: headerSeparator.bottomAnchor, constant: 16).isActive = true
        yourIpAddressLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        
        addSubview(aliasLabel)
        aliasLabel.translatesAutoresizingMaskIntoConstraints = false
        aliasLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        aliasLabel.topAnchor.constraint(equalTo: yourIpAddressLabel.bottomAnchor, constant: 16).isActive = true
        aliasLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        
        addSubview(aliasTextField)
        aliasTextField.translatesAutoresizingMaskIntoConstraints = false
        aliasTextField.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        aliasTextField.topAnchor.constraint(equalTo: aliasLabel.bottomAnchor, constant: 4).isActive = true
        aliasTextField.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        aliasTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        addSubview(ipAddressLabel)
        ipAddressLabel.translatesAutoresizingMaskIntoConstraints = false
        ipAddressLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        ipAddressLabel.topAnchor.constraint(equalTo: aliasTextField.bottomAnchor, constant: 16).isActive = true
        ipAddressLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        
        addSubview(ipAddressTextField)
        ipAddressTextField.translatesAutoresizingMaskIntoConstraints = false
        ipAddressTextField.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        ipAddressTextField.topAnchor.constraint(equalTo: ipAddressLabel.bottomAnchor, constant: 4).isActive = true
        ipAddressTextField.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        ipAddressTextField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        addSubview(callButton)
        callButton.translatesAutoresizingMaskIntoConstraints = false
        callButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        callButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16).isActive = true
        callButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        callButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
    }
}
