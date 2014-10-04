//
//  SelectCarViewController.swift
//  SwiftCircuitRacer
//
//  Created by Shayne Meyer on 10/4/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

import UIKit

class SelectCarViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        SKTAudio.sharedInstance().playBackgroundMusic("circuitracer.mp3")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func carButtonPressed(sender: UIButton) {
        SKTAudio.sharedInstance().playSoundEffect("button_press.wav")
        
        let levelViewController = self.storyboard!.instantiateViewControllerWithIdentifier("SelectLevelViewController") as SelectLevelViewController
        
        levelViewController.carType = CarType.fromRaw(sender.tag)!
        navigationController!.pushViewController(levelViewController, animated: true)
    }
    
    

}
