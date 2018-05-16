//
//  TestCell.swift
//  phase4word
//
//  Created by Yusef Nathanson on 1/19/18.
//  Copyright © 2018 Yusef Nathanson. All rights reserved.
//

import UIKit
import RealmSwift

class NoteCell: UITableViewCell {
    
    @IBOutlet weak var neuTimeLabel: UILabel!
    @IBOutlet weak var gLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        
        
        neuTimeLabel.lineBreakMode = .byTruncatingMiddle
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configure(with note: Note) {
        
        let greenTime = GreenTime(date: note.time)
        let neuDescription = greenTime.oneLineDescription
        
        gLabel.text = greenLabelFormatter(green: note.green)
        neuTimeLabel.text = neuDescription
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
