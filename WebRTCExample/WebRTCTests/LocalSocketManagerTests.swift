//
//  LocalSocketManagerTests.swift
//  WebRTCExampleTests
//
//  Created by Baran Karaoğuz on 20.10.2024.
//

import Foundation
import XCTest
import Network
@testable import WebRTCExample

final class LocalSocketConnecterTests: XCTestCase {

    var localSocketConnecter: LocalSocketConnectable!
    
    override func setUp() {
        super.setUp()
        localSocketConnecter = LocalSocketConnecter()
    }

    override func tearDown() {
        localSocketConnecter = nil
        super.tearDown()
    }
    
    func testShouldSendValidMessage() async throws {
        let message = "Hello, World!"
        let host = "localhost"
        
        do {
            try await localSocketConnecter.send(message: message, to: host)
        } catch {
            XCTFail("send(message:to:) threw an error: \(error)")
        }
    }

    func testShouldThrowParseErrorWhenMessageCannotBeConverted() async throws {
        let invalidMessage = String(bytes: [0xD8, 0x00] as [UInt8], encoding: .utf8) // Geçersiz string
        let host = "localhost"

        do {
            try await localSocketConnecter.send(message: invalidMessage ?? "", to: host)
            XCTFail("Expected to throw sendMessageDataParseError, but no error was thrown")
        } catch let error as LocalSocketConnecter.ErrorType {
            XCTAssertEqual(error, .sendMessageDataParseError)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
}
