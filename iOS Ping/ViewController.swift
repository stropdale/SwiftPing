//
//  ViewController.swift
//  iOS Ping
//
//  Created by Richard Stockdale on 07/08/2019.
//  Copyright © 2019 RGB Consulting. All rights reserved.
//

import UIKit
import os.log

class ViewController: UIViewController {
    
    @IBOutlet weak var hostField: UITextField!
    @IBOutlet weak var resultView: UITextView!
    
    var ping: Ping?
    
    @IBAction func ping(_ sender: Any) {
        let hostName = hostField.text
        
        if ping == nil {
            ping = Ping.init(hostName: hostName!, completion: { (result, message) in
                self .response(result: result, message: message)
            })
            ping?.sendPing()
            
            return
        }
        
        if ping?.host == hostName {
            ping?.sendPing()
        }
        else {
            resultView.text = ""
            ping = nil
            ping(sender)
        }
    }
    
    private func response(result: Ping.PingResult, message: String) {
        let resultText = "\(result.description()): \(message)"
        
        let resultViewText = resultView.text!
        resultView.text = resultViewText + "\n" + resultText
    }
}

