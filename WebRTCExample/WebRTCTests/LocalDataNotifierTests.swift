//
//  LocalDataNotifierTests.swift
//  WebRTCExampleTests
//
//  Created by Baran Karaoğuz on 20.10.2024.
//

import Foundation
import XCTest
import Combine
import WebRTC
@testable import WebRTCExample

// Mock sınıfları oluşturuyoruz
final class MockSocketConnecter: LocalSocketConnectable {
    var messageReceivedCallback: Callback<String>?
    var isListeningStarted = false
    var sentMessages = [(String, String)]()
    
    func listen() {
        isListeningStarted = true
    }
    
    func send(message: String, to host: String) async throws {
        sentMessages.append((message, host))
    }
}

final class MockSignalParser: SignalParsable {
    var mockParsedString: String?
    var shouldThrowError = false
    
    func parseToData(_ signal: SignalingMessage) throws -> Data {
        throw NSError() // Bu testte gerek yok
    }
    
    func parseToString(_ signal: SignalingMessage) throws -> String {
        if shouldThrowError {
            throw SignalParser.ErrorType.dataConvertError
        }
        return mockParsedString ?? ""
    }
}

fileprivate final class MockSignalGenerator: SignalGeneratable {
    var mockSignalMessage: SignalingMessage?
    
    func generateSignalMessage(from sessionDescription: RTCSessionDescription, senderProp: SenderProperties) throws -> SignalingMessage {
        return mockSignalMessage!
    }
    
    func generateSignalMessage(from iceCandidate: RTCIceCandidate) throws -> SignalingMessage {
        return mockSignalMessage!
    }
    
    func generateSignalMessage(from sdp: String) throws -> SignalingMessage {
        return mockSignalMessage!
    }
}

fileprivate final class LocalSocketDataNotifierTests: XCTestCase {
    
    var mockSocketConnecter: MockSocketConnecter!
    var mockSignalParser: MockSignalParser!
    var mockSignalGenerator: MockSignalGenerator!
    var dataNotifier: LocalSocketDataNotifier!
    
    override func setUp() {
        super.setUp()
        mockSocketConnecter = MockSocketConnecter()
        mockSignalParser = MockSignalParser()
        mockSignalGenerator = MockSignalGenerator()
        
        let provider = LocalSocketDataProvider(socketConnecter: mockSocketConnecter)
        dataNotifier = LocalSocketDataNotifier(provider: provider, signalParser: mockSignalParser, signalGenerator: mockSignalGenerator)
    }
    
    override func tearDown() {
        dataNotifier = nil
        mockSignalParser = nil
        mockSocketConnecter = nil
        mockSignalGenerator = nil
        super.tearDown()
    }
    
    func testShouldSendParsedMessage() async throws {
        let messageModel = SignalingMessage(type: "offer", sessionDescription: nil, senderProp: nil, candidate: nil)
        mockSignalParser.mockParsedString = "parsedMessage"
        
        try await dataNotifier.send(messageModel: messageModel, to: "localhost")
        
        XCTAssertEqual(mockSocketConnecter.sentMessages.count, 1)
        XCTAssertEqual(mockSocketConnecter.sentMessages.first?.0, "parsedMessage")
        XCTAssertEqual(mockSocketConnecter.sentMessages.first?.1, "localhost")
    }
    
    func testShouldThrowErrorWhenParseFails() async {
        
        let messageModel = SignalingMessage(type: "offer", sessionDescription: nil, senderProp: nil, candidate: nil)
        mockSignalParser.shouldThrowError = true
        
        do {
            try await dataNotifier.send(messageModel: messageModel, to: "localhost")
            XCTFail("Expected to throw, but succeeded")
        } catch {
            XCTAssertEqual(error as? SignalParser.ErrorType, .dataConvertError)
        }
    }
    
    func testShouldReceiveSignalingMessage() {
        let expectation = expectation(description: "Observe signaling message")
        let expectedSignalingMessage = SignalingMessage(type: "offer", sessionDescription: nil, senderProp: nil, candidate: nil)
        
        mockSignalGenerator.mockSignalMessage = expectedSignalingMessage
        
        dataNotifier.startListening()
        dataNotifier.observe { signalingMessage in
            XCTAssertEqual(signalingMessage.type, expectedSignalingMessage.type)
            expectation.fulfill()
        }
        mockSocketConnecter.messageReceivedCallback?("IncomingMessage")
        waitForExpectations(timeout: 1, handler: nil)
    }

    
    func testShouldStartSocketListening() {
        dataNotifier.startListening()
        
        XCTAssertTrue(mockSocketConnecter.isListeningStarted)
    }
}
