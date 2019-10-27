//
// PEHttpUtils.h
//

#import <Foundation/Foundation.h>

/** A collection of HTTP-related helper functions. */
@interface PEHttpUtils : NSObject

#pragma mark - Helpers

/**
 *  Constructs and returns a NSURL instsance from the provided host, port and
 *  scheme.
 *  @param host   The server host name.
 *  @param port   The server port number.
 *  @param scheme The HTTP scheme to use (http or https).
 *  @return The constructed NSURL instance.
 */
+ (NSURL *)urlFromHost:(NSString *)host
                  port:(NSUInteger)port
                scheme:(NSString *)scheme;

@end
