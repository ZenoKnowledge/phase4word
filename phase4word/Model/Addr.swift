//
//  Addr.swift
//  phase4word
//
//  Created by Yusef Nathanson on 1/21/18.
//  Copyright © 2018 Yusef Nathanson. All rights reserved.
//

import Foundation
import RealmSwift

@objcMembers class Addr: Object {
    
    dynamic var address: String = "" // hex representation of 4h(rsa public key)
    dynamic var nick: String? = nil
    dynamic var phlo: Double = 1.0
    dynamic var shares: [Share] = []
    dynamic var fam: Bool = false
    dynamic var owner: Bool = false
//    dynamic var green: Int = 0
    
    override static func primaryKey() -> String {
        return "address"
    }
    
    convenience init(address: String, owner: Bool) {
        self.init()
        self.address = address
        self.owner = owner
    }
    
    
}


