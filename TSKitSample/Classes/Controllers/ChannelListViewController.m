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



@interface ChannelListViewController () <TSClientDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray<TSChannel *> *channels;
@property (nonatomic, strong) TSClient *client;
@end

@implementation ChannelListViewController

- (void)viewDidLoad
{
    self.channels = [NSMutableArray array];
    [super viewDidLoad];


    TSClientOptions *options = [[TSClientOptions alloc] initWithHost:@"192.168.0.12"
                                                                port:9986
                                                            nickName:@"ios"
                                                            password:@"12345"
                                                         receiveOnly:YES];


    self.client = [[TSClient alloc] initWithOptions:options];
    self.client.delegate = self;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender
{
    if([segue.identifier isEqualToString:@"ShowChannelSegue"]) {
        ChannelViewController *channelViewController =  segue.destinationViewController;
        channelViewController.client = self.client;

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
    switch(move.visibiliy) {
        case TSChannelVisibilityEnter:
            NSLog(@"%@ joins from %@ to %@", user.name, move.fromChannel.name, move.toChannel.name);
            break;
        case TSChannelVisibilitySwitch:
            NSLog(@"%@ moves from %@ to %@", user.name, move.fromChannel.name, move.toChannel.name);
            break;
        case TSChannelVisibilityLeave:
            NSLog(@"%@ leaves from %@ to %@", user.name, move.fromChannel.name, move.toChannel.name);
            break;
        case TSChannelVisibilityUnknown:
            break;
    }
}


@end
