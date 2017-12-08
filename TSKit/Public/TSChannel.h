//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface TSChannel : NSObject

@property (nonatomic, assign) UInt64 uid;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy, nullable) NSString *topic;
@property (nonatomic, copy, nullable) NSString *channelDescription;


- (instancetype)initWithUid:(uint64_t)uid
                       name:(nullable NSString *)name
                      topic:(nullable NSString *)topic
         channelDescription:(nullable NSString *)channelDescription;

- (instancetype)initWithUid:(uint64_t)uid;

- (instancetype)initWithName:(NSString*) name;

+ (instancetype)channelWithUid:(uint64_t)uid
                          name:(nullable NSString *)name
                         topic:(nullable NSString *)topic
            channelDescription:(nullable NSString *)channelDescription;


@end

NS_ASSUME_NONNULL_END
