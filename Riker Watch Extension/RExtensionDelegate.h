//
//  RExtensionDelegate.h
//  Riker Watch Extension
//
//  Created by PEVANS on 5/1/17.
//  Copyright © 2017 Riker. All rights reserved.
//

#import <WatchKit/WatchKit.h>
@import WatchConnectivity;
@import UserNotifications;

@interface RExtensionDelegate : NSObject <WKExtensionDelegate,
WCSessionDelegate,
UNUserNotificationCenterDelegate>

@property (nonatomic) NSMutableDictionary *movementsAndSettings;

@property (nonatomic) NSNumber *selectedBodySegmentId;
@property (nonatomic) NSNumber *selectedMuscleGroupId;
@property (nonatomic) NSNumber *selectedMovementId;
@property (nonatomic) NSString *selectedMovementName;
@property (nonatomic) BOOL selectedMovementIsBodyLift;
@property (nonatomic) NSDecimalNumber *selectedMovementPercentageOfBodyWeight;
@property (nonatomic) NSNumber *selectedMovementVariantId;
@property (nonatomic) NSString *selectedMovementVariantName;
@property (nonatomic) NSInteger setNumber;
@property (nonatomic) NSMutableDictionary *settings;
@property (nonatomic) NSInteger numPendingSets;
@property (nonatomic) BOOL canDismissEnterBmlScreen;
@property (nonatomic) NSDictionary *selectedSet;
@property (nonatomic) NSInteger selectedSetIndex;
@property (nonatomic) NSNumber *deletedSetIndex;
@property (nonatomic) NSDictionary *selectedBml;
@property (nonatomic) NSInteger selectedBmlIndex;
@property (nonatomic) NSNumber *deletedBmlIndex;

- (void)setLastSelectedMovementId:(NSNumber *)movementId;
- (NSNumber *)lastSelectedMovementId;

- (void)setLastSelectedMovementName:(NSString *)movementName;
- (NSString *)lastSelectedMovementName;

- (void)setLastSelectedMovementVariantId:(NSNumber *)movementVariantId;
- (NSNumber *)lastSelectedMovementVariantId;

- (void)setLastSelectedMovementVariantName:(NSString *)movementVariantName;
- (NSString *)lastSelectedMovementVariantName;

- (void)setEnterRepsScreenLastVisitedAtTime:(NSNumber *)loggedAtTime;
- (NSDate *)enterRepsScreenLastVisitedAt;

- (void)setEnterRepsScreenLastSetNumber:(NSNumber *)setNumber;
- (NSNumber *)enterRepsScreenLastSetNumber;

- (void)setEnterRepsScreenLastWeight:(NSDecimalNumber *)weight;
- (NSDecimalNumber *)enterRepsScreenLastWeight;

- (void)setEnterRepsScreenLastReps:(NSNumber *)reps;
- (NSDecimalNumber *)enterRepsScreenLastReps;

- (void)setEnterRepsScreenLastToFailure:(BOOL)toFailure;
- (BOOL)enterRepsScreenLastToFailure;

- (void)setEnterRepsScreenLastNegatives:(BOOL)negatives;
- (BOOL)enterRepsScreenLastNegatives;

- (BOOL)captureNegatives;
- (void)setCaptureNegatives:(BOOL)captureNegatives;

- (NSDate *)suppressedWeightDefaultedToBodyWeightPopupAt;
- (void)setSuppressedWeightDefaultedToBodyWeightPopupAt:(NSDate *)date;

- (void)writeSettings;

- (NSArray *)movementVariants;

@end
