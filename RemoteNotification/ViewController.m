//
//  ViewController.m
//  RemoteNotification
//
//  Created by Александр Карцев on 11/27/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//
#import "ViewController.h"
#import "BackgroundSessionManager.h"
#import <UIAlertController+Blocks/UIAlertController+Blocks.h>
#import "MyAlertViewController.h"

@interface ViewController ()

@property (nonatomic, assign) BOOL isHasFailedDownloads;
@property (nonatomic, assign) BOOL isHasWrongURLs;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSData *jpgData = [NSData dataWithContentsOfFile:[self documentsPathForFileName:@"image"]];
    if (jpgData) {
        self.myImageView.image = [UIImage imageWithData:jpgData];
    }
    else
    {
        self.myImageView.image = nil;
        NSLog(@"NO IMAGE");
    }
    NSDictionary *retrievedDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:nameOfDictInNSUserDefaults];
    NSArray* arrayOfKeys = [retrievedDictionary allKeysForObject:@"Downloading"];
    if (arrayOfKeys.count){
        self.isHasFailedDownloads = YES;
    }
    NSArray* arrayOfKeysForWrongURL = [retrievedDictionary allKeysForObject:@"WrongURL"];
    if (arrayOfKeysForWrongURL.count){
        self.isHasWrongURLs = YES;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wrongURLWasReceived:) name:@"WrongURL" object:nil];
}

- (void) setValue: (NSString *) value toUrl:(NSString *) stringURL{
    NSMutableDictionary *retrievedDictionary = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:nameOfDictInNSUserDefaults] mutableCopy];
    [retrievedDictionary setObject:value forKey:stringURL];
    [[NSUserDefaults standardUserDefaults] setObject:retrievedDictionary forKey:nameOfDictInNSUserDefaults];
}

- (void)viewWillAppear:(BOOL)animated{
    [[BackgroundSessionManager sharedManager] addObserver:self
                                               forKeyPath:@"isProcessing"
                                                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                                                  context:nil];
    [super viewWillAppear:YES];
}

- (void)viewDidAppear:(BOOL)animated{
    if ([BackgroundSessionManager sharedManager].isProcessing) {
        if (!self.hud) {
            self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        }
    }
    else if (self.isHasFailedDownloads) {
        NSDictionary *retrievedDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:nameOfDictInNSUserDefaults];
        NSArray* arrayOfKeys = [retrievedDictionary allKeysForObject:@"Downloading"];
        if (arrayOfKeys.count) {
            [BackgroundSessionManager sharedManager].isProcessing = YES;
            [MyAlertViewController showAlertWithTitle:@"Attention!" withMessage:@"Sorry, you have unfinished downloads. Keep calm, the situation will be correct soon" forViewController:self];
            for (int i=0;i<arrayOfKeys.count;i++) {
                NSString *url = [arrayOfKeys objectAtIndex:i];
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
                [[[BackgroundSessionManager sharedManager] downloadTaskWithRequest:request
                                                                          progress:nil
                                                                       destination:nil
                                                                 completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                                     if (i == (arrayOfKeys.count-1)) {
                                                                         [BackgroundSessionManager sharedManager].isProcessing = NO;
                                                                         self.isHasFailedDownloads= NO;
                                                                     }
                                                                     [self setValue:@"Success" toUrl:url];
                                                                 }] resume];
            }
        }
    }
    if (self.isHasWrongURLs) {
        [MyAlertViewController showAlertWithTitle:@"Attention" withMessage:@"URLs in some your Push Notifications are invalid" forViewController:self];
        NSDictionary *retrievedDictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey:nameOfDictInNSUserDefaults];
        NSArray* arrayOfKeys = [retrievedDictionary allKeysForObject:@"WrongURL"];
        for (NSString *url in arrayOfKeys) {
            [self setValue:@"WrongURLWasShowed" toUrl:url];
        }
    }
    [super viewDidAppear:YES];
}

- (void)wrongURLWasReceived: (NSNotification *)notification {
    [MyAlertViewController showAlertWithTitle:@"Attention" withMessage:@"URL in Push Notification is invalid" forViewController:self];
    [self setValue:@"WrongURLWasShowed" toUrl:notification.object];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqual:@"isProcessing"]) {
        if ([[change valueForKey:@"new"] isEqualToNumber:@YES]) {
            self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        }
        else if ([[change valueForKey:@"old"] isEqualToNumber:@YES]){
            [self updateImage];
        }
    }
}

- (void)updateImage {
    NSData *jpgData = [NSData dataWithContentsOfFile:[self documentsPathForFileName:@"image"]];
    if (jpgData) {
        self.myImageView.image = [UIImage imageWithData:jpgData];
    }
    else
    {
        self.myImageView.image = nil;
    }
    
    if (self.hud) {
        [self.hud hide:YES];
    }
}

- (NSString *)documentsPathForFileName:(NSString *)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *newName = [NSString stringWithFormat:@"%@.jpg",name];
    return [documentsPath stringByAppendingPathComponent:newName];
}

- (void)viewWillDisappear:(BOOL)animated{
    [[BackgroundSessionManager sharedManager] removeObserver:self forKeyPath:@"isProcessing" context:nil];
    [super viewWillDisappear:YES];
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"WrongURL" object:nil];
}

@end
