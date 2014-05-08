//
//  DACircularProgressView+AFNetworking.m
//  Gamer
//
//  Created by Caio Mello on 07/05/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "DACircularProgressView+AFNetworking.h"
#import <objc/runtime.h>

static void * AFTaskCountOfBytesSentContext = &AFTaskCountOfBytesSentContext;
static void * AFTaskCountOfBytesReceivedContext = &AFTaskCountOfBytesReceivedContext;

@implementation DACircularProgressView (AFNetworking)

- (BOOL)af_uploadProgressAnimated {
    return [(NSNumber *)objc_getAssociatedObject(self, @selector(af_uploadProgressAnimated)) boolValue];
}

- (BOOL)af_downloadProgressAnimated{
    return [(NSNumber *)objc_getAssociatedObject(self, @selector(af_downloadProgressAnimated)) boolValue];
}

- (void)af_setDownloadProgressAnimated:(BOOL)animated{
    objc_setAssociatedObject(self, @selector(af_downloadProgressAnimated), @(animated), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setProgressWithDownloadProgressOfTask:(NSURLSessionDownloadTask *)task animated:(BOOL)animated{
    [task addObserver:self forKeyPath:@"state" options:0 context:AFTaskCountOfBytesReceivedContext];
    [task addObserver:self forKeyPath:@"countOfBytesReceived" options:0 context:AFTaskCountOfBytesReceivedContext];
	
    [self af_setDownloadProgressAnimated:animated];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(__unused NSDictionary *)change context:(void *)context{
    if (context == AFTaskCountOfBytesSentContext || context == AFTaskCountOfBytesReceivedContext) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(countOfBytesSent))]) {
            if ([object countOfBytesExpectedToSend] > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setProgress:[object countOfBytesSent] / ([object countOfBytesExpectedToSend] * 1.0f) animated:self.af_uploadProgressAnimated];
                });
            }
        }
		
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(countOfBytesReceived))]) {
            if ([object countOfBytesExpectedToReceive] > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setProgress:[object countOfBytesReceived] / ([object countOfBytesExpectedToReceive] * 1.0f) animated:self.af_downloadProgressAnimated];
                });
            }
        }
		
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(state))]) {
            if ([(NSURLSessionTask *)object state] == NSURLSessionTaskStateCompleted) {
                @try {
                    [object removeObserver:self forKeyPath:NSStringFromSelector(@selector(state))];
					
                    if (context == AFTaskCountOfBytesSentContext) {
                        [object removeObserver:self forKeyPath:NSStringFromSelector(@selector(countOfBytesSent))];
                    }
					
                    if (context == AFTaskCountOfBytesReceivedContext) {
                        [object removeObserver:self forKeyPath:NSStringFromSelector(@selector(countOfBytesReceived))];
                    }
                }
                @catch (NSException * __unused exception) {}
            }
        }
    }
}

@end
