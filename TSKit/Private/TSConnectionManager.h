//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import <Foundation/Foundation.h>

@class TSClient;


@interface TSConnectionManager : NSObject

+ (instancetype)sharedManager;

- (void)registerClient:(TSClient *)client;
- (void)unregisterClient:(TSClient *)client;

- (void)initializeLibrary;
@end
