//
//  HCResourceSerializerSupport.m
//

#import "HCResourceSerializerSupport.h"

@implementation HCResourceSerializerSupport {
  HCCharset *_requestSerializationCharacterSet;
  HCCharset *_responseSerializationCharacterSet;
}

#pragma mark - Initializers

- (id)initWithMediaType:(HCMediaType *)mediaType
charsetForRequestSerialization:(HCCharset *)reqCharset
charsetForResponseSerialization:(HCCharset *)respCharset
serializersForEmbeddedResources:(NSDictionary *)embeddedSerializers
actionsForEmbeddedResources:(NSDictionary *)actions {
  self = [super init];
  if (self) {
    _mediaType = mediaType;
    _requestSerializationCharacterSet = reqCharset;
    _responseSerializationCharacterSet = respCharset;
    _embeddedSerializers = embeddedSerializers;
    _embeddedResourceActions = actions;
  }
  return self;
}

- (id)initWithMediaType:(HCMediaType *)mediaType
                charset:(HCCharset *)charset
serializersForEmbeddedResources:(NSDictionary *)embeddedSerializers
actionsForEmbeddedResources:(NSDictionary *)actions {
  return [self initWithMediaType:mediaType
  charsetForRequestSerialization:charset
 charsetForResponseSerialization:charset
 serializersForEmbeddedResources:embeddedSerializers
     actionsForEmbeddedResources:actions];
}

#pragma mark - Serialization (model -> HTTP request entity)

- (NSData *)serializeResourceModelToTextData:(id)resourceModel {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"You must \
override %@ in a subclass", NSStringFromSelector(_cmd)]
                               userInfo:nil];
}

#pragma mark - Deserialization (HTTP response entity -> model+relations)

- (HCDeserializedPair *)deserializeResourceFromTextData:(NSData *)data
                                      resourceMediaType:(HCMediaType *)mediaType 
                                            resourceURL:(NSURL *)url
                                           httpResponse:(NSHTTPURLResponse *)httpResponse {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"You must \
override %@ in a subclass", NSStringFromSelector(_cmd)]
                               userInfo:nil];
}

- (HCDeserializedPair *)deserializeEmbeddedResource:(id)readTextData {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"You must \
override %@ in a subclass", NSStringFromSelector(_cmd)]
                               userInfo:nil];
}

@end
