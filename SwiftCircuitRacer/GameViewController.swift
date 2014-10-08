//
//  GameViewController.swift
//  SwiftCircuitRacer
//
//  Created by Shayne Meyer on 10/2/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

import UIKit
import SpriteKit
import CoreMotion

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            var sceneData = NSData.dataWithContentsOfFile(path, options: .DataReadingMappedIfSafe, error: nil)
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
    
    let motionManager: CMMotionManager = CMMotionManager()
    
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
            
            scene.gameOverBlock = {(didWin) in
                self.gameOverWithWin(didWin)
            }
            
            motionManager.accelerometerUpdateInterval = 0.05
            motionManager.startAccelerometerUpdates()
            scene.motionManager = motionManager
        }
    }
    
    deinit {
        motionManager.stopAccelerometerUpdates()
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.toRaw())
        } else {
            return Int(UIInterfaceOrientationMask.All.toRaw())
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
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
    
    // MARK: UIAlert Methods
    
    func goBack(alert: UIAlertController) {
        alert.dismissViewControllerAnimated(true, completion: {
            self.navigationController!.popToRootViewControllerAnimated(false)
            return
        })
    }
}
