//
//  SignalingModels.swift
//  WebRTCExample
//
//  Created by Baran Karaoğuz on 19.10.2024.
//

import Foundation

struct SignalingMessage: Codable {
    let type: String
    let sessionDescription: SDPMessage?
    let senderProp: SenderProperties?
    let candidate: CandidateModel?
}

struct SDPMessage: Codable {
    let sdp: String
}

struct CandidateModel: Codable {
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String
}

struct SenderProperties: Codable {
    let ipAddress: String
    let name: String?
}
