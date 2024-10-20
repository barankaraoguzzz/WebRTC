//
//  SignalParser.swift
//  WebRTCExample
//
//  Created by Baran Karaoğuz on 19.10.2024.
//

import Foundation

protocol SignalParsable {
    func parseToData(_ signal: SignalingMessage) throws -> Data
    func parseToString(_ signal: SignalingMessage) throws -> String
}

final class SignalParser: SignalParsable {
    
    enum ErrorType: Error {
        case dataConvertError
    }
    
    
    func parseToData(_ signal: SignalingMessage) throws -> Data {
        let data = try JSONEncoder().encode(signal)
        return data
    }
    
    func parseToString(_ signal: SignalingMessage) throws -> String {
        let data = try parseToData(signal)
        guard let message = String(data: data, encoding: .utf8) else {
            throw ErrorType.dataConvertError
        }
        return message
    }
    
    
}
