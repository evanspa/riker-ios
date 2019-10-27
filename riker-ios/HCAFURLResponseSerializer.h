//
//  HCAFURLResponseSerializer.h
//

@import Foundation;
#import <AFNetworking/AFURLResponseSerialization.h>

@protocol HCResourceSerializer;

/**
 An implementation of AFNetworking's response serializer that would leverage an
 HC resource serializer.
 */
@interface HCAFURLResponseSerializer : AFHTTPResponseSerializer

#pragma mark - Initializers

/**
 Creates and returns an instance using the given HC resource serializer.
 @param hcserializer the underlying serializer to be used when leveraging
 AFNetworking to make actual HTTP calls.
 @return a new instance
 */
- (id)initWithHCSerializer:(id<HCResourceSerializer>)hcserializer;

@end
