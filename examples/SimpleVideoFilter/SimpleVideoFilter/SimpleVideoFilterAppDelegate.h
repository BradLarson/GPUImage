//
//  SimpleVideoFilterAppDelegate.h
//  SimpleVideoFilter
//
//  Created by Brad Larson on 2/12/2012.
//  Copyright (c) 2012 Cell Phone. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SimpleVideoFilterViewController;

@interface SimpleVideoFilterAppDelegate : UIResponder <UIApplicationDelegate>
{
    SimpleVideoFilterViewController *rootViewController;
}

@property (strong, nonatomic) UIWindow *window;

@end
