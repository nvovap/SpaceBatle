//
//  GameScene.swift
//  SpaceBatle
//
//  Created by nvovap on 10/20/16.
//  Copyright © 2016 nvovap. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion



#if os(watchOS)
    import WatchKit
    // <rdar://problem/26756207> SKColor typealias does not seem to be exposed on watchOS SpriteKit
    typealias SKColor = UIColor
#endif





class GameScene: SKScene{
    
    
    fileprivate var label : SKLabelNode?
    fileprivate var spinnyNode : SKShapeNode?
    
    
    
    
    
    
    var starfield: SKEmitterNode!
    
    var labelScore: SKLabelNode!
    
    
    
    var motionManager = CMMotionManager()
    var xAcceleration: CGFloat = 0
    
    
    var score: Int = 0 {
        didSet {
            labelScore.text = "Scope: \(score)"
        }
        
    }
    
    
    var gameTimer: Timer!
    
    var torpedoSound: SKAction!
    var explosionSound: SKAction!
    
    
    var possibleAlients = ["alien","alien2","alien3"]
    
    let alienCategory: UInt32 = 0x1 << 1
    let photonTorpedoCategory: UInt32 = 0x1 << 0
    
    var player: SKSpriteNode!

    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        
        // Set the scale mode to scale to fit the window
        scene.scaleMode = .aspectFill
        
        return scene
    }
    
    func setUpScene() {
        
        if self.childNode(withName: "player") == nil {
            torpedoSound = SKAction.playSoundFileNamed("torpedo.mp3", waitForCompletion: false)
            explosionSound = SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false)
            
            labelScore = self.childNode(withName: "scoreLabel") as! SKLabelNode
            
            
            starfield = SKEmitterNode(fileNamed: "Starfield")
            starfield.position = CGPoint(x: self.frame.width/2, y: self.frame.height)
            starfield.advanceSimulationTime(10)
            starfield.zPosition = -1
            
            self.addChild(starfield)
            
            
            
            self.physicsWorld.contactDelegate = self
            
            player = self.childNode(withName: "player") as! SKSpriteNode
            player.position = CGPoint(x: self.frame.width / 2, y: player.position.y)
            
            
            
            gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
            
            
            motionManager.accelerometerUpdateInterval = 0.2
            
            motionManager.startAccelerometerUpdates(to: OperationQueue.current!, withHandler: {(data: CMAccelerometerData?, error:Error?) in
                if let accelerometerData = data {
                    self.xAcceleration = CGFloat(accelerometerData.acceleration.x) * 0.75 + self.xAcceleration * 0.25
                }
                
            })
            
            
            
//            player = SKSpriteNode(imageNamed: "shuttle")
//            player.position = CGPoint(x: 0.0, y: 0.0)
//            player.name = "player"
//            
//            self.addChild(player)
        }
        
        
        #if os(watchOS)
                
            let crownSequencer = WKExtension.shared().rootInterfaceController!.crownSequencer
            crownSequencer.delegate = self
            crownSequencer.focus()
                
        #endif

    }
    
    override func didSimulatePhysics() {
        player.position.x += xAcceleration * 50
        
        if  player.position.x < 20 {
            player.position = CGPoint(x: 20, y: player.position.y)
        } else if player.position.x > self.frame.width-20 {
            player.position = CGPoint(x: self.frame.width-20, y: player.position.y)
        }
    }
    
    
    
  
    
    func addAlien() {
        possibleAlients = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAlients) as! [String]
        
        let alien = SKSpriteNode(imageNamed: possibleAlients[0])
        
        
        let randomAlienPosition = GKRandomDistribution(lowestValue: 0, highestValue: Int(self.frame.width) - 30)
        let position = CGFloat(randomAlienPosition.nextInt())
        
        alien.position = CGPoint(x: position, y: self.frame.height - alien.size.height)
        
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask      = alienCategory
        alien.physicsBody?.contactTestBitMask   = photonTorpedoCategory
        alien.physicsBody?.collisionBitMask     = 0
        
        self.addChild(alien)
        
        let animationDuration:TimeInterval = 6
        
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x: position, y: -alien.size.height) , duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        alien.run(SKAction.sequence(actionArray))
        
    }
    
    
    
    func fireTorpedo() {
        self.run(torpedoSound)
        
        let torpedoNode = SKSpriteNode(imageNamed: "torpedo")
        torpedoNode.position = player.position
        
        torpedoNode.position.y += 5
        
        torpedoNode.physicsBody = SKPhysicsBody(circleOfRadius: torpedoNode.size.width / 2)
        torpedoNode.physicsBody?.isDynamic = true
        
        torpedoNode.physicsBody?.categoryBitMask      = photonTorpedoCategory
        torpedoNode.physicsBody?.contactTestBitMask   = alienCategory
        torpedoNode.physicsBody?.collisionBitMask     = 0
        torpedoNode.physicsBody?.usesPreciseCollisionDetection = true
        
        self.addChild(torpedoNode)
        
        let animationDuration:TimeInterval = 0.3
        
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x: player.position.x, y: self.frame.height+10) , duration: animationDuration))
        actionArray.append(SKAction.removeFromParent())
        
        torpedoNode.run(SKAction.sequence(actionArray))
        
        
        
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireTorpedo()
    }
    
    
    
    #if os(watchOS)
    override func sceneDidLoad() {
        self.setUpScene()
    }
    #else
    override func didMove(to view: SKView) {
        self.setUpScene()
    }
    #endif

    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}

extension GameScene: SKPhysicsContactDelegate {
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody  = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody  = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if (firstBody.categoryBitMask & photonTorpedoCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0 {
            torpedoDidCollideWithAlien(torpedo: firstBody.node as! SKSpriteNode, alien: secondBody.node as! SKSpriteNode)
        }
    }
    
    func torpedoDidCollideWithAlien(torpedo: SKSpriteNode, alien: SKSpriteNode) {
        let explosion = SKEmitterNode(fileNamed: "Explosion")!
        explosion.position = alien.position
        
        self.addChild(explosion)
        
        self.run(explosionSound)
        
        alien.removeFromParent()
        torpedo.removeFromParent()
        
        self.run(SKAction.wait(forDuration: 2), completion: {
            explosion.removeFromParent()
        })
        
        
        score += 5
    }
    
}

#if os(watchOS)
extension GameScene: WKCrownDelegate {
    
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?,
                        rotationalDelta: Double) {
        
        print(rotationalDelta)
        
        player.position = CGPoint(x: player.position.x + CGFloat(rotationalDelta * 1000), y: 0.0 )
        
    }
    
    func crownDidBecomeIdle(_ crownSequencer: WKCrownSequencer?) {
        
    }
    
    
}
#endif
    
//#if os(iOS) || os(tvOS)
// Touch-based event handling
//extension GameScene {
//
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        if let label = self.label {
//            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
//        }
//        
//        for t in touches {
//            self.makeSpinny(at: t.location(in: self), color: SKColor.green)
//        }
//    }
//    
//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for t in touches {
//            self.makeSpinny(at: t.location(in: self), color: SKColor.blue)
//        }
//    }
//    
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for t in touches {
//            self.makeSpinny(at: t.location(in: self), color: SKColor.red)
//        }
//    }
//    
//    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//        for t in touches {
//            self.makeSpinny(at: t.location(in: self), color: SKColor.red)
//        }
//    }
//    
//   
//}
//#endif

//#if os(OSX)
// Mouse-based event handling
//extension GameScene {
//
//    override func mouseDown(with event: NSEvent) {
//        if let label = self.label {
//            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
//        }
//        self.makeSpinny(at: event.location(in: self), color: SKColor.green)
//    }
//    
//    override func mouseDragged(with event: NSEvent) {
//        self.makeSpinny(at: event.location(in: self), color: SKColor.blue)
//    }
//    
//    override func mouseUp(with event: NSEvent) {
//        self.makeSpinny(at: event.location(in: self), color: SKColor.red)
//    }
//
//}
//#endif

