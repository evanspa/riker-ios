//
//  PELMNotificationUtils.m
//

#import "PELMNotificationUtils.h"
#import "PELMMainSupport.h"

NSString * const PELMNotificationEntitiesUserInfoKey = @"PELMNotificationEntitiesUserInfoKey";

@implementation PELMNotificationUtils

+ (void)postNotificationWithName:(NSString *)notificationName
                        entities:(NSArray *)entities {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter]
      postNotificationName:notificationName
                    object:nil
                  userInfo:@{PELMNotificationEntitiesUserInfoKey : entities}];
  });
}

+ (void)postNotificationWithName:(NSString *)notificationName
                          entity:(PELMMainSupport *)entity {
  NSArray *entities;
  if (entity) {
    entities = @[entity];
  } else {
    entities = @[];
  }
  [PELMNotificationUtils postNotificationWithName:notificationName
                                         entities:entities];
}

+ (void)postNotificationWithName:(NSString *)notificationName {
  [PELMNotificationUtils postNotificationWithName:notificationName
                                         entities:@[]];
}

+ (NSArray *)entitiesFromNotification:(NSNotification *)notification {
  NSDictionary *userInfo = [notification userInfo];
  if (userInfo) {
    return userInfo[PELMNotificationEntitiesUserInfoKey];
  }
  return nil;
}

+ (NSNumber *)indexOfEntityRef:(PELMMainSupport *)entity
                  notification:(NSNotification *)notification {
  NSArray *entities = [PELMNotificationUtils entitiesFromNotification:notification];
  NSInteger numEntities = [entities count];
  for (NSInteger i = 0; i < numEntities; i++) {
    if ([entity doesHaveEqualIdentifiers:entities[i]]) {
      return @(i);
    }
  }
  return nil;
}

+ (PELMMainSupport *)entityAtIndex:(NSInteger)index
                      notification:(NSNotification *)notification {
  NSArray *entities = [PELMNotificationUtils entitiesFromNotification:notification];
  if (index < [entities count]) {
    return entities[index];
  }
  return nil;
}

@end
