//
//  CallViewModel.swift
//  WebRTCExample
//
//  Created by Baran Karaoğuz on 19.10.2024.
//

import Foundation
import WebRTC
import class UIKit.UIView

extension CallViewModel {
    
    public struct TransitionData {
        
    }

    /// This structure is a view presentation model.
    /// Actually, if you want to pass data to the view structure for the initial state, this structure should be used.
    struct PresentationModel {
        let headerText: String
        let yourIpAddressText: String
        let aliasLabelText: String
        let ipaaddressLabelText: String
        let callButtonText: String
    }
    
    /// This enum type provides calls to the viewController layer.
    /// If you want to trigger actions for the viewController, you should add new cases.
    enum Actions {
        case setPresentationModel(model: PresentationModel)
        case changeButtonState(isEnable: Bool)
        case showReceiveCallView(isShow: Bool, alias: String, ipAddress: String)
        case showMeetView(isShow: Bool, presentationModel: MeetingView.PresentationModel?)
    }
    
}

protocol CallViewModelProtocol: LifeCycleProtocol,
                                ObserveManageable where ActionType == CallViewModel.Actions {
    /// This method called on viewController for binding viewModel <-> viewController
    /// - Parameter callback: callback is binding action.
    func didTapCallButton()
    func updateAlias(value: String)
    func updateRemoteIpAddress(value: String)
    func didTapAcceptButton()
    func didTapRejectButton()
    func didTapMeetingViewActions(type: MeetingView.ButtonType)
}


final class CallViewModel: CallViewModelProtocol, ActionSendable {
    
    let transitionData: TransitionData
    let webRTCManager: WebRTCClientProtocol
    let localSocketDataNotifier: LocalSocketDataNotifiable
    let messageGenerator: SignalGeneratable
    let signalParser: SignalParsable
    let ipGenerator: IPGeneratorProtocol
    let offerMessageStorage: OfferMessageStorage
    
    /// Callbacks
    var observer: Callback<Actions>!
    
    /// View Properties
    var remoteIpAddress: String = "" {
        didSet {
            checkButtonState()
        }
    }
    var alias: String = "" {
        didSet {
            checkButtonState()
        }
    }
    
    private var localIpAddress: String = ""
    
    // MARK: - Init Method
    init(
        transitionData: TransitionData,
        webRTCManager: WebRTCClientProtocol = WebRTCClient(),
        localSocketDataNotifier: LocalSocketDataNotifiable = LocalSocketDataNotifier(),
        messageGenerator: SignalGeneratable = SignalGenerator(),
        signalParser: SignalParsable = SignalParser(),
        ipGenerator: IPGeneratorProtocol = IPGenerator(),
        offerMessageStorage: OfferMessageStorage = OfferMessageStorage()
    ) {
        self.transitionData = transitionData
        self.webRTCManager = webRTCManager
        self.localSocketDataNotifier = localSocketDataNotifier
        self.messageGenerator = messageGenerator
        self.signalParser = signalParser
        self.ipGenerator = ipGenerator
        self.localIpAddress = ipGenerator.getIPAddress() ?? "" //TODO: -
        self.offerMessageStorage = offerMessageStorage
    }
    
    func viewDidLoad() {
        observe()
        setupWebRtc()
        sendAction(.setPresentationModel(model: .init(headerText: "IPCaller",
                                                      yourIpAddressText: "Your IP Address: \(self.localIpAddress)",
                                                      aliasLabelText: "Alias",
                                                      ipaaddressLabelText: "Ip Address",
                                                      callButtonText: "Call")))
    }
    
    //MARK: - Protocol Methods
    func didTapCallButton() {
        webRTCManager.connect()
        Task {
            do {
                let offerSdp = try await webRTCManager.makeOffer()
                let signalingMessage = try self.messageGenerator.generateSignalMessage(from: offerSdp, senderProp: .init(ipAddress: localIpAddress, name: alias))
                try await localSocketDataNotifier.send(messageModel: signalingMessage, to: remoteIpAddress)
            } catch(let error) {
                print("Send offer error: \(error.localizedDescription)")
            }
            
        }
    }
    
    func updateAlias(value: String) {
        self.alias = value
    }
    
    func updateRemoteIpAddress(value: String) {
        self.remoteIpAddress = value
    }
    
    func didTapMeetingViewActions(type: MeetingView.ButtonType) {
        switch type {
        case .mute(let state):
            webRTCManager.toggleMute(state == .on)
        case .speaker(let state):
            webRTCManager.toggleSpeaker(state == .on)
        case .reject:
            self.disconnect()
        case .switchCamera:
            webRTCManager.switchCamera()
        }
    }
    
    func didTapAcceptButton() {
        Task {
            guard let signalingMessage = await self.offerMessageStorage.signalingMessage else {
                self.disconnect()
                return
            }
            guard let sdp = signalingMessage.sessionDescription?.sdp else {
                self.disconnect()
                return
            }
            
            guard let senderIpAddress = signalingMessage.senderProp?.ipAddress else {
                self.disconnect()
                return
            }
            do {
                try await webRTCManager.receiveOffer(from: .init(type: .offer, sdp: sdp))
                let answerSdp = try await webRTCManager.makeAnswer()
                let signalingMessage = try self.messageGenerator.generateSignalMessage(from: answerSdp, senderProp: .init(ipAddress: localIpAddress, name: alias))
                try await localSocketDataNotifier.send(messageModel: signalingMessage, to: senderIpAddress)
                sendAction(
                    .showMeetView(
                        isShow: true,
                        presentationModel: .init(
                            alias: alias,
                            ipAddress: signalingMessage.senderProp?.name ?? "",
                            localVideView: webRTCManager.localView,
                            remoteVideoView: webRTCManager.remoteView
                        )
                    )
                )
            } catch {
                self.disconnect()
            }
        }

    }
    
    func didTapRejectButton() {
        Task {
            self.disconnect()
        }
    }
    
    //MARK: - Private methods
    private func observe() {
        localSocketDataNotifier.startListening()
        localSocketDataNotifier.observe { [weak self] message in
            guard let self else { return }
            print(message)
            switch message.type {
            case "offer":
                sendAction(
                    .showReceiveCallView(
                        isShow: true,
                        alias: message.senderProp?.name ?? "",
                        ipAddress: message.senderProp?.ipAddress ?? ""
                    )
                )
                Task {
                    await self.offerMessageStorage.store(signalingMessage: message)
                }
            case "answer":
                guard let sdp = message.sessionDescription?.sdp else { return }
                Task {
                    do {
                        await self.offerMessageStorage.store(signalingMessage: message)
                        try await self.webRTCManager.receiveAnswer(from: .init(type: .answer, sdp: sdp))
                        self.sendAction(
                            .showMeetView(
                                isShow: true,
                                presentationModel: .init(
                                    alias: message.senderProp?.name ?? "",
                                    ipAddress: message.senderProp?.ipAddress ?? "",
                                    localVideView: self.webRTCManager.localView,
                                    remoteVideoView: self.webRTCManager.remoteView
                                )
                            )
                        )
                    } catch(let error) {
                        print("Error receiving answer: \(error.localizedDescription)")
                    }
                }
            case "candidate":
                guard let candidate = message.candidate else { return }
                self.webRTCManager.receiveCandidate(
                    candidate: RTCIceCandidate(
                        sdp: candidate.sdp,
                        sdpMLineIndex: candidate.sdpMLineIndex,
                        sdpMid: candidate.sdpMid
                    )
                )
            default: break
            }
        }
    }
    
    private func setupWebRtc() {
        webRTCManager.delegate = self
        webRTCManager.setup()
    }
    
    private func checkButtonState() {
        if !alias.isEmpty && !remoteIpAddress.isEmpty {
            sendAction(.changeButtonState(isEnable: true))
        } else {
            sendAction(.changeButtonState(isEnable: false))
        }
    }
    
    private func disconnect() {
        Task { @MainActor in
            await self.offerMessageStorage.clear()
            webRTCManager.disconnect()
            sendAction(.showReceiveCallView(isShow: false, alias: "", ipAddress: ""))
            sendAction(.showMeetView(isShow: false, presentationModel: nil))
        }
    }
}

extension CallViewModel: WebRTCClientDelegate {
    func didStateChanged(didChange stateChanged: RTCSignalingState) {
        
    }
    
    func didIceConnectionStateChanged(didChange newState: RTCIceConnectionState) {
        
    }
    
    func didGenerateCandidate(didGenerate candidate: RTCIceCandidate) {
        Task {
            do {
                guard let offerSignalingMessage = await offerMessageStorage.signalingMessage, let remoteIpdAddress = offerSignalingMessage.senderProp?.ipAddress else { return }
                let signalingMessage = try messageGenerator.generateSignalMessage(from: candidate)
                try await self.localSocketDataNotifier.send(messageModel: signalingMessage, to: remoteIpdAddress)
            } catch {
                
            }
        }
    }
    
    func didConnect() {
        
    }
    
    func didDisconnect() {
        self.disconnect()
    }

}

final actor OfferMessageStorage {
    
    private(set) var signalingMessage: SignalingMessage?
    
    func store(signalingMessage: SignalingMessage) {
        self.signalingMessage = signalingMessage
    }
    
    func clear() {
        signalingMessage = nil
    }
    
}
