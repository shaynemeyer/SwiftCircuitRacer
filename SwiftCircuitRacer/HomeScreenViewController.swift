//
//  HomeScreenViewController.swift
//  SwiftCircuitRacer
//
//  Created by Shayne Meyer on 10/11/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

import UIKit

class HomeScreenViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IBAction Methods
    @IBAction func playGame(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect("button_press.wav")
        
        if let storyboard = storyboard {
            let carViewController = storyboard.instantiateViewControllerWithIdentifier("SelectCarViewController") as SelectCarViewController
            
            navigationController?.pushViewController(carViewController, animated: true)
        }
    }
    
    @IBAction func gameCenter(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect("button_press.wav")
        GameKitHelper.sharedInstance.showGKGameCenterViewController(self)
    }
}
