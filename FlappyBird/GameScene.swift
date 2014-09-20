//
//  GameScene.swift
//  FlappyBird
//
//  Created by Federico Knüssel on 9/20/14.
//  Copyright (c) 2014 ArgenDev. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Nodes
    var bird = SKSpriteNode()
    var skyColor = SKColor()
    var verticalPipeGap = 170.0
    var pipeTexture1 = SKTexture()
    var pipeTexture2 = SKTexture()
    var moveAndRemovePipes = SKAction()
    
    // Collisions
    let birdCategory: UInt32 = 1 << 0
    let worldCategory: UInt32 = 1 << 1
    let pipeCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    
    // In order to stop the world movement and disable the user control over the bird upon a collision
    // we can make use of the speed property of the SKNode. Setting the node speed to zero means that
    // all of the running actions are paused. In order to avoid setting the speed in each individual moving
    // entity in the scene, we create a dummy parent node called "moving" which holds all moving entities:
    // the pipes, the background, the ground.
    var moving = SKNode()
    
    // We will set this flag to TRUE after the bird has collided
    // and once the background has finished flashing
    var canRestart = false
    
    var pipes = SKNode()
    
    // Score Counting
    var scoreLabelNode = SKLabelNode()
    var score = NSInteger()
    
    override func didMoveToView(view: SKView) {
        
        // -----------------------------------------------
        // Scene Properties & Set Up
        // -----------------------------------------------
        
        // Let's create the moving node at the beginning of the scene
        // and attach every single moving node to it
        self.addChild(moving)
        
        moving.addChild(pipes)
        
        // This will set the gravity from 9.8 to 5
        self.physicsWorld.gravity = CGVectorMake( 0.0, -5.0 )
        
        // Sky background color
        skyColor = SKColor(red: 113.0/255.0, green: 197.0/255.0, blue: 207.0/255.0, alpha: 1.0)
        self.backgroundColor = skyColor
        
        // Collisions something
        self.physicsWorld.contactDelegate = self
        
        
        // -----------------------------------------------
        // Bird
        // -----------------------------------------------
        
        // Create a texture that holds the bird images
        var birdTexture1 = SKTexture(imageNamed: "Bird1")
        birdTexture1.filteringMode = SKTextureFilteringMode.Nearest
        var birdTexture2 = SKTexture(imageNamed: "Bird2")
        birdTexture2.filteringMode = SKTextureFilteringMode.Nearest
        
        // Flap animation
        var animation = SKAction.animateWithTextures([birdTexture1, birdTexture2], timePerFrame: 0.2)
        var flap = SKAction.repeatActionForever(animation)
        
        // Add the texture to the bird node
        bird = SKSpriteNode(texture: birdTexture1)
        
        // Set the bird position relative to the frame
        bird.position = CGPoint(x: self.frame.size.width / 2.8, y:CGRectGetMidY(self.frame))
        
        // Run the flap animation on the bird node
        bird.runAction(flap)
        
        // Add physics to our scene so that the bird falls
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        bird.physicsBody?.dynamic = true
        bird.physicsBody?.allowsRotation = false
        
        // Add collisions
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.physicsBody?.contactTestBitMask = worldCategory | pipeCategory
        
        // Add the bird node to the scene
        self.addChild(bird)
        
        
        // -----------------------------------------------
        // Ground
        // -----------------------------------------------
        
        // Create the texture that will hold the ground image
        var groundTexture = SKTexture(imageNamed: "Ground")
        groundTexture.filteringMode = SKTextureFilteringMode.Nearest
        
        // Move the ground alongside the "x" axis
        var moveGroundSprite = SKAction.moveByX(-groundTexture.size().width, y: 0, duration: NSTimeInterval(0.01 * groundTexture.size().width))
        var resetGroundSprite = SKAction.moveByX(groundTexture.size().width, y: 0, duration: 0.0)
        var moveGroundSpritesForever = SKAction.repeatActionForever(SKAction.sequence([moveGroundSprite, resetGroundSprite]))
        
        // Repeat the ground texture with a loop
        for var i:CGFloat = 0; i < 2 + self.frame.size.width / (groundTexture.size().width); ++i {
            var sprite = SKSpriteNode(texture: groundTexture)
            sprite.position = CGPointMake(i * sprite.size.width, sprite.size.height / 2)
            sprite.runAction(moveGroundSpritesForever)
            moving.addChild(sprite)
        }
        
        
        // -----------------------------------------------
        // Dummy Ground
        // -----------------------------------------------
        
        // We could add the ground non physics so it would catch the bird.
        // But as the ground is constantly moving, it will push the bird to the left.
        // This is not what we want. We want the bird to stay at the point it collided with the ground.
        // This is why we make a simple dummy rectangular physics node where the ground is.
        // Now the bird will get caught by the ground.
        var dummy = SKNode()
        dummy.position = CGPointMake(0, groundTexture.size().height / 2)
        dummy.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width, groundTexture.size().height))
        dummy.physicsBody?.dynamic = false
        dummy.physicsBody?.categoryBitMask = worldCategory;
        self.addChild(dummy)
        
        
        // -----------------------------------------------
        // Skyline
        // -----------------------------------------------
        
        // Create the texture that will hold the skyline image
        var skyTexture = SKTexture(imageNamed: "Skyline")
        skyTexture.filteringMode = SKTextureFilteringMode.Nearest

        // Move the skyline
        var moveSkySprite = SKAction.moveByX(-skyTexture.size().width, y: 0, duration: NSTimeInterval(0.1 * skyTexture.size().width))
        var resetSkySprite = SKAction.moveByX(skyTexture.size().width, y: 0, duration: 0.0)
        var moveSkySpritesForever = SKAction.repeatActionForever(SKAction.sequence([moveSkySprite,resetSkySprite]))
        
        // Repeat the skyline texture with a loop
        for var i:CGFloat = 0; i < 2.0 + self.frame.size.width / ( skyTexture.size().width); ++i {
            var sprite = SKSpriteNode(texture: skyTexture)
            sprite.zPosition = -20
            sprite.position = CGPointMake(i * sprite.size.width, sprite.size.height / 2 + groundTexture.size().height)
            sprite.runAction(moveSkySpritesForever)
            moving.addChild(sprite)
        }
        
        
        // -----------------------------------------------
        // Pipes
        // -----------------------------------------------
        
        // Pipes will have a physics body attached for collisions
        pipeTexture1 = SKTexture(imageNamed: "Pipe1")
        pipeTexture1.filteringMode = SKTextureFilteringMode.Nearest
        pipeTexture2 = SKTexture(imageNamed: "Pipe2")
        pipeTexture2.filteringMode = SKTextureFilteringMode.Nearest
        
        var distanceToMove = CGFloat(self.frame.size.width + 2 * pipeTexture1.size().width)
        var movePipes = SKAction.moveByX(-distanceToMove, y:0, duration:NSTimeInterval(0.01 * distanceToMove))
        var removePipes = SKAction.removeFromParent();
        moveAndRemovePipes = SKAction.sequence([movePipes, removePipes]);
        
        // Making sure the spawnPipes method is called regularly to create new pipes and attach animation to them
        var spawn = SKAction.runBlock( { () in self.spawnPipes() } )
        var delay = SKAction.waitForDuration(NSTimeInterval(2.0))
        var spawnThenDelay = SKAction.sequence([spawn, delay])
        var spawnThenDelayForever = SKAction.repeatActionForever(spawnThenDelay)
        self.runAction(spawnThenDelayForever)
        
        // Scoring
        // The game is over when the bird hits either a pipe or the ground
        score = 0
        scoreLabelNode.fontName = "Helvetica-Bold"
        scoreLabelNode.position = CGPointMake( CGRectGetMidX( self.frame ), self.frame.size.height / 6 )
        scoreLabelNode.fontSize = 600
        scoreLabelNode.alpha = 0.2
        scoreLabelNode.zPosition = -30
        scoreLabelNode.text = "\(score)"
        self.addChild(scoreLabelNode)
        
    }
    
    func spawnPipes() {
        
        // Pipes consist of two Sprite Nodes, so we can wrap them both in an empty node as a parent
        // The two children (pipes) are positioned relatived to the parent node
        // So we only need to worry about their vertical position
        var pipePair = SKNode()
        pipePair.position = CGPointMake( self.frame.size.width + pipeTexture1.size().width * 2, 0 )
        pipePair.zPosition = -10
        
        var height = UInt32( self.frame.size.height / 3 )
        var y = arc4random() % height
        
        var pipe1 = SKSpriteNode(texture: pipeTexture1)
        pipe1.position = CGPointMake(0.0, CGFloat(y))
        pipe1.physicsBody = SKPhysicsBody(rectangleOfSize: pipe1.size)
        pipe1.physicsBody?.dynamic = false
        pipe1.physicsBody?.categoryBitMask = pipeCategory
        pipe1.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(pipe1)
        
        var pipe2 = SKSpriteNode(texture: pipeTexture2)
        pipe2.position = CGPointMake(0.0, CGFloat(y) + pipe1.size.height + CGFloat(verticalPipeGap))
        pipe2.physicsBody = SKPhysicsBody(rectangleOfSize: pipe2.size)
        pipe2.physicsBody?.dynamic = false
        pipe2.physicsBody?.categoryBitMask = pipeCategory
        pipe2.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(pipe2)
        
        var contactNode = SKNode()
        contactNode.position = CGPointMake( pipe1.size.width + bird.size.width / 2, CGRectGetMidY( self.frame ) )
        contactNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(pipe1.size.width, self.frame.size.height))
        contactNode.physicsBody?.dynamic = false
        contactNode.physicsBody?.categoryBitMask = scoreCategory
        contactNode.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(contactNode)
        
        pipePair.runAction(moveAndRemovePipes)
        
        pipes.addChild(pipePair)
        
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        if (moving.speed > 0) {
            bird.physicsBody?.velocity = CGVectorMake(0, 0)
            bird.physicsBody?.applyImpulse(CGVectorMake(0, 8))
        } else if (canRestart) {
            self.resetScene()
        }
    }
    
    func resetScene() {
        bird.position = CGPoint(x: self.frame.size.width / 2.8, y:CGRectGetMidY(self.frame))
        bird.physicsBody?.velocity = CGVectorMake(0, 0)
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.speed = 1.0
        bird.zRotation = 0.0
        
        pipes.removeAllChildren()
        
        canRestart = false
        
        moving.speed = 1
        
        score = 0;
        scoreLabelNode.text = "\(score)"
        
    }
    
    // Rotation of the bird when moving, it should point down when falling and up when rising
    // This function ensures the rotation doesn't go over a certain min and max value
    func clamp(min: CGFloat, max: CGFloat, value: CGFloat) -> CGFloat {
        if( value > max ) {
            return max;
        } else if( value < min ) {
            return min;
        } else {
            return value;
        }
    }
    
    // Contact notification method
    func didBeginContact(contact: SKPhysicsContact!) {
        
        // In order to stop the animation, we can set the moving speed to zero
        // The parent's speed is applied to all child nodes
        if( moving.speed > 0 ) {
            
            if( ( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory ) {
                
                score++;
                scoreLabelNode.text = "\(score)"
                
            } else {
            
                // Halt
                moving.speed = 0
            
                bird.physicsBody?.collisionBitMask = worldCategory
            
                var rotateBird = SKAction.rotateByAngle(0.01, duration: 0.003)
                var stopBird = SKAction.runBlock({() in self.killBirdSpeed()})
                var birdSequence = SKAction.sequence([rotateBird, stopBird])
                bird.runAction(birdSequence)
            
                self.removeActionForKey("flash")
                var turnBackgroundRed = SKAction.runBlock({() in self.setBackgroundColorRed()})
                var wait = SKAction.waitForDuration(0.05)
                var turnBackgroundWhite = SKAction.runBlock({() in self.setBackgroundColorWhite()})
                var turnBackgroundSky = SKAction.runBlock({() in self.setBackgroundColorSky()})
                var sequenceOfActions = SKAction.sequence([turnBackgroundRed, wait, turnBackgroundWhite, wait, turnBackgroundSky])
                var repeatSequence = SKAction.repeatAction(sequenceOfActions, count: 4)
                var canRestartAction = SKAction.runBlock({() in self.letItRestart()})
                var groupOfActions = SKAction.group([repeatSequence, canRestartAction])
                self.runAction(groupOfActions, withKey: "flash")
            }
            
        }
        
    }
    
    func killBirdSpeed() {
        bird.speed = 0
    }
    
    func letItRestart() {
        canRestart = true
    }
    
    func setBackgroundColorRed() {
        self.backgroundColor = UIColor.redColor()
    }
    
    func setBackgroundColorWhite() {
        self.backgroundColor = UIColor.whiteColor()
    }
    
    func setBackgroundColorSky() {
        self.backgroundColor = SKColor(red:113.0/255.0, green:197.0/255.0, blue:207.0/255.0, alpha:1.0)
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        if( moving.speed > 0 ) {
            bird.zRotation = self.clamp( -1, max: 0.5, value: bird.physicsBody!.velocity.dy * ( bird.physicsBody!.velocity.dy < 0 ? 0.002 : 0.001 ) )
        }
    }
}
