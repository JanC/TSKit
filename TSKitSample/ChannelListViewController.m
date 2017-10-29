//
//  ChannelListViewController.m
//  TSKitSample
//
//  Created by Jan Chaloupecky on 26.10.17.
//  Copyright © 2017 Tequila Apps. All rights reserved.
//

#import "ChannelListViewController.h"
#import "TSClient.h"
#import "ChannelViewController.h"

@import TSKit;

@interface ChannelListViewController () <TSClientDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray<TSChannel *> *channels;
@property (nonatomic, strong) TSClient *client;
@end

@implementation ChannelListViewController

- (void)viewDidLoad
{

    [super viewDidLoad];

    self.client = [[TSClient alloc] initWithHost:@"localhost"
                                            port:9986
                                  serverNickname:@"ios"
                                  serverPassword:nil
                                     receiveOnly:NO];

    [self.client connectWithCompletion:^(BOOL success, NSError *_Nonnull error) {
        NSLog(@"");
    }];

    self.client.delegate = self;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender
{
    if([segue.identifier isEqualToString:@"ShowChannelSegue"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        TSChannel *channel = self.channels[(NSUInteger) indexPath.row];
        [self.client switchToChannel:channel authCallback:nil];
        
        ChannelViewController *channelViewController =  segue.destinationViewController;
        channelViewController.client = self.client;

//        self.channels[(NSUInteger) indexPath.row];
    }
    [super prepareForSegue:segue sender:sender];
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
    return cell;
}

#pragma mark - UITableViewDelegate

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    TSChannel *channel = self.channels[(NSUInteger) indexPath.row];
//    [self.client switchToChannel:channel authCallback:nil];
//}

#pragma mark - TSClientDelegate

- (void)client:(TSClient *)client connectStatusChanged:(TSConnectionStatus)newStatus
{
    if (newStatus == TSConnectionStatusEstablished) {
        self.channels = [client listChannels];
        [self.tableView reloadData];
        NSLog(@"channels: %@", self.channels);
    }
}

- (void)client:(TSClient *)client clientName:(NSString *)clientName clientID:(int)clientID talkStatusChanged:(BOOL)talking
{
    NSLog(@"%@ is talking %@", clientName, @(talking));
}

- (void)client:(TSClient *)client onConnectionError:(NSError *)error
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Connection Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

    }]];

    [self presentViewController:alertController animated:YES completion:^{

    }];
}


@end
