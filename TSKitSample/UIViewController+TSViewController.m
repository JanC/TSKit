//
//  This file is part of Tequila Apps SDK.
//  See the file LICENSE.txt for copying permission.
//

#import "UIViewController+TSViewController.h"

@implementation UIViewController (TSViewController)


- (void)ts_askForPassword:(void (^)(NSString *password))completion
{
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Enter password"
                                                                        message:[NSString stringWithFormat:@"for channel"]
                                                                 preferredStyle:UIAlertControllerStyleAlert];

    [controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Password";
        textField.textColor = [UIColor blueColor];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.secureTextEntry = YES;
    }];

    [controller addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        completion(controller.textFields.firstObject.text);

    }]];

    [self presentViewController:controller animated:YES completion:nil];
}

- (void)ts_showAlert:(NSString *)title message:(NSString *)message
{
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:title
                                                                        message:message
                                                                 preferredStyle:UIAlertControllerStyleAlert];

    [controller addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {


    }]];

    [self presentViewController:controller animated:YES completion:nil];
}
@end