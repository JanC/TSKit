//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import <Foundation/Foundation.h>


@interface TSUser : NSObject

@property (nonatomic, assign) uint64_t uid;
@property (nonatomic, copy) NSString *name;

- (instancetype)initWithUid:(uint64_t)uid name:(NSString *)name;

+ (instancetype)userWithUid:(uint64_t)uid name:(NSString *)name;


@end