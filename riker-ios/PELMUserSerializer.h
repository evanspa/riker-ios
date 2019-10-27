//
//  RUserSerializer.h
//

#import "HCHalJsonSerializerExtensionSupport.h"

@class PELMMainSupport;

@interface PELMUserSerializer : HCHalJsonSerializerExtensionSupport

+ (void)populateUserFieldsOn:(PELMMainSupport *)entity fromDictionary:(NSDictionary *)resDict;

@end
