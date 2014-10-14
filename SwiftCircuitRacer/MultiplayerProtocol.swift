//
//  MultiplayerProtocol.swift
//  SwiftCircuitRacer
//
//  Created by Shayne Meyer on 10/13/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

import Foundation
import GameKit

protocol MultiplayerProtocol {
    func matchEnded()
}

class MultiplayerNetworking: NSObject, GameKitHelperDelegate {
    var delegate: MultiplayerProtocol?
    var noOfLaps: Int?
    
    var ourRandomNumber: UInt32
    var gameState: GameState
    var isPlayer1: Bool
    var receivedAllRandomNumbers: Bool
    var orderOfPlayers: [RandomNumberDetails]
    
    enum GameState: Int {
        case WaitingForMatch, WaitingForRandomNumber, WaitingForStart, Playing, Done
    }
    
    enum MessageType: Int {
        case RandomNumber, GameBegin, Move, LapComplete, GameOver
    }
    
    struct Message {
        let messageType: MessageType
    }
    
    struct MessageRandomNumber {
        let message: Message
        let randomNumber: UInt32
    }
    
    struct MessageGameBegin {
        let message: Message
    }
    
    struct MessageMove {
        let message: Message
        let dx: Float
        let dy: Float
        let rotate: Float
    }
    
    struct MessageLapComplete {
        let message: Message
    }
    
    struct MessageGameOver {
        let message: Message
    }
    
    class RandomNumberDetails: NSObject {
        let playerId: String
        let randomNumber: UInt32
        
        init(playerId: String, randomNumber: UInt32) {
            self.playerId = playerId
            self.randomNumber = randomNumber
            super.init()
        }
        
        override func isEqual(object: AnyObject?) -> Bool {
            let randomNumberDetails = object as? RandomNumberDetails
            return randomNumberDetails?.playerId == self.playerId
        }
    }
    
    override init() {
        ourRandomNumber = arc4random()
        gameState = GameState.WaitingForMatch
        isPlayer1 = false
        receivedAllRandomNumbers = false
        
        orderOfPlayers = [RandomNumberDetails]()
        orderOfPlayers.append(RandomNumberDetails(playerId: GKLocalPlayer.localPlayer().playerID, randomNumber: ourRandomNumber))
        super.init()
    }
    
    // MARK: GameKitHelperDelegate methods
    func matchStarted() {
        println("Match has started successfuly")
        if receivedAllRandomNumbers {
            gameState = GameState.WaitingForStart
        } else {
            gameState = GameState.WaitingForRandomNumber
        }
        sendRandomNumber()
        tryStartGame()
    }
    
    func sendRandomNumber() {
        var message = MessageRandomNumber(message: Message(messageType: MessageType.RandomNumber), randomNumber: ourRandomNumber)
        
        let data = NSData(bytes: &message, length: sizeof(MessageRandomNumber))
        sendData(data)
    }
    
    func tryStartGame() {
        if isPlayer1 && gameState == GameState.WaitingForStart {
            gameState = GameState.Playing
            sendBeginGame()
        }
    }
    
    func sendBeginGame() {
        var message = MessageGameBegin(message: Message(messageType: MessageType.GameBegin))
        
        let data = NSData(bytes: &message, length: sizeof(MessageGameBegin))
        sendData(data)
    }
    
    func sendData(data: NSData) {
        var sendDataError: NSError?
        let gameKitHelper = GameKitHelper.sharedInstance
        
        if let multiplayerMatch = gameKitHelper.multiplayerMatch {
            let success = multiplayerMatch.sendDataToAllPlayers(data, withDataMode: .Reliable, error: &sendDataError)
            if !success {
                if let error = sendDataError {
                    println("Error:\(error.localizedDescription)")
                    matchEnded()
                }
            }
        }
    }
    
    func processReceivedRandomNumber(randomNumberDetails: RandomNumberDetails) {
        // 1 
        let mutableArray = NSMutableArray(array: orderOfPlayers)
        mutableArray.addObject(randomNumberDetails)
        
        // 2
        let sortByRandomNumber = NSSortDescriptor(key: "randomNumber", ascending: false)
        let sortDescriptors = [sortByRandomNumber]
        mutableArray.sortUsingDescriptors(sortDescriptors)
        
        // 3
        orderOfPlayers = NSArray(array: mutableArray) as [RandomNumberDetails]
        
        // 4
        if allRandomNumbersAreReceived() {
            receivedAllRandomNumbers = true
        }
    }
    
    func allRandomNumbersAreReceived() -> Bool {
        var receivedRandomNumbers = Set<UInt32>()
        
        for playerDetail in orderOfPlayers {
            receivedRandomNumbers.insert(playerDetail.randomNumber)
        }
        
        if let multiplayerMatch = GameKitHelper.sharedInstance.multiplayerMatch {
            if receivedRandomNumbers.count == multiplayerMatch.playerIDs.count + 1 {
                return true
            }
        }
        return false
    }
    
    func isLocalPLayerPlayer1() -> Bool {
        let playerDetail = orderOfPlayers[0]
        if playerDetail.playerId == GKLocalPlayer.localPlayer().playerID {
            println("I'm player 1.. w00t :]")
            return true
        }
        return false
    }
    
    func matchEnded() {
        delegate?.matchEnded()
    }
    
    func matchReceivedData(match: GKMatch, data: NSData, fromPlayer player: String) {
        // 1
        var message = UnsafePointer<Message>(data.bytes).memory
        
        if message.messageType == MessageType.RandomNumber {
            let messageRandomNumber = UnsafePointer<MessageRandomNumber>(data.bytes).memory
            
            println("Received random number:\(messageRandomNumber.randomNumber)")
            
            var tie = false
            if messageRandomNumber.randomNumber == ourRandomNumber {
                // 2
                println("Tie")
                tie = true
                
                var idx: Int?
                
                for (index, randomNumberDetails) in
                    enumerate(orderOfPlayers) {
                        if randomNumberDetails.randomNumber == ourRandomNumber {
                            idx = index
                            break
                        }
                }
                
                if let validIndex = idx {
                    ourRandomNumber = arc4random()
                    orderOfPlayers.removeAtIndex(validIndex)
                    orderOfPlayers.append(RandomNumberDetails(playerId: GKLocalPlayer.localPlayer().playerID, randomNumber: ourRandomNumber))

                }
                sendRandomNumber()
            } else {
                // 3
                processReceivedRandomNumber(RandomNumberDetails(playerId: player, randomNumber: messageRandomNumber.randomNumber))
            }
            
            // 4
            if receivedAllRandomNumbers {
                isPlayer1 = isLocalPLayerPlayer1()
            }
            
            if !tie && receivedAllRandomNumbers {
                // 5
                if gameState == GameState.WaitingForRandomNumber {
                    gameState = GameState.WaitingForStart
                }
                tryStartGame()
            }
        }
    }
}