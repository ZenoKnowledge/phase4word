//
//  Note.swift
//  phase4word
//
//  Created by Yusef Nathanson on 1/21/18.
//  Copyright © 2018 Yusef Nathanson. All rights reserved.
//

import Foundation
import RealmSwift


@objcMembers class Note: Object, Codable {
    
    ///TODO: add issuerAddress and recipientAddress
    
    dynamic var meta:      String = "" // encrypted with k= h(h(moment) ^^^ h(data))
    dynamic var longitude: Double  = 0.0
    dynamic var latitude:  Double  = 0.0
    dynamic var time:      Date   = Date()
    dynamic var data:      String = "" // encrypted with k = h(h(digest) ^^^ h(moment)
    dynamic var green:     Int    = 0
    dynamic var ssi:       Data   = Data() // ssi is a SSSS share of a procName. //ssi is nonce for all crypt ops
    dynamic var address:   String = "" // hex representation of double sha256 hash of rsa public key, encrypted with k= h(h(data) ^^^ h(meta))
    dynamic var signature: String = "" // hex representation of signature of json of plaintext, encyrpted with k = h(h(ssi))
    dynamic var digest:    String = "" // hex representation of sha256 hash of json of note, encrypted with k= h(h(signature) ^^^ h(ssi))
    
    
    
    
    

    convenience init(green: Int, ssi: Data, address: String, signature: String, digest: String, longitude: Double, latitude: Double, time: Date, data: String, meta: String) {
        self.init()
        self.green      = green
        self.ssi        = ssi
        self.address    = address
        self.signature  = signature
        self.digest     = digest
        self.longitude  = longitude
        self.latitude   = latitude
        self.time       = time
        self.data       = data
        self.meta       = meta
        
    }
    
    convenience init(unsignedNote: NoteToSign, digest: String, signature: String) {
        self.init()
        self.green      = unsignedNote.green
        self.ssi        = unsignedNote.ssi
        self.address    = unsignedNote.address
        self.longitude  = unsignedNote.longitude
        self.latitude   = unsignedNote.latitude
        self.time       = unsignedNote.time
        self.data       = unsignedNote.data
        self.meta       = unsignedNote.meta
        self.signature  = signature
        self.digest     = digest
    }
    
//    convenience required init() {
//        self.init()
//        self.green      = 0
//        self.ssi        = "rand".data(using: .utf8)!
//        self.address    = "address"
//        self.signature  = "signature"
//        self.digest     = "digest"
//        self.longitude  = 42.0
//        self.latitude   = -42.0
//        self.time       = Date()
//        self.data       = ""
//        self.meta       = ""
//    }
    
    
    
    func toJson() -> Data? {
        return try? JSONEncoder().encode(self)
    }
    
    enum NoteAction {
        case mply
        case left
    }
    
    
}

struct NoteToSign: Codable {
    /*This is a struct that contains the content of a note, without a signature. It is serialized to JSON, then signed with msg = JSON(NoteToSign), key = handPrivateKey. Then JSON is appended with 2 more fields, address = PublicKey, and signature. Then it is encrypted with ecdsa secp256r1. Encrypted payload is sent to PlayerAgent. PlayerAgent decrypts with PlayerAgent.public_key. Signature is verified. Then playerAgent takes data.sha256, and uses it as chacha20 encryption key for meta. Then, note JSON is broadcast in channel with name = meta.
    */
    
    // it doesnt have signature and digest because they are determined by the value of this json object
    
    let green:      Int
    let ssi:        Data
    let data:       String
    let meta:       String
    let longitude:  Double
    let latitude:   Double
    let time:       Date
    let address:    String
    
    
    func toJson() -> Data? {
        return try? JSONEncoder().encode(self)
    }

    
}




extension Double {
    private static let arc4randomMax = Double(UInt32.max)
    
    static func onePlusRand() -> Double {
        return 1 + ((Double(arc4random()) / arc4randomMax) / 10000)
    }
}
