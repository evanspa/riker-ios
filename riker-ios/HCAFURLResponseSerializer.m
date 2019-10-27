//
//  HCAFURLResponseSerializer.m
//

#import "HCAFURLResponseSerializer.h"
#import "HCMediaType.h"
#import "HCResourceSerializer.h"
#import "RLogging.h"

@implementation HCAFURLResponseSerializer {
  id<HCResourceSerializer> _hcserializer;
}

#pragma mark - Initializers

- (id)initWithHCSerializer:(id<HCResourceSerializer>)hcserializer {
  self = [super init];
  if (self) {
    _hcserializer = hcserializer;
  }
  return self;
}

#pragma mark - AFURLResponseSerialization protocol

- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error {
  NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  DDLogInfo(@"(HCAFURLResponseSerializer/responseObjectForResponse:) HTTP \
response: [%@].  Response body (assuming UTF-8 encoding): [%@].", response,
             responseStr);
  NSString *contentTypeStr = [response MIMEType];
  HCMediaType *mediaType = nil;
  if (contentTypeStr) {
    mediaType = [HCMediaType MediaTypeFromString:contentTypeStr];
  }
  NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
  // don't try to parse 503 response because it'll be some default text/html
  // content from nginx or something meant for a human
  if (!(httpResp.statusCode == 503)) {
    return [_hcserializer deserializeResourceFromTextData:data
                                        resourceMediaType:mediaType
                                              resourceURL:[response URL]
                                             httpResponse:(NSHTTPURLResponse *)response];
  }
  return nil;
}

@end
