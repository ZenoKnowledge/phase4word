//
//  ViewController.swift
//  phase4word
//
//  Created by Yusef Nathanson on 1/19/18.
//  Copyright © 2018 Yusef Nathanson. All rights reserved.
//

import UIKit
import CoreLocation
import RealmSwift
import CryptoSwift
import SwiftyRSA
import StoreKit

class NoteVC: UIViewController, CLLocationManagerDelegate, UITextViewDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver {

    
    
    var ipfsURLs = ["http://ovsyukov.info:8081/",
                    "http://35.180.30.25:3000/",
                    "http://138.197.50.102:3000/"]
    
    @IBOutlet weak var libr: UIButton!
    @IBOutlet weak var powr: UIButton!
    @IBOutlet weak var readd: UIButton!
    @IBOutlet weak var mply: UIButton!
    @IBOutlet weak var powrBook: UIButton!
    
    @IBOutlet weak var mplyBar: UIImageView!
    @IBOutlet weak var mplySlider: MplySlider!
    @IBOutlet weak var sign: UIButton!
    
    @IBOutlet weak var greenLabel: UILabel!
    @IBOutlet weak var metaText: UITextView! //{
//        didSet {
////            let metaTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.metaTap(sender:)))
////            metaTapRecognizer.numberOfTapsRequired = 2
//            print("metaTap triggered")
//        }
    //}
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var dataText: UITextView! {
        didSet {
            let leftSwipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(self.leftSwipeData(recognizer:)))
            
            dataText.addGestureRecognizer(leftSwipeRecognizer)
            leftSwipeRecognizer.direction = .left
            
            let beginningOfDocument = dataText.beginningOfDocument
            dataText.selectedTextRange = dataText.textRange(from: beginningOfDocument, to: beginningOfDocument)
        }
    }
    
    @IBOutlet weak var buyGreenLabel: UILabel!
    
    @IBOutlet weak var dataTextViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var buyOrBurnCenterXConstraint: NSLayoutConstraint!
    
    var defaultDataTextViewBottomHeight: CGFloat = 0.0
    
    var state: State!
    
    
//    var notes: Results<Note>!
    var matchingNotes: [Note] = []
    var testNotes: [Note] = []
    
    
    
    let locationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 42.36, longitude: 71.06)
    
    /* Variables */
    var greenToStake = 0
    var rateLimit    = 0
    let GREEN_POWR_PRODUCT_ID = "online.phase4.greenpowerv0"
    
    var productsRequest = SKProductsRequest()
    var products = [SKProduct]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup location
        
        func setupLocationServices() {
            self.locationManager.requestWhenInUseAuthorization()
            
            if CLLocationManager.locationServicesEnabled() {
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.distanceFilter = 1000
                locationManager.startUpdatingLocation()
            }
        }
        
        setupLocationServices()
        
        SKPaymentQueue.default().add(self)
        
        dataText.delegate = self
        metaText.delegate = self
        
        // connect to db and read from db
        let realm = RealmService.shared.realm
        
        print("statenotestimeing")
        let savedStates = realm.objects(Save.self)
        if let loadState = savedStates.last {
            state.counter = loadState.counter
            state.buffer = loadState.buffer
            
            if state.game == .Entry {
                
                state.green = loadState.green
            }
        }
        print("one", state.orderedNotes.count)
        state.orderedNotes = state.loadedNotes + state.orderedNotes
        print("b4nilcheck, currentNote:", state.currentNote)
        if state.currentNote == nil {
            state.currentNote = state.orderedNotes[0]
        }
        print("two", state.orderedNotes.count)
        
        print(state.game)
        
        
        switch state.game {
        case .NoteView:
//            print(state.orderedNotes[0].digest)
            state.players = realm.objects(Addr.self)
        case .Powering:
            mply.titleLabel?.text = "book"
        case .Entry:
            print("hardNoteSetup")
            hardNoteSetup()
        case .WillPower:
            break
//        case .Influx:
//            state.green += influx
        default:
            state.game = .NoteView
            print("default. state now=", state.game)
        }
        
        print("b4 switch. currentNote:", state.currentNote)
        switch state.game {
        case .WillPower, .ToNote:
            displayCurrentNote()
        default:
            print("beforelogic, currentNote:", state.currentNote)
            if state.currentNote != nil || state.buffer != nil {
                print("passed 1st gate")
                displayCurrentNote()
                print("past displayCurrentNote")
            } else {
                print("in 1st else statment")
                //            print("oN.First:", state.orderedNotes.first)
                state.currentNote = state.orderedNotes.first
                print("assigned state.currentNote to s.oN.first")
                displayCurrentNote()
            }
        }
        
        print("displaying currentnote. meta: \(String(describing: state.currentNote?.meta)), time: \(String(describing: state.currentNote?.time))")
        print("afterdisplaying, state.game", state.game)
        
//        if state.orderedNotes.count > 1 {
//            state.currentNote = nextNote(after: state.currentNote ?? randomElement(state.orderedNotes))
//        }
    
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.textViewNotification), name: NSNotification.Name.UITextViewTextDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.textViewNotification), name: NSNotification.Name.UITextViewTextDidBeginEditing, object: nil)
        
        
        setupLayout()
//        print("before greenBalance called. player = \(player). state.green= \(player.green)")
//        greenBalance()
//        print("after greenBalance called. state.player = \(state.player). state.green = \(state.green)")
//        greenColor()
    }
    
    @objc func doneTapped() {
        view.endEditing(true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        if let notes = state.notes {
            let saveState = Save(counter: state.counter, green: state.green, notes: notes, buffer: state.buffer, state: state)
            RealmService.shared.create(saveState)
        }
    }
        
    
    

    @IBAction func mplyTapped(_ sender: UIButton) {
        print("mplyTapped0. state.game=", state.game)
        switch state.game {
        case .WillPower:
            state.game = .Powering
        case .Powering:
            break
        default:
            state.game = .Mplying
        }
        
        print("mplyTapped1. state.game=", state.game)
        switch metaText.text {
        case "":
            setBottomBar(for: .NoteView)
            break
        default:
            print("mplyTapped2. state.game=", state.game)
            setBottomBar(for: state.game)
            greenLabel.text = "♻️"
            
            print("b4switch state.game:", state.game)
            print("b4switch state.green:", state.green)
            print("b4switch buyOrBurnCenterXConstraint:", buyOrBurnCenterXConstraint)
            switch state.game {
            case .Powering:
                if state.green < 4 {
                    buyOrBurnCenterXConstraint.constant = 0
                    
                    UIView.animate(withDuration: 0.2, animations: {
                        self.view.layoutIfNeeded()
                    })
                } else { break }
            default:
                 greenLabel.text = "🤐"
            }
        }
    }
    @IBAction func burnTapped(_ sender: Any) {
        buyOrBurnCenterXConstraint.constant = -444
        
        UIView.animate(withDuration: 0.1, animations: {
            self.view.layoutIfNeeded()
        })
        
        print("burnTapped, currentNote.data:", state.currentNote?.data)
        state.game = .NoteView
        setBottomBar(for: state.game)
        state.currentNote = randomElement(state.orderedNotes)
        displayCurrentNote()
        
    }
    
    @IBAction func buyTapped(_ sender: Any) {
        print("About to fetch the product...")
        
        // Can make payments
        if (SKPaymentQueue.canMakePayments())
        {
            let productID = [self.GREEN_POWR_PRODUCT_ID] as Set
            let productsRequest:SKProductsRequest = SKProductsRequest(productIdentifiers: productID)
            productsRequest.delegate = self
            productsRequest.start()
            print("Fetching Products")
        }else{
            print("Can't make purchases")
        }
    }
    
    func buyProduct(product: SKProduct){
        print("Sending the Payment Request to Apple")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
        
    }
    
    
    
    
    
    

    func setBottomBar(for mood: Game) {
        print("settingBottomBar. current mood", state.game)
        switch mood {
        case .NoteView, .Influx, .Editing, .WillPower:
            scrollView.isHidden = false
            mplyBar.isHidden    = true
            mplySlider.isHidden = true
            sign.isHidden = true
            greenLabel.isHidden = true
        case .Powering, .Mplying:
            scrollView.isHidden = true
            mplyBar.isHidden    = false
            mplySlider.isHidden = false
            sign.isHidden = false
            greenLabel.isHidden = false
        default:
            scrollView.isHidden = false
            mplyBar.isHidden    = true
            mplySlider.isHidden = true
            sign.isHidden = true
            greenLabel.isHidden = true
        }
    }
    
    @IBAction func signTapped(_ sender: Any) {
        switch state.game {
        case .Powering:
            
            if greenLabel.text == "♻️" || greenLabel.text == "pay2play" {
                break
            }
            
            let crypto = CryptoService.shared
            
            if let jsonData = state.jsonData {
//                print("currentNote:", state.currentNote?.data)
//                print("jsonData:", jsonData, jsonData.bytes.count)
                
//                DispatchQueue.global(qos: .background).async {
                let noteBook = noteBookFrom(json: jsonData, green: greenToStake)
                let jsonToEncrypt = try! notesToJSON(notes: noteBook)
                let encryptedBytes = crypto.encryptData(data: jsonToEncrypt, code: self.metaText.text)
//                print("encryptedBytes", encryptedBytes, encryptedBytes.count)
//                }
                print("1state.game", state.game)
                if let keyCode = metaText.text {
                    uploadToIPFS(bytes: encryptedBytes, digest: jsonData.hexDescription.sha256(), rateLimit: rateLimit, keyCode: keyCode, green: greenToStake)
                    dataText.text = "Your phase4 keyCode valid for \(rateLimit) views\n\n\n==\n\(metaText.text!)"
                    state.green -= greenToStake
                    metaText.text = "noteBook uploaded"
                    print("2state.game", state.game)
                    setBottomBar(for: .NoteView)
                    state.game = .NoteView
                    print("3state.game", state.game)
                }
            }
            
            
        default:
            print("0signing note. state.green:", state.green)
            let green = greenFrom(greenLabel: greenLabel.text!)
            
            state.green -= green
            print("1signing note. state.green:", state.green)
            let note = newNote(green: green)
            updatePhlo(action: .mply, address: note.address, green: green)
            RealmService.shared.create(note)
            
            
            
            state.orderedNotes.insert(note, at: 0)
            
//            subtractGreen(g: green)
//            greenBalance()
            
            //        notes = RealmService.shared.realm.objects(Note.self)
            //        state.orderedNotes = orderNotesByDate(input: state.orderedNotes)
            print("note created")
            print("2signing note. state.green:", state.green)
            //        print(notes.count)
            
            //        let net = NetworkService.shared
            //        net.mply(note: noteJson!, head: "phase4", agent: "agent")
            
            state.currentNote = note
            
            //        let predicate = NSPredicate(format: "meta == %@", (state.currentNote?.meta)!)
            matchingNotes = state.orderedNotes.filter({ (note) -> Bool in
                note.meta == state.currentNote?.meta
            })
            performSegue(withIdentifier: "mplySegue", sender: nil)
        }
        
        }
    
    
    @IBAction func readdTapped(_ sender: UIButton) {
        print("readTapped. state.currentNote =", state.currentNote!)
        print("state.currentNote.green =", state.currentNote!.green)
        print("0.readdTapped", state.green)
        addGreen(green: state.currentNote!.green)
        print("1.readdTapped", state.green)

        readd.setTitle("\(state.green)", for: .normal)
//        greenColor()
//        print("oCurrentNote", state.currentNote)
        if state.orderedNotes.count > 0 {
            if nextNote(after: state.currentNote!)?.meta == "" {
                state.currentNote = randomElement(state.orderedNotes)
            } else if state.currentNote?.data.sha256() != nextNote(after: state.currentNote!)?.data.sha256() {
                state.currentNote = nextNote(after: state.currentNote!)
                
            } else {
                state.currentNote = randomElement(state.orderedNotes)
            }
        }
//        print("nCurrentNote", state.currentNote)
        displayCurrentNote()
    }
    @IBAction func librTapped(_ sender: UIButton) {
        print("libr tapped")
//        let (metaline, data) = readSavedNote()
//        metaText.text = metaline
//        dataText.text = data
        
        performSegue(withIdentifier: "librSegue", sender: nil)
        print("performing segue to librVC")
    }
    
   
    @IBAction func powrTapped(_ sender: UIButton) {
//        print("notes.count: \(notes.count), state.players.count: \(state.players.count), state.orderedNotes.count: \(state.orderedNotes.count)")
        let buffer = state.buffer
//        print("s.buffer: \(state.buffer)")
        powrBook.isHidden = false
        metaText.text = ""
        dataText.text = ""
        state.buffer = buffer
//        print("s.buffer: \(state.buffer)")
        
        // must set up observer for textView
//        
//        if metaText.isFirstResponder || dataText.isFirstResponder {
//            powrBook.isHidden = true
//        }
    }
    //    func mply(note: NoteToSign, green: Int) -> Note {
//        var newNote = Note()
//        do {
//
//            let noteJson = try JSONEncoder().encode(note)
////            print(note)
//            let secretKey = try CryptoService.shared.retrieveKey()
//
//            let publicKey = SecKeyCopyPublicKey(secretKey)
//
//
//
//            let pubKeyHash = CryptoService.shared.secKeyToHexString(key: publicKey).sha256()
//            let signature = try CryptoService.shared.sign(privateKey: secretKey, data: noteJson)
//            let sigHex = signature.hexDescription
//            let digest = noteJson.sha256()
//
//            let fullNote = Note(data: note.data, meta: note.metaline, moment: note.moment, address: pubKeyHash, signature: sigHex, digest: digest)
//            print(fullNote)
//
//            newNote = fullNote
//        } catch {
//            print("error")
//        }
//        return newNote
//
//    }
    
    @IBAction func powrBookTapped(_ sender: UIButton) {
        
        //when powrBook is tapped, player is shown modal popup requesting payment
        // it costs g state.greento powr a book. after paying green, player is segued
        // to librVC to select which notes to include. After selecting, player is prompted
        // to give spam email to which libr.8 code will be sent
        // g = min(median state.greenper player, 25% of green)
        
        performSegue(withIdentifier: "powrSegue", sender: nil)
    }
    // this function crashes a phone with no saved notes
//    func readSavedNote() -> (metaline: String, data: String) {
//        let note = notes.last
//        let metaline = note!.meta
//        let data = note!.data
//
//        return (metaline, data)
//    }
    
    @objc func leftSwipeData(recognizer: UISwipeGestureRecognizer) {
        if state.orderedNotes.count > 0 {
            state.lastNote    = state.currentNote
            state.currentNote = nextNote(after: state.currentNote!)
        }
        updatePhlo(action: .left, address: state.lastNote!.address, green: nil)
        
        displayLeftHand()
        state.game = .NoteView
        setBottomBar(for: state.game)
        
        
    }
    
    func updatePhlo(action: Note.NoteAction, address: String, green: Int?) {
        let predicate = NSPredicate(format: "address == %@", address)
        print("after predicate def")
        if let player = state.players.filter(predicate).first {
            var phlo = player.phlo
            print("phlo = \(phlo)")
            print("after let player")
            print("action = \(action)", "address = \(address)", "state.green= \(String(describing: green))")
            
            switch action {
            case .mply:
                print(Double.onePlusRand(), logn(val: Double(green!), forBase: 100.0))
                phlo *= (Double.onePlusRand() + logn(val: Double(green!), forBase: 100.0))
                print("case .mply")
                print("phlo = \(phlo)")
            case .left:
                phlo *= 0.5
                print("case .left")
                print("phlo = \(phlo)")
            }
            
            let dict = ["phlo": phlo]
            RealmService.shared.update(player, with: dict)
        }
    }
    
//    func encryptNoteJson(data: Data, key: PrivateKey) -> Data {
//        
//    }
    
    func displayLeftHand() {
        print("displayLeftHand started")
        // trigger state transition to Game.left
        
        let address = state.lastNote!.address
        let predicate = NSPredicate(format: "address == %@", address)
        let phlo = state.players.filter(predicate).first?.phlo ?? 0.5
//        var countdownString = "5...4...3...2...1..."
        
        print("phlo: \(phlo), address: \(address)")
        
//        let metaString = "note = left" + "\n" + "tap powr to undo"
//        var dataString = "Address: \(address)" + "\n" + "phlo: \(phlo)" + "\n\n" + "Next note in "
//        metaText.text = metaString
//        dataText.text = dataString
      
        
        
        
//        for _ in 0..<countdownString.count { // countdownString.count == 20
//            dataString.append(countdownString.remove(at: countdownString.startIndex))
//            dataText.text = dataString
//            print("countdownString: \(countdownString)")
//            print(dataString)
//            usleep(250000)
//        }
        
        displayCurrentNote()
        
    }
    
    func randomElement<T>(_ array: Array<T>) -> T {
        let randomIndex = Int(arc4random_uniform(UInt32(array.count)))
        return array[randomIndex]
    }
    
    func randomElement<T>(_ collection: Results<T>) -> T {
        let randomIndex = Int(arc4random_uniform(UInt32(collection.count)))
        return collection[randomIndex]
    }
    
    
    func newNote(green: Int) -> Note {
        let key = try! PrivateKey(reference: state.secretKey!)
        
        let crypto = CryptoService.shared
        
        let latitude = Double(currentLocation.latitude)
        let longitude = Double(currentLocation.longitude)
        
        let time = Date()
        
//        let publicKeyData = crypto.secKeyToData(key: SecKeyCopyPublicKey(secretKey!))
        let pubKey = try! PublicKey(reference: state.publicKey!)
        let pemString = try! pubKey.pemString()
//        print(pemString, pemString.data(using: .utf8)?.bytes.count)
        
        let secret = try! Secret(data: pemString.data(using: .utf8)!, threshold: 4, shares: 20)
        let shares = try! secret.split()
        
        
        let address = pemString.sha256().sha256()
        print("after address")
        let ssi = randomElement(shares).data
        print("ssi", ssi)
        let noteToSign = NoteToSign(green: green, ssi: ssi, data: dataText.text, meta: metaText.text, longitude: longitude, latitude: latitude, time: time, address: address)
        print("noteToSign")
        
        let noteJson = noteToSign.toJson()
//        print("noteJson", noteJson, noteJson?.bytes.count)
        
        let digest = noteJson!.sha256data()
        let digestString: String = noteJson!.hexDescription.sha256()
        
        print(digest, "digest")
        let signature = crypto.sign(key: key as Key, data: digest)
        print(signature, "signature")
        
        let trizzy = crypto.verify(publicKey: pubKey, data: digest, base64EncSignature: signature)
        print("trizzy", trizzy)
        let newNote = Note(unsignedNote: noteToSign, digest: digestString, signature: signature)
        print(newNote, "newNote")
//        let newNoteJson = try! JSONEncoder().encode(newNote)
//        print(newNoteJson, "newNoteJson")
        
        return newNote
        
    }
    
    func notesToJSON(notes: [Note]) throws -> Data {
        let data = try! JSONEncoder().encode(notes)
        return data
    }
    
//    func encryptData(data: Data) -> ([UInt8], String) {
//        let crypto = CryptoService.shared
//        let digest = data.hexDescription.sha256()
//        let key = Array(digest.sha256().utf8) as [UInt8]
//        let iv = crypto.cha20IvMaker(digest: digest)
//        
//        let cipherData = try! ChaCha20(key: key, iv: iv).encrypt(Array(data.bytes))
//        return (cipherData, digest)
//    }
//    
//    func decryptBytes(bytes: [UInt8], digest: String) -> Data {
//        let crypto = CryptoService.shared
//        
//        let key = Array(digest.sha256().utf8) as [UInt8]
//        let iv = crypto.cha20IvMaker(digest: digest)
//        let decrypted = try! ChaCha20(key: key, iv: iv).decrypt(bytes)
//        let data = Data(bytes: decrypted)
//        
//        return data        
//    }
    
    
    
    
//    let cipherText = try! ChaCha20(key: key, iv: iv).encrypt(Array(lastHash.utf8))
//
//
//    let decrypted = try! ChaCha20(key: key, iv: iv).decrypt(cipherText)
//    let decString = String(bytes: decrypted, encoding: .utf8)!
    
    
    
    func displayCurrentNote() {
        if let currentNote = state.currentNote {
//            print("game",state.game, "counter", state.counter)
            switch state.game {
            case .ToNote:
                if let buffer = state.buffer {
                    metaText.text = buffer.0
                    dataText.text = buffer.1
                    state.game = .NoteView
                }
            default:
                metaText.text = currentNote.meta
                dataText.text = currentNote.data
            }

            // I wanted to delete currentNote if it has green < 0 for what reason?
            // if people get some cryptoNotes on their phone, ok...
//            if currentNote.green < 0 {
//                RealmService.shared.delete(currentNote)
//            }
            
//            state.currentNote = nextNote(after: currentNote)
            
            print("bp=beforeCreatePlayerIfNeeded")
            createPlayerIfNeeded(note: currentNote)
            
        }
        
        
    }
    
    func displayNote(_ note: Note) {
//        print("currentNote.digest.green", state.currentNote?.digest, state.currentNote?.green)
        metaText.text = note.meta
        dataText.text = note.data
        
        createPlayerIfNeeded(note: note)
    }
    
//    func newCurrentNote() -> Note {
////        var newCurrentNote: Note
////        if state.orderedNotes == [] {
////            newCurrentNote = randomElement(notes)
////        } else {
////            newCurrentNote = state.orderedNotes.first!
////        }
//        let newCurrentNote = state.orderedNotes.remove(at: state.orderedNotes.startIndex)
//        return newCurrentNote
//    }
    
//    func nextNote(after currentNote: Note) -> Note? {
//        if state.orderedNotes.count <= 1 {
//            return randomElement(state.orderedNotes) // ?? blankNote(data: "", meta: "")
//        } else {
//            if let index = state.orderedNotes.index(of: currentNote) {
//                return state.orderedNotes[min(state.orderedNotes.count - 1, index + 1)]
//            } else {
//                return blankNote(data: "", meta: "")
//            }
//        }
//    }
    
    func nextNote(after currentNote: Note) -> Note? {
        if let index = state.orderedNotes.index(of: currentNote) {
            return state.orderedNotes[min(state.orderedNotes.count - 1, index + 1)]
        } else {
            return randomElement(state.orderedNotes)
        }
    }
    
    func blankNote(data: String, meta: String, green: Int) -> Note {
        return Note(green: green, ssi: "ssi".data(using: .utf8)!, address: "address", signature: "signature", digest: "digest", longitude: 42.0, latitude: -42.0, time: Date(), data: data, meta: meta)
    }
    
    func noteBookFrom(json: Data, green: Int) -> [Note] {
        //creates a noteBook by adding a note with green equal to total green staked
        // that note's body is
        
        let selectedNotes = try! JSONDecoder().decode([Note].self, from: json)
        
        let key = try! PrivateKey(reference: state.secretKey!)
        let signature = CryptoService.shared.sign(key: key, data: json)
        let greenTimeNow = GreenTime(date: Date()).shortDescription
        let leadNote = blankNote(data: signature, meta: "♻️" + "\(green)\n\(greenTimeNow)", green: -green)
        let notesToEncrypt = [leadNote] + selectedNotes
        return notesToEncrypt
        
        
    }
    
    func createPlayerIfNeeded(note: Note) {
        let address = note.address
        let predicate = NSPredicate(format: "address == %@", address)
        if state.players.filter(predicate).first == nil {
            print("pretrying to addr")
            let player = Addr(address: address, owner: true)
            print("trying to addr")
            RealmService.shared.create(player)
            print("player created")
        }
    }
    
    @IBAction func mplyAmountChanged(_ sender: Any) {
        switch state.game {
        case .Powering:
            let val = mplySlider.value * -1
            let p = Double(val / 10.0)
            var impressionCapacity = 0.0
            var rem = Double(state.green)
            
            while rem >= 4 {
                rem *= 0.75
                impressionCapacity += 1.0
            }
            
            rateLimit = Int(impressionCapacity * p)
            
            greenToStake = Int((Double(state.green) - rem) * p)
            
            if rateLimit > 0 {
                greenLabel.textColor = UIColor(red: 0.163, green: 1.0, blue: 0.432, alpha: 1.0)
                greenLabel.text = "\(rateLimit)👀 for ♻️\(greenToStake)"
            } else {
                greenLabel.textColor = UIColor.brown
                greenLabel.text = "pay2play"
            }
            
            
        default:
            let val = mplySlider.value * -1
            let green = Int(round(val * val))
            
            switch green {
            case 1:
                greenLabel.textColor = UIColor(named: "GrayLight")
                greenLabel.text = "🤐"
            case 100:
                greenLabel.text = "🔥"
            default:
                greenLabel.textColor = UIColor(red: 0.163, green: 1.0, blue: 0.432, alpha: 1.0)
                greenLabel.text = String(green)
            }
        }
        
        
    }
    
    func orderNotes() -> [Note] {
        let orderedNotes = state.notes!.sorted { (lhs, rhs) -> Bool in
            score(lhs) > score(rhs)
        }
        return orderedNotes
    }
    
    func orderNotesByDate(input: Results<Note>) -> [Note] {
        let notesByDate = input.sorted { (lhs, rhs) -> Bool in
            lhs.time > rhs.time
        }
        return notesByDate
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
    
    
    /// testing function to load 10,000 notes in ram
    func createNotes(n: Int, template: Note) -> [Note] {
        var notes: [Note] = []
        var meta: String?
        for i in 0..<n {
            if i % 2 == 0 {
                meta = template.meta.sha256()
            }
            let note = Note(green: i % 100, ssi: "ssi".data(using: .utf8)!, address: template.address, signature: template.signature, digest: template.digest, longitude: template.longitude, latitude: template.latitude, time: template.time, data: template.data, meta: meta ?? template.meta)
            notes.append(note)
        }
        return notes
    }
    
    @objc func metaTap(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            testNotes = createNotes(n: 1000, template: mockNote())
        }
    }
    
    func mockNote() -> Note {
        return state.currentNote ?? randomElement(state.orderedNotes)
    }
    
    
    
    
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let locValue:CLLocationCoordinate2D = manager.location?.coordinate {
//            print("locations = \(locValue.latitude) \(locValue.longitude)")
            self.currentLocation = locValue
            
        }
        
    }
    
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        let count: Int = response.products.count
        if count > 0 {
            let validProduct: SKProduct = response.products[0] as SKProduct
            if (validProduct.productIdentifier == self.GREEN_POWR_PRODUCT_ID) {
//                print(validProduct.localizedTitle)
//                print(validProduct.localizedDescription)
//                print(validProduct.price)
                buyProduct(product: validProduct)
            } else {
                print(validProduct.productIdentifier)
            }
        } else {
            print("nothing")
        }
    }
    
    
    private func request(request: SKRequest!, didFailWithError error: Error!) {
        print("Error Fetching product information")
    }
    
    func paymentQueue(_ queue: SKPaymentQueue,
                      updatedTransactions transactions: [SKPaymentTransaction]) {
        print("Received Payment Transaction Response from Apple")
        
        for transaction: AnyObject in transactions {
            if let trans: SKPaymentTransaction = transaction as? SKPaymentTransaction {
                switch trans.transactionState {
                case .purchased:
                    print("Product Purchased")
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    state.green = 4
                    UserDefaults.standard.set(true , forKey: "purchased")
                    break
                case .failed:
                    print("Purchased Failed")
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    break
                default:
                    break;
                }
            }
        }
        
    }
    
    
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mplySegue" {
            state.game = .Mplying
            state.buffer = (metaText.text, dataText.text)
            let tableMapVC: TableMapVC = segue.destination as! TableMapVC
            tableMapVC.matchingNotes = matchingNotes
            tableMapVC.state = state
        }
        
        if segue.identifier == "librSegue" || segue.identifier == "powrSegue" {
            print("preparing to segue to librVC")
            state.game = .Library
            if metaText.text != "" && dataText.text != "" {
                state.buffer = (metaText.text, dataText.text)
            }
            let librVC: LibrVC = segue.destination as! LibrVC
            librVC.state = state
            librVC.state.notes = state.notes
            librVC.state.game = .Library
            librVC.sortedNotes = state.orderedNotes
            
            if segue.identifier == "powrSegue" {
                print("powrSegue")
                print("state.green", state.green)
                librVC.state.game = .Powering
                
            }
            
        }
    }
    
    func setupLayout() {
        defaultDataTextViewBottomHeight = dataTextViewBottomConstraint.constant
//        print("defaultDataTextViewHeight: \(defaultDataTextViewBottomHeight)")
        
        let halfViewWidth = self.view.frame.width / 2
        let yHeight = self.view.frame.height - 84
        self.scrollView.frame = CGRect(x: 0, y: yHeight, width: self.view.frame.width, height: self.view.frame.height)
        
        let scrollViewWidth  = self.scrollView.frame.width
        //        let scrollViewHeight = self.scrollView.frame.height
        
        scrollView.contentSize.width = scrollViewWidth * 2
        
        metaText.textContainer.maximumNumberOfLines = 2
        metaText.textContainer.lineBreakMode = .byTruncatingMiddle
        
        //buttons
        
        
        libr.frame = CGRect(x: halfViewWidth * 3, y: 0, width: halfViewWidth, height: libr.frame.size.height)
        
        powr.frame = CGRect(x: halfViewWidth * 2, y: 0, width: halfViewWidth, height: powr.frame.size.height)
        
        readd.frame = CGRect(x: 0, y: 0, width: halfViewWidth, height: readd.frame.size.height)
        
        mply.frame = CGRect(x: halfViewWidth, y: 0, width: halfViewWidth, height: mply.frame.size.height)
        
        
        let toolbar = UIToolbar()
//        let trans = UIColor(displayP3Red: 0.1, green: 0.25, blue: 0.25, alpha: 0.25) //just a test
        toolbar.barStyle = .blackTranslucent
        
        
        
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let noisyBar = UIImage(imageLiteralResourceName: "nrect6")
        let doneButton = UIBarButtonItem(image: noisyBar, style: .done, target: self, action: #selector(self.doneTapped))
//        toolbar.setBackgroundImage(noisyBar, forToolbarPosition: .top, barMetrics: .default)
//        flexibleSpace.setBackgroundImage(noisyBar, for: .normal, barMetrics: .default)
//        let undoButton = UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: #selector(self.undoTapped))
//        doneButton.setBackgroundImage(noisyBar, for: .normal, barMetrics: .default)
//        undoButton.setBackgroundImage(noisyBar, for: .normal, barMetrics: .default)
        toolbar.setItems([flexibleSpace, doneButton], animated: true)
        toolbar.sizeToFit()
        
        metaText.inputAccessoryView = toolbar
        dataText.inputAccessoryView = toolbar
        
        buyGreenLabel.text = "You have \(state.green) green. You need at least 4 green to share Notes. Would you like to pay 4 green power?"
        
    }
    
    @objc func keyboardNotification(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = info[UIKeyboardFrameEndUserInfoKey] as! CGRect
        
        switch notification.name {
        case .UIKeyboardWillShow:
            
            powrBook.isHidden = true
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.dataTextViewBottomConstraint.constant = keyboardFrame.size.height + 4})
            
        case .UIKeyboardWillHide:
            UIView.animate(withDuration: 0.1, animations: { () -> Void in
                self.dataTextViewBottomConstraint.constant = self.defaultDataTextViewBottomHeight })
        default:
            break
        }
        
        
    }
    
    @objc func textViewNotification(notification: NSNotification) {
        switch notification.name {
        case .UITextViewTextDidBeginEditing:
            if state.game != .Powering {
                setBottomBar(for: state.game)
            }
        case .UITextViewTextDidChange:
            state.buffer = (metaText.text, dataText.text)
        default:
            break
        }
        
        state.buffer = (metaText.text, dataText.text)
//        print("s.buffer", state.buffer)
    }
    
//    func greenBalance() {
//
////        if state.player.green == nil {
////            return
////        } else {
////        print("inside greenBalance. state.green= \(state.green). player.state.green= \(state.player.green)")
//        print("b4gb. player.green, state.green", state.green, state.green)
//        print("greenbalance begins")
//        addGreen(green: state.green - state.green)
////        state.green = state.green
//        print("aftergb. player.green, state.green", state.green, state.green)
////        print("leaving greenBalance. state.green= \(state.green). player.state.green= \(state.player.green)")
////        }
//
//    }
    
    func addGreen(green: Int) {
        print("addingGreen")
//        var dict = ["" : 0]
        if green < 0 {
            state.green -= green
//            dict = ["green": state.green - green]
            print("adding \(-green) green")
            print("1.addingGreen", state.green)
        } else {
            state.green += 1
//            dict = ["green": state.green + 1]
            print("addingOneGreen")
            print("2.addingGreen", state.green)
            
        }
//        RealmService.shared.update(state.player!, with: dict)
        print("GreenAdded")
    }
    
//    func subtractGreen(g: Int) {
//        state.green -= g
////        let dict = ["green": state.green - g]
////        RealmService.shared.update(state.player!, with: dict)
//    }
    
    
    func greenFrom(greenLabel: String) -> Int {
        switch greenLabel {
        case "🤐":
            return 1
        case "🔥":
            return 100
        default:
            return Int(greenLabel) ?? 1
        }
    }
    
//    func greenColor() {
//        switch state.green{
//        case -Int.max..<0:
//            readd.titleLabel?.textColor = .red
//        case 0:
//            readd.titleLabel?.textColor = .blue
//        case 0...Int.max:
//            readd.titleLabel?.textColor = .green
//        default:
//            break
//        }
//    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    
    func logn(val: Double, forBase base: Double) -> Double {
        return log(val)/log(base)
    }
    
    func uploadToIPFS(bytes: [UInt8], digest: String, rateLimit: Int, keyCode: String, green: Int) {
        let jsonData = try! JSONEncoder().encode(bytes)
        print("jsonData", jsonData, jsonData.count)
        
        let ipfsUrl = ipfsURLs[2] + "ipfs"
        let url = URL(string: ipfsUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
    
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let params: [String : String] = ["file": "\(bytes.sha256())", digest: digest, "rateLimit": "\(rateLimit)", "keyCode": "\(keyCode.sha256().sha256().sha256().sha256())"]
        
        request.httpBody = createBody(parameters: params,
                                boundary: boundary,
                                data: jsonData,
                                mimeType: "text/plain",
                                filename: "hello.json")
        
        // insert json data to the request
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
        }
        
        task.resume()
    }
    
    func createBody(parameters: [String: String],
                    boundary: String,
                    data: Data,
                    mimeType: String,
                    filename: String) -> Data {
        let body = NSMutableData()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for (key, value) in parameters {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        
        body.appendString(boundaryPrefix)
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n")
        body.appendString("--".appending(boundary.appending("--")))
        
        return body as Data
    }
    
    let hardNotesText: [(meta: String, data: String)] = [
        ("phase4word is a competitive space for ideals", "We wish to flip the script on the debt that binds humanity. In phase4, you earn 1 green every Note that you readd.\nreadd = read ⊕ add\nEdit notes naturally, in line with your intuition that anything written is subject to change. Save notes by tapping mply, then selecting green from 1-100 to stake behind the idea.\nmply = multiply ⊕ amplify ⊕ imply"),
        ("it pays 2 read\npatience is key", "the principle behind this is shared risk. It's embarassing and costly to say the wrong thing. But poetry is not written from a place of fear. Take a risk to write something amazing.\n\nIf you swipe left on the BottomBar, you reveal 2 more buttons, powr and libr.\n\npowr comes from authority. Tap powr, then tap the Diamond to display all Notes in a list. You may select Notes to share, then tap the Diamond again.\n\nYou will be prompted to create a keyCode, a password you input into the topBar. You need at least 4 green to create a keyCode and share your Notebook."),
        ("Letters and numbers are how we navigate the world", "civilization was built with symbols. If you cannot read, what can you do today? Internet culture has become visual culture. It is time to reclaim languange."),
        ("speech, writing, publishing, social media", "welcome to the 4th phase of existance\n\nHumans are special animals who speak. Speech facilitates cooperation. One man may scream at a few thousand people.\n\nWriting makes speach portable across spacetime. Architecture, law, math, science, etc., are only possible once writing is invented.\n\nPublishing makes written documents industrial goods. Abundance of supply of published works encourages mass literacy. The printing press facilitates an educated populous. But mass production of media, especially audio and video, creates a hierarchy of a few elite media producers over the masses. One radio host can scream at 1 million people, but never face a response.\n\nContemporary social media still replicates the patterns of the last generation of mass media. Online platforms focus on influencers, people who are famous for being famous. We all agree that it's a problem, but most just blame human nature....Of course the pretty faces are magnets of attention, it's natural...")
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
    
    

}

extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}

