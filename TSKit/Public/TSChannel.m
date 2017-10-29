//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import "TSChannel.h"

@interface TSChannel ()

@end


@implementation TSChannel

- (instancetype)initWithUid:(uint64_t)uid name:(NSString *)name topic:(NSString *)topic channelDescription:(NSString *)channelDescription
{
    self = [super init];
    if (self) {
        self.uid = uid;
        self.name = name;
        self.topic = topic;
        self.channelDescription = channelDescription;
    }

    return self;
}

- (instancetype)initWithUid:(uint64_t)uid
{
    return [self initWithUid:uid name:nil topic:nil channelDescription:nil];
}

+ (instancetype)channelWithUid:(uint64_t)uid name:(NSString *)name topic:(NSString *)topic channelDescription:(NSString *)channelDescription
{
    return [[self alloc] initWithUid:uid name:name topic:topic channelDescription:channelDescription];
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
