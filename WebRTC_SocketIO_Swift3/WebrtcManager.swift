//
//  WebrtcManager.swift
//  ConnectedColors
//
//  Created by Mahabali on 4/8/16.
//  Copyright © 2016 Ralf Ebert. All rights reserved.
//

import Foundation
import AVFoundation
class WebrtcManager: NSObject,RTCPeerConnectionDelegate,RTCSessionDescriptionDelegate {
  var peerConnection:RTCPeerConnection?
  var peerConnectionFactory:RTCPeerConnectionFactory?
  var videoCapturer:RTCVideoCapturer?
  var localAudioTrack:RTCAudioTrack?
  var localVideoTrack:RTCVideoTrack?
  var localSDP:RTCSessionDescription?
  var remoteSDP:RTCSessionDescription?
  var delegate:WebrtcManagerProtocol?
  var localStream:RTCMediaStream?
  var unusedICECandidates:[RTCICECandidate] = []
  var initiator = false
  
  override init() {
    super.init()
    peerConnectionFactory = RTCPeerConnectionFactory.init()
    let iceServer = RTCICEServer.init(uri: URL(string: "stun:stun.l.google.com:19302"), username: "", password: "")
    peerConnection = peerConnectionFactory?.peerConnection(withICEServers: [iceServer], constraints: RTCMediaConstraints(mandatoryConstraints: nil,optionalConstraints: [RTCPair.init(key: "DtlsSrtpKeyAgreement", value: "true")]), delegate: self)
  }
  
  func addLocalMediaStream(){
    var cameraID: String?
    for captureDevice in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {
      // Support Front cam alone, as it's suitable for video conferencing
      if (captureDevice as AnyObject).position == AVCaptureDevicePosition.front {
        cameraID = (captureDevice as AnyObject).localizedName
      }
    }
    let videoCapturer = RTCVideoCapturer(deviceName: cameraID)
    self.videoCapturer = videoCapturer
    let videoSource = peerConnectionFactory?.videoSource(with: videoCapturer, constraints: nil)
    let videoTrack = peerConnectionFactory?.videoTrack(withID: "ARDAMSv0", source: videoSource)
    localStream = peerConnectionFactory?.mediaStream(withLabel: "ARDAMS")
    let audioTrack = peerConnectionFactory?.audioTrack(withID: "ARDAMSa0")
    localAudioTrack = audioTrack
    localVideoTrack = videoTrack
    localStream?.addVideoTrack(videoTrack)
    localStream?.addAudioTrack(audioTrack)
    DispatchQueue.main.async { 
    
    }
    self.peerConnection?.add(localStream!)
    self.delegate?.localStreamAvailable(localStream!)
  }
  
  func startWebrtcConnection(){
    if (initiator){
      self.createOffer()
    }
    else{
      self.waitForAnswer()
    }
  }
  
  func createOffer(){
    addLocalMediaStream()
    let offerContratints = createConstraints()
    self.peerConnection?.createOffer(with: self, constraints: offerContratints)
  }
  
  func createConstraints() -> RTCMediaConstraints{
    let pairOfferToReceiveAudio = RTCPair(key: "OfferToReceiveAudio", value: "true")
    let pairOfferToReceiveVideo = RTCPair(key: "OfferToReceiveVideo", value: "true")
    let pairDtlsSrtpKeyAgreement = RTCPair(key: "DtlsSrtpKeyAgreement", value: "true")
    let peerConnectionConstraints = RTCMediaConstraints(mandatoryConstraints: [pairOfferToReceiveVideo,pairOfferToReceiveAudio], optionalConstraints: [pairDtlsSrtpKeyAgreement])
    return peerConnectionConstraints!
  }
  
  func waitForAnswer(){
    // Do nothing. Maybe initialize something here. Nothing for this example
  }
  
  func createAnswer(){
    DispatchQueue.main.async { 
      let remoteSDP = self.remoteSDP!
      self.addLocalMediaStream()
      self.peerConnection!.setRemoteDescriptionWith(self, sessionDescription: remoteSDP)
    }
      }
  
  func setAnswerSDP(){
    DispatchQueue.main.async {
      self.peerConnection?.setRemoteDescriptionWith(self, sessionDescription: self.remoteSDP)
      self.addUnusedIceCandidates()
    }
    
  }
  
  func setICECandidates(_ iceCandidate:RTCICECandidate){
    DispatchQueue.main.async {
      self.peerConnection?.add(iceCandidate)
    }
  }
  
  func addUnusedIceCandidates(){
    for (iceCandidate) in self.unusedICECandidates{
      print("added unused ices")
      self.peerConnection?.add(iceCandidate)
    }
    self.unusedICECandidates = []
  }
  func peerConnection(_ peerConnection: RTCPeerConnection!, addedStream stream: RTCMediaStream!) {
    print("Log: PEER CONNECTION:- Stream Added")
    self.delegate?.remoteStreamAvailable(stream)
  }
  
  func peerConnection(_ peerConnection: RTCPeerConnection!, gotICECandidate candidate: RTCICECandidate!) {
    print("PEER CONNECTION:- Got ICE Candidate - \(candidate)")
    self.delegate?.iceCandidatesCreated(candidate)
 
  }
  func peerConnection(_ peerConnection: RTCPeerConnection!, iceConnectionChanged newState: RTCICEConnectionState)
  {
    print("PEER CONNECTION:- ICE Connection Changed \(newState)")
  }
  func peerConnection(_ peerConnection: RTCPeerConnection!, iceGatheringChanged newState: RTCICEGatheringState) {
    print("PEER CONNECTION:- ICE Gathering Changed - \(newState)")
  
  }
  func peerConnection(_ peerConnection: RTCPeerConnection!, removedStream stream: RTCMediaStream!) {
    print("PEER CONNECTION:- Stream Removed")
  }
  func peerConnection(_ peerConnection: RTCPeerConnection!, signalingStateChanged stateChanged: RTCSignalingState){
    print("PEER CONNECTION:- Signaling State Changed \(stateChanged)")
  }
  func peerConnection(onRenegotiationNeeded peerConnection: RTCPeerConnection!) {
    print("PEER CONNECTION:- Renegotiation Needed")
  }
  
  func peerConnection(_ peerConnection:RTCPeerConnection!, didOpen dataChannel:RTCDataChannel) {
    print("PEER CONNECTION:- Open Data Channel")
  }

  func peerConnection(_ peerConnection: RTCPeerConnection!, didCreateSessionDescription sdp: RTCSessionDescription!, error: Error!) {
    if let er = error {
      print(er.localizedDescription)
    }
    if(sdp == nil) {
      print("Problem creating SDP - \(sdp)")
    } else {
      
      print("SDP created -: \(sdp)")
    }
    self.localSDP = sdp
    self.peerConnection?.setLocalDescriptionWith(self, sessionDescription: sdp)
    if (initiator){
      self.delegate?.offerSDPCreated(sdp)
    }
    else{
      self.delegate?.answerSDPCreated(sdp)
    }
  }
  
  func peerConnection(_ peerConnection: RTCPeerConnection!, didSetSessionDescriptionWithError error: Error!) {
    if error != nil{
    print("sdp error \(error.localizedDescription) \(error)")
    }
    else{
      print("SDP set success")
      if initiator == false && self.localSDP == nil{
      
        let answerConstraints = self.createConstraints()
        self.peerConnection!.createAnswer(with: self, constraints: answerConstraints)
      }
    }
  }
  
  // Called when the data channel state has changed.
  func channelDidChangeState(_ channel:RTCDataChannel){

  }
  
  func channel(_ channel: RTCDataChannel!, didReceiveMessageWithBuffer buffer: RTCDataBuffer!) {
   self.delegate?.dataReceivedInChannel(buffer.data)
  }
  func disconnect(){
    self.peerConnection?.close()
  }
}
