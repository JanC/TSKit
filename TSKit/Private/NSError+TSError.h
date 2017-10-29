//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import <Foundation/Foundation.h>

@interface NSError (TSError)

+ (NSString *)ts_errorMessageFromCode:(NSUInteger)error;

+ (NSError *)ts_errorWithCode:(NSUInteger)errorCode;

@end