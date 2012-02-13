//
//  SimpleVideoFilterViewController.h
//  SimpleVideoFilter
//
//  Created by Brad Larson on 2/12/2012.
//  Copyright (c) 2012 Cell Phone. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface SimpleVideoFilterViewController : UIViewController
{
    GPUImageVideoCamera *videoCamera;
    GPUImagePixellateFilter *pixellateFilter;
}

- (IBAction)updatePixelWidth:(id)sender;

@end
