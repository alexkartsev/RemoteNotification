//
//  BackgroundSessionManager.h
//  RemoteNotification
//
//  Created by Александр Карцев on 12/1/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@interface BackgroundSessionManager : AFHTTPSessionManager

+ (instancetype)sharedManager;

@property (nonatomic, copy) void (^savedCompletionHandler)(void);
@property (nonatomic, assign) BOOL isProcessing;
@property (nonatomic, assign) NSInteger numOfDownloadings;

@end
