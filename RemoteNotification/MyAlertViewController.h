//
//  MyAlertViewController.h
//  RemoteNotification
//
//  Created by Александр Карцев on 12/3/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyAlertViewController : UIAlertController

+ (instancetype) showAlertWithTitle: (NSString *)title withMessage: (NSString *)message forViewController: (UIViewController *)viewController;

@end
