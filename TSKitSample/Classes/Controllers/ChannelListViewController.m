//
//  ChannelListViewController.m
//  TSKitSample
//
//  Created by Jan Chaloupecky on 26.10.17.
//  Copyright © 2017 Tequila Apps. All rights reserved.
//

#import "ChannelListViewController.h"
#import "ChannelViewController.h"
#import "UIViewController+TSViewController.h"

#import <TSKit/TSKit.h>



@interface ChannelListViewController () <TSClientDelegate, ChannelViewControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray<TSChannel *> *channels;
@property (nonatomic, strong) TSClient *client;
@property (nonatomic, strong) ChannelViewController *channelViewController;

@property (nonatomic, assign) uint64_t followedUserId;
@end

@implementation ChannelListViewController

- (void)viewDidLoad
{
    self.channels = [NSMutableArray array];
    [super viewDidLoad];


    TSClientOptions *options = [[TSClientOptions alloc] initWithHost:@"192.168.0.10"
                                                                port:9986
                                                            nickName:@"ios"
                                                            password:@"1234"
                                                         receiveOnly:NO];


    self.client = [[TSClient alloc] initWithOptions:options];
    self.client.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if(self.channelViewController != nil) {
        self.channelViewController = nil;

        // move back to the default channel
        //[self.client moveToChannel:[TSChannel defaultChannel] authCallback:nil completion:nil];
    }

}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender
{
    if([segue.identifier isEqualToString:@"ShowChannelSegue"]) {
        self.channelViewController = segue.destinationViewController;
        self.channelViewController.client = self.client;
        self.channelViewController.delegate = self;

    }
    [super prepareForSegue:segue sender:sender];
}


#pragma mark - Actions

-(IBAction)connectAction:(id)sender
{
    [self.client connect:nil completion:^(BOOL success, NSError *_Nonnull error) {
        NSLog(@"");
    }];
}

-(IBAction)disconnectAction:(id)sender
{
    [self.client disconnect];
    [self.channels removeAllObjects];
    [self.tableView reloadData];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.channels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    TSChannel *channel = self.channels[(NSUInteger) indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", @(channel.uid), channel.name];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@", channel.topic, channel.channelDescription];

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TSChannel *channel = self.channels[(NSUInteger) indexPath.row];
    [self navigateToChannel:channel];
}

#pragma mark - ChannelViewControllerDelegate

-(void) channelViewController:(ChannelViewController*) controller didSelectUser:(TSUser *) user {
    NSString *title = [NSString stringWithFormat:@"User %@", user.name];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];



    UIAlertAction *muteAction = [UIAlertAction actionWithTitle: user.isMuted ? @"Unmute" : @"Mute" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSError *error;
        NSLog(@"Muting user: %@ mute: %@", user.name, @(!user.isMuted));
        BOOL success = [self.client muteUser:user mute:!user.isMuted error:&error];
        [controller reload];

        if(!success) {
            NSLog(@"Failed to mute user: %@", user);
        }

    }];


    UIAlertAction *followAction = [UIAlertAction actionWithTitle: [self isFollowing:user.uid] ? @"UnFollow" : @"Follow" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.followedUserId = [self isFollowing:user.uid] ? 0 : user.uid;
    }];

    [alertController addAction:muteAction];
    [alertController addAction:followAction];

    [self presentViewController:alertController animated:YES completion:nil];

}

-(BOOL) isFollowing:(uint64_t) userId {
    return self.followedUserId == userId;
}
#pragma mark - TSClientDelegate

- (void)client:(TSClient *)client connectStatusChanged:(TSConnectionStatus)status
{
    NSLog(@"Connection status: %@", @(status));
    
    if (status == TSConnectionStatusEstablished) {
        [self.tableView reloadData];
        NSLog(@"channels: %@", self.channels);
    }
}

- (void)client:(TSClient *)client user:(TSUser *)user talkStatusChanged:(BOOL)talking;
{
    NSLog(@"%@ is talking %@ in %@", [NSString stringWithFormat:@"%@%@", user.name, user.isMuted ? @" (muted)" : @""], @(talking), client.currentChannel.name);
}

- (void)client:(TSClient *)client onConnectionError:(NSError *)error
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Connection Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

    }]];

    [self presentViewController:alertController animated:YES completion:^{

    }];
}

- (void)client:(TSClient *)client didReceivedChannel:(TSChannel *)channel
{
    NSArray<TSUser*> *users = [client listUsersInChannel:channel error:nil];
    NSLog(@"Users in %@: %@", channel.name, users);

    [self.channels addObject:channel];
    [self.tableView reloadData];
}

- (void)client:(TSClient *)client didDeleteChannel:(NSUInteger)channelId
{
    [self.channels filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(TSChannel *currentChannel, NSDictionary*bindings) {
        return currentChannel.uid != channelId;
    }]];

    [self.tableView reloadData];
}

- (void)client:(TSClient *)client user:(TSUser *)user didMove:(TSChannelMove *)move
{

    // add the user to the user channel list if needed
    if(self.channelViewController && self.client.currentChannel.uid == move.toChannel.uid) {
        [self.channelViewController addUser:user];
    }

    // remove the user to the user channel list if needed
    if(self.channelViewController && self.client.currentChannel.uid == move.fromChannel.uid) {
        [self.channelViewController removeUser:user];
    }

    switch(move.visibiliy) {
        case TSChannelVisibilityEnter:

            NSLog(@"%@ joins from %@ to %@", user, move.fromChannel, move.toChannel);
            break;
        case TSChannelVisibilitySwitch:
            NSLog(@"%@ moves from %@ to %@", user, move.fromChannel, move.toChannel);
            break;
        case TSChannelVisibilityLeave:
            NSLog(@"%@ leaves from %@ to %@", user, move.fromChannel, move.toChannel);

            break;
        case TSChannelVisibilityUnknown:
            NSLog(@"Unknown visibility for user %@ from %@ to %@", user, move.fromChannel, move.toChannel);
            break;
    }

    [self followUser:user toChannel:move.toChannel];

}

-(void) followUser:(TSUser *)user toChannel:(TSChannel *) channel
{
    if(self.client.ownClientID == user.uid) {
        NSLog(@"Not following self move") ;
        return;
    }
    
    if(![self isFollowing:user.uid]) {
        NSLog(@"Not following unfollowed user '%@'", user.name) ;
        return;
    }

    NSLog(@"Follow user to %@ (id: %@)", channel.name, @(channel.uid));
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self navigateToChannel:channel];
}

-(void) navigateToChannel:(TSChannel*) channel {

    // we are already in this channel
    if (channel.uid == self.client.currentChannel.uid) {
        [self performSegueWithIdentifier:@"ShowChannelSegue" sender:nil];
        return;
    }

    [self.client moveToChannel:channel authCallback:^(TSClientAuthCallback authCallback) {
        [self ts_askForPassword:^(NSString *password) {
            authCallback(password);
        }];
    } completion:^(BOOL success, NSError *error) {
        if (!success) {
            [self ts_showAlert:@"Could not move to channel" message:error.localizedDescription];
            return;
        }
        [self performSegueWithIdentifier:@"ShowChannelSegue" sender:nil];
    }];
}


@end
