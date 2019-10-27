//
//  HCResourceSerializerSupport.h
//

@import Foundation;
#import "HCResourceSerializer.h"

/**
 Convenient class to base concrete implementations of the HCResourceSerializer
 protocol off of.
 */
@interface HCResourceSerializerSupport : NSObject <HCResourceSerializer>

#pragma mark - Properties from the HCResourceSerializer protocol

@property (nonatomic, readonly) HCMediaType *mediaType;

@property (nonatomic, readonly) NSDictionary *embeddedSerializers;

@property (nonatomic, readonly) NSDictionary *embeddedResourceActions;

@property (nonatomic, readonly) HCCharset *requestSerializationCharacterSet;

@property (nonatomic, readonly) HCCharset *responseSerializationCharacterSet;

@end
