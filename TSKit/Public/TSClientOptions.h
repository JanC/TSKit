//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TSClientOptions : NSObject

/// TeamSpeak server host
@property (nonatomic, copy) NSString *host;

/// TeamSpeak server port
@property (nonatomic, assign) NSUInteger port;

/// Your TeamSpeak nick name
@property (nonatomic, copy) NSString *nickName;

/// Optional TeamSpeak server password
@property (nonatomic, copy, nullable) NSString *password;


/**
 * If `YES`, the connection will be made only for listening without transmitting.
 * If `NO`, the client will setup a capture device which requires the iOS user permissions.
 */
@property (nonatomic, assign) BOOL receiveOnly;

- (instancetype)initWithHost:(NSString *)host
                        port:(NSUInteger)port
                    nickName:(NSString *)nickName
                    password:(nullable NSString *)password
                 receiveOnly:(BOOL)receiveOnly NS_DESIGNATED_INITIALIZER;



-(instancetype) init NS_UNAVAILABLE;
-(instancetype) new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
