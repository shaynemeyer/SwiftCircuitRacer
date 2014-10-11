//
//  AchievementsHelper.swift
//  SwiftCircuitRacer
//
//  Created by Shayne Meyer on 10/11/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

import Foundation
import GameKit

class AchievementsHelper {
    struct Constants {
        static let MaxCollisions = 20
        static let DestructionHeroAchievementId = "com.maynesoft.swiftcircuitracer.destructionhero"
        static let AmateurAchievementId = "com.maynesoft.swiftcircuitracer.amateurracer"
        static let IntermediateAchievementId = "com.maynesoft.swiftcircuitracer.intermediateracer"
        static let ProfessionalAchievementId = "com.maynesoft.swiftcircuitracer.professionalracer"
    }
    
    class func collisionAchievement(noOfCollisions: Int) -> GKAchievement {
        // calculate percent complete gase on the number of boxes the player has hit so far.
        let percent = (noOfCollisions/Constants.MaxCollisions) * 100
        
        // create an achievement
        let collisionAchievement = GKAchievement(identifier: Constants.DestructionHeroAchievementId)
        
        // set percent complete
        collisionAchievement.percentComplete = Double(percent)
        collisionAchievement.showsCompletionBanner = true
        return collisionAchievement
    }
    
    class func achievementForLevel(levelType: LevelType) -> GKAchievement {
        var achievementId = Constants.AmateurAchievementId
        
        if levelType == LevelType.Medium {
            achievementId = Constants.IntermediateAchievementId
        } else if levelType == LevelType.Hard {
            achievementId = Constants.ProfessionalAchievementId
        }
        
        let levelAchievment = GKAchievement(identifier: achievementId)
        
        levelAchievment.percentComplete = 100
        levelAchievment.showsCompletionBanner = true
        return levelAchievment
    }
}
