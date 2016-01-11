//
//  BackgroundSessionManager.m
//  RemoteNotification
//
//  Created by Александр Карцев on 12/1/15.
//  Copyright © 2015 Alex Kartsev. All rights reserved.
//

#import "BackgroundSessionManager.h"

static NSString * const kBackgroundSessionIdentifier = @"com.AlexKartsev.RemoteNotification";

@implementation BackgroundSessionManager

+ (instancetype)sharedManager
{
    static id sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (instancetype)init
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:kBackgroundSessionIdentifier];
    self = [super initWithSessionConfiguration:configuration];
    if (self) {
        [self configureDownloadFinished];            // when download done, save file
        [self configureBackgroundSessionFinished];   // when entire background session done, call completion handler
    }
    return self;
}

- (void)configureDownloadFinished
{
    // just save the downloaded file to documents folder using filename from URL
    __weak BackgroundSessionManager *weakSelf = self;
    [self setDownloadTaskDidFinishDownloadingBlock:^NSURL *(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location) {
        if ([downloadTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSInteger statusCode = [(NSHTTPURLResponse *)downloadTask.response statusCode];
            if (statusCode != 200) {
                NSLog(@"%@ failed (statusCode = %ld)", [downloadTask.originalRequest.URL lastPathComponent], (long)statusCode);
                return nil;
            }
        }
        if (weakSelf) {
            [weakSelf deleteImageFromDocumentsWithName:@"image"];
        }
        else
        {
            NSLog(@"IMAGE WAS NOT DELETTED");
        }
        NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *path = [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"image.jpg"]];
        return [NSURL fileURLWithPath:path];
    }];
    
    [self setTaskDidCompleteBlock:^(NSURLSession *session, NSURLSessionTask *task, NSError *error) {
        if (error) {
            NSLog(@"%@: %@", [task.originalRequest.URL lastPathComponent], error);
        }
    }];
}

- (void)configureBackgroundSessionFinished
{
    __weak BackgroundSessionManager *weakSelf = self;
    [self setDidFinishEventsForBackgroundURLSessionBlock:^(NSURLSession *session) {
        if (weakSelf.savedCompletionHandler) {
            weakSelf.savedCompletionHandler();
            weakSelf.savedCompletionHandler = nil;
        }
    }];
}

- (void)deleteImageFromDocumentsWithName:(NSString *)imageName
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager removeItemAtPath:[self documentsPathForFileName:imageName] error:&error];
}

- (NSString *)documentsPathForFileName:(NSString *)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *newName = [NSString stringWithFormat:@"%@.jpg",name];
    return [documentsPath stringByAppendingPathComponent:newName];
}

@end

