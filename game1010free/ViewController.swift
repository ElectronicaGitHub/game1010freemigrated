import UIKit
import iAd
import AVFoundation

var padding : CGFloat = 2;
var block_size : CGFloat = 28;
let map_size = 10;
//var blurView : UIVisualEffectView?
//var blurView : UIView? = UIView()
var gameView : UIView?
var lastShowedRank = UIView()
var menu : Menu?
var udKey = "b2bhighscores"
var userHighscores : AnyObject?
var maxScore : Int? = Int()
var highScoreReached : Bool = false
var menuCoefficient : CGFloat = 1 // for 568
var audioPlayer = AVAudioPlayer()
var comboCounter = 0

var bounds : CGRect = CGRect()

class ViewController: UIViewController, ADBannerViewDelegate {
    
    @IBOutlet weak var adBanner: ADBannerView!
    
    let defaultColor = UIColor(rgb: 0xEEEEEE)
    var rectanglesArray = [Rectangle]()
    var figuresArray = [Figure]()
    let afterTouchYOffset : CGFloat = 70
    var score = 0
    var round_score = 0
    var score_multiplier = 0
    var pointsLabel : UILabel = UILabel()
    var figures_for_test_inited : figures_for_test = figures_for_test()
    // DIMENSIONS
    var rectsHeight = 50
    var figuresHeight = 435
    var rectsForDissapear = Array<Dictionary<String,Any>>()
    var clearNumbers = Array<Int>()
    var figureEndCoords : CGPoint = CGPoint()
    var rank = -1
    var maxRank = Ranks.count - 1
    var rankView = UIView()
    // устранение смещения после увеличения фигуры до нормального размера
    var afterTouchSizeOffset : CGFloat = 25
    
    var startScreen : StartScreen?
    
    func GetFiguresScaling(size:CGFloat, padding:CGFloat) -> CGFloat {
        return (300/3) / (    (size + padding) * 5);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bounds = UIScreen.main.bounds
        
        menuCoefficient = bounds.height / 568
//        println(bounds)
//        println(menuCoefficient)
        if bounds.height == 480 {
            block_size = 25
            figuresHeight = 380
            afterTouchSizeOffset = 23
        } else if bounds.height == 667 {
            block_size = 33
            padding = 3
            figuresHeight = 520
            afterTouchSizeOffset = 28
        } else if bounds.height == 736 {
            block_size = 36
            padding = 4
            figuresHeight = 570
            afterTouchSizeOffset = 33
        } else if bounds.height == 1024 {
            block_size = 55
            padding = 6
            rectsHeight = 100
            figuresHeight = 830
            afterTouchSizeOffset = 50
        }
        
        let ud = UserDefaults.standard
        if let i : Any = ud.object(forKey: udKey) {
            userHighscores = i as! NSDictionary
            maxScore = userHighscores!["score"] as? Int
        } else {
            let default_settings = [
                "score" : 0,
                "rank" : 0
            ]
            ud.set(default_settings, forKey: udKey)
            userHighscores = default_settings as AnyObject
            maxScore = nil
            highScoreReached = true
        }
        
        // init menu classes
        menu = Menu(view: view, _self: self)
        startScreen = StartScreen(view: view, _self: self)
        
        // НАПОЛНЯЕМ МАССИВ СВОБОДНЫХ ЭЛЕМЕНТОВ
        
        for i in 0...99 {
            clearNumbers.append(i)
        }
        
        // GAME VIEW INIT
        
        gameView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        view.addSubview(gameView!)
        
//        var blur = UIBlurEffect(style: UIBlurEffectStyle.Light)
//        blurView = UIVisualEffectView(effect: blur)
//        blurView?.backgroundColor = UIColor.blackColor()
//        blurView?.alpha = 0.4


        
        // MENU ADD
//        menuInit(view, self)
        menu!.menuInit()
        startScreen!.startScreenInit()
//        menu!.showMenu(score, rank:rank)
        
        
        // LOAD IAD HIDDEN
        
        self.canDisplayBannerAds = true
        self.adBanner.delegate = self
        self.adBanner.isHidden = true

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // для координат внутри фигуры и других обработок
    var selectedFigure : Figure?
    var startTouchCoords : CGPoint = CGPoint()
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if selectedFigure == nil {
            // TOUCH START
            let touch = touches[touches.startIndex]
//            let touch = touches.allObjects[0] as UITouch
            // detect element type
            let viewCoords = touch.location(in: view)
            //ищем в FIGURES и находим нужный RECT
            for j in figuresArray {
                let i = j.figureView.frame
                if viewCoords.x >= i.origin.x  && viewCoords.x <= i.origin.x + i.width &&
                    viewCoords.y >= i.origin.y && viewCoords.y <= i.origin.y + i.height {
                        selectedFigure = j
                        selectedFigure!.start_x = selectedFigure!.figureView.frame.origin.x
                        selectedFigure!.start_y = selectedFigure!.figureView.frame.origin.y
                        
    //                    let file = "grab" + String(random() % 9 + 1)
    //                    let file = "grab1"
    //                    playSound(file)
                }
            }
            startTouchCoords = touch.location(in: view)
            
            if selectedFigure != nil {
                // НЕМНОГО ПОДНИМАЕМ ФИГУРУ ДЛЯ УДОБСТВА
                UIView.animate(withDuration : 0.1, animations: {
                    self.selectedFigure!.figureView.transform = CGAffineTransform.identity
                    self.selectedFigure!.figureView.frame.origin.y -= self.afterTouchYOffset
    //                self.selectedFigure!.figureView.frame.origin.x += 25
                    
                })
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        // TOUCH MOVE
        let touch = touches[touches.startIndex]
        
        if (touch.view != self.view && selectedFigure != nil ) {
            let coords = touch.location(in: self.view) as CGPoint
            
            let dx = coords.x - startTouchCoords.x as CGFloat
            let dy = coords.y - startTouchCoords.y as CGFloat
            
            selectedFigure!.figureView.frame.origin.x = selectedFigure!.start_x + dx - afterTouchSizeOffset
            selectedFigure!.figureView.frame.origin.y = selectedFigure!.start_y + dy - afterTouchYOffset - afterTouchSizeOffset
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // TOUCH ENDED
        
        var modified = 0
        var rectArr : [Int] = [Int]()
        var figArr : [Int] = [Int]()
        
        if selectedFigure != nil {
            // ОБРАБОТКА ФИГУРЫ
            let figurePos : CGPoint = CGPoint(x: selectedFigure!.figureView.frame.origin.x, y: selectedFigure!.figureView.frame.origin.y)
//            for var i=0; i < selectedFigure!.figure.count; i++ {
            for i in 0..<selectedFigure!.figure.count {
//                for var j=0; j < rectanglesArray.count; j++ {
                for j in 0..<rectanglesArray.count {
                    if selectedFigure!.figure[i].inner_x + figurePos.x + selectedFigure!.figure[i].size/2 >= rectanglesArray[j].outer_x &&
                        selectedFigure!.figure[i].inner_x + figurePos.x + selectedFigure!.figure[i].size/2 <= rectanglesArray[j].outer_x + rectanglesArray[j].size &&
                        selectedFigure!.figure[i].inner_y + figurePos.y + selectedFigure!.figure[i].size/2 >= rectanglesArray[j].outer_y &&
                        selectedFigure!.figure[i].inner_y + figurePos.y + selectedFigure!.figure[i].size/2 <= rectanglesArray[j].outer_y + rectanglesArray[j].size &&
                        rectanglesArray[j].type == "default"
                    {
                            modified += 1
                            rectArr.append(j)
                            figArr.append(i)
                        
//                        if let q = clearNumbers.first(where:{$0 == j}) {
                        if let q = clearNumbers.firstIndex(of: j) {
//                        if let q = clearNumbers.indexOf(j) {
//                            print("q", q)
//                            print("clearNumbers", clearNumbers.count, clearNumbers)
                            clearNumbers.remove(at: q)
                        }
//                        if let q = find(clearNumbers, j) {
//                            clearNumbers.removeAtIndex(q)
//                        }
                    }
                }
            }
            
            if modified == selectedFigure?.figure.count {
                // ФИГУРА ПОПАЛА

                let localSF = selectedFigure
                selectedFigure = nil
                figureEndCoords = localSF!.figureView.center
                
                // добавляем фигуры из view фигуры в главный view на тех же глобальных координатах
                for i in localSF!.figure {
                    i.box.frame.origin.x = localSF!.figureView.frame.origin.x + i.inner_x
                    i.box.frame.origin.y = localSF!.figureView.frame.origin.y + i.inner_y
                    view.addSubview(i.box)
                }
                localSF!.figureView.removeFromSuperview()
                
                UIView.animateKeyframes(withDuration: 0.1, delay: 0, options: [], animations: {
//                    for var i=0; i < rectArr.count; i++ {
                    for i in 0..<rectArr.count {
                        self.rectanglesArray[rectArr[i]].type = "modified"
                        localSF!.figure[figArr[i]].box.frame.origin.x = self.rectanglesArray[rectArr[i]].outer_x
                        localSF!.figure[figArr[i]].box.frame.origin.y = self.rectanglesArray[rectArr[i]].outer_y
                    }
                    }, completion: { _ in
//                        for var i=0; i < rectArr.count; i++ {
                        for i in 0..<rectArr.count {
                            if localSF != nil {
                                self.rectanglesArray[rectArr[i]].color = localSF!.figure[figArr[i]].color
                                self.rectanglesArray[rectArr[i]].box.backgroundColor = localSF!.figure[figArr[i]].color
                                localSF!.figure[figArr[i]].box.removeFromSuperview()
                                self.round_score+=1
                            }
                        }
                        
                        for (index, i) in self.figuresArray.enumerated() {
                            if i === localSF {
                                self.figuresArray.remove(at: index)
                                // ПРОВЕРЯЕМ ЕСЛИ ФИГУР НЕ ОСТАЛОСЬ ТО СОЗДАЕМ НОВЫЕ ФИГУРЫ
                                if self.figuresArray.count == 0 {
                                    self.generateFigures()
                                }
                            }
                        }
                        self.breakLines(blocks: rectArr)
                        
                        var game_ended = true
                        
                        for i in self.figuresArray {
                            let res = self.tryFigureOnMap(figure: i)
                            if res == true {
                                game_ended = false
                                break
                            }
                        }
                        
                        if game_ended == true {
//                            println("игра закончена нахуй")
                            
                            if self.score > maxScore! {
                                let data : NSDictionary = [
                                    "score" : self.score,
                                    "rank" : self.rank
                                ]
                                UserDefaults.standard.set(data, forKey: udKey)
                                maxScore = self.score
                            }
                            
                            for i in self.figuresArray {
                                i.figureView.removeFromSuperview()
                            }
                            menu!.showMenu(score: self.score, rank: self.rank)
                            self.endGame()
                        }
                        
//                        self.selectedFigure = nil
                        rectArr.removeAll(keepingCapacity: true)
                        figArr.removeAll(keepingCapacity: true)

                })
                
            } else {
                // ФИГУРА НЕ ПОПАЛА И ВОЗРВРАЩАЕТСЯ НА ПРЕЖНЕЕ МЕСТО
                
//                let file = "baddrop" + String(random() % 3 + 1)
                let file = "baddrop3"
                playSound(file: file, volume: 0.02)
                
                let figuresScaling = GetFiguresScaling(size: block_size, padding: padding);
                
                UIView.animateKeyframes(withDuration: 0.2, delay: 0, options: [], animations: {
                    self.selectedFigure!.figureView.transform = CGAffineTransform(scaleX: figuresScaling, y: figuresScaling)
                    self.selectedFigure!.figureView.frame.origin.x = self.selectedFigure!.start_x
                    self.selectedFigure!.figureView.frame.origin.y = self.selectedFigure!.start_y
                }, completion: nil)
                selectedFigure = nil
            }
        }
    }
    
    func breakLines(blocks : [Int]) {
//        var date = NSDate()
        var rows : [Int] = [Int](),
            cols : [Int] = [Int]()
        
        for (_, a) in blocks.enumerated() {
            let row = Int(floor(Float(a)/Float(map_size))),
                col = a%map_size
            var has_col = false,
                has_row = false
            for i in rows {
                if i == row { has_row = true }
            }
            for k in cols {
                if k == col { has_col = true }
            }
            if has_row == false { rows.append(row) }
            if has_col == false { cols.append(col) }
        }
        for r in rows {
            var row_full = true
//            for var i = 0; i < map_size; i++ {
            for i in 0..<map_size {
                let n = r * map_size + i;
                if (rectanglesArray[n].type == "default") {
                    row_full = false;
                }
            }
            if row_full == true {
//                for var j = 0; j < map_size; j++ {
                for j in 0..<map_size {
                    rectsForDissapear.append([
                        "n" : Int(r * map_size + j),
                        "element" : "row"
                    ])
                }
                score_multiplier+=1;
            }
        }
        for c in cols {
            var col_full = true;
//            for var i = 0; i < map_size; i++ {
            for i in 0..<map_size {
                let n = i * map_size + c;
                if (rectanglesArray[n].type == "default") {
                    col_full = false;
                }
            }
            if col_full == true {
//                for var j = 0; j < map_size; j++ {
                for j in 0..<map_size {
                    rectsForDissapear.append([
                        "n" : Int(j * map_size + c),
                        "element" : "col"
                    ])
                    
                }
                score_multiplier+=1;
            }   
        }
        
        if rectsForDissapear.isEmpty == false {
            comboCounter = comboCounter >= 7 ? comboCounter : comboCounter + 1
            let file = "linep" + String(comboCounter)
            
            playSound(file: file, volume : 0.3)
        } else {
            
            playSound(file: "asmr1", volume : 0.5)
            comboCounter = 0
        }
        
        for i in rectsForDissapear {
            let n = i["n"] as! Int
            let elem = i["element"] as! String
            dissapearing(j: n, element: elem)
            
            if clearNumbers.contains(n) {
            } else {
                clearNumbers.append(n)
            }
        }
        rectsForDissapear = []
        
        if score_multiplier != 0 {
            let finalRS = (round_score * score_multiplier) + ((score_multiplier * 10) + ((score_multiplier-1) * 10)) * comboCounter
            showRoundScore(score: finalRS, position: figureEndCoords)
            score = score + finalRS
        } else {
            showRoundScore(score: round_score, position: figureEndCoords)
            score = score + round_score
        }
        
        // HIGHSCORE ПРОВЕРКА
        
        if highScoreReached == false {
            if score > maxScore! {
                newHighscore()
                highScoreReached = true
            }
        }
        
        showRank(score: score)
        setScore(score: score)
        round_score = 0
        score_multiplier = 0
        
//        var endDate = NSDate()
//        var exec_time = endDate.timeIntervalSinceDate(date)
//        println("breakLines \(exec_time)")
    }
    
    func dissapearing(j : Int, element : String) {
        
        var stTime : Float = Float()
        if element == "row" {
//            stTime = ( (Float(j) % Float(map_size) ) + 1) * 0.02;
            stTime = ( (Float(j).truncatingRemainder(dividingBy: Float(map_size))) + 1) * 0.02;
        }
        else if element == "col" {
            stTime = (floor(Float(j)/Float(map_size) ) + 1) * 0.02
        }
        
        let delay : TimeInterval = TimeInterval(stTime)
        
        UIView.animateKeyframes(withDuration: 0.3, delay: delay, options: [], animations: {
            if self.rectanglesArray.isEmpty == false {
                if let b = self.rectanglesArray[j] as Rectangle? {
                    b.type = "default"
                    b.box.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    b.box.backgroundColor = self.defaultColor
                }
            }
            }, completion: {
                _ in
                if self.rectanglesArray.isEmpty == false {
                    if let b = self.rectanglesArray[j] as Rectangle? {
                        b.box.transform = CGAffineTransform.identity
                        b.color = self.defaultColor
                        b.box.backgroundColor = self.defaultColor
                    }
                }
        })
    }
    
    func generateFigures() {
//        var date = NSDate()
        let figuresPositions : [CGFloat] = [view.frame.width/6, view.frame.width/2, view.frame.width*5/6]
//        for var i = 0; i < 3; i++ {
        for i in 0..<3 {
            let cnt = UInt32(figures_map.maps.count)
            let figNumber = Int(arc4random_uniform(cnt))
            let figureView = UIView(frame: CGRect(x: 0, y: 0, width: (block_size + padding) * 5, height: (block_size + padding) * 5))
            let fig = Figure(map: figures_map.maps[figNumber]["map"] as! [NSDictionary],
                             color: figures_map.maps[figNumber]["color"] as! UIColor,
                             view : gameView!,
                             figure_view : figureView,
                             x: figuresPositions[i],
                             w: figures_map.maps[figNumber]["w"] as! Int,
                             h: figures_map.maps[figNumber]["h"] as! Int,
                             type: figures_map.maps[figNumber]["type"] as! String,
                             start_w_offset : figures_map.maps[figNumber]["start_w"] as? Int
            )
//            figureView.center = CGPoint(x: figuresPositions[i], y: CGFloat(figuresHeight))
            figureView.center = CGPoint(x: figuresPositions[i], y: CGFloat(figuresHeight + 500))
            view.addSubview(figureView)
            for i in fig.figure {
                figureView.addSubview(i.box)
            }
            let figuresScaling = GetFiguresScaling(size: block_size, padding: padding);
            figureView.transform = CGAffineTransform(scaleX: figuresScaling, y: figuresScaling)
            
            figuresArray.append(fig)
            
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [], animations: {
                for (index,i) in self.figuresArray.enumerated() {
                    i.figureView.center = CGPoint(x: figuresPositions[index], y: CGFloat(self.figuresHeight))

                }
                }, completion: nil)
        }
    }
    
    func setScore(score : Int) {
        pointsLabel.text = String(score)
        UIView.animate(withDuration: 0.1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [], animations: {
            self.pointsLabel.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            self.pointsLabel.frame.origin.x -= 15
            }, completion: { _ in
                UIView.animate(withDuration: 0.1, animations: {
                    self.pointsLabel.transform = CGAffineTransform.identity
                    self.pointsLabel.frame.origin.x += 15
                })
        })
    }
    
    
    // FOR TESTS
//    var last_rects = Array<UIView>()
    
    func tryFigureOnMap(figure : Figure) -> Bool {
//        var date = NSDate()
        let rect_map = figures_for_test_inited.maps[figure.type]!
        let except_first_element_width = figure.w
        let start_width_offset = figure.start_w_offset == nil ? 0 : figure.start_w_offset
        let except_first_element_height = figure.h
//        var rect_figures = Array<Array<Int>>()
//        var rect_offsets = Array<Array<Int>>()
        var num = Int()
//        var direction : Bool = except_first_element_width > except_first_element_height
        
//        for var c = 0; c < map_size; c++ {
        for c in 0..<map_size {
//            for var r = 0; r < map_size; r++ {
            for r in 0..<map_size {
                num = c * map_size + r
                
                if rectanglesArray[num].type == "default" {
                    var counter = 0
                    var array_helpers = Array<Int>()
                    
                    if (
                        r < (map_size - except_first_element_width) &&
                        c < (map_size - except_first_element_height) &&
                        (r >= start_width_offset!)
                    ) {
                        for (_, i) in rect_map.enumerated() {
                            
                            let need_num = num + i
//                            println("фигура образуется из \(need_num) в точке \(num)")
                            
//                            if let q = find(clearNumbers, need_num) {
                            if (clearNumbers.contains(need_num)) {
                                counter+=1
                                array_helpers.append(need_num)
                            } else {
//                                println("для квадрата  \(need_num) нет ячейки в списке свободных квадратов")
                                break
                            }
                        }
//                        println("========")
                        if counter == rect_map.count {
//                            var endDate = NSDate()
//                            var exec_time = endDate.timeIntervalSinceDate(date)
//                            println("tryFiguresOnMap \(exec_time)")
                            
                            // tests
//                            for i in last_rects {
//                                i.removeFromSuperview()
//                            }
//                            last_rects = []
//                            for i in array_helpers {
//                                let rect = rectanglesArray[i]
//                                var q : UIView = UIView(frame: CGRect(x: rect.outer_x, y: rect.outer_y, width: rect.size, height: rect.size))
//                                q.backgroundColor = UIColor.blueColor()
//                                q.alpha = 0.1
//                                view.addSubview(q)
//                                last_rects.append(q)
//                            }
                            //
                            return true
                        }
                    }
                }
            }
        }
        return false
    }
    
    @objc func startGame() {
        
        menu!.hideMenu()
        startScreen!.hideStartScreen()
        // POINTS LABEL
        
        pointsLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        
        if bounds.height == 1024 {
            pointsLabel.frame.origin.x = view.frame.width - 200
            pointsLabel.frame.origin.y = 25
            pointsLabel.font = UIFont(name: "HelveticaNeue-CondensedBlack", size: 35)
        } else {
            pointsLabel.frame.origin.x = view.frame.width - 110
            pointsLabel.frame.origin.y = 0
            pointsLabel.font = UIFont(name: "HelveticaNeue-CondensedBlack", size: 20)
        }
        pointsLabel.textAlignment = NSTextAlignment.right
        
        pointsLabel.text = String(0)
        gameView!.addSubview(pointsLabel)
        
        // GENERATING MAP
        for i in 1...map_size {
            for j in 1...map_size {
                let _x = (view.frame.width - CGFloat(map_size) * (CGFloat(block_size) + CGFloat(padding)))/2 + CGFloat(j-1) * (block_size + padding)
                let _y = CGFloat(rectsHeight) + CGFloat(i-1) * (block_size + padding)
                let r = Rectangle(type: "default", x: _x, y: _y, size: block_size, color: defaultColor, view: gameView!,real_x : _x, real_y : _y)
                rectanglesArray.append(r)
            }
        }
        
        // GENERATE FIGURE
        generateFigures()
        
        showRank(score: 0)
    }
    
    func endGame() {
        
//        let file = "end" + String(random() % 3 + 1)
        let file = "end" + String(arc4random() % 3 + 1)
        playSound(file: file, volume : 0.03)
        
        for i in gameView!.subviews {
            i.removeFromSuperview()
        }
//        blurView!.frame = CGRect(x: 0, y: 0, width: gameView!.frame.width, height: gameView!.frame.height)
//        blurView!.backgroundColor = UIColor.blackColor()
//        gameView!.addSubview(blurView!)
        
        figuresArray = []
        rectanglesArray = []
        score = 0
        round_score = 0
        clearNumbers = []
        for i in 0...99 {
            clearNumbers.append(i)
        }
        rank = -1
        highScoreReached = false
    }
    
    func showRank(score : Int) {
        
        var showNewRank = false
        let x_offset = 220
        
//        for var i = 0; i < Ranks.count - 1; i++ {
        for i in 0..<Ranks.count - 1 {
            let this = Ranks[i][0] as! Int
            let next = Ranks[i+1][0] as! Int
            if (score >= this) && (score < next) {
                if rank != i {
                    showNewRank = true
                    rank+=1
                    break
                }
            }
        }
        
        if showNewRank {
            
            // set sizes
            var rankPositionX : CGFloat
            var rankPositionY : CGFloat
            var rankFontSize : CGFloat
            var rankViewHeight : CGFloat
            var rankImgSize : CGFloat
            
            if bounds.height == 1024 {
                rankPositionX = 75
                rankPositionY = 35
                rankFontSize = 30
                rankViewHeight = 45
                rankImgSize = 35
            } else {
                rankPositionX = 10
                rankPositionY = 10
                rankFontSize = 20
                rankViewHeight = 35
                rankImgSize = 25
            }
            
            //
            
//            let str = Ranks[rank][1] as? String
//            let str_l = str!.count
//            let rs = 40 + str_l * 10
            
            rankView = UIView(frame: CGRect(x: rankPositionX, y: -60, width: 0, height: rankViewHeight))
            rankView.backgroundColor = UIColor(rgb: 0xFFFFFF)
            rankView.layer.cornerRadius = 4
            rankView.layer.borderWidth = 1
            rankView.layer.borderColor = UIColor(rgb: 0xd5d5d5).cgColor
            rankView.clipsToBounds = true
            
            view.addSubview(rankView)
            let iv = UIImageView(frame: CGRect(x: 0, y: 0, width: rankImgSize, height: rankImgSize))
            iv.center = CGPoint(x: rankViewHeight/2, y: rankView.frame.height/2)
            let image_to_crop = UIImage(named: "ranks.png")?.cgImage
            let cropping_rect = CGRect(x: x_offset * rank, y: 0, width: 220, height: 220)
            let viewpic = image_to_crop?.cropping(to: cropping_rect)
//            var viewpic = CGImageCreateWithImageInRect(UIImage(named: "ranks.png").CGImage, CGRect(x: x_offset * rank, y: 0, width: 220, height: 220))
            iv.image = UIImage(cgImage: viewpic!)
            rankView.addSubview(iv)
            
            let label = UILabel(frame: CGRect(x: rankViewHeight, y: 0, width: 0, height: 35))
            label.text = Ranks[rank][1] as? String
            label.font = UIFont(name: "HelveticaNeue-CondensedBlack", size: rankFontSize)
            let rect = label.attributedText?.boundingRect(with: CGSize(width: 9999, height: 35), options: .usesLineFragmentOrigin, context: nil)
            label.center.y = rankView.frame.height/2
            label.frame.size.width = rect!.size.width
            rankView.addSubview(label)
            
            let finalSize = label.frame.width + rankViewHeight + 5
            
            rankView.frame.size.width = finalSize
            
            UIView.animate(withDuration: 0.3, delay: 0.3, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: [], animations: {
                    self.rankView.frame.origin.y = rankPositionY
                
                }, completion: { _ in
                    
            })
            UIView.animateKeyframes(withDuration: 0.3, delay: 0, options: [], animations: {
                lastShowedRank.frame.origin.x = -200
                }, completion: {
                    _ in
                    lastShowedRank.removeFromSuperview()
                    lastShowedRank = self.rankView
            })
            
        }
    }
    
    func showRoundScore(score : Int, position : CGPoint) {
        var color : UIColor = UIColor()
        switch score {
        case 1...30:
            color = UIColor(rgb: 0x27ae60)
        case 30...80:
            color = UIColor(rgb: 0x2980b9)
        case 80...999:
            color = UIColor(rgb: 0x8e44ad)
        default:
            color = UIColor(rgb: 0x2c3e50)
        }
        let scv = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        scv.center = position
        scv.textAlignment = NSTextAlignment.center
        let str = "+" + String(score)
//        scv.text = "+\(score)"
        scv.text = str
        scv.font = UIFont(name: "HelveticaNeue-CondensedBlack", size: 30)
        scv.textColor = color
        
        var cbv : UILabel = UILabel()
        
        if comboCounter > 1 {
            cbv = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
            cbv.center.y = position.y + 40
            cbv.center.x = position.x >= view.center.x ? position.x + view.frame.width : position.x - view.frame.width
            cbv.textAlignment = NSTextAlignment.center
            let cbvstr = "x" + String(comboCounter) + " Combo"
            cbv.text = cbvstr
            cbv.font = UIFont(name: "HelveticaNeue-CondensedBlack", size: 25)
            cbv.textColor = color
        }
        
        
        
        view.addSubview(scv)
        view.addSubview(cbv)
        
        UIView.animate(withDuration: 0.2, animations: {
            cbv.center.x = position.x >= self.view.center.x ? position.x - 50 : position.x + 50
            
            }, completion: {
                _ in
                UIView.animate(withDuration: 0.5, animations: {
                    cbv.alpha = 0
                    cbv.center.y -= 20
                    }, completion: { _ in
                        cbv.removeFromSuperview()
                })
                
        })
        UIView.animateKeyframes(withDuration: 0.7, delay: 0.1, options: [], animations: {
            scv.center.y -= 40
            scv.alpha = 0
            }, completion: { _ in
                scv.removeFromSuperview()
        })
    }
    
    func newHighscore() {
        let nhs = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        nhs.center.x = view.center.x
        nhs.backgroundColor = UIColor.white
        nhs.frame.origin.y = -100
        nhs.layer.borderWidth = 1
        nhs.layer.borderColor = UIColor(rgb: 0xd7d7d7).cgColor
        nhs.layer.cornerRadius = 5
        nhs.layer.shadowColor = UIColor.black.cgColor
        nhs.layer.shadowOpacity = 0.3
        nhs.layer.shadowOffset = CGSize(width: 1, height: 3)
        
        let l = UILabel(frame: CGRect(x: 0, y: 0, width: nhs.frame.width, height: nhs.frame.height))
        l.text = "New Highscore"
        l.textAlignment = NSTextAlignment.center
        l.font = UIFont(name: "HelveticaNeue-CondensedBlack", size: 20)
        
        nhs.addSubview(l)
        
        view.addSubview(nhs)
        
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 1, options: [], animations: {
            nhs.frame.origin.y = 20
            }, completion: {
                _ in
                UIView.animate(withDuration: 0.3, delay: 0.3, options : [], animations: {
                    nhs.frame.origin.y = -100
                }, completion: nil)
                
        })
    }
    
    func playSound(file : String, volume : Float) {
        let sound = NSURL(fileURLWithPath: Bundle.main.path(forResource: "sounds/" + file, ofType: "wav")!)
        
//        audioPlayer = AVAudioPlayer(contentsOfURL: sound as URL, error: &error)
        if let audioPlayer = try? AVAudioPlayer(contentsOf: sound as URL) {
            audioPlayer.volume = volume
            audioPlayer.prepareToPlay()
            audioPlayer.play()
        }
    }
    
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        adBanner.isHidden = false
    }
    
    private func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        adBanner.isHidden = true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true;
    }
    
}

