//
//  PELMNotificationUtils.h
//

@import Foundation;

@class PELMMainSupport;

FOUNDATION_EXPORT NSString * const PELMNotificationEntitiesUserInfoKey;

@interface PELMNotificationUtils : NSObject

#pragma mark - Notification related

+ (void)postNotificationWithName:(NSString *)notificationName
                        entities:(NSArray *)entities;

+ (void)postNotificationWithName:(NSString *)notificationName
                          entity:(PELMMainSupport *)entity;

+ (void)postNotificationWithName:(NSString *)notificationName;

+ (NSArray *)entitiesFromNotification:(NSNotification *)notification;

+ (NSNumber *)indexOfEntityRef:(PELMMainSupport *)entity
                  notification:(NSNotification *)notification;

+ (PELMMainSupport *)entityAtIndex:(NSInteger)index
                      notification:(NSNotification *)notification;

@end
