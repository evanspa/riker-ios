//
//  HCUtils.m
//

#import "HCUtils.h"
#import "HCHalJsonSerializer.h"
#import "HCResource.h"
#import "PEUtils.h"
#import "HCCharset.h"
#import "HCDeserializedPair.h"
#import "HCMediaType.h"

NSString * const HTTP_DATE_FORMAT_PATTERN = @"EEE, dd MMM yyyy HH:mm:ss z";

@implementation HCUtils

#pragma mark - Private Helpers

+ (BOOL)doesRepresentAbsoluteURL:(NSString *)urlString {
  return [[urlString lowercaseString] hasPrefix:@"http"];
}

#pragma mark - General

+ (NSDictionary *)charsetStringToSysConstant {
  // there are a bunch more, but I'm not bothering with them right now
  return @{ @"UTF-8" : [NSNumber numberWithInt:NSUTF8StringEncoding],
            @"ISO-8859-1" : [NSNumber numberWithInt:NSISOLatin1StringEncoding] };
}

+ (BOOL)isSuccessResponse:(NSHTTPURLResponse *)httpResponse {
  return ([httpResponse statusCode] >= 200) && ([httpResponse statusCode] < 300);
}

#pragma mark - URL related

+ (NSURL *)ResourceURLFromString:(NSString *)urlString
            enclosingResourceURL:(NSURL *)resourceUrl {
  NSURL *url = nil;
  if ([HCUtils doesRepresentAbsoluteURL:urlString]) {
    url = [NSURL URLWithString:urlString];
  } else {
    NSURL *baseUrl;
    if ([urlString hasPrefix:@"/"]) {
      baseUrl = [resourceUrl URLByDeletingPathExtension];
    } else {
      if (![[resourceUrl absoluteString] hasSuffix:@"/"]) {
        baseUrl = [resourceUrl URLByDeletingLastPathComponent];
      } else {
        baseUrl = resourceUrl;
      }
    }
    url = [[NSURL alloc] initWithString:urlString relativeToURL:baseUrl];
  }
  return url;
}

+ (NSString *)locationFromResponse:(NSHTTPURLResponse *)httpResponse {
  return [[httpResponse allHeaderFields] objectForKey:@"location"];
}

+ (NSURL *)locationAsUrlFromResponse:(NSHTTPURLResponse *)httpResp {
  NSString *locStr = [HCUtils locationFromResponse:httpResp];
  if (locStr) {
    return [NSURL URLWithString:locStr];
  }
  return nil;
}

+ (NSDate *)lastModifiedFromResponse:(NSHTTPURLResponse *)httpResp {
  return [HCUtils rfc7231DateFromString:
            [[httpResp allHeaderFields] objectForKey:@"last-modified"]];
}

+ (HCMediaType *)mediaTypeFromResponse:(NSHTTPURLResponse *)httpResp {
  NSString *contentType = [[httpResp allHeaderFields] objectForKey:@"content-type"];
  if (contentType) {
    return [HCMediaType MediaTypeFromString:contentType];
  }
  return nil;
}

+ (NSDate *)rfc7231DateFromString:(NSString *)dateString {
  if (dateString) {
    return [PEUtils dateFromString:dateString
                       withPattern:HTTP_DATE_FORMAT_PATTERN];
  }
  return nil;
}

+ (NSString *)rfc7231StringFromDate:(NSDate *)date {
  return [PEUtils stringFromDate:date withPattern:HTTP_DATE_FORMAT_PATTERN];
}

+ (NSDictionary *)relsFromLocalHalJsonResource:(NSBundle *)bundle
                                      fileName:(NSString *)fileName
                          resourceApiMediaType:(HCMediaType *)mediaType {
  NSURL *resourceUri = [bundle URLForResource:fileName withExtension:@"json"];
  HCResource *resource = [[HCResource alloc] initWithMediaType:mediaType uri:resourceUri];
  HCHalJsonSerializer *halJsonSerializer =
    [[HCHalJsonSerializer alloc]
     initWithMediaType:mediaType charset:[HCCharset UTF8] serializersForEmbeddedResources:@{} actionsForEmbeddedResources:@{}];
  NSData *resourceContents = [NSData dataWithContentsOfURL:[resource uri]];
  return [[halJsonSerializer
            deserializeResourceFromTextData:resourceContents
                          resourceMediaType:[resource mediaType]
                                resourceURL:[resource uri]
                               httpResponse:nil] relations];
}

@end
