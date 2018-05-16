//
//  LibrCell.swift
//  phase4word
//
//  Created by Yusef Nathanson on 1/20/18.
//  Copyright © 2018 Yusef Nathanson. All rights reserved.
//

import UIKit
import RealmSwift

class LibrCell: UITableViewCell {

    @IBOutlet weak var greenLabel: UILabel!
    @IBOutlet weak var metaLabel: UILabel!
    @IBOutlet weak var hashLabel: UILabel!
    @IBOutlet weak var greenTimeLabel: UILabel!
    
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
    }

    func configure(with note: Note, row: Int) {
        metaLabel.text  = note.meta
        greenLabel.text = greenLabelFormatter(green: note.green)
        hashLabel.text  = note.data.sha256()
        greenTimeLabel.text = GreenTime(date: note.time).threeLineDescription
        
//        if row % 2 == 0 {
//            self.backgroundColor = UIColor(displayP3Red: 0.1, green: 0, blue: 0.3, alpha: 0.1)
//        }
    }
    
    func greenLabelFormatter(green: Int) -> String {
        switch green {
        case 1:
            return "🤐"
        case 100:
            return "🔥"
        default:
            return "\(green)"
        }
    }
}
