//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@interface TSChannel : NSObject

@property (nonatomic, assign) uint64_t uid;
@property (nonatomic, copy) NSString *name;

- (instancetype)initWithUid:(uint64_t)uid name:(nullable NSString *)name;

+ (instancetype)channelWithUid:(uint64_t)uid name:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
