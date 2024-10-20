//
//  SignalParserTests.swift
//  WebRTCExampleTests
//
//  Created by Baran Karaoğuz on 20.10.2024.
//

import Foundation
import XCTest
@testable import WebRTCExample

final class SignalParserTests: XCTestCase {

    var ipAddress: String!
    var signalParser: SignalParser!
    
    override func setUp() {
        super.setUp()
        ipAddress = "192.168.1.119"
        signalParser = SignalParser()
    }

    override func tearDown() {
        signalParser = nil
        ipAddress = nil
        super.tearDown()
    }
    
    func testWithValidSignalingMessageForDataResult() throws {
        // Arrange
        let signalingMessage = SignalingMessage(
            type: "offer",
            sessionDescription: SDPMessage(sdp: "valid_sdp"),
            senderProp: SenderProperties(ipAddress: ipAddress, name: "Sender"),
            candidate: nil
        )
        
        // Act
        let result = try signalParser.parseToData(signalingMessage)
        
        // Assert
        XCTAssertNotNil(result)
        let jsonString = String(data: result, encoding: .utf8)
        XCTAssertTrue(jsonString!.contains("\"type\":\"offer\""))
        XCTAssertTrue(jsonString!.contains("\"sdp\":\"valid_sdp\""))
        XCTAssertTrue(jsonString!.contains("\"ipAddress\":\"192.168.1.119\""))
    }

    func testWithValidSignalingMessageForStringResult() throws {
        // Arrange
        let signalingMessage = SignalingMessage(
            type: "answer",
            sessionDescription: SDPMessage(sdp: "sdp_answer"),
            senderProp: SenderProperties(ipAddress: ipAddress, name: "Sender"),
            candidate: nil
        )
        
        // Act
        let result = try signalParser.parseToString(signalingMessage)
        
        // Assert
        XCTAssertNotNil(result)
        XCTAssertTrue(result.contains("\"type\":\"answer\""))
        XCTAssertTrue(result.contains("\"sdp\":\"sdp_answer\""))
        XCTAssertTrue(result.contains("\"ipAddress\":\"192.168.1.119\""))
    }
    
}

