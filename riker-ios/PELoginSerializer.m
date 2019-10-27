//
//  FPLoginSerializer.m
//

#import "PELoginSerializer.h"
#import "PELMLoginUser.h"
#import "NSMutableDictionary+PEAdditions.h"
#import "PELMUserSerializer.h"

NSString * const PELoginUserEmailKey    = @"user/username-or-email";
NSString * const PELoginUserPasswordKey = @"user/password";

@implementation PELoginSerializer {
  PELMUserSerializer *_userSerializer;
}

- (id)initWithMediaType:(HCMediaType *)mediaType
                charset:(HCCharset *)charset
         userSerializer:(PELMUserSerializer *)userSerializer {
  self = [super initWithMediaType:mediaType
                          charset:charset
  serializersForEmbeddedResources:[userSerializer embeddedSerializers]
      actionsForEmbeddedResources:[userSerializer embeddedResourceActions]];
  if (self) {
    _userSerializer = userSerializer;
  }
  return self;
}

#pragma mark - Serialization (Resource Model -> JSON Dictionary)

- (NSDictionary *)dictionaryWithResourceModel:(id)resourceModel {
  PELMLoginUser *loginUser = (PELMLoginUser *)resourceModel;
  NSMutableDictionary *userDict = [NSMutableDictionary dictionary];
  [userDict setObjectIfNotNull:[loginUser email] forKey:PELoginUserEmailKey];
  [userDict setObjectIfNotNull:[loginUser password] forKey:PELoginUserPasswordKey];
  return userDict;
}

#pragma mark - Deserialization (JSON Dictionary -> Resource Model)

- (id)resourceModelWithDictionary:(NSDictionary *)resDict
                        relations:(NSDictionary *)relations
                        mediaType:(HCMediaType *)mediaType
                         location:(NSString *)location
                     lastModified:(NSDate *)lastModified {
  return [_userSerializer resourceModelWithDictionary:resDict
                                            relations:relations
                                            mediaType:mediaType
                                             location:location
                                         lastModified:lastModified];
}

@end
