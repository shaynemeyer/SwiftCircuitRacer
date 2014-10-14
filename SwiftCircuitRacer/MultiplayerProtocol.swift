//
//  MultiplayerProtocol.swift
//  SwiftCircuitRacer
//
//  Created by Shayne Meyer on 10/13/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

import Foundation
import GameKit

protocol MultiplayerProtocol {
    func matchEnded()
}

class MultiplayerNetworking: NSObject, GameKitHelperDelegate {
    var delegate: MultiplayerProtocol?
    var noOfLaps: Int?
    
    // MARK: GameKitHelperDelegate methods
    func matchStarted() {
        println("Match has started successfuly")
    }
    
    func matchEnded() {
        delegate?.matchEnded()
    }
    
    func matchReceivedData(match: GKMatch, data: NSData, fromPlayer player: String) {
        
    }
}