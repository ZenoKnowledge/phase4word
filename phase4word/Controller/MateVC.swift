//
//  MateVC.swift
//  phase4word
//
//  Created by Yusef Nathanson on 3/7/18.
//  Copyright © 2018 Yusef Nathanson. All rights reserved.
//

import UIKit
import SwiftyRSA
import RealmSwift
import SAConfettiView

class MateVC: UIViewController, UITextFieldDelegate {

    var ipfsURLs = ["http://ovsyukov.info:8081/",
                    "http://35.180.30.25:3000/",
                    "http://138.197.50.102:3000/"]
    
    @IBOutlet weak var linkButton: UIButton!
    @IBOutlet weak var urlField: UITextField!
    var confettiView: SAConfettiView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        urlField.delegate = self

        confettiView = SAConfettiView(frame: self.view.bounds)
        view.addSubview(confettiView)
        confetti(view: confettiView)
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        print("4 sec")
        sleep(4)
        print("4 real")
        confettiView.stopConfetti()
        if urlField.text == "" {
            segue(with: "mateToEntry")
        }
        
        
        
    }
    
    @IBAction func linkButtonTapped(_ sender: Any) {
        ipfsURLs.append(urlField.text!)
        segue(with: "mateToEntry")
    }
    func confetti(view: SAConfettiView) {
        view.startConfetti()
        
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.linkButton.setTitle("add endpoint", for: .normal)
    }
    
    func segue(with identifier: String) {
        performSegue(withIdentifier: identifier, sender: self)
    }
        
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "mateToEntry":
            let noteVC: NoteVC = segue.destination as! NoteVC
            if let url = urlField.text {
                noteVC.ipfsURLs = ipfsURLs
            }
        default:
            break
        }
    }

}
