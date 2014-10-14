//
//  GameKitHelper.swift
//  SwiftCircuitRacer
//
//  Created by Shayne Meyer on 10/11/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

import GameKit
import Foundation

let singleton = GameKitHelper()
let PresentAuthenticationViewController = "PresentAuthenticationViewController"

protocol GameKitHelperDelegate {
    func matchStarted()
    func matchEnded()
    func matchReceivedData(match: GKMatch, data: NSData, fromPlayer player: String)
}

class GameKitHelper: NSObject, GKGameCenterControllerDelegate, GKMatchmakerViewControllerDelegate, GKMatchDelegate {
    var authenticationViewController: UIViewController?
    var lastError:NSError?
    var gameCenterEnabled: Bool
    
    var delegate: GameKitHelperDelegate?
    var multiplayerMatch: GKMatch?
    var presentingViewController: UIViewController?
    var multiplayerMatchStarted: Bool
    
    class var sharedInstance: GameKitHelper {
        return singleton
    }
    
    override init() {
        gameCenterEnabled = true
        multiplayerMatchStarted = false
        super.init()
    }
    
    func authenticateLocalPlayer() {
        //
        let localPlayer = GKLocalPlayer.localPlayer()
        localPlayer.authenticateHandler = {(viewController, error) in
            // store any error in local variable
            self.lastError = error
            
            if viewController != nil {
                // if user hasnt logged into game center show game center login controller
                self.authenticationViewController = viewController
                
                NSNotificationCenter.defaultCenter().postNotificationName(PresentAuthenticationViewController, object: self)
            } else if localPlayer.authenticated {
                // if logged in
                self.gameCenterEnabled = true
            } else {
                // not logged in
                self.gameCenterEnabled = false
            }
        }
    }
    
    func reportAchievements(achievements: [GKAchievement]) {
        if !gameCenterEnabled {
            println("Local player is not authenticated")
            return
        }
        GKAchievement.reportAchievements(achievements) {(error) in
            self.lastError = error
        }
    }
    
    // MARK: GameCenter Methods
    
    func showGKGameCenterViewController(viewController: UIViewController!) {
        if !gameCenterEnabled {
            println("Local player is not authenticated")
            return
        }
        // initialize
        let gameCenterViewController = GKGameCenterViewController()
        
        // set the delegate
        gameCenterViewController.gameCenterDelegate = self
        
        // set default view state to Leaderboards
        gameCenterViewController.viewState = .Leaderboards
        
        // present controller
        viewController.presentViewController(gameCenterViewController, animated: true, completion: nil)
    }
    
    func reportScore(score: Int64, forLeaderboardId leaderBoardId: String) {
        if !gameCenterEnabled {
            println("Local player is not authenticated")
            return
        }
        
        // GameCenter expects scores to be a GKScore object.
        let scoreReporter = GKScore(leaderboardIdentifier: leaderBoardId)
        scoreReporter.value = score
        scoreReporter.context = 0
        
        let scores = [scoreReporter]
        
        // This code calls the completion handler when Game Center is done processing the scores, and again, this method takes care of auto-sensing scores on network failures.
        GKScore.reportScores(scores) { (error) in
            self.lastError = error
        }
    }
    
    // MARK: GameCenter - Multiplayer Methods
    
    func findMatch(minPlayers: Int, maxPlayers: Int, presentingViewController viewController: UIViewController, delegate: GameKitHelperDelegate) {
        // exit if player is not authenticated
        if !gameCenterEnabled {
            println("Local player is not authenticated")
            return
        }
        
        // if authenticated set variables
        multiplayerMatchStarted = false
        multiplayerMatch = nil
        self.delegate = delegate
        presentingViewController = viewController
        
        // create a request with the appropriate criteria
        let matchRequest = GKMatchRequest()
        matchRequest.minPlayers = minPlayers
        matchRequest.maxPlayers = maxPlayers
        
        //
        let matchMakerViewController = GKMatchmakerViewController(matchRequest: matchRequest)
        matchMakerViewController.matchmakerDelegate = self
        presentingViewController?.presentViewController(matchMakerViewController, animated: false, completion: nil)
    }
    
    // MARK: GameCenter - GKMatchDelegate Methods
    
    func match(match: GKMatch!, didReceiveData data: NSData!, fromPlayer playerID: String!) {
        if multiplayerMatch != match {
            return
        }
        delegate?.matchReceivedData(match, data: data, fromPlayer: playerID)
    }
    
    func match(match: GKMatch!, didFailWithError error: NSError!) {
        if multiplayerMatch != match {
            return
        }
        multiplayerMatchStarted = false
        delegate?.matchEnded()
    }
    
    func match(match: GKMatch!, player playerID: String!, didChangeState state: GKPlayerConnectionState) {
        if multiplayerMatch != match {
            return
        }
        switch state {
        case .StateConnected:
            println("Player connected")
            if !multiplayerMatchStarted && multiplayerMatch?.expectedPlayerCount == 0 {
                println("Ready to start the match")
                multiplayerMatchStarted = true
                delegate?.matchStarted()
            }
        case .StateDisconnected:
            println("Player disconnected")
            multiplayerMatchStarted = false
            delegate?.matchEnded()
        case .StateUnknown:
            println("Initial player state")
        }
    }
    
    // MARK: GKGameCenterControllerDelegate methods
    
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController!) {
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: GameCenter - GKMatchmakerViewControllerDelegate Methods
    
    func matchmakerViewControllerWasCancelled(viewController: GKMatchmakerViewController!) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        delegate?.matchEnded()
    }
    
    func matchmakerViewController(viewController: GKMatchmakerViewController!, didFailWithError error: NSError!) {
        presentingViewController?.dismissViewControllerAnimated(true
            , completion: nil)
        println("Error creating match: \(error.localizedDescription)")
        delegate?.matchEnded()
    }
    
    func matchmakerViewController(viewController: GKMatchmakerViewController!, didFindMatch match: GKMatch!) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
        multiplayerMatch = match
        multiplayerMatch!.delegate = self
        
        if !multiplayerMatchStarted && multiplayerMatch?.expectedPlayerCount == 0 {
            println("Ready to start the match")
            multiplayerMatchStarted = true
            delegate?.matchStarted()
        }
    }
}
