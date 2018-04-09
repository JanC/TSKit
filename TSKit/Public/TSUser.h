//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import <Foundation/Foundation.h>


@interface TSUser : NSObject

@property (nonatomic, assign) uint64_t uid;
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, assign, getter=isMuted) BOOL muted;

- (instancetype)initWithUid:(uint64_t)uid name:(NSString *)name muted:(BOOL) muted;

+ (instancetype)userWithUid:(uint64_t)uid name:(NSString *)name muted:(BOOL) muted;


@end
