//
//  MyAlertViewController.m
//  RemoteNotification
//
//  Created by Александр Карцев on 12/3/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//

#import "MyAlertViewController.h"

@interface MyAlertViewController ()

@end

@implementation MyAlertViewController

+ (instancetype) showAlertWithTitle: (NSString *)title withMessage: (NSString *)message forViewController: (UIViewController *)viewController {
    
    MyAlertViewController *alertController = [MyAlertViewController  alertControllerWithTitle:@"Attention!"  message:message  preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [viewController dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    [viewController presentViewController:alertController animated:YES completion:nil];
    
    return alertController;
}

@end
