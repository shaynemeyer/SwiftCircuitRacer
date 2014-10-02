//
//  GameScene.swift
//  SwiftCircuitRacer
//
//  Created by Shayne Meyer on 10/2/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

import SpriteKit

enum CarType: Int {
    case Yellow, Blue, Red
}

enum LevelType: Int {
    case Easy, Medium, Hard
}

class GameScene: SKScene {
    
    var carType: CarType!
    var levelType: LevelType!
    var timeInSeconds = 0
    var numberOfLaps = 0
    
    override func didMoveToView(view: SKView) {
        initializeGame()
    }

    func initializeGame() {
        loadLevel()
        loadTrackTexture()
    }
    
    func loadLevel() {
        let filePath = NSBundle.mainBundle().pathForResource("LevelDetails", ofType: "plist")!
        
        let levels = NSArray(contentsOfFile: filePath)
        
        let levelData = levels[levelType.toRaw()] as NSDictionary
        
        timeInSeconds = levelData["time"] as Int
        numberOfLaps = levelData["laps"] as Int
    }
    
    func loadTrackTexture() {
        let track = self.childNodeWithName("track") as SKSpriteNode
        track.texture = SKTexture(imageNamed: "track_\(levelType.toRaw() + 1)")
    }
}
