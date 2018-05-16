//
//  GreenTime.swift
//  phase4word
//
//  Created by Yusef Nathanson on 5/4/18.
//  Copyright © 2018 Yusef Nathanson. All rights reserved.
//

import Foundation

typealias NeuTime = (year: Double, wing: Double, min: Double)

//magic constants
let daysPerYear = 365.2422
let wingsPerYear = daysPerYear * 2.0 // 740.4844
let secondsPerYear = 365.2422 * 24 * 60 * 60 // 31556926.08
let minutesPerWing = 720.0

let phi = 1.6180339887498948482045868
let billion = 1000000000.0
let phiTime = phi * billion
let phiTimeInterval = TimeInterval(exactly: phiTime)! // 1618033988.7498949

struct GreenTime {
    var unixTime: TimeInterval
    var date: Date
    
    var neuTime: NeuTime {
        get {
            return unixTimeToGreenTime(secondsSince1970: unixTime)
        }
    }
    
    var oneLineDescription: String {
        get {
            return formatGreenTime(neuTime: neuTime, threeLines: false)
        }
    }
    
    var threeLineDescription: String {
        get {
            return formatGreenTime(neuTime: neuTime, threeLines: true)
        }
    }
    
    var shortDescription: String {
        get {
            return formatGreenTime(neuTime: neuTime, yearDecimals: 3, wingDecimals: 3, minDecimals: 2, threeLines: false)
        }
    }
    
    init(unixTime: TimeInterval) {
        self.unixTime = unixTime
        self.date = Date(timeIntervalSince1970: unixTime)
        
    }
    
    init(date: Date) {
        self.unixTime = date.timeIntervalSince1970
        self.date = date
    }
    
    func formatGreenTime(neuTime: NeuTime, yearDecimals: Int = 5, wingDecimals: Int = 3, minDecimals: Int = 3, threeLines: Bool = false) -> String {
        let yearDesc = String(format: "%.\(yearDecimals)f", neuTime.year)
        let wingDesc = String(format: "%.\(wingDecimals)f", neuTime.wing)
        let minDesc  = String(format: "%.\(minDecimals)f", neuTime.min)
        
        switch threeLines {
        case true:
            return "\(yearDesc)\n\(wingDesc)\n\(minDesc)"
        case false:
            return "\(yearDesc):\(wingDesc):\(minDesc)"
        }
    }
    
    func unixTimeToGreenTime(secondsSince1970: TimeInterval) -> NeuTime {
        let phiTimeInterval = TimeInterval(exactly: phiTime)! // 1618033988.7498949
        let secondsBeforePhiTime = TimeInterval(exactly: phiTimeInterval - secondsSince1970)!
        let year = secondsBeforePhiTime / secondsPerYear
        
        let wing = (year * wingsPerYear).truncatingRemainder(dividingBy: wingsPerYear)
        
        let minutesSinceWingBegan = wing - wing.rounded(.towardZero)
        let min = minutesSinceWingBegan * minutesPerWing
        
        return (year, wing, min)
    }
        
//    func oldUnixTimeToGreenTime(secondsSince1970: TimeInterval) -> NeuTime {
//        //magic constants
//        let daysPerYear = 365.2422
//        let wingsPerYear = daysPerYear * 2.0
//        let secondsPerYear = wingsPerYear * 12.0 * 3600.0 // wingsPerYear * 12 hoursPerwing * 3600 secondsPerHour
//        let minutesPerWing = 720.0
//
//        let yearsSince1970 = (secondsSince1970 / secondsPerYear).rounded(.towardZero)
//
//        let fractionalYearsSinceJanuary1 = (secondsSince1970 / secondsPerYear) - yearsSince1970
//        let wing = fractionalYearsSinceJanuary1 * wingsPerYear
//
//        let minutesSinceWingBegan = wing - wing.rounded(.towardZero)
//        let min = minutesSinceWingBegan * minutesPerWing
//
//        let year = secondsSince1970 / secondsPerYear + 1970.0
//
//        print(year, wing, min)
//
//        return (year, wing, min)
//
//    }
    
        

}
