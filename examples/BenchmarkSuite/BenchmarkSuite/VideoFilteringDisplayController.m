#import "VideoFilteringDisplayController.h"

@implementation VideoFilteringDisplayController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self displayVideoForCPU];
    [self displayVideoForCoreImage];
    [self displayVideoForGPUImage];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Video filtering

- (void)displayVideoForCPU;
{
    
}

- (void)displayVideoForCoreImage;
{
    
}

- (void)displayVideoForGPUImage;
{
    
}

#pragma mark -
#pragma mark Accessors

@synthesize delegate;

@end
