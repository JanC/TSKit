//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import "TSClientOptions.h"

@interface TSClientOptions ()

@end

@implementation TSClientOptions

- (instancetype)initWithHost:(NSString *)host port:(NSUInteger)port nickName:(NSString *)nickName password:(NSString *)password receiveOnly:(BOOL)receiveOnly
{
    self = [super init];
    if (self) {
        self.host = host;
        self.port = port;
        self.nickName = nickName;
        self.password = password;
        self.receiveOnly = receiveOnly;
    }

    return self;
}


@end