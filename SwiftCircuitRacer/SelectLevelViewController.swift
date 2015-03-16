//
//  SelectLevelViewController.swift
//  SwiftCircuitRacer
//
//  Created by Shayne Meyer on 10/4/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

import UIKit

class SelectLevelViewController: UIViewController {

    var carType: CarType!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: IBAction Methods
    @IBAction func backButtonPressed(sender: UIButton) {
        navigationController!.popViewControllerAnimated(true)
        SKTAudio.sharedInstance().playSoundEffect("button_press.wav")
    }
    
    @IBAction func levelButtonPressed(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect("button_press.wav")
        
        let levelType = LevelType(rawValue: sender.tag)
        
        let gameViewController = self.storyboard!.instantiateViewControllerWithIdentifier("GameViewController") as GameViewController
        
        gameViewController.carType = carType
        gameViewController.levelType = levelType
        
        navigationController!.pushViewController(gameViewController, animated: true)
    }

}
