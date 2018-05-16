//
//  Code.swift
//  phase4word
//
//  Created by Yusef Nathanson on 5/4/18.
//  Copyright © 2018 Yusef Nathanson. All rights reserved.
//

import Foundation
import RealmSwift


@objcMembers class Code: Object {
    
    dynamic var code: String = ""
    
    convenience init(code: String) {
        self.init()
        self.code = code
    }
    
}
