//
//  GameScene.swift
//  SwiftCircuitRacer
//
//  Created by Shayne Meyer on 10/2/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

import SpriteKit
import CoreMotion
import GameKit

enum CarType: Int {
    case Yellow, Blue, Red
}

enum LevelType: Int {
    case Easy, Medium, Hard
}

var numberOfPlays: Int = 0

class GameScene: SKScene, AnalogControlPositionChange, SKPhysicsContactDelegate, MultiplayerProtocol {
    
    var carType: CarType!
    var levelType: LevelType!
    
    var timeInSeconds = 0
    var numberOfLaps = 0
    
    var box1: SKSpriteNode!, box2: SKSpriteNode!
    var laps: SKLabelNode!, time: SKLabelNode!
    
    var maxSpeed = 0
    
    var trackCenter = CGPoint.zeroPoint
    var nextProgressAngle = M_PI
    
    var boxSoundAction: SKAction!, hornSoundAction: SKAction!, lapSoundAction: SKAction!, nitroSoundAction: SKAction!
    
    var previousTimeInterval: CFTimeInterval = 0
    
    typealias GameOverBlock = (didWin: Bool) -> Void
    var gameOverBlock: GameOverBlock?
    
    typealias GameEndedBlock = () -> Void
    var gameEndedBlock: GameEndedBlock?
    
    var noOfCollisionsWithBoxes = 0
    
    var maxTime = 0
    let leaderBoardIDMap = [
        "\(CarType.Yellow.toRaw())_\(LevelType.Easy.toRaw())" : "com.maynesoft.swiftcircuitracer.car1_level_easy_fastest_time",
        "\(CarType.Yellow.toRaw())_\(LevelType.Medium.toRaw())" : "com.maynesoft.swiftcircuitracer.car1_level_medium_fastest_time",
        "\(CarType.Yellow.toRaw())_\(LevelType.Hard.toRaw())" : "com.maynesoft.swiftcircuitracer.car1_level_hard_fastest_time",
        "\(CarType.Blue.toRaw())_\(LevelType.Easy.toRaw())" : "com.maynesoft.swiftcircuitracer.car2_level_easy_fastest_time",
        "\(CarType.Blue.toRaw())_\(LevelType.Medium.toRaw())" : "com.maynesoft.swiftcircuitracer.car2_level_medium_fastest_time",
        "\(CarType.Blue.toRaw())_\(LevelType.Hard.toRaw())" : "com.maynesoft.swiftcircuitracer.car2_level_hard_fastest_time",
        "\(CarType.Red.toRaw())_\(LevelType.Easy.toRaw())" : "com.maynesoft.swiftcircuitracer.car3_level_easy_fastest_time",
        "\(CarType.Red.toRaw())_\(LevelType.Medium.toRaw())" : "com.maynesoft.swiftcircuitracer.car3_level_medium_fastest_time",
        "\(CarType.Red.toRaw())_\(LevelType.Hard.toRaw())" : "com.maynesoft.swiftcircuitracer.car3_level_hard_fastest_time"]
    
    var noOfCars: Int?
    var networkingEngine: MultiplayerNetworking?
    var isMultiplayerMode: Bool = false
    var cars = [SKSpriteNode]()
    var currentIndex: Int?
    
    struct PhysicsCategories {
        static let CarCategoryMask: UInt32 = 1
        static let BoxCategoryMask: UInt32 = 2
    }
    
    override func didMoveToView(view: SKView) {
        initializeGame()
    }

    func initializeGame() {
        loadLevel()
        setupPhysicsBodies()
        loadTrackTexture()
        addLabels()
        loadObstacles()
        //loadCarTexture()
        
        trackCenter = childNodeWithName("track")!.position
        
        boxSoundAction = SKAction.playSoundFileNamed("box.wav", waitForCompletion: false)
        hornSoundAction = SKAction.playSoundFileNamed("horn.wav", waitForCompletion: false)
        lapSoundAction = SKAction.playSoundFileNamed("lap.wav", waitForCompletion: false)
        nitroSoundAction = SKAction.playSoundFileNamed("nitro.wav", waitForCompletion: false)
        
        if let nrOfCars = noOfCars {
            if nrOfCars > 1 {
                /**
                We're keeping the number of cars fixed to 2
                However, this can be changed to support any number by simply removing the constraint and adding more car types
                */
                noOfCars = 2
                initializeMultiplayerGame()
            } else {
                initializeSinglePlayerGame()
            }
        } else {
            initializeSinglePlayerGame()
        }
        
        physicsWorld.contactDelegate = self
    }
    
    func initializeSinglePlayerGame() {
        maxSpeed = 500 * (2 + carType.toRaw())
        physicsWorld.contactDelegate = self
        
        let car = addCar(carType, atPosition: CGPointMake(CGRectGetMidX(childNodeWithName("track")!.frame) - 160, CGRectGetMidY(childNodeWithName("track")!.frame) - 320))
        cars.append(car)
        currentIndex = 0
    }
    
    func initializeMultiplayerGame() {
        numberOfLaps = 5
        isMultiplayerMode = true
        maxSpeed = 600
        
        time.hidden = true
        laps.text = "Laps: \(numberOfLaps)"
        
        box1.removeFromParent()
        box2.removeFromParent()
        
        var xDisplacement: CGFloat = 140
        for index in 0..<noOfCars! {
            //1 Select a car
            let carType = CarType.fromRaw(index)
            
            //2 Set the position
            let car = addCar(carType!, atPosition: CGPointMake(CGRectGetMidX(childNodeWithName("track")!.frame) - xDisplacement, CGRectGetMidY(childNodeWithName("track")!.frame) - (index % 2 == 0 ? 320 : 460)))
            
            //3 Add to cars array
            cars.append(car)
            
            xDisplacement = ((index + 1) % 2) == 0 ? xDisplacement + 240 : xDisplacement
        }
    }
    
    func addCar(carType: CarType, atPosition position: CGPoint) -> SKSpriteNode {
        let atlas = SKTextureAtlas(named: "sprites")
        let car = SKSpriteNode(texture: atlas.textureNamed("car_\(carType.toRaw() + 1).png"))
        car.position = position
        
        car.physicsBody = SKPhysicsBody(rectangleOfSize: car.frame.size)
        car.physicsBody!.categoryBitMask = PhysicsCategories.CarCategoryMask
        car.physicsBody!.collisionBitMask = PhysicsCategories.BoxCategoryMask | PhysicsCategories.CarCategoryMask
        car.physicsBody!.contactTestBitMask = PhysicsCategories.BoxCategoryMask
        car.physicsBody!.dynamic = true
        
        addChild(car)
        return car
    }
    
    func loadLevel() {
        let filePath = NSBundle.mainBundle().pathForResource("LevelDetails", ofType: "plist")!
        
        let levels = NSArray(contentsOfFile: filePath)
        
        let levelData = levels[levelType.toRaw()] as NSDictionary
        
        timeInSeconds = levelData["time"] as Int
        numberOfLaps = levelData["laps"] as Int
        
        maxTime = timeInSeconds
    }
    
    func loadTrackTexture() {
        let track = self.childNodeWithName("track") as SKSpriteNode
        track.texture = SKTexture(imageNamed: "track_\(levelType.toRaw() + 1)")
    }
    
    func setupPhysicsBodies() {
        let innerBoundary = SKNode()
        innerBoundary.position = childNodeWithName("track")!.position
        addChild(innerBoundary)
        
        innerBoundary.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(720, 480))
        innerBoundary.physicsBody!.dynamic = false
        
        let trackFrame = CGRectInset(self.childNodeWithName("track")!.frame, 200, 0)
        
        let maxAspectRatio: CGFloat = 3.0 / 2.0 // iPhone 4
        let maxAspectRatioHeight = trackFrame.size.width / maxAspectRatio
        let playableMarginY: CGFloat = (trackFrame.size.height - maxAspectRatioHeight) / 2
        let playableMaringX: CGFloat = (frame.size.width - trackFrame.size.width) / 2
        
        let playableRect = CGRect(x: playableMaringX, y: playableMarginY, width: trackFrame.size.width, height: trackFrame.size.height - playableMarginY * 2)
        
        physicsBody = SKPhysicsBody(edgeLoopFromRect: playableRect)
    }
    
    func loadObstacles() {
        box1 = self.childNodeWithName("box_1") as SKSpriteNode
        box2 = self.childNodeWithName("box_2") as SKSpriteNode
    }
    
    func addLabels() {
        laps = self.childNodeWithName("laps_label") as SKLabelNode
        time = self.childNodeWithName("time_left_label") as SKLabelNode
        
        laps.text = "Laps: \(numberOfLaps)"
        time.text = "Time: \(timeInSeconds)"
    }
    
    func analogControlPositionChanged(analogControl: AnalogControl, position: CGPoint) {
        if let index = currentIndex {
            let car = cars[index]
            
            car.physicsBody!.velocity = CGVector(
                position.x * CGFloat(maxSpeed),
                -position.y * CGFloat(maxSpeed))
            
            if position != CGPointZero {
                car.zRotation = CGPointMake(position.x, -position.y).angle
            }
            
            networkingEngine?.sendMove(Float(car.physicsBody!.velocity.dx), dy: Float(car.physicsBody!.velocity.dy), rotation: Float(car.zRotation))
        }
    }
    
    override func update(currentTime: NSTimeInterval) {
        if previousTimeInterval == 0 {
            previousTimeInterval = currentTime
        }
        
        if paused {
            previousTimeInterval = currentTime
            return
        }
        
        if currentTime - previousTimeInterval > 1 {
            timeInSeconds -= Int(currentTime - previousTimeInterval)
            previousTimeInterval = currentTime
            if timeInSeconds >= 0 {
                time.text = "Time: \(timeInSeconds)"
            }
        }
        
        if let index = currentIndex {
            let carPosition = cars[index].position
            let vector = carPosition - trackCenter
            let progressAngle = Double(vector.angle) + M_PI
            
            // check whether the current angle is greater than the next target, but only by a little it: M_PI_4. This prevents the player from going backward.
            if progressAngle > nextProgressAngle && (progressAngle - nextProgressAngle) < M_PI_4 {
                // move on to the next quadrant.
                nextProgressAngle += M_PI_2
                
                //
                if nextProgressAngle >= (2 * M_PI) {
                    nextProgressAngle = 0
                }
                
                // if next target angle = M_PI, car has just passed the finish line.
                if fabs(nextProgressAngle - M_PI) < Double(FLT_EPSILON) {
                    // lap completed!
                    numberOfLaps -= 1
                    laps.text = "Laps: \(numberOfLaps)"
                    runAction(lapSoundAction)
                    networkingEngine?.sendLapComplete()
                }
            }
        
            if timeInSeconds < 0 || numberOfLaps == 0 && !isMultiplayerMode{
                paused = true
                
                if let block = gameOverBlock {
                    reportAchievementsForGameState(numberOfLaps == 0)
                    reportScoreToGameCenter()
                    block(didWin: numberOfLaps == 0)
                }
            }
        }
    }
    
    // MARK: GameCenter Methods
    
    func reportAchievementsForGameState(hasWon: Bool) {
        // 1
        var achievements = [GKAchievement]()
        
        // 2
        achievements.append(AchievementsHelper.collisionAchievement(noOfCollisionsWithBoxes))
        
        // 3
        if hasWon {
            achievements.append(AchievementsHelper.achievementForLevel(levelType))
        }
        
        // Check number of plays
        numberOfPlays += 1
        achievements.append(AchievementsHelper.racingAddictAchievement(numberOfPlays))
        
        // 4
        GameKitHelper.sharedInstance.reportAchievements(achievements)
    }
    
    func reportScoreToGameCenter() {
        let timeToComplete = maxTime - timeInSeconds
        
        GameKitHelper.sharedInstance.reportScore(Int64(timeToComplete),
            forLeaderboardId: leaderBoardIDMap["\(carType.toRaw())_\(levelType.toRaw())"]!)
    }
    
    // MARK: MultiplayerProtocol method
    func matchEnded() {
        if let block = gameEndedBlock {
            paused = true
            block()
        }
    }
    
    func setCurrentPlayerIndex(index: Int) {
        currentIndex = index
    }
    
    func setPositionOfCar(index: Int, dx: Float, dy: Float, rotation: Float) {
        let car = cars[index] as SKSpriteNode
        car.physicsBody?.velocity = CGVector(CGFloat(dx), CGFloat(dy))
        if rotation != 0 {
            car.zRotation = CGFloat(rotation)
        }
    }
    
    func gameOver(didLocalPlayerWin: Bool) {
        paused = true
        gameOverBlock?(didWin: didLocalPlayerWin)
    }
    
    
    // MARK: SKPhysicsContactDelegate method
    
    func didBeginContact(contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask != UInt32.max && contact.bodyB.categoryBitMask != UInt32.max && (contact.bodyA.categoryBitMask + contact.bodyB.categoryBitMask == PhysicsCategories.CarCategoryMask + PhysicsCategories.BoxCategoryMask) {
            noOfCollisionsWithBoxes += 1
            runAction(boxSoundAction)
        }
    }
}


