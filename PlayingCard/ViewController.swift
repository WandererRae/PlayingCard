//
//  ViewController.swift
//  PlayingCard
//
//  Created by Shannon on 3/12/18.
//  Copyright © 2018 Shannon. All rights reserved.
//

import UIKit
@IBDesignable
class ViewController: UIViewController {

    var deck = PlayingCardDeck()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for _ in 1...10 {
            if let card = deck.draw() {
                print("\(card)")
            }
        }
    }



}

