//
//  IAPService.swift
//  phase4word
//
//  Created by Yusef Nathanson on 5/8/18.
//  Copyright © 2018 Yusef Nathanson. All rights reserved.
//

import Foundation

public struct GreenProducts {
    
    public static let greenPower = "online.phase4.greenpowerv0"
    fileprivate static let productIdentifiers: Set<ProductIdentifier> = [GreenProducts.greenPower]
    
    public static let store = IAPHelper(productIds: GreenProducts.productIdentifiers)
    
    func resourceNameForProductIdentifier(_ productIdentifier: String) -> String? {
        return productIdentifier.components(separatedBy: ".").last
    }
}

