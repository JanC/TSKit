//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import "TSHelper.h"
#import "TSUser.h"
#import "TSChannel.h"
#import "NSError+TSError.h"
#import <teamspeak/clientlib.h>
#import <teamspeak/public_errors.h>
#import <teamspeak/public_definitions.h>



@implementation TSHelper


+ (TSChannel *)channelDetails:(UInt64)channelID connectionID:(UInt64) connectionId
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

    char *topic;
    NSString *topicString;
    if ((errorCode = ts3client_getChannelVariableAsString(connectionId, channelID, CHANNEL_TOPIC, &topic)) == ERROR_ok) {
        topicString = [NSString stringWithCString:topic encoding:NSUTF8StringEncoding];
        ts3client_freeMemory(topic);
    } else {
        NSLog(@"Error getting channel topic: %@", [NSError ts_errorMessageFromCode:errorCode]);
    }

    char *description;
    NSString *descriptionString;
    if ((errorCode = ts3client_getChannelVariableAsString(connectionId, channelID, CHANNEL_DESCRIPTION, &description)) == ERROR_ok) {
        descriptionString = [NSString stringWithCString:description encoding:NSUTF8StringEncoding];
        ts3client_freeMemory(description);
    } else {
        NSLog(@"Error getting channel description: %@", [NSError ts_errorMessageFromCode:errorCode]);
    }

    return [TSChannel channelWithUid:channelID name:nameString
                               topic:topicString
                  channelDescription:descriptionString];
}

+ (TSUser *)clientDetails:(UInt64)clientId connectionID:(UInt64)connectionHandlerId
{
    NSUInteger error;
    char *name;
    NSString *nameString = @"unknown";
    
    if ((error = ts3client_getClientVariableAsString(connectionHandlerId, (anyID) clientId, CLIENT_NICKNAME, &name)) == ERROR_ok) {
        nameString = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
    } else {
        NSLog(@"ts3client_getClientVariableAsString: %@", [NSError ts_errorMessageFromCode:error]);
    }
    
    int clientIsMuted;
    if(ts3client_getClientVariableAsInt(connectionHandlerId, clientId, CLIENT_IS_MUTED, &clientIsMuted) != ERROR_ok) {
        NSLog(@"Error querying client muted state");
    }
    
    ts3client_freeMemory(name);
    
    return [TSUser userWithUid:clientId name:nameString muted:clientIsMuted];
    
}


@end
