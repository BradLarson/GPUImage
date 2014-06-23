//
//  main.m
//  CubeExample
//
//  Created by Brad Larson on 4/20/2010.
//

#import <UIKit/UIKit.h>
#import "CubeExampleAppDelegate.h"

int main(int argc, char *argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, NSStringFromClass([CubeExampleAppDelegate class]));
    [pool release];
    return retVal;
}
