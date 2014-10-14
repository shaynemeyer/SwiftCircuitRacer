//
//  Set.swift
//  SwiftCircuitRacer
//
//  Created by Shayne Meyer on 10/13/14.
//  Copyright (c) 2014 Maynesoft LLC. All rights reserved.
//

import Foundation

struct Set<T: Hashable> {
    var map: Dictionary<T, ()> = [:]
    
    var count: Int {
        get {
            return map.count
        }
    }
    
    func isEmpty() -> Bool {
        return count <= 0
    }
    
    mutating func insert(item: T) {
        map[item] = ()
    }
    
    mutating func remove(item: T) {
        map.removeValueForKey(item)
    }
    
    mutating func clear(keepCapacity: Bool = false) {
        map.removeAll(keepCapacity: keepCapacity)
    }
}