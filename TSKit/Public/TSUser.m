//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import "TSUser.h"

@interface TSUser ()

@end

@implementation TSUser

- (instancetype)initWithUid:(uint64_t)uid name:(NSString *)name muted:(BOOL) muted;
{
    self = [super init];
    if (self) {
        self.uid = uid;
        self.name = name;
        self.muted = muted;
    }

    return self;
}

+ (instancetype)userWithUid:(uint64_t)uid name:(NSString *)name muted:(BOOL) muted;
{
    return [[self alloc] initWithUid:uid name:name muted:muted];
}

@end
