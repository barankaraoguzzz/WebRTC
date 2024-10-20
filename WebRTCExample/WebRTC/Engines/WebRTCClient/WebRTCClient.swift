//
//  WebRTCClient.swift
//  WebRTCExample
//
//  Created by Baran Karaoğuz on 19.10.2024.
//

import Foundation
import WebRTC


protocol WebRTCClientDelegate {
    func didStateChanged(didChange stateChanged: RTCSignalingState)
    func didIceConnectionStateChanged(didChange newState: RTCIceConnectionState)
    func didGenerateCandidate(didGenerate candidate: RTCIceCandidate)
    func didConnect()
    func didDisconnect()
}

protocol WebRTCClientProtocol: AnyObject {
    var delegate: WebRTCClientDelegate? { get set }
    var localView: UIView! { get }
    var remoteView: UIView! { get }
    func setup()
    func connect()
    func disconnect()
    func makeOffer() async throws -> RTCSessionDescription
    func makeAnswer() async throws -> RTCSessionDescription
    func receiveOffer(from sdp: RTCSessionDescription) async throws
    func receiveAnswer(from sdp: RTCSessionDescription) async throws
    func receiveCandidate(candidate: RTCIceCandidate)
    
    func toggleSpeaker(_ isSpeakerOn: Bool)
    func toggleMute(_ isMuted: Bool)
    func switchCamera()
}

final class WebRTCClient: NSObject, WebRTCClientProtocol {
    
    enum ErrorType: Error {
        case peerConnectionIsNil
    }
    
    var delegate: WebRTCClientDelegate?
    public private(set) var isConnected: Bool = false
    private var peerConnection: RTCPeerConnection?
    private var videoCapturer: RTCCameraVideoCapturer!
    private var peerConnectionFactory: RTCPeerConnectionFactory!
    private var localVideoTrack: RTCVideoTrack!
    private var localAudioTrack: RTCAudioTrack!
    private var remoteStream: RTCMediaStream?
    
    /// For views
    private var localRenderView: RTCEAGLVideoView?
    private(set) var localView: UIView!
    private var remoteRenderView: RTCEAGLVideoView?
    private(set) var remoteView: UIView!
    
    func setup(){
        createPeerConnectionFactory()
        setupView()
        setupLocalTracks()
        startCaptureLocalVideo(cameraPositon: .front, videoWidth: 640, videoHeight: 640*16/9, videoFps: 30)
    }
    
    func connect() {
        self.peerConnection = setupPeerConnection()
        self.peerConnection!.delegate = self
        self.peerConnection!.add(localVideoTrack, streamIds: ["stream0"])
        self.peerConnection!.add(localAudioTrack, streamIds: ["stream0"])
    }
    
    func disconnect(){
        if self.peerConnection != nil {
            self.peerConnection!.close()
            self.peerConnectionFactory = nil
            self.peerConnection = nil
        }
        createPeerConnectionFactory()
    }
    
    func makeOffer() async throws -> RTCSessionDescription {
        guard let peerConnection else {
            throw ErrorType.peerConnectionIsNil
        }
        
        let sessionDescription = try await peerConnection.offer(for: .init(mandatoryConstraints: nil, optionalConstraints: nil))
        try await peerConnection.setLocalDescription(sessionDescription)
        return sessionDescription
        
    }
    
    func makeAnswer() async throws -> RTCSessionDescription {
        guard let peerConnection else {
            throw ErrorType.peerConnectionIsNil
        }
        
        let sessionDescription = try await peerConnection.answer(for: .init(mandatoryConstraints: nil, optionalConstraints: nil))
        try await peerConnection.setLocalDescription(sessionDescription)
        return sessionDescription
        
    }
    
    func receiveOffer(from sdp: RTCSessionDescription) async throws {
        if self.peerConnection == nil {
            self.connect()
        }
        try await self.peerConnection!.setRemoteDescription(sdp)
    }
    
    func receiveAnswer(from sdp: RTCSessionDescription) async throws {
        try await self.peerConnection!.setRemoteDescription(sdp)
    }
    
    func receiveCandidate(candidate: RTCIceCandidate) {
        self.peerConnection!.add(candidate)
    }
    
    func toggleSpeaker(_ isSpeakerOn: Bool) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, options: isSpeakerOn ? .defaultToSpeaker : [])
            try audioSession.setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
    
    func toggleMute(_ isMuted: Bool) {
        if let audioTrack = peerConnection?.senders.compactMap({ $0.track }).first(where: { $0.kind == "audio" }) as? RTCAudioTrack {
            audioTrack.isEnabled = !isMuted // true ise ses açık, false ise sessiz
        }
    }
    
    func switchCamera() {
        guard let capturer = videoCapturer else { return }
        let currentPosition = capturer.captureSession.inputs.first?.ports.first?.sourceDevicePosition

        let newPosition: AVCaptureDevice.Position = (currentPosition == .front) ? .back : .front
        let devices = RTCCameraVideoCapturer.captureDevices()
        
        if let newCamera = devices.first(where: { $0.position == newPosition }) {
            let formats = RTCCameraVideoCapturer.supportedFormats(for: newCamera)
            let fps = formats.first?.videoSupportedFrameRateRanges.first?.maxFrameRate ?? 30
            
            capturer.stopCapture {
                capturer.startCapture(with: newCamera, format: formats.first!, fps: Int(fps))
            }
        }
    }
}

//MARK: - Private Methods
extension WebRTCClient {
    
    private func createPeerConnectionFactory() {
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        self.peerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }
    
    private func setupView(){
        //TODO: - For Local Renderer
        localRenderView = RTCEAGLVideoView()
        localRenderView!.delegate = self
        localRenderView!.contentMode = .scaleAspectFit
        localView = UIView()
        localView.addSubview(localRenderView!)
        localRenderView!.translatesAutoresizingMaskIntoConstraints = false
        localRenderView?.fit(to: localView)
        
        //TODO: - For Remote Renderer
        remoteRenderView = RTCEAGLVideoView()
        remoteRenderView!.delegate = self
        remoteRenderView!.contentMode = .scaleAspectFit
        remoteView = UIView()
        remoteView.addSubview(remoteRenderView!)
        remoteRenderView!.translatesAutoresizingMaskIntoConstraints = false
        remoteRenderView?.fit(to: remoteView)
    }
    
    private func setupLocalTracks(){
        self.localVideoTrack = createVideoTrack()
        self.localAudioTrack = createAudioTrack()
    }
    
    private func createAudioTrack() -> RTCAudioTrack {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = self.peerConnectionFactory.audioSource(with: audioConstrains)
        let audioTrack = self.peerConnectionFactory.audioTrack(with: audioSource, trackId: "audio0")
        
        return audioTrack
    }
    
    private func createVideoTrack() -> RTCVideoTrack {
        let videoSource = self.peerConnectionFactory.videoSource()
        self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        let videoTrack = self.peerConnectionFactory.videoTrack(with: videoSource, trackId: "video0")
        return videoTrack
    }
    
    private func startCaptureLocalVideo(cameraPositon: AVCaptureDevice.Position, videoWidth: Int, videoHeight: Int?, videoFps: Int) {
        var targetDevice: AVCaptureDevice?
        var targetFormat: AVCaptureDevice.Format?
        
        let devicies = RTCCameraVideoCapturer.captureDevices()
        devicies.forEach { (device) in
            if device.position ==  cameraPositon{
                targetDevice = device
            }
        }
        
        let formats = RTCCameraVideoCapturer.supportedFormats(for: targetDevice!)
        formats.forEach { (format) in
            for _ in format.videoSupportedFrameRateRanges {
                let description = format.formatDescription as CMFormatDescription
                let dimensions = CMVideoFormatDescriptionGetDimensions(description)
                
                if dimensions.width == videoWidth && dimensions.height == videoHeight ?? 0{
                    targetFormat = format
                } else if dimensions.width == videoWidth {
                    targetFormat = format
                }
            }
        }
        
        videoCapturer.startCapture(with: targetDevice!,
                                   format: targetFormat!,
                                   fps: videoFps)
        self.localVideoTrack?.add(self.localRenderView!)
    }
    
    private func setupPeerConnection() -> RTCPeerConnection {
        let rtcConf = RTCConfiguration()
        rtcConf.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        let mediaConstraints = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)
        let peerConnection = self.peerConnectionFactory.peerConnection(with: rtcConf, constraints: mediaConstraints, delegate: nil)
        return peerConnection
    }
    
    private func onConnected(){
        self.isConnected = true
        Task { @MainActor in
            self.remoteRenderView?.isHidden = false
            self.delegate?.didConnect()
        }
    }
    
    private func onDisConnected(){
        self.isConnected = false
        Task { @MainActor in
            self.peerConnection?.close()
            self.peerConnection = nil
            self.remoteRenderView?.isHidden = true
            self.delegate?.didDisconnect()
        }
    }
}

extension WebRTCClient: RTCVideoViewDelegate {
    func videoView(_ videoView: any RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        let isLandScape = size.width < size.height
        var renderView: RTCEAGLVideoView?
        var parentView: UIView?
        if videoView.isEqual(localRenderView) {
            renderView = localRenderView
            parentView = localView
        }
        
        if videoView.isEqual(remoteRenderView!) {
            renderView = remoteRenderView
            parentView = remoteView
        }
        
        guard let _renderView = renderView, let _parentView = parentView else { return }
        
        if (isLandScape) {
            let ratio = size.width / size.height
            _renderView.frame = CGRect(x: 0, y: 0, width: _parentView.frame.height * ratio, height: _parentView.frame.height)
            _renderView.center.x = _parentView.frame.width/2
        } else{
            let ratio = size.height / size.width
            _renderView.frame = CGRect(x: 0, y: 0, width: _parentView.frame.width, height: _parentView.frame.width * ratio)
            _renderView.center.y = _parentView.frame.height/2
        }
    }
}

extension WebRTCClient: RTCPeerConnectionDelegate {
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        self.delegate?.didStateChanged(didChange: stateChanged)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        self.remoteStream = stream
        if let track = stream.videoTracks.first {
          track.add(remoteRenderView!)
        }
        if let audioTrack = stream.audioTracks.first{
          audioTrack.source.volume = 10
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        switch newState {
        case .connected, .completed:
          if !self.isConnected {
            self.onConnected()
          }
        default:
          if self.isConnected{
            self.onDisConnected()
          }
        }
        
        Task { @MainActor in
            self.delegate?.didIceConnectionStateChanged(didChange: newState)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.delegate?.didGenerateCandidate(didGenerate: candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) { }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) { }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) { }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) { }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) { }
}
