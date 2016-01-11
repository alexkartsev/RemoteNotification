//
//  AppDelegate.m
//  RemoteNotification
//
//  Created by Александр Карцев on 11/27/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse.h>
#import <AFNetworking/AFNetworking.h>
#import "BackgroundSessionManager.h"
#import "ViewController.h"
#import <UIAlertController+Blocks/UIAlertController+Blocks.h>




#ifdef DEBUG
#define DLog(...) NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat:__VA_ARGS__])
#else
#define DLog(...)
#endif

@interface AppDelegate ()

@end

@implementation AppDelegate

static NSString * const kApplicationId = @"gAU7TbFjPQACmhw8YaRSKfgKF7MdxgZkv8yoq4CG";
static NSString * const kClientKey = @"VwydwgVBj7TXCVI48bA2RiBjOvvkoqimE2qKrKHz";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Parse setApplicationId:kApplicationId
                  clientKey:kClientKey];
    
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
    
    NSDictionary *retrievedDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:nameOfDictInNSUserDefaults];
    if (!retrievedDictionary) {
        NSMutableDictionary *dic = [[NSMutableDictionary  alloc] init];
        [[NSUserDefaults standardUserDefaults] setObject:dic forKey:nameOfDictInNSUserDefaults];
    }
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application{
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    NSAssert([[BackgroundSessionManager sharedManager].session.configuration.identifier isEqualToString:identifier], @"Identifiers didn't match");
    [BackgroundSessionManager sharedManager].savedCompletionHandler = completionHandler;
}


- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler{
    if ([self validateUrl:[userInfo valueForKey:@"url"]]) {
        [PFPush handlePush:userInfo];
        [BackgroundSessionManager sharedManager].numOfDownloadings ++;
        [self setValue:@"Downloading" toUrl:[userInfo valueForKey:@"url"]];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[userInfo valueForKey:@"url"]]];
        [[[BackgroundSessionManager sharedManager] downloadTaskWithRequest:request
                                                                  progress:nil
                                                               destination:nil
                                                         completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                             completionHandler(UIBackgroundFetchResultNewData);
                                                             [BackgroundSessionManager sharedManager].numOfDownloadings --;
                                                             if (![BackgroundSessionManager sharedManager].numOfDownloadings) {
                                                                 [BackgroundSessionManager sharedManager].isProcessing = NO;
                                                             }
                                                             [self setValue:@"Success" toUrl:[userInfo valueForKey:@"url"]];
                                                         }] resume];
        [BackgroundSessionManager sharedManager].isProcessing = YES;
    }
    else {
        [self setValue:@"WrongURL" toUrl:[userInfo valueForKey:@"url"]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WrongURL" object:[userInfo valueForKey:@"url"]];
        completionHandler(UIBackgroundFetchResultNewData);
    }
}

- (BOOL)validateUrl: (NSString *)candidate {
    NSURL *candidateURL = [NSURL URLWithString:candidate];
    if (candidateURL && candidateURL.scheme && candidateURL.host) {
        return YES;
    }
    else {
        return NO;
    }
}

- (void) setValue:(NSString *)value toUrl:(NSString *)stringURL {
    NSMutableDictionary *retrievedDictionary = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:nameOfDictInNSUserDefaults] mutableCopy];
    [retrievedDictionary setObject:value forKey:stringURL];
    [[NSUserDefaults standardUserDefaults] setObject:retrievedDictionary forKey:nameOfDictInNSUserDefaults];
}


- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    currentInstallation.channels = @[ @"global" ];
    [currentInstallation saveEventually];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == 3010) {
        NSLog(@"Push notifications are not supported in the iOS Simulator.");
    } else {
        // show some alert or otherwise handle the failure to register.
        NSLog(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
    }
}

@end
