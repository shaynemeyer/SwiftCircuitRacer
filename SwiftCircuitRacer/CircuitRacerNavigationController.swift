//
//  CircuitRacerNavigationController.swift
//  SwiftCircuitRacer
//
//  Created by Shayne Meyer on 10/11/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

import UIKit

class CircuitRacerNavigationController: UINavigationController {

    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: Selector("showAuthenticationViewController"),
            name: PresentAuthenticationViewController,
            object: nil)
        
        GameKitHelper.sharedInstance.authenticateLocalPlayer()
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showAuthenticationViewController() {
        let gameKitHelper = GameKitHelper.sharedInstance
        
        if let authenticationViewController = gameKitHelper.authenticationViewController {
            topViewController.presentViewController(authenticationViewController,
                animated: true,
                completion: nil)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}
