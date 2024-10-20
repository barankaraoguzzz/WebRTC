//
//  LocalSocketDataProvider.swift
//  WebRTCExample
//
//  Created by Baran Karaoğuz on 19.10.2024.
//

import Foundation
import Combine

protocol LocalSocketDataNotifiable {
    func send(messageModel: SignalingMessage, to host: String) async throws
    func startListening()
    func observe(_ completion: @escaping Callback<SignalingMessage>)
}

final class LocalSocketDataNotifier: LocalSocketDataNotifiable {
    
    private var cancellable: AnyCancellable?
    private let publisher: AnyPublisher<String?, Never>!
    private let provider: LocalSocketDataProvider
    private let signalParser: SignalParsable
    private let signalGenerator: SignalGeneratable
    
    public init(
        provider: LocalSocketDataProvider = LocalSocketDataProvider.shared,
        signalParser: SignalParsable = SignalParser(),
        signalGenerator: SignalGeneratable = SignalGenerator()
    ) {
        self.provider = provider
        self.signalParser = signalParser
        self.signalGenerator = signalGenerator
        self.publisher = provider.$signalingMessage
            .eraseToAnyPublisher()
    }
    
    public func send(messageModel: SignalingMessage, to host: String) async throws {
        let message = try signalParser.parseToString(messageModel)
        try await provider.send(message: message, to: host)
    }
    
    func startListening() {
        provider.startListening()
    }
    
    func observe(_ completion: @escaping Callback<SignalingMessage>) {
        cancellable = publisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveValue: { [weak self] response in
                    guard let self else { return }
                    guard let signalMessage = response else { return }
                    do {
                        let signalingModel = try signalGenerator.generateSignalMessage(from: signalMessage)
                        completion(signalingModel)
                    } catch(let error) {
                        print("Signaling model generate error: \(error.localizedDescription)")
                    }
            })
    }
}

class LocalSocketDataProvider {
    private var socketConnecter: LocalSocketConnectable
    public static let shared = LocalSocketDataProvider()
    @Published public var signalingMessage: String?
    
    public init(socketConnecter: LocalSocketConnectable = LocalSocketConnecter()) {
        self.socketConnecter = socketConnecter
        socketConnecter.listen()
    }
    
    func startListening() {
        socketConnecter.messageReceivedCallback = { [weak self] message in
            guard let self else { return }
            self.signalingMessage = message
        }
    }
    
    func send(message: String, to host: String) async throws {
        try await socketConnecter.send(message: message, to: host)
    }
    
}
