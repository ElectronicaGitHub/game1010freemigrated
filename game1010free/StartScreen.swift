import Foundation
import UIKit
import AVFoundation

var startScreenWrapper : UIView = UIView()

class StartScreen {
    var view : UIView
    var _self : UIViewController
    var uh : NSDictionary
//    var audioPlayer : AVAudioPlayer
    var audioPlayer: AVAudioPlayer?
    init(view : UIView, _self : UIViewController) {
        self.uh = userHighscores as! NSDictionary
        self.view = view
        self._self = _self
    }
    func startScreenInit() {
        let file = NSURL(fileURLWithPath: Bundle.main.path(forResource: "sounds/menuloop4", ofType: "wav")!)
//        if audioPlayer = try? AVAudioPlayer(contentsOfURL: file as URL) as! AVAudioPlayer {
        if let ap = try? AVAudioPlayer(contentsOf: file as URL) {
            
            audioPlayer = ap

            audioPlayer!.prepareToPlay()
            audioPlayer!.volume = 0.1
            audioPlayer!.numberOfLoops = -1
            audioPlayer!.play()
        }
        
        let rank = uh["rank"] as! Int
        let score = uh["score"] as! Int
        
        startScreenWrapper = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        startScreenWrapper.backgroundColor = UIColor.white
        
        view.addSubview(startScreenWrapper)
        
        let startScreenView = UIView(frame: CGRect(x: 0, y: 0, width: 200 * menuCoefficient, height: 360 * menuCoefficient))
        startScreenView.center = CGPoint(x: view.center.x, y: view.center.y)
        startScreenView.backgroundColor = UIColor(rgb: 0xFFFFFF)

        let logo = UIImageView(frame: CGRect(x: 0, y: 0, width: startScreenView.frame.width, height: 40 * menuCoefficient))
        let img = UIImage(named: "/block2blocklogoblack.png")
        logo.frame.size.width = startScreenView.frame.width
        logo.center.x = startScreenView.frame.width/2
        logo.contentMode = UIView.ContentMode.scaleAspectFit
        logo.image = img
        startScreenView.addSubview(logo)
        
        ranklabel = UILabel(frame: CGRect(x: 0, y: 0, width: startScreenView.frame.width, height: 30 * menuCoefficient))
        ranklabel.text = "Your rank"
        ranklabel.frame.origin.y = 50 * menuCoefficient
        ranklabel.textAlignment = NSTextAlignment.center
        ranklabel.font = UIFont(name: "HelveticaNeue-CondensedBlack", size: 20 * menuCoefficient)
        startScreenView.addSubview(ranklabel)
        
        let rp = UIImageView(frame: CGRect(x: 0, y: 0, width: 110 * menuCoefficient, height: 110 * menuCoefficient))
        rp.center = CGPoint(x: startScreenView.frame.width/2, y: 140 * menuCoefficient)
        
        let image_to_crop = UIImage(named: "ranks.png")?.cgImage
        let cropping_rect = CGRect(x: 220 * rank, y: 0, width: 220, height: 220)
        let image = image_to_crop?.cropping(to: cropping_rect)
//        var image = CGImageCreateWithImageInRect(UIImage(named: "ranks.png").CGImage!, CGRect(x: 220 * rank, y: 0, width: 220, height: 220))
        rp.image = UIImage(cgImage: image!)
        startScreenView.addSubview(rp)
        
        let rn = UILabel(frame: CGRect(x: 0, y: 0, width: startScreenView.frame.width, height: 30 * menuCoefficient))
        rn.text = Ranks[rank][1] as? String
        rn.frame.origin.y = 200 * menuCoefficient
        rn.textAlignment = NSTextAlignment.center
        rn.font = UIFont(name: "HelveticaNeue-CondensedBlack", size: 20 * menuCoefficient)
        startScreenView.addSubview(rn)
        
        let rectStrip = UIView(frame: CGRect(x: 0, y: 0, width: 150, height: 2 * menuCoefficient))
        rectStrip.center = CGPoint(x: startScreenView.frame.width/2, y: 0)
        rectStrip.backgroundColor = UIColor(rgb: 0xd5d5d5)
        rectStrip.frame.origin.y =  235 * menuCoefficient
        startScreenView.addSubview(rectStrip)
        
        let scoreLabel = UILabel(frame: CGRect(x: 0, y: 0, width: startScreenView.frame.width, height: 30 * menuCoefficient))
        scoreLabel.frame.origin.y = 245 * menuCoefficient
        scoreLabel.font = UIFont(name: "HelveticaNeue-CondensedBlack", size: 20 * menuCoefficient)
        scoreLabel.text = "Top Score"
        scoreLabel.textAlignment = NSTextAlignment.center
        startScreenView.addSubview(scoreLabel)
        
        let scoreNumber = UILabel(frame: CGRect(x: 0, y: 0, width: startScreenView.frame.width, height: 40 * menuCoefficient))
        scoreNumber.text = String(score)
        scoreNumber.frame.origin.y = 275 * menuCoefficient
        scoreNumber.textAlignment = NSTextAlignment.center
        scoreNumber.font = UIFont(name: "HelveticaNeue-CondensedBlack", size: 40 * menuCoefficient)
        startScreenView.addSubview(scoreNumber)
        
        // добавляем кнопку
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: startScreenView.frame.width, height: 40 * menuCoefficient))
        button.backgroundColor = UIColor(rgb: 0x29ABE2)
        button.setTitle("PLAY", for: UIControl.State.normal)
        button.titleLabel!.font = UIFont(name: "HelveticaNeue-CondensedBlack", size: 20 * menuCoefficient)
        button.addTarget(_self, action: #selector(ViewController.startGame), for: UIControl.Event.touchUpInside)
        button.frame.origin.y = 320 * menuCoefficient
        startScreenView.addSubview(button)
        
        startScreenWrapper.addSubview(startScreenView)
    }
    
    func hideStartScreen() {
        audioPlayer!.stop()
        UIView.animate(withDuration: 0.5, animations: {
            startScreenWrapper.frame.origin.y = -1000 * menuCoefficient
            }, completion: {
                _ in
        })
    }
    
}
