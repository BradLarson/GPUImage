//
// Created by Tuo on 2/4/15.
// Copyright (c) 2015 Brad Larson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THImageMovieManager : NSObject

+(THImageMovieManager *)shared;

@property(nonatomic) dispatch_queue_t mainSerializationQueue;

@property(nonatomic) dispatch_queue_t rwAudioSerializationQueue;

@property(nonatomic) dispatch_queue_t rwVideoSerializationQueue;

@property(nonatomic) dispatch_group_t readingAllReadyDispatchGroup;

@end
