//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import "ChannelViewController.h"
#import <TSKit/TSKit.h>


@interface ChannelViewController()

@property (nonatomic, strong) NSArray<TSUser*> *users;

@end

@implementation ChannelViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.client listUsersIn:self.client.currentChannel completion:^(NSArray<TSUser*> *users, NSError *error) {

        self.users = users;
        [self.tableView reloadData];

    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.textLabel.text = self.users[(NSUInteger) indexPath.row].name;
    return cell;
}

#pragma mark - Overrides

- (NSString *)title
{
    return self.client.currentChannel.name;
}


@end
