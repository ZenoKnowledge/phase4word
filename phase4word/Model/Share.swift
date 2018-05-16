//
//  Share.swift
//  phase4word
//
//  Created by Yusef Nathanson on 1/26/18.
//  Copyright © 2018 Yusef Nathanson. All rights reserved.
//

import Foundation

struct Share {
    
    let share:              Secret.Share
    var shareDescription:   String {
        return String(data: share.data, encoding: .utf8)!
    }
}

struct Proc {
    let proc: [String: [Share]]
}
