//
//  GameViewController.swift
//  SwiftCircuitRacer
//
//  Created by Shayne Meyer on 10/2/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

import UIKit
import SpriteKit

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            var sceneData = NSData.dataWithContentsOfMappedFile(path) as NSData
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameViewController: UIViewController {

    var analogControl: AnalogControl!
    
    var carType: CarType!
    var levelType: LevelType!
    
    var noOfCars: Int?
    var networkingEngine: MultiplayerNetworking?
    
    @IBOutlet weak var pauseButton: UIButton!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            // Configure the view.
            let skView = self.view as SKView
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill
            
            scene.levelType = levelType
            scene.carType = carType
            
            if let nrOfCars = noOfCars {
                if nrOfCars > 1 {
                    scene.levelType = LevelType.Easy
                    scene.noOfCars = nrOfCars
                    
                    networkingEngine = MultiplayerNetworking()
                    networkingEngine!.noOfLaps = 5
                    networkingEngine!.delegate = scene
                    
                    scene.networkingEngine = networkingEngine
                    
                    pauseButton.hidden = true
                    GameKitHelper.sharedInstance.findMatch(nrOfCars, maxPlayers: nrOfCars, presentingViewController: self, delegate: networkingEngine!)
                }
            }
            
            skView.presentScene(scene)
            skView.showsPhysics = true
            
            let padSide: CGFloat = view.frame.size.height / 2.5
            let padPadding: CGFloat = view.frame.size.height / 32
            
            analogControl = AnalogControl(frame: CGRectMake(padPadding,
                skView.frame.size.height - padPadding - padSide,
                padSide,
                padSide))
            
            analogControl.delegate = scene

            view.addSubview(analogControl)
            
            scene.gameOverBlock = gameOverWithWin
            scene.gameEndedBlock = goBack
        }
    }

    func gameOverWithWin(didWin: Bool) {
        let alert = UIAlertController(title: didWin ? "You won!" : "You lost",
            message: "Game Over",
            preferredStyle: .Alert)
        presentViewController(alert, animated: true, completion: nil)
        
        let delayInSeconds = 3.0
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delayInSeconds) * Int64(NSEC_PER_SEC))
        
        dispatch_after(popTime, dispatch_get_main_queue(), {
            self.goBack(alert)
        })
    }
    
    // MARK: UIAlert Methods
    
    func goBack(alert: UIAlertController) {
        alert.dismissViewControllerAnimated(true, completion: {
            self.navigationController!.popToRootViewControllerAnimated(false)
            return
        })
    }
    
    func goBack() {
        navigationController?.popToRootViewControllerAnimated(false)
    }
    
    // MARK: IBAction Methods
    @IBAction func showInGameMenu(sender: AnyObject!) {
        (self.view as SKView).paused = true
        
        let alert = UIAlertController(title: "Game Menu", message: nil, preferredStyle: .Alert)
        
        alert.addAction(UIAlertAction(title: "Go to menu", style: .Default, {_ in
            (self.view as SKView).paused = false
            self.gameOverWithWin(false)
        }))
        
        alert.addAction(UIAlertAction(title: "Resume level", style: .Default, {_ in
            (self.view as SKView).paused = false
        }))
        
        presentViewController(alert, animated: true, completion: nil)
    }
    


    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
