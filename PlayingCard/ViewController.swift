//
//  ViewController.swift
//  PlayingCard
//
//  Created by Shannon on 3/12/18.
//  Copyright © 2018 Shannon. All rights reserved.
//

import UIKit
import CoreMotion

@IBDesignable
class ViewController: UIViewController {
    
    var deck = PlayingCardDeck()
    @IBOutlet private var cardViews: [PlayingCardView]!
    lazy var cardBehavior = CardBehavior(in: animator)
    lazy var animator = UIDynamicAnimator(referenceView: view)
    
    let cardMatchedSize: CGFloat = 3.0
    let cardFlipAnimationTime: Double = 0.6
    let cardScaleAnimationTime: Double = 1.0
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        accelerationDueToGravity()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cardBehavior.gravityBehavior.magnitude = 0
        CMMotionManager.shared.stopAccelerometerUpdates()
    }
    
    private func accelerationDueToGravity() {
        if CMMotionManager.shared.isAccelerometerAvailable {
            cardBehavior.gravityBehavior.magnitude = 1.0
            CMMotionManager.shared.accelerometerUpdateInterval = 1/10
            CMMotionManager.shared.startAccelerometerUpdates(to: .main) { (data, error) in
                if var x = data?.acceleration.x, var y = data?.acceleration.y {
                    
                    switch UIDevice.current.orientation {
                    case .portrait: y *= -1
                    case .portraitUpsideDown: break
                    case .landscapeRight: swap(&x, &y)
                    case .landscapeLeft: swap (&x, &y); y *= -1
                    default: x = 0; y = 0;
                    }
                    
                    self.cardBehavior.gravityBehavior.gravityDirection = CGVector(dx: x, dy: y)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var cards = [PlayingCard]()
        for _ in 1...((cardViews.count + 1)/2) {
            let card = deck.draw()!
            cards += [card, card]
        }
        for cardView in cardViews {
            cardView.isFaceUp = false
            let card = cards.remove(at: cards.count.arc4random)
            cardView.rank = card.rank.order
            cardView.suit = card.suit.rawValue
            cardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(flipCard(_:))))
            cardBehavior.addItem(cardView)
        }
    }
    
    private var faceUpCardViews: [PlayingCardView] {
        return cardViews.filter {
            $0.isFaceUp &&
                !$0.isHidden &&
                $0.transform != CGAffineTransform.identity.scaledBy(x: cardMatchedSize, y: cardMatchedSize) &&
                $0.alpha == 1
            
        }
    }
    
    var lastChosenCardView: PlayingCardView?
    
    private var faceUpCardViewsMatch:Bool {
        return faceUpCardViews.count == 2 &&
            faceUpCardViews[0].rank == faceUpCardViews[1].rank &&
            faceUpCardViews[0].suit == faceUpCardViews[1].suit
    }
    
    @objc func flipCard (_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            if let chosenCardView = recognizer.view as? PlayingCardView, faceUpCardViews.count < 2 {
                lastChosenCardView = chosenCardView
                cardBehavior.removeItem(chosenCardView)
                UIView.transition(
                    with: chosenCardView,
                    duration: cardFlipAnimationTime,
                    options: [.transitionFlipFromLeft],
                    animations: {
                        chosenCardView.isFaceUp = !chosenCardView.isFaceUp
                },
                    completion: {finished in
                        let cardsToAnimate = self.faceUpCardViews
                        if self.faceUpCardViewsMatch {
                            UIViewPropertyAnimator.runningPropertyAnimator(
                                withDuration: self.cardScaleAnimationTime,
                                delay: 0,
                                options: [],
                                animations: {
                                    cardsToAnimate.forEach {
                                        $0.transform = CGAffineTransform.identity.scaledBy(x: self.cardMatchedSize, y: self.cardMatchedSize)
                                    }
                            },
                                completion: {position in
                                    UIViewPropertyAnimator.runningPropertyAnimator(
                                        withDuration: 1.5*(self.cardScaleAnimationTime),
                                        delay: 0,
                                        options: [],
                                        animations: {
                                            cardsToAnimate.forEach {
                                                $0.transform = CGAffineTransform.identity.scaledBy(x: (self.cardMatchedSize)/10, y: (self.cardMatchedSize)/10)
                                                $0.alpha = 0
                                            }
                                    },
                                        completion: { position in
                                            cardsToAnimate.forEach {
                                                $0.isHidden = true
                                                $0.alpha = 1
                                                $0.transform = .identity
                                            }
                                    }
                                    )
                            }
                            )
                        } else if cardsToAnimate.count == 2 {
                            if chosenCardView == self.lastChosenCardView {
                                cardsToAnimate.forEach {cardView in
                                    UIView.transition (
                                        with: cardView,
                                        duration: 0.3,
                                        options: [.transitionFlipFromLeft],
                                        animations: {
                                            cardView.isFaceUp = false
                                    },
                                        completion: { finished in
                                            self.cardBehavior.addItem(cardView)
                                    }
                                    )
                                }
                            }
                        } else {
                            if !chosenCardView.isFaceUp {
                                self.cardBehavior.addItem(chosenCardView)
                            }
                        }
                }
                )
                
            }
        default: break
        }
    }
}

extension CGFloat {
    var arc4random:CGFloat {
        if self > 0 {
            return CGFloat(arc4random_uniform(UInt32(101)))/100*self
        } else if self < 0 {
            return -CGFloat(arc4random_uniform(UInt32(101)))/100*self
        } else {
            return 0
        }
    }
}
