//
//  Save.swift
//  phase4word
//
//  Created by Yusef Nathanson on 5/12/18.
//  Copyright © 2018 Yusef Nathanson. All rights reserved.
//

import Foundation
import RealmSwift

@objcMembers class Save: Object {
    
    dynamic var counter: Int = 0
    dynamic var green: Int = 0
    
    dynamic var notes: Results<Note>!
    dynamic var buffer: (String, String)?
    
    dynamic var state: State?
    
    convenience init(counter: Int, green: Int, notes: Results<Note>, buffer: (String, String)?, state: State?) {
        self.init()
        self.counter = counter
        self.green = green
        self.notes = notes
        self.buffer = buffer
        self.state = state
    }
    
}
