//
//  DACircularProgressView+AFNetworking.h
//  Gamer
//
//  Created by Caio Mello on 07/05/2014.
//  Copyright (c) 2014 Caio Mello. All rights reserved.
//

#import "DACircularProgressView.h"

@interface DACircularProgressView (AFNetworking)

- (void)setProgressWithDownloadProgressOfTask:(NSURLSessionDownloadTask *)task animated:(BOOL)animated;

@end
