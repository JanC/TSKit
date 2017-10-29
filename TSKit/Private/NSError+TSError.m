//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import "NSError+TSError.h"
#import <teamspeak/public_errors.h>
#import <teamspeak/clientlib.h>


@implementation NSError (TSError)


+ (NSString *)ts_errorMessageFromCode:(NSUInteger)error
{
    NSString *message = nil;
    char *cstring;
    if (ts3client_getErrorMessage((unsigned int)error, &cstring) == ERROR_ok) {
        message = [NSString stringWithUTF8String:cstring];
        ts3client_freeMemory(cstring);
    }
    return message;
}

+ (NSError *)ts_errorWithCode:(NSUInteger)errorCode
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[NSLocalizedDescriptionKey] = [self ts_errorMessageFromCode:errorCode];

    return [NSError errorWithDomain:@"com.ts" code:errorCode userInfo:userInfo];
}
@end
