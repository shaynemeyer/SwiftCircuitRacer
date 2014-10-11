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

class GameScene: SKScene, AnalogControlPositionChange, SKPhysicsContactDelegate {
    
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
    
    var motionManager: CMMotionManager!
    
    let ay = Vector3(x: 0.63, y: 0.0, z: -0.92)
    let az = Vector3(x: 0.0, y: 1.0, z: 0.0)
    let ax = Vector3.crossProduct(Vector3(x: 0.0, y: 1.0, z: 0.0),
        right: Vector3(x: 0.63, y: 0.0, z: -0.92)).normalized()
    
    let steerDeadZone = CGFloat(0.15)
    
    let blend = CGFloat(0.2)
    var lastVector = Vector3(x: 0, y: 0, z: 0)
    
    var noOfCollisionsWithBoxes = 0
    
    struct PhysicsCategories {
        static let CarCategoryMask: UInt32 = 1
        static let BoxCategoryMask: UInt32 = 2
    }
    
    override func didMoveToView(view: SKView) {
        initializeGame()
    }

    func initializeGame() {
        loadLevel()
        loadTrackTexture()
        setupPhysicsBodies()
        loadCarTexture()
        loadObstacles()
        addLabels()
        
        maxSpeed = 500 * (2 + carType.toRaw())
        
        trackCenter = childNodeWithName("track")!.position
        
        boxSoundAction = SKAction.playSoundFileNamed("box.wav", waitForCompletion: false)
        hornSoundAction = SKAction.playSoundFileNamed("horn.wav", waitForCompletion: false)
        lapSoundAction = SKAction.playSoundFileNamed("lap.wav", waitForCompletion: false)
        nitroSoundAction = SKAction.playSoundFileNamed("nitro.wav", waitForCompletion: false)
        
        physicsWorld.contactDelegate = self
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
    
    func loadCarTexture() {
        let car = self.childNodeWithName("car") as SKSpriteNode
        car.texture = SKTexture(imageNamed: "car_\(carType.toRaw() + 1)")
        
        /**
            Defines what logical 'categories' of bodies this body generates intersection notifications with.
        */
        car.physicsBody?.contactTestBitMask = PhysicsCategories.BoxCategoryMask
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
        let car = self.childNodeWithName("car") as SKSpriteNode
        
        car.physicsBody!.velocity = CGVector(position.x * CGFloat(maxSpeed), -position.y * CGFloat(maxSpeed))
        
        if position != CGPointZero {
            car.zRotation = CGPointMake(position.x, -position.y).angle
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
        
        let carPosition = childNodeWithName("car")!.position
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
            }
        }
        
        if timeInSeconds < 0 || numberOfLaps == 0 {
            paused = true
            
            if let block = gameOverBlock {
                reportAchievementsForGameState(numberOfLaps == 0)
                block(didWin: numberOfLaps == 0)
            }
        }
//        
//        if motionManager.accelerometerData != nil {
//            println("accelerometer [\(motionManager.accelerometerData.acceleration.x), \(motionManager.accelerometerData.acceleration.y),               \(motionManager.accelerometerData.acceleration.z)]")
//        }
        
        moveCarFromAcceleration()
    }
    
    // MARK: Accelerometer Methods
    
    func moveCarFromAcceleration() {
        var accel2D = CGPoint.zeroPoint
        
        if motionManager.accelerometerData == nil {
            println("no acceleration data yet")
            return
        }
        
        var raw = Vector3 (x: CGFloat(motionManager.accelerometerData.acceleration.x),
            y: CGFloat(motionManager.accelerometerData.acceleration.y
            ), z: CGFloat(motionManager.accelerometerData.acceleration.z))
        
        raw = lowPassWithVector(raw)
        
        accel2D.x = Vector3.dotProduct(raw, right: az)
        accel2D.y = Vector3.dotProduct(raw, right: ax)
        accel2D.normalize()
        
        if abs(accel2D.x) < steerDeadZone {
            accel2D.x = 0
        }
        
        if abs(accel2D.y) < steerDeadZone {
            accel2D.y = 0
        }
        
        let maxAccelerationPerSecond = maxSpeed
        let car = childNodeWithName("car") as SKSpriteNode
        car.physicsBody!.velocity = CGVector(accel2D.x * CGFloat(maxAccelerationPerSecond),
            accel2D.y * CGFloat(maxAccelerationPerSecond))
        
        // if the car is in the deadzone, don't rotate.
        if accel2D.x != 0 || accel2D.y != 0 {
            // get the angle of acceleration vector
            let orientationFromVelocity = CGPoint(x: car.physicsBody!.velocity.dx, y: car.physicsBody!.velocity.dy).angle
            
            var angleDelta = CGFloat(0.0)
            
            // if the car needs to rotate more than 175 degrees to 185 degrees, that means the value of zRotation need to change from 3.05 radians to -3.05 radians.
            if abs(orientationFromVelocity - car.zRotation) > 1 {
                // prevent wild rotation
                angleDelta = orientationFromVelocity - car.zRotation
            } else {
                // blend rotation
                let blendFactor = CGFloat(0.25)
                angleDelta = (orientationFromVelocity - car.zRotation) * blendFactor
                
                angleDelta = shortestAngleBetween(car.zRotation, car.zRotation + angleDelta)
            }
            
            // adjust the current rotation by angleDelta 
            car.zRotation += angleDelta
        }
        
    }
    
    func lowPassWithVector(var vector: Vector3) -> Vector3 {
        vector.x = vector.x * blend + lastVector.x * (1.0 - blend)
        vector.y = vector.y * blend + lastVector.y * (1.0 - blend)
        vector.z = vector.z * blend + lastVector.z * (1.0 - blend)
        
        lastVector = vector
        return vector
    }
    
    // MARK: Collision Detection Methods
    
    func didBeginContact(contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask != UInt32.max && contact.bodyB.categoryBitMask != UInt32.max && (contact.bodyA.categoryBitMask + contact.bodyB.categoryBitMask == PhysicsCategories.CarCategoryMask + PhysicsCategories.BoxCategoryMask) {
            noOfCollisionsWithBoxes += 1
            runAction(boxSoundAction)
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
        
        // 4
        GameKitHelper.sharedInstance.reportAchievements(achievements)
    }
    
}

