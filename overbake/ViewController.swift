//
//  ViewController.swift
//  overbake
//
//  Created by Yi-Ning Huang on 10/21/18.
//  Copyright © 2018 Yi-Ning Huang. All rights reserved.
//

import UIKit
import ReactiveSwift
import ReactiveCocoa
import Result

enum GameState {
    case none
    case inProgress
    case over
}

final class GameViewModel {
    let nextGameStateAction: Action<GameState, GameState, NoError>
    let setTimeAction: Action<(), Date, NoError>
    
    var gameStateLabelText: MutableProperty<String>
    var gameStartButtonText: MutableProperty<String>
    var timerLabelText: MutableProperty<String>
    var pizzaStatusText: MutableProperty<String>
    var pizzaColor: MutableProperty<UIColor>
    
    var status: GameState
    var startTime: Date

    init() {
        gameStateLabelText = MutableProperty<String>("")
        gameStartButtonText = MutableProperty<String>("Start")
        timerLabelText = MutableProperty<String>("0")
        pizzaStatusText  = MutableProperty<String>("")
        pizzaColor = MutableProperty<UIColor>(UIColor(red: 1, green: 0.9373, blue: 0.8471, alpha: 1.0))
        status = .none
        startTime = Date()

        let timerSignalProducer: () -> SignalProducer<Date, NoError> = {
            return SignalProducer.timer(interval: DispatchTimeInterval.seconds(1), on: QueueScheduler.main)
        }
        setTimeAction = Action<(), Date, NoError>(execute: timerSignalProducer)
        
        let nextGameStateSignalProducer: (GameState) -> SignalProducer<GameState, NoError>  = { status in
            return SignalProducer<GameState, NoError> { (observer, lifetime) in
                switch status {
                case .none:
                    observer.send(value: GameState.inProgress)
                    observer.sendCompleted()
                case .inProgress:
                    observer.send(value: GameState.over)
                    observer.sendCompleted()
                case .over:
                    observer.send(value: GameState.inProgress)
                    observer.sendCompleted()
                }
            }
        }
        nextGameStateAction = Action<GameState, GameState, NoError>(execute: nextGameStateSignalProducer)
        
        // set observe values
        setTimeAction.values.observeValues { (date) in
            if self.status == .inProgress {
                let interval = Int(date.timeIntervalSince(self.startTime))
                self.timerLabelText.value = String(interval)
                if interval <= 3 {
                    self.pizzaStatusText.value = "No cooked...😑"
                } else if interval <= 6 {
                    self.pizzaColor.value = UIColor(red: 1, green: 0.8627, blue: 0.6588, alpha: 1.0)
                } else if interval < 9 {
                    self.pizzaStatusText.value = "About right!🤤"
                    self.pizzaColor.value = UIColor(red: 0.9176, green: 0.6275, blue: 0.2745, alpha: 1.0)
                } else if interval < 12 {
                    self.pizzaStatusText.value = "Crispy!😎"
                    self.pizzaColor.value = UIColor(red: 0.7098, green: 0.5294, blue: 0, alpha: 1.0)
                } else {
                    self.pizzaStatusText.value = "OVERBAKED!...🤮"
                    self.pizzaColor.value = UIColor(red: 0.5294, green: 0.3216, blue: 0.0353, alpha: 1.0)
                }
                
                if interval == 30 {
                    self.nextGameStateAction.apply(self.status).start()
                }
            }
        }
        
        nextGameStateAction.values.observeValues { value in
            switch value {
            case .none:
                self.gameStartButtonText.value = "Start Baking!"
                self.gameStateLabelText.value = ""
            case .inProgress:
                self.setTimeAction.apply().start()
                self.pizzaColor.value = UIColor(red: 1, green: 0.8627, blue: 0.6588, alpha: 1.0)
                self.startTime = Date()
                
                self.gameStartButtonText.value = "Stop Baking"
                self.gameStateLabelText.value = "Baking in progress..."
                
            case .over:
                self.gameStartButtonText.value = "Start Baking"
                self.gameStateLabelText.value = self.pizzaStatusText.value
            }
            self.status = value
        }
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var pizzaStatus: UILabel!
    @IBOutlet weak var gameStartButton: UIButton!
    @IBOutlet weak var pizzaImage: UIImageView!
    
    let vm = GameViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        instructionLabel.reactive.text <~ vm.gameStateLabelText
        gameStartButton.reactive.title <~ vm.gameStartButtonText
        pizzaStatus.reactive.text <~ vm.pizzaStatusText
        pizzaStatus.isHidden = true
        //timerLabel.reactive.text <~ vm.timerLabelText
        timerLabel.isHidden = true
        let tintedImage = pizzaImage?.image!.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        pizzaImage.image = tintedImage
        pizzaImage.reactive.tintColor <~ vm.pizzaColor
        
    }

    @IBAction func tapStartButton(_ sender: Any) {
        vm.nextGameStateAction.apply(vm.status).start()
        
    }
}
