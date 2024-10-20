//
//  CallViewModelTests.swift
//  WebRTCExampleTests
//
//  Created by Baran Karaoğuz on 21.10.2024.
//

import Foundation
import WebRTC
import XCTest
@testable import WebRTCExample

fileprivate final class MockWebRTCClient: WebRTCClientProtocol {
    var delegate: WebRTCClientDelegate?
    var localView: UIView! = UIView()
    var remoteView: UIView! = UIView()
    
    var connectCalled = false
    var makeOfferCalled = false
    var makeAnswerCalled = false
    var receiveOfferCalled = false
    var receiveAnswerCalled = false
    var disconnectCalled = false
    var toggleMuteCalled = false
    var toggleSpeakerCalled = false
    var switchCameraCalled = false
    
    var mockOffer: RTCSessionDescription?
    var mockAnswer: RTCSessionDescription?
    
    func setup() {}
    
    func connect() {
        connectCalled = true
    }
    
    func disconnect() {
        disconnectCalled = true
    }
    
    func makeOffer() async throws -> RTCSessionDescription {
        makeOfferCalled = true
        return mockOffer ?? RTCSessionDescription(type: .offer, sdp: "sdp")
    }
    
    func makeAnswer() async throws -> RTCSessionDescription {
        makeAnswerCalled = true
        return mockAnswer ?? RTCSessionDescription(type: .answer, sdp: "sdp")
    }
    
    func receiveOffer(from sdp: RTCSessionDescription) async throws {
        receiveOfferCalled = true
    }
    
    func receiveAnswer(from sdp: RTCSessionDescription) async throws {
        receiveAnswerCalled = true
    }
    
    func receiveCandidate(candidate: RTCIceCandidate) {}
    
    func toggleSpeaker(_ isSpeakerOn: Bool) {
        toggleSpeakerCalled = true
    }
    
    func toggleMute(_ isMuted: Bool) {
        toggleMuteCalled = true
    }
    
    func switchCamera() {
        switchCameraCalled = true
    }
}

fileprivate final class MockLocalSocketDataNotifier: LocalSocketDataNotifiable {
    var sendMessageCalled = false
    var startListeningCalled = false
    var observeCalled = false
    var messageModelSent: SignalingMessage?
    var sentIpAddress: String?
    
    func send(messageModel: SignalingMessage, to host: String) async throws {
        sendMessageCalled = true
        messageModelSent = messageModel
        sentIpAddress = host
    }
    
    func startListening() {
        startListeningCalled = true
    }
    
    func observe(_ completion: @escaping Callback<SignalingMessage>) {
        observeCalled = true
    }
}

fileprivate final class MockSignalGenerator: SignalGeneratable {
    var generatedMessage: SignalingMessage?
    
    func generateSignalMessage(from sessionDescription: RTCSessionDescription, senderProp: SenderProperties) throws -> SignalingMessage {
        return SignalingMessage(
            type: sessionDescription.type == .offer ? "offer" : "answer",
            sessionDescription: SDPMessage(sdp: sessionDescription.sdp),
            senderProp: senderProp,
            candidate: nil
        )
    }
    
    func generateSignalMessage(from iceCandidate: RTCIceCandidate) throws -> SignalingMessage {
        return SignalingMessage(type: "candidate", sessionDescription: nil, senderProp: nil, candidate: CandidateModel(sdp: iceCandidate.sdp, sdpMLineIndex: iceCandidate.sdpMLineIndex, sdpMid: iceCandidate.sdpMid!))
    }
    
    func generateSignalMessage(from sdp: String) throws -> SignalingMessage {
        return SignalingMessage(type: "offer", sessionDescription: SDPMessage(sdp: sdp), senderProp: nil, candidate: nil)
    }
}

fileprivate final class CallViewModelTests: XCTestCase {
    
    var viewModel: CallViewModel!
    var mockWebRTCClient: MockWebRTCClient!
    var mockLocalSocketDataNotifier: MockLocalSocketDataNotifier!
    var mockMessageGenerator: MockSignalGenerator!
    
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        return false
    }
    
    override func setUp() {
        super.setUp()
        mockWebRTCClient = MockWebRTCClient()
        mockLocalSocketDataNotifier = MockLocalSocketDataNotifier()
        mockMessageGenerator = MockSignalGenerator()
        
        viewModel = CallViewModel(
            transitionData: .init(),
            webRTCManager: mockWebRTCClient,
            localSocketDataNotifier: mockLocalSocketDataNotifier,
            messageGenerator: mockMessageGenerator
        )
        
        viewModel.observer = { [weak self] actionType in
            switch actionType {
            default: break
            }
        }
    }
    
    override func tearDown() {
        viewModel = nil
        mockWebRTCClient = nil
        mockLocalSocketDataNotifier = nil
        mockMessageGenerator = nil
        super.tearDown()
    }
    
    func testDidTapCallButton() async {
        
        let expectedSdp = RTCSessionDescription(type: .offer, sdp: "sdp")
        mockWebRTCClient.mockOffer = expectedSdp
        viewModel.remoteIpAddress = "192.168.1.119"
        viewModel.alias = "DummyAlias"
        
        viewModel.didTapCallButton()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertTrue(self.mockWebRTCClient.connectCalled)
            XCTAssertTrue(self.mockWebRTCClient.makeOfferCalled)
            XCTAssertTrue(self.mockLocalSocketDataNotifier.sendMessageCalled)
            XCTAssertEqual(self.mockLocalSocketDataNotifier.sentIpAddress, "192.168.1.119")
            XCTAssertEqual(self.mockMessageGenerator.generatedMessage?.sessionDescription?.sdp, expectedSdp.sdp)
        }
    }
    
    func testDidTapAcceptButton() async {
        let offerMessage = SignalingMessage(
            type: "offer",
            sessionDescription: SDPMessage(sdp: "dummy_sdp"),
            senderProp: SenderProperties(ipAddress: "192.168.1.119", name: "SenderAlias"),
            candidate: nil
        )
        await viewModel.offerMessageStorage.store(signalingMessage: offerMessage)
        mockWebRTCClient.mockAnswer = RTCSessionDescription(type: .answer, sdp: "dummy_sdp")
        
        viewModel.didTapAcceptButton()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertTrue(self.mockWebRTCClient.receiveOfferCalled)
            XCTAssertTrue(self.mockWebRTCClient.makeAnswerCalled)
            XCTAssertTrue(self.mockLocalSocketDataNotifier.sendMessageCalled)
        }
    }
    
    
    func testDidTapRejectButton() async {
        viewModel.didTapRejectButton()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertTrue(self.mockWebRTCClient.disconnectCalled)
        }
    }
    
    func testCheckButtonState() {
        viewModel.updateAlias(value: "Alias")
        viewModel.updateRemoteIpAddress(value: "192.168.1.119")
        
        XCTAssertNotNil(viewModel.observer)
    }
    

    func testShouldStartListeningAndReceiveMessage() {
        viewModel.viewDidLoad()
        
        XCTAssertTrue(mockLocalSocketDataNotifier.startListeningCalled)
        XCTAssertTrue(mockLocalSocketDataNotifier.observeCalled)
    }
    
    func testDidTapMeetingViewActions() async {
        
        viewModel.didTapMeetingViewActions(type: .mute(.on))
        
        XCTAssertTrue(mockWebRTCClient.toggleMuteCalled)
        
        viewModel.didTapMeetingViewActions(type: .speaker(.on))
        
        XCTAssertTrue(mockWebRTCClient.toggleSpeakerCalled)
        
        viewModel.didTapMeetingViewActions(type: .switchCamera)
        
        XCTAssertTrue(mockWebRTCClient.switchCameraCalled)
        
        viewModel.didTapMeetingViewActions(type: .reject)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertTrue(self.mockWebRTCClient.disconnectCalled)
        }
    }
    
    func testDidGenerateCandidate() async {
        let candidate = RTCIceCandidate(sdp: "dummy_sdp", sdpMLineIndex: 0, sdpMid: "0")
        let offerMessage = SignalingMessage(
            type: "offer",
            sessionDescription: SDPMessage(sdp: "dummy_sdp"),
            senderProp: SenderProperties(ipAddress: "192.168.1.119", name: "SenderAlias"),
            candidate: nil
        )
        
        await viewModel.offerMessageStorage.store(signalingMessage: offerMessage)
        
        viewModel.didGenerateCandidate(didGenerate: candidate)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertTrue(self.mockLocalSocketDataNotifier.sendMessageCalled)
            XCTAssertEqual(self.mockLocalSocketDataNotifier.sentIpAddress, "192.168.1.119")
            XCTAssertEqual(self.mockMessageGenerator.generatedMessage?.candidate?.sdp, "dummy_sdp")
        }
    }


}
