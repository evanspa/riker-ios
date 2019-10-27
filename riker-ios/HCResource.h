//
//  HCResource.h
//

@import Foundation;
@class HCMediaType;

/**
 Abstraction for an HTTP resource.
 */
@interface HCResource : NSObject

#pragma mark - Initializers

/**
 Creates and returns a new instance with the given data elements.
 @param mediaType the internet media type for the resource (it's type)
 @param uri the identifier for the resource
 @param model the underlying model backing the resource
 @return the created resource instance
*/
- (id)initWithMediaType:(HCMediaType *)mediaType
                    uri:(NSURL *)uri
                  model:(id)model;

/**
 Creates and returns a new instance with the given data elements.
 @param mediaType the internet media type for the resource (it's type)
 @param uri the identifier for the resource
 @return the created resource instance
*/
- (id)initWithMediaType:(HCMediaType *)mediaType
                    uri:(NSURL *)uri;

#pragma mark - Conveniences

- (instancetype)copyWithNewUri:(NSURL *)newUri;

/**
 For when a resource instance is needed, but only the URL is needed/relevant.
 */
+ (instancetype)resourceWithUri:(NSURL *)url;

#pragma mark - Equality

/**
 @param resource the resource with which to compare the receiving resource
 @return a Boolean value that indicates whether the receiving resource is
 equal to the given resource.
*/
- (BOOL)isEqualToResource:(HCResource *)resource;

#pragma mark - Properties

/**
 The media type
 */
@property (nonatomic, readonly) HCMediaType *mediaType;

/**
 The identifier
 */
@property (nonatomic, readonly) NSURL *uri;

/**
 The backing model object
 */
@property (nonatomic, readonly) id model;

#pragma mark - Methods

- (HCResource *)ResourceByAppendingQueryString:(NSString *)queryString;

@end
