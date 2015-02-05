//
//  THImageMovieManager.m
//  GPUImage
//
//  Created by Tuo on 2/3/15.
//  Copyright (c) 2015 Brad Larson. All rights reserved.
//

#import "THImageMovieManager.h"

@implementation THImageMovieManager

+ (THImageMovieManager *)shared {
    static THImageMovieManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[THImageMovieManager alloc] init];
        // Do any other initialisation stuff here
    });
    return shared;
}

- (id)init {
    self = [super init];
    if (self) {
        [self setupQueues];
    }

    return self;
}

- (void)setupQueues {
    NSString *serializationQueueDescription = [NSString stringWithFormat:@"%@ serialization queue", self];

    // Create the main serialization queue.
    self.mainSerializationQueue = dispatch_queue_create([serializationQueueDescription UTF8String], NULL);
    NSString *rwAudioSerializationQueueDescription = [NSString stringWithFormat:@"%@ rw audio serialization queue", self];

    // Create the serialization queue to use for reading and writing the audio data.
    self.rwAudioSerializationQueue = dispatch_queue_create([rwAudioSerializationQueueDescription UTF8String], NULL);
    NSString *rwVideoSerializationQueueDescription = [NSString stringWithFormat:@"%@ rw video serialization queue", self];

    // Create the serialization queue to use for reading and writing the video data.
    self.rwVideoSerializationQueue = dispatch_queue_create([rwVideoSerializationQueueDescription UTF8String], NULL);

    self.readingAllReadyDispatchGroup = dispatch_group_create();
}


@end
