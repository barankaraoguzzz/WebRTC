//
//  SignalGenerator.swift
//  WebRTCExample
//
//  Created by Baran Karaoğuz on 19.10.2024.
//

import Foundation
import WebRTC

protocol SignalGeneratable {
    func generateSignalMessage(from sessionDescription: RTCSessionDescription, senderProp: SenderProperties) throws -> SignalingMessage
    func generateSignalMessage(from iceCandidate: RTCIceCandidate) throws -> SignalingMessage
    func generateSignalMessage(from sdp: String) throws -> SignalingMessage
}

final class SignalGenerator: SignalGeneratable {
    
    enum ErrorType: Error {
        case invalidSessionDescription
        case invalidMessageType
        case invalidIceCandidate
        case generateDataFromSdpStringError
    }
    
    
    func generateSignalMessage(from sessionDescription: RTCSessionDescription, senderProp: SenderProperties) throws -> SignalingMessage {
        let messageType = switch sessionDescription.type {
        case .offer: "offer"
        case .answer: "answer"
        case .prAnswer: "prAnswer"
        @unknown default: ""
        }
        
        if messageType.isEmpty {
            throw ErrorType.invalidMessageType
        }
        
        if sessionDescription.sdp.isEmpty {
            throw ErrorType.invalidSessionDescription
        }
        
        let sdpMessage = SDPMessage.init(sdp: sessionDescription.sdp)
        
        return .init(
            type: messageType,
            sessionDescription: sdpMessage,
            senderProp: senderProp,
            candidate: nil
        )
    }
    
    func generateSignalMessage(from iceCandidate: RTCIceCandidate) throws -> SignalingMessage {
        if iceCandidate.sdp.isEmpty {
            throw ErrorType.invalidIceCandidate
        }
         let candidate = CandidateModel.init(sdp: iceCandidate.sdp, sdpMLineIndex: iceCandidate.sdpMLineIndex, sdpMid: iceCandidate.sdpMid!)
        return .init(type: "candidate",
                     sessionDescription: nil,
                     senderProp: nil,
                     candidate: candidate)
    }
    
    func generateSignalMessage(from sdp: String) throws -> SignalingMessage {
        guard let sdpData = sdp.data(using: .utf8) else {
            throw ErrorType.generateDataFromSdpStringError
        }
        
        let signalingMessage = try JSONDecoder().decode(SignalingMessage.self, from: sdpData)
        return signalingMessage
    }
}
