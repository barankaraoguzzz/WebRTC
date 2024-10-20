//
//  MeetingView.swift
//  WebRTCExample
//
//  Created by Baran Karaoğuz on 20.10.2024.
//

import Foundation
import UIKit
import AtomicDesignSystem

final class MeetingView: UIView {
    
    enum ButtonType {
        enum State {
            case on
            case off
            
            var toggle: State {
                switch self {
                case .on: return .off
                case .off: return .on
                }
            }
        }
        
        case mute(State)
        case speaker(State)
        case reject
        case switchCamera
        
        func getImage() -> UIImage? {
            switch self {
            case .mute(let state):
                switch state {
                case .on:
                    return UIImage(systemName: "mic.slash")
                case .off:
                    return UIImage(systemName: "mic")
                }
            case .speaker(let state):
                switch state {
                case .on:
                    return UIImage(systemName: "speaker.2")
                case .off:
                    return UIImage(systemName: "speaker")
                }
            case .reject:
                return nil
            case .switchCamera:
                return UIImage(systemName: "arrow.triangle.2.circlepath.camera")
            }
        }
    }
    
    struct PresentationModel {
        let alias: String
        let ipAddress: String
        let localVideView: UIView
        let remoteVideoView: UIView
    }
    
    var remoteVideoView = UIView()
    var localVideoView = UIView()
    var closeMeetActionButton = ReceiveCallActionButton(type: .reject)
    var switchCameraButton = UIButton()
    var muteButton = UIButton()
    var speakerButton = UIButton()
    var aliasLabel = UILabel()
    var ipAddressLabel = UILabel()
    
    private var actionCallback: Callback<ButtonType>?
    
    ///Properties
    private var muteState: ButtonType.State = .off
    private var speakerState: ButtonType.State = .off
    
    init() {
        super.init(frame: .zero)
        prepare()
        draw()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func prepare() {
        backgroundColor = Colors.primary.value
        
        aliasLabel.textAlignment = .left
        aliasLabel.font = FontStyles.body.value
        aliasLabel.textColor = Colors.primary.value
        
        ipAddressLabel.textAlignment = .left
        ipAddressLabel.font = FontStyles.bodySecondary.value
        ipAddressLabel.textColor = Colors.primary.value
        
        [switchCameraButton, muteButton, speakerButton].forEach { button in
            button.layer.cornerRadius = 20
            button.backgroundColor = Colors.text.value.withAlphaComponent(0.5)
            button.tintColor = Colors.primary.value
        }
        
        switchCameraButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        switchCameraButton.addTarget(self, action: #selector(didTapSwitchCameratButton), for: .touchUpInside)
        muteButton.setImage(UIImage(systemName: "mic"), for: .normal)
        muteButton.addTarget(self, action: #selector(didTapMuteButton), for: .touchUpInside)
        speakerButton.setImage(UIImage(systemName: "speaker"), for: .normal)
        speakerButton.addTarget(self, action: #selector(didTapSpeakerButton), for: .touchUpInside)
        
        closeMeetActionButton.bottomTextIsHidden(true)
        closeMeetActionButton.button.addTarget(self, action: #selector(didTapRejectButton), for: .touchUpInside)
    }
    
    @objc private func didTapSwitchCameratButton() {
        actionCallback?(.switchCamera)
    }
    
    @objc private func didTapMuteButton() {
        muteState = muteState.toggle
        muteButton.setImage(ButtonType.mute(muteState).getImage(), for: .normal)
        actionCallback?(.mute(muteState))
    }
    
    @objc private func didTapSpeakerButton() {
        speakerState = speakerState.toggle
        speakerButton.setImage(ButtonType.speaker(speakerState).getImage(), for: .normal)
        actionCallback?(.speaker(speakerState))
    }
    
    @objc private func didTapRejectButton() {
        actionCallback?(.reject)
    }
    
    public func configure(_ model: PresentationModel?) {
        guard let model else { return }
        self.localVideoView.addSubview(model.localVideView)
        model.localVideView.fit(to: self.localVideoView)
        
        self.remoteVideoView.addSubview(model.remoteVideoView)
        model.remoteVideoView.fit(to: self.remoteVideoView)
        
        aliasLabel.text = model.alias
        ipAddressLabel.text = model.ipAddress
    }
    
    public func observeAction(_ callback: @escaping Callback<ButtonType>) {
        self.actionCallback = callback
    }
    
}

//MARK: - For Drawing
extension MeetingView {
    
    private func draw() {
        addSubview(remoteVideoView)
        remoteVideoView.fit(to: self)
        
        addSubview(localVideoView)
        localVideoView.translatesAutoresizingMaskIntoConstraints = false
        localVideoView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 32).isActive = true
        localVideoView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32).isActive = true
        localVideoView.setSize(width: 120, height: 160)
        
        let rightButtonsContainerView = UIStackView()
        rightButtonsContainerView.axis = .vertical
        rightButtonsContainerView.distribution = .fillEqually
        rightButtonsContainerView.spacing = 8
        
        addSubview(rightButtonsContainerView)
        rightButtonsContainerView.translatesAutoresizingMaskIntoConstraints = false
        rightButtonsContainerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -72).isActive = true
        rightButtonsContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32).isActive = true
        
        rightButtonsContainerView.addArrangedSubview(switchCameraButton)
        rightButtonsContainerView.addArrangedSubview(muteButton)
        rightButtonsContainerView.addArrangedSubview(speakerButton)
        
        switchCameraButton.setSize(width: 40, height: 40)
        muteButton.setSize(width: 40, height: 40)
        speakerButton.setSize(width: 40, height: 40)
        
        let leftContainerView = UIStackView()
        leftContainerView.axis = .vertical
        leftContainerView.distribution = .fillEqually
        leftContainerView.spacing = 4
        
        addSubview(leftContainerView)
        leftContainerView.translatesAutoresizingMaskIntoConstraints = false
        leftContainerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -72).isActive = true
        leftContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32).isActive = true
        
        leftContainerView.addArrangedSubview(aliasLabel)
        leftContainerView.addArrangedSubview(ipAddressLabel)
        
        addSubview(closeMeetActionButton)
        closeMeetActionButton.translatesAutoresizingMaskIntoConstraints = false
        closeMeetActionButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -32).isActive = true
        closeMeetActionButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
}
