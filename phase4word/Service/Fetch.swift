//
//  Fetch.swift
//  phase4word
//
//  Created by Yusef Nathanson on 5/13/18.
//  Copyright © 2018 Yusef Nathanson. All rights reserved.
//

import Foundation

struct Fetch {
    
    
    static func get(url: URL) -> Data? {
        let request = URLRequest(url: url)
        
        var success = false
        var data: Data?
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: request, completionHandler: { json, response, error in
            if let error = error {
                print("Error while trying to re-authenticate the user: \(error)")
            } else {
                success = true
                data = json
                print(data!)
            }
            semaphore.signal()
        })
        
        task.resume()
        print("task resumed")
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        print("semaphore complete")
        return data
    }
}
