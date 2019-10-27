//
//  NSURL+HCAdditions.h
//

@import Foundation;

@interface NSURL (HCAdditions)

- (NSURL *)URLByAppendingQueryString:(NSString *)queryString;

@end
