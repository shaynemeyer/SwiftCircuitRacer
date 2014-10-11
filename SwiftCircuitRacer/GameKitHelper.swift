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

class GameKitHelper: NSObject, GKGameCenterControllerDelegate {
    var authenticationViewController: UIViewController?
    var lastError:NSError?
    var gameCenterEnabled: Bool
    
    class var sharedInstance: GameKitHelper {
        return singleton
    }
    
    override init() {
        gameCenterEnabled = true
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
        
        // set default view state to Achievements
        gameCenterViewController.viewState = .Achievements
        
        // present controller
        viewController.presentViewController(gameCenterViewController, animated: true, completion: nil)
    }
    
    func gameCenterViewControllerDidFinish(gameCenterViewController: GKGameCenterViewController!) {
        gameCenterViewController.dismissViewControllerAnimated(true, completion: nil)
    }
}
