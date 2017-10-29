//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import "TSHelper.h"
#import "TSChannel.h"
#import "NSError+TSError.h"
#import <teamspeak/clientlib.h>
#import <teamspeak/public_errors.h>
#import <teamspeak/public_definitions.h>



@implementation TSHelper


+ (TSChannel *)channelDetails:(NSUInteger)channelID connectionID:(UInt64) connectionId
{
    char *name;
    NSString *nameString = @"";
    NSUInteger errorCode;
    if ((errorCode = ts3client_getChannelVariableAsString(connectionId, channelID, CHANNEL_NAME, &name)) == ERROR_ok) {
        nameString = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        ts3client_freeMemory(name);
    } else {
        NSLog(@"Error getting channel name: %@", [NSError ts_errorMessageFromCode:errorCode]);
    }

    return [TSChannel channelWithUid:channelID name:nameString];
}


@end