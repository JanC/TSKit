//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import "TSChannel.h"

@interface TSChannel ()

@end


@implementation TSChannel

- (instancetype)initWithUid:(uint64_t)uid name:(NSString *)name
{
    self = [super init];
    if (self) {
        self.uid = uid;
        self.name = name;
    }

    return self;
}

+ (instancetype)channelWithUid:(uint64_t)uid name:(NSString *)name
{
    return [[self alloc] initWithUid:uid name:name];
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.uid=%llu", self.uid];
    [description appendFormat:@", self.name=%@", self.name];
    [description appendString:@">"];
    return description;
}


@end
