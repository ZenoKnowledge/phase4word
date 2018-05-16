//
//  Game.swift
//  phase4word
//
//  Created by Yusef Nathanson on 3/7/18.
//  Copyright © 2018 Yusef Nathanson. All rights reserved.
//

import Foundation
import RealmSwift

enum Game {
    
//    case Ntri, Ntro, Play, Edit, Mply, Gpsm, Libr, Penv, Mate
    case Entry, NoteView, ToNote, Editing, Mplying, MapToNote, Library, Powering, WillPower, Mating, Influx, Save
}

class State {
//    static let shared = State(players: Results<Addr>)
    
    var game: Game
    var counter: Int
    var currentCode: Code?
    var firstPlay: Bool {
        get {
            if counter < 4 {
                return true
            } else {
                return false
            }
        }
    }
    
    var currentNote: Note?
    var lastNote:    Note?
    
    var notes:      Results<Note>?
    var orderedNotes: [Note]
    var loadedNotes: [Note]
    
    var players: Results<Addr>
    var green: Int
    
    var secretKey: SecKey?
    var publicKey: SecKey?
    
    var jsonData: Data?
    var buffer: (String, String)?
    
    init(game: Game, counter: Int, currentCode: Code?, currentNote: Note?, lastNote: Note?, notes: Results<Note>?, orderedNotes: [Note], loadedNotes: [Note], players: Results<Addr>, green: Int, secretKey: SecKey?, publicKey: SecKey?, jsonData: Data?, buffer: (String, String)?) {
        self.game = game
        self.counter = counter
        self.currentCode = currentCode
        self.currentNote = currentNote
        self.lastNote = lastNote
        self.notes = notes
        self.orderedNotes = orderedNotes
        self.loadedNotes = loadedNotes
        self.players = players
        self.green = green
        self.secretKey = secretKey
        self.publicKey = publicKey
        self.jsonData = jsonData
        self.buffer = buffer
    }
    
    convenience init(game: Game, players: Results<Addr>) {
        self.init(game: game, counter: 0, currentCode: nil, currentNote: nil, lastNote: nil, notes: nil, orderedNotes: [], loadedNotes: [], players: players, green: 0, secretKey: nil, publicKey: nil, jsonData: nil, buffer: nil)
    }
    
    
    convenience init(players: Results<Addr>) {
        self.init(game: .Entry, players: players)
        
    }
    
    
}
