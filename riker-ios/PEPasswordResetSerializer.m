//
//  PEPasswordResetSerializer.m
//

#import "PEPasswordResetSerializer.h"
#import "PELMLoginUser.h"
#import "NSMutableDictionary+PEAdditions.h"

NSString * const FPUnknownUserEmailKey = @"user/email";

@implementation PEPasswordResetSerializer

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  PELMLoginUser *unknownUser = (PELMLoginUser *)resourceModel;
  NSMutableDictionary *dict = [NSMutableDictionary dictionary];
  [dict setObjectIfNotNull:[unknownUser email] forKey:FPUnknownUserEmailKey];
  return dict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  return [[NSObject alloc] init];
}

@end
