//
//  SignalGeneratorTests.swift
//  WebRTCExample
//
//  Created by Baran Karaoğuz on 20.10.2024.
//

import XCTest
import WebRTC
@testable import WebRTCExample

final class SignalGeneratorTests: XCTestCase {
    
    var senderProperties: SenderProperties!
    var ipAddress: String!
    
    override func setUp() {
        super.setUp()
        ipAddress = "192.168.1.119"
        senderProperties = SenderProperties(ipAddress: ipAddress, name: "Sender")
    }
    
    override  func tearDown() {
        ipAddress = nil
        senderProperties = nil
        super.tearDown()
    }
    
    
    func testWithValidSessionDescription() throws {
        let sessionDescription = RTCSessionDescription(type: .offer, sdp: "valid_sdp")
        let signalGenerator = SignalGenerator()
        
        let result = try signalGenerator.generateSignalMessage(from: sessionDescription, senderProp: senderProperties)
        
        XCTAssertEqual(result.type, "offer")
        XCTAssertEqual(result.sessionDescription?.sdp, "valid_sdp")
        XCTAssertEqual(result.senderProp?.ipAddress, ipAddress)
    }
    
    func testWithEmptySdp() throws {
        let sessionDescription = RTCSessionDescription(type: .offer, sdp: "")
        let signalGenerator = SignalGenerator()
        
        XCTAssertThrowsError(try signalGenerator.generateSignalMessage(from: sessionDescription, senderProp: senderProperties)) { error in
            XCTAssertEqual(error as? SignalGenerator.ErrorType, .invalidSessionDescription)
        }
    }
    
    func testWithValidIceCandidate() throws {
        // Arrange
        let iceCandidate = RTCIceCandidate(sdp: "valid_candidate_sdp", sdpMLineIndex: 1, sdpMid: "0")
        let signalGenerator = SignalGenerator()
        
        // Act
        let result = try signalGenerator.generateSignalMessage(from: iceCandidate)
        
        // Assert
        XCTAssertEqual(result.type, "candidate")
        XCTAssertEqual(result.candidate?.sdp, "valid_candidate_sdp")
        XCTAssertEqual(result.candidate?.sdpMLineIndex, 1)
        XCTAssertEqual(result.candidate?.sdpMid, "0")
    }
    
    func testWithEmptyIceCandidateSdp() throws {
        // Arrange
        let iceCandidate = RTCIceCandidate(sdp: "", sdpMLineIndex: -1, sdpMid: "0")
        let signalGenerator = SignalGenerator()
        
        // Assert
        XCTAssertThrowsError(try signalGenerator.generateSignalMessage(from: iceCandidate)) { error in
            XCTAssertEqual(error as? SignalGenerator.ErrorType, .invalidIceCandidate)
        }
    }
    
    func testWithValidSdpString() throws {
        let sdpString = """
        {
            "type": "offer",
            "sessionDescription": {
                "sdp": "sdp_string"
            },
            "senderProp": {
                "ipAddress": "192.168.1.119",
                "name": "Sender"
            },
            "candidate": null
        }
        """
        let signalGenerator = SignalGenerator()
        
        let result = try signalGenerator.generateSignalMessage(from: sdpString)
        
        XCTAssertEqual(result.type, "offer")
        XCTAssertEqual(result.sessionDescription?.sdp, "sdp_string")
        XCTAssertEqual(result.senderProp?.ipAddress, ipAddress)
    }
    
    func testWithInvalidSdpString() throws {
        
        let invalidSdpString = "invalid_sdp_string"
        let signalGenerator = SignalGenerator()
        
        XCTAssertThrowsError(try signalGenerator.generateSignalMessage(from: invalidSdpString)) { error in
            XCTAssertNotNil(error)
        }
    }
}
