//
//  EntryVC.swift
//  phase4word
//
//  Created by Yusef Nathanson on 1/19/18.
//  Copyright © 2018 Yusef Nathanson. All rights reserved.
//

import UIKit
import SwiftyRSA
import RealmSwift

class EntryVC: UIViewController, URLSessionTaskDelegate  {
    
    
    var ipfsURLs = ["http://ovsyukov.info:8081/",
                    "http://35.180.30.25:3000/",
                    "http://138.197.50.102:3000/"]
    
    var state: State!
    
    var key: Key?
    
    var notes: Results<Note>!
    var players: Results<Addr>!
    var codes: Results<Code>!
    var saveStates: Results<Save>!
    
    var notesToAdd: [Note]?
    var loadedNotes: [Note] = []
    
    var validCode = false
    

    
    @IBOutlet weak var proceedLabel: UILabel!
    @IBOutlet weak var librTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let realm = RealmService.shared.realm
        notes = realm.objects(Note.self)
        print("notes.count", notes.count)
        if notes.count == 0 {
            print("b4setup notes.count ==", notes.count)
            hardNoteSetup()
            print("after setup notes.count ==", notes.count)
            notes = realm.objects(Note.self)
        }
        
        players = realm.objects(Addr.self)
        print("players", players)
        codes = realm.objects(Code.self)
        saveStates = realm.objects(Save.self)
        print("savestates.count", saveStates.count)
        print("savednotes.count", saveStates.last?.state?.notes?.count)
        state = saveStates.last?.state ?? State(game: .Entry, counter: 0, currentCode: nil, currentNote: nil, lastNote: nil, notes: nil, orderedNotes: [], loadedNotes: [], players: players, green: 0, secretKey: nil, publicKey: nil, jsonData: nil, buffer: nil)
        
        print("game", state.game)
        
        
        state.orderedNotes = orderNotes()
        print("state.players", state.players)
        print("codes", codes)
        
        print("state.game", state?.game)
        
        librTextField.text = "libr.8"
        
        try! retrieveOrGenerateKey()
        
        let pk = try! PublicKey(reference: state!.publicKey!)
        let pkPem = try! pk.pemString()
//        let timeStamp = Int(Date().timeIntervalSince1970)
//        let timeData = timeStamp.description.data(using: .utf8)
//        let signature = CryptoService.shared.sign(key: key!, data: timeData!)
        
        
        let address = pkPem.sha256().sha256()
        let predicate = NSPredicate(format: "address == %@", address)
        if let player = state.players.filter(predicate).first {
            if player.owner == false {
                let dict = ["owner": true]
                RealmService.shared.update(player, with: dict)
                
            }
            print("happyPlayer", player)
        } else {
            if let player = createPlayerIfNeeded(address: address, owner: true) {
                print("#2happyPlayer", player)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func goTapped(_ sender: UIButton) {
        if librTextField.text == "libr.8" { // or otherwise valid
            print("2st libr8 segue")
            performSegue(withIdentifier: "libr8", sender: nil)
        } else {
            self.state?.currentCode = Code(code: librTextField.text!)
            print(state.currentCode)
            
            if let keyCode = self.state?.currentCode {
                // if code is already saved, don't download Notes.
                // next version, we will make it live, with async networking.
                if codes.contains(keyCode) {
                    print("3nd libr8 segue")
                    performSegue(withIdentifier: "libr8", sender: nil)
                } else {
                    let url = URL(string: ipfsURLs[2] + "ipfs/\(keyCode.code.sha256().sha256().sha256().sha256())")!
                    print("url", url)
                    
                    validCode = false
                    
                    if let data = Fetch.get(url: url) {
                        if let notesToLoad = loadNotesFrom(data: data, keyCode: keyCode) {
                            print("notes loaded", notesToLoad)
                            print("0state.green", state.green)
                            let greenToSubtract = findLowestGreenIn(notes: loadedNotes)
                            print("greenToSubtract", greenToSubtract)
                            state.green -= greenToSubtract
                            print("1state.green", state.green)
                            self.loadedNotes = notesToLoad
                            state.loadedNotes = self.loadedNotes
                            print("loadedNotes", loadedNotes, loadedNotes.count)
                            
                            print("notesToLoad", notesToLoad, notesToLoad.count)
                            print("state.loadedNotes", state.loadedNotes, state.loadedNotes.count)
                        }
                    } else {
                        self.proceedLabel.text = "code is invalid. plz retry"
                    }
                    
                    print("loadedNotes", loadedNotes, loadedNotes.count)
                    print("5th libr8 segue")
                    validCode = true
                    if validCode && loadedNotes.count > 1 {
                        performSegue(withIdentifier: "libr8", sender: nil)
                    } else {
                        self.proceedLabel.text = "code is invalid. retry"
                    }
                }
            }
        }
        
        print("notes", notes, "codes", codes)
    }
    
    func findLowestGreenIn(notes: [Note]) -> Int {
        var minG = -1
        for note in notes {
            print("dig:green", note.digest, note.green)
            minG = min(minG, note.green)
        }
        return minG
    }
    
//    func completion(data: Data, keyCode: Code, semaphore: DispatchSemaphore) {
//        print("completion begins")
//        var validCode = false
//        print("CData", String(data: data, encoding: .utf8))
//        do {
//            print("do begins")
//            let notesJSON =  try JSONDecoder().decode([UInt8].self, from: data)
//            print("notesJSON",notesJSON)
//            let decrypted = CryptoService.shared.decryptBytes(bytes: notesJSON, code: keyCode.code)
//            let newNotes = try! self.JSONToNotes(data: decrypted)
//            loadedNotes.append(contentsOf: newNotes)
//            print("notesToAdd", loadedNotes)
//            print("validCode", validCode)
//        } catch {
//            validCode = false
//        }
//        semaphore.signal()
//    }
    
    func loadNotesFrom(data: Data, keyCode: Code) -> [Note]? {
        do {
            let notesJSON =  try JSONDecoder().decode([UInt8].self, from: data)
            print("notesJSON", notesJSON)
            let decrypted = CryptoService.shared.decryptBytes(bytes: notesJSON, code: keyCode.code)
            let newNotes = try! self.JSONToNotes(data: decrypted)
            print("newNotes", newNotes.count)
            for note in newNotes {
                print(note.data, note.green, note.digest)
            }
            return newNotes
        } catch {
            print("error loading notes")
            self.proceedLabel.text = "code is invalid. plz retry"
            return nil
        }
    }
    
    func retrieveOrGenerateKey() throws {
        
        //maybe libr8 code must be tag segment? not sure
        let crypto = CryptoService.shared
        
        do {
            state!.secretKey = try crypto.retrieveKey()
            print("key retrieved")
        } catch CryptoService.CryptoError.cannotRetrieveKey {
            state!.secretKey = try! crypto.generateKey()
            print("key generated")
        } catch {
            print("error")
        }
        
        key = try PrivateKey(reference: state!.secretKey!) // as PrivateKey
        state!.publicKey = SecKeyCopyPublicKey(state!.secretKey!)
        
            
    }
    
    
    
    func JSONToNotes(data: Data) throws -> [Note] {
        let notes = try! JSONDecoder().decode([Note].self, from: data)
        return notes
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "libr8":
            let noteVC: NoteVC = segue.destination as! NoteVC
            print(state!)
            switch librTextField.text! {
            
            
            case "libr.8":
                noteVC.state = state
                noteVC.state.notes = notes
                print("state", state)
                print("notevcstate", noteVC.state)
                
            default:
                print("state.counter", state!.counter)
                print("state.counter+", state!.counter)
                
//                state.loadedNotes = loadedNotes
                noteVC.state = state
                
                print("loadedNotesAboveAdditions", loadedNotes)
                noteVC.state.game = .Influx
                
            }
            
            if state!.counter < 4 {
                noteVC.state!.game = .Entry
            } else {
                noteVC.state!.game = .NoteView
            }
        default:
            break
        }
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func createPlayerIfNeeded(address: String, owner: Bool) -> Addr? {
        let predicate = NSPredicate(format: "address == %@", address)
        var player: Addr?
        if state.players.filter(predicate).first == nil {
            print("pretrying to addr")
            player = Addr(address: address, owner: owner)
            print("trying to addr")
            RealmService.shared.create(player!)
            print("player created")
        }
        return player
    }
    
    func orderNotes() -> [Note] {
        let orderedNotes = notes.sorted { (lhs, rhs) -> Bool in
            score(lhs) > score(rhs)
        }
        return orderedNotes
    }
    
    func score(_ note: Note) -> Double {
        let address = note.address
        let predicate = NSPredicate(format: "address == %@", address)
        if let player = state.players.filter(predicate).first {
            let score = pow(Double(note.green), player.phlo)
            return score
        }
        return 0.0
    }
    
    func urlSession(_ session: URLSession,
                             taskIsWaitingForConnectivity task: URLSessionTask) {
        proceedLabel.text = "connection needed to download Notes"
    }
    
    let hardNotesText: [(meta: String, data: String)] = [
        ("phase4word is the ideal competition", "We wish to flip the script on the debt that binds humanity. In phase4, you earn 1 green every Note that you readd.\n\nreadd = read ⊕ add\\nnEdit notes naturally, in line with your intuition that anything written is subject to change. Save notes by tapping mply, then selecting green from 1-100 to stake behind the idea.\n\nmply = multiply ⊕ amplify ⊕ imply"),
        ("it pays 2 read\npatience is key", "the principle behind this is shared risk. It's embarassing and costly to say the wrong thing. But poetry is not written from a place of fear. Take a risk to write something amazing.\n\nIf you swipe left on the BottomBar, you reveal 2 more buttons, powr and libr.\n\npowr comes from authority. Tap powr, then tap the Diamond to display all Notes in a list. You may select Notes to share, then tap the Diamond again.\n\nYou will be prompted to create a keyCode, a password you input into the topBar. You need at least 4 green to create a keyCode and share your Notebook."),
        ("Letters and numbers govern the world", "civilization was built with symbols. If you cannot read, what can you do today? Internet culture has become visual culture. It is time to reclaim languange."),
        ("speak, write, publish, transmedia", "welcome to the 4th phase of existance\n\nHumans are special animals who speak. Speech facilitates cooperation. One man may scream at a few thousand people.\n\nWriting makes speach portable across spacetime. Architecture, law, math, science, etc., explode given writing.\n\nPublishing makes written documents industrial goods. Abundant supply of published works encourages mass literacy. The printing press facilitates an educated populous. But mass production of media, especially audio and video, creates a hierarchy of a few elite media producers over the masses. One radio host can scream at 1 million people, but never face a response.\n\nContemporary social media still replicates the patterns of the last generation of mass media. Online platforms focus on influencers, people who are famous for being famous. We all agree that it's a problem, but most just blame human nature....Of course the pretty faces are magnets of attention, it's natural...")
    ]
    
    func hardNoteSetup() {
        if state != nil { return }
        
        let hardNote1: Note = blankNote(data: hardNotesText[0].data, meta: hardNotesText[0].meta, green: 4)
        let hardNote2: Note = blankNote(data: hardNotesText[1].data, meta: hardNotesText[1].meta, green: 3)
        let hardNote3: Note = blankNote(data: hardNotesText[2].data, meta: hardNotesText[2].meta, green: 2)
        let hardNote4: Note = blankNote(data: hardNotesText[3].data, meta: hardNotesText[3].meta, green: 1)
        
        let hardNotes = [hardNote1, hardNote2, hardNote3, hardNote4]
        
        for n in hardNotes {
            RealmService.shared.create(n)
            print("hardNotesTimimg")
        }
        
    }
    func blankNote(data: String, meta: String, green: Int) -> Note {
        return Note(green: green, ssi: "ssi".data(using: .utf8)!, address: "address", signature: "signature", digest: "digest", longitude: 42.0, latitude: -42.0, time: Date(timeIntervalSince1970: 0.0), data: data, meta: meta)
    }

}
