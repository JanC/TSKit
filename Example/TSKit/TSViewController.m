//
//  TSViewController.m
//  TSKit
//
//  Created by b6d25604c4d125f66b5ef8e08032a02a755c6590 on 04/24/2019.
//  Copyright (c) 2019 b6d25604c4d125f66b5ef8e08032a02a755c6590. All rights reserved.
//

#import "TSViewController.h"

@import TSKit;

@interface TSViewController ()

@end

@implementation TSViewController

- (void)viewDidLoad
{
    [TSUser sayHello];
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
