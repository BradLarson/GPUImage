#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface ViewController : UIViewController
@property (retain, nonatomic) IBOutlet UILabel *thTimeLabel;

@property (retain, nonatomic) IBOutlet UILabel *gpuTimeLabel;
@property(nonatomic, retain) NSDate *startDate;
@end
