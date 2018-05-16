//
//  CustomSlider.swift
//  phase4word
//
//  Created by Yusef Nathanson on 1/29/18.
//  Copyright © 2018 Yusef Nathanson. All rights reserved.
//

import UIKit

@IBDesignable
class MplySlider: UISlider {

    @IBInspectable var thumbImage: UIImage? {
        didSet {
            setThumbImage(thumbImage, for: .normal)
        }
    }

}
