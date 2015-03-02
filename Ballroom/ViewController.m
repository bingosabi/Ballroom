//
//  ViewController.m
//  Ballroom
//
//  Created by Ben Bruckhart on 2/17/15.
//  Copyright (c) 2015 Listomni. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>


@interface ViewController ()

@property (nonatomic,strong) CMMotionManager *manager;
@property (strong, nonatomic) UIDynamicAnimator *animator;
@property (nonatomic,strong) UIGravityBehavior *gravity;
@property (nonatomic, strong) NSMutableArray *balls;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (nonatomic, strong) UICollisionBehavior *supercollider;
@property (nonatomic, strong) UIDynamicItemBehavior *properties;
@property (nonatomic, strong) NSMutableArray *pushBehaviors;

@end

static const CGFloat kGravityModifier = 2.2;

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
//    self.containerView.layer.borderColor = [[UIColor blackColor] CGColor];
//    self.containerView.layer.borderWidth = 0.5;
    [self.containerView removeFromSuperview];
    self.containerView = self.view ;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self createBalls:100 withBallSize:10.0 andDeviation:9.0];
    [self setupGravity:self.animator];
    [self setupInteraction];
    //[self setupBoundaries];
}

- (void)didPan:(UIPanGestureRecognizer *)panner {
    
    [self.pushBehaviors enumerateObjectsUsingBlock:^(UIPushBehavior *behavior, NSUInteger idx, BOOL *stop) {
        if (!behavior.active) {
            [self.animator removeBehavior:behavior];
        }
    }];
    
    
    CGPoint location = [panner locationInView:panner.view];
    CGFloat interactionSize = 20;
    CGRect activeRect = CGRectMake(location.x - interactionSize/2.0, location.y - interactionSize/2.0, interactionSize, interactionSize);
    NSMutableArray *interactingViews = [NSMutableArray array];
    [panner.view.subviews enumerateObjectsUsingBlock:^(UIView *ball, NSUInteger idx, BOOL *stop) {
        CGRect intersection = CGRectIntersection(ball.frame, activeRect);
        if (!CGRectEqualToRect(CGRectNull, intersection)) {
            [interactingViews addObject:ball];
        }
    }];
    
    if (panner.state== UIGestureRecognizerStateBegan) {
        [interactingViews enumerateObjectsUsingBlock:^(UIView *ball, NSUInteger idx, BOOL *stop) {
            UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[ball] mode:UIPushBehaviorModeInstantaneous];
            pushBehavior.angle = [self pointPairToBearingDegrees:location secondPoint:ball.center];
            pushBehavior.magnitude = 0.2;
            [self.animator addBehavior:pushBehavior];
        }];
        
    } else if (panner .state == UIGestureRecognizerStateEnded || panner.state == UIGestureRecognizerStateCancelled) {
        [self.pushBehaviors enumerateObjectsUsingBlock:^(UIPushBehavior *behavior, NSUInteger idx, BOOL *stop) {
            [self.animator removeBehavior:behavior];
        }];
    } else if (panner.state == UIGestureRecognizerStateChanged){
        [interactingViews enumerateObjectsUsingBlock:^(UIView *ball, NSUInteger idx, BOOL *stop) {
            UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[ball] mode:UIPushBehaviorModeInstantaneous];
            pushBehavior.angle = [self pointPairToBearingDegrees:location secondPoint:ball.center];
            pushBehavior.magnitude = 0.05;
            [self.animator addBehavior:pushBehavior];
        }];
    }
}

- (void)didTap:(UITapGestureRecognizer *)panner {
    [self.pushBehaviors enumerateObjectsUsingBlock:^(UIPushBehavior *behavior, NSUInteger idx, BOOL *stop) {
        if (!behavior.active) {
            [self.animator removeBehavior:behavior];
        }
    }];
    
    
    CGPoint location = [panner locationInView:panner.view];
    CGFloat interactionSize = 20;
    CGRect activeRect = CGRectMake(location.x - interactionSize/2.0, location.y - interactionSize/2.0, interactionSize, interactionSize);
    NSMutableArray *interactingViews = [NSMutableArray array];
    [panner.view.subviews enumerateObjectsUsingBlock:^(UIView *ball, NSUInteger idx, BOOL *stop) {
        CGRect intersection = CGRectIntersection(ball.frame, activeRect);
        if (!CGRectEqualToRect(CGRectNull, intersection)) {
            [interactingViews addObject:ball];
        }
    }];
    
    if (panner.state== UIGestureRecognizerStateBegan) {
        
        
    } else if (panner .state == UIGestureRecognizerStateEnded ) {
        [interactingViews enumerateObjectsUsingBlock:^(UIView *ball, NSUInteger idx, BOOL *stop) {
            UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[ball] mode:UIPushBehaviorModeInstantaneous];
            pushBehavior.angle = [self pointPairToBearingDegrees:location secondPoint:ball.center];
            pushBehavior.magnitude = 0.2;
            [self.animator addBehavior:pushBehavior];
        }];
    } else if (panner.state == UIGestureRecognizerStateChanged){
        
    }
}

- (CGFloat) pointPairToBearingDegrees:(CGPoint)startingPoint secondPoint:(CGPoint) endingPoint
{
    CGPoint originPoint = CGPointMake(endingPoint.x - startingPoint.x, endingPoint.y - startingPoint.y); // get origin point to origin by subtracting end from start
    float bearingRadians = atan2f(originPoint.y, originPoint.x); // get bearing in radians
    float bearingDegrees = bearingRadians * (180.0 / M_PI); // convert to degrees
    bearingDegrees = (bearingDegrees > 0.0 ? bearingDegrees : (360.0 + bearingDegrees)); // correct discontinuity
    return bearingDegrees;
}

- (void)createBalls:(int) ballcount withBallSize:(CGFloat)diameter andDeviation:(CGFloat)deviationModifier{
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.containerView];
    self.balls = [NSMutableArray array];
    for (int i = 0; i < ballcount; i++) {
        double deviation = arc4random() % (int)deviationModifier;
        UIView *ball = [[UIView alloc] initWithFrame:CGRectMake(arc4random() % (int) (self.containerView.bounds.size.width - diameter-deviation), arc4random() % (int) (self.containerView.bounds.size.height - diameter-deviation), diameter + deviation, diameter+ deviation)];
        ball.layer.cornerRadius = (diameter + deviation)/2.0;
        switch (arc4random() % 3) {
            case 0:
                ball.backgroundColor = [UIColor redColor];
                break;
            case 1:
                ball.backgroundColor = [UIColor greenColor];
                break;
            case 2:
                ball.backgroundColor = [UIColor blueColor];
                break;
                
            default:
                ball.backgroundColor = [UIColor blackColor];
                break;
        }
        [self.containerView addSubview:ball];
        [self.balls addObject:ball];
        
    }
}

- (void) setupGravity:(UIDynamicAnimator *)animator {
    self.gravity = [[UIGravityBehavior alloc] initWithItems:self.balls];
    
    [animator addBehavior:self.gravity];
    
    self.supercollider = [[UICollisionBehavior alloc]
                                   initWithItems:self.balls];
    self.supercollider.translatesReferenceBoundsIntoBoundary = YES;
    [self.animator addBehavior:self.supercollider];
    
    
    UIDynamicItemBehavior *bounce = [[UIDynamicItemBehavior alloc] initWithItems:self.balls];
    bounce.elasticity = 0.90;
    bounce.friction = 0.1;
    [self.animator addBehavior:bounce];
    
}

- (void) setupBoundaries {
    UICollisionBehavior*collide = [[UICollisionBehavior alloc]
                                   initWithItems:self.balls];
    [collide addBoundaryWithIdentifier:@"topEdgeBarrier"
                             fromPoint:CGPointMake(0, 1)
                               toPoint:CGPointMake(self.containerView.bounds.size.width, 1)];
    
    [collide addBoundaryWithIdentifier:@"bottomEdgeBarrier"
                             fromPoint:CGPointMake(0, self.containerView.bounds.size.height-1)
                               toPoint:CGPointMake(self.containerView.bounds.size.width, self.containerView.bounds.size.height-1)];
    [collide addBoundaryWithIdentifier:@"leftEdgeBarrier"
                             fromPoint:CGPointMake(1, 0)
                               toPoint:CGPointMake(1, self.containerView.bounds.size.height)];
    
    [collide addBoundaryWithIdentifier:@"rightEdgeBarrier"
                             fromPoint:CGPointMake(self.containerView.bounds.size.width -1, 0)
                               toPoint:CGPointMake(self.containerView.bounds.size.width -1, self.containerView.bounds.size.height)];
    
    
    collide.translatesReferenceBoundsIntoBoundary = YES;
    [self.animator addBehavior:collide];
}

- (void) setupInteraction {
    //Setup finger interaciton
    UIPanGestureRecognizer * panner = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    [self.containerView addGestureRecognizer:panner];
    
    UITapGestureRecognizer * tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    [self.containerView addGestureRecognizer:tapper];
    
    //Setup motion interaciton.
    [self.manager stopAccelerometerUpdates];
    self.manager = nil;
    self.manager = [[CMMotionManager alloc] init];
    if (self.manager.deviceMotionAvailable) {
        self.manager.deviceMotionUpdateInterval = 0.05;
        [self.manager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            CMAcceleration acc = accelerometerData.acceleration;
            self.gravity.gravityDirection = CGVectorMake( acc.x*kGravityModifier,
                                                         -acc.y*kGravityModifier );

        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
