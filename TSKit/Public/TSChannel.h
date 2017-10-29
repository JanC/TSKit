//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface TSChannel : NSObject

@property (nonatomic, assign) UInt64 uid;
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy, nullable) NSString *topic;
@property (nonatomic, copy, nullable) NSString *channelDescription;


- (instancetype)initWithUid:(uint64_t)uid
                       name:(nullable NSString *)name
                      topic:(nullable NSString *)topic
         channelDescription:(nullable NSString *)channelDescription;

- (instancetype)initWithUid:(uint64_t)uid;

+ (instancetype)channelWithUid:(uint64_t)uid name:(NSString *)name topic:(NSString *)topic channelDescription:(NSString *)channelDescription;


@end

NS_ASSUME_NONNULL_END
