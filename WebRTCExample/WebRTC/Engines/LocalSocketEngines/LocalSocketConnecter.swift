//
//  LocalSocketConnecter.swift
//  WebRTCExample
//
//  Created by Baran Karaoğuz on 19.10.2024.
//

import Foundation
import Network

protocol LocalSocketConnectable {
    var messageReceivedCallback: Callback<String>? { get set }
    func listen()
    func send(message: String, to host: String) async throws
}

final class LocalSocketConnecter: LocalSocketConnectable {
    private var listenPort: UInt16 = 50004
    private var connection: NWConnection?
    private let listener: NWListener!
    private let queue = DispatchQueue(label: "udp_client_queue")
    
    var messageReceivedCallback: Callback<String>?
    
    enum ErrorType: Error {
        case sendMessageDataParseError
        case sendMessageDataError
    }

    init() {
        let parameters = NWParameters.udp
        do {
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: listenPort)!)
        } catch {
            print("Listener create error: \(error.localizedDescription)")
            fatalError()
        }
    }
    
    
    func listen() {
        listener.newConnectionHandler = { [weak self] connection in
            guard let self else { return }
            connection.start(queue: self.queue)
            self.receiveMessage(on: connection)
        }
        listener.start(queue: queue)
    }
    
    func receiveMessage(on connection: NWConnection) {
        connection.receiveMessage { [weak self] (data, _, _, error) in
            guard let self else { return }
            if error != nil {
                print("LocalSocketManager receive message error: \(error!.localizedDescription)")
                return
            }
            if let data = data, let message = String(data: data, encoding: .utf8) {
                self.messageReceivedCallback?(message)
            }
            self.receiveMessage(on: connection)
        }
    }
    
    func send(message: String, to host: String) async throws {
        let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: listenPort)!, using: .udp)
        connection.start(queue: queue)
        guard let data = message.data(using: .utf8), !data.isEmpty else {
            throw ErrorType.sendMessageDataParseError
        }
        return try await withCheckedThrowingContinuation({ continuation in
           connection.send(content: data, completion: .contentProcessed({ error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
                connection.cancel()
            }))
        })
    }
}
