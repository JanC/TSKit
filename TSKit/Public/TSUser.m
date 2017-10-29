//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import "TSUser.h"

@interface TSUser ()

@end

@implementation TSUser

- (instancetype)initWithUid:(uint64_t)uid name:(NSString *)name
{
    self = [super init];
    if (self) {
        self.uid = uid;
        self.name = name;
    }

    return self;
}

+ (instancetype)userWithUid:(uint64_t)uid name:(NSString *)name
{
    return [[self alloc] initWithUid:uid name:name];
}

@end