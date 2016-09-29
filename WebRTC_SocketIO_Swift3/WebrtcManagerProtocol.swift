//
//  WebrtcManagerProtocol.swift
//  ConnectedColors
//
//  Created by Mahabali on 4/8/16.
//  Copyright © 2016 Ralf Ebert. All rights reserved.
//

import Foundation
@objc protocol WebrtcManagerProtocol {

  func offerSDPCreated(_ sdp:RTCSessionDescription)
  func localStreamAvailable(_ stream:RTCMediaStream)
  func remoteStreamAvailable(_ stream:RTCMediaStream)
  func answerSDPCreated(_ sdp:RTCSessionDescription)
  func iceCandidatesCreated(_ iceCandidate:RTCICECandidate)
  func dataReceivedInChannel(_ data:Data)
}
