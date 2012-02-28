#import "SimpleVideoFileFilterViewController.h"

@implementation SimpleVideoFileFilterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
  
    NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:@"sample_iPod" withExtension:@"m4v"];
    
    movieFile = [[GPUImageMovie alloc] initWithURL:sampleURL];
    pixellateFilter = [[GPUImagePixellateFilter alloc] init];
    GPUImageRotationFilter *rotationFilter = [[GPUImageRotationFilter alloc] initWithRotation:kGPUImageRotateRight];
    
    [movieFile addTarget:rotationFilter];
    [rotationFilter addTarget:pixellateFilter];
    GPUImageView *filterView = (GPUImageView *)self.view;
    [pixellateFilter addTarget:filterView];
    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    
//    NSLog(@"Movie: %@", [documentsDirectory stringByAppendingPathComponent:@"Movie.mov"]);
    NSURL *movieURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"Movie.mov"]];
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL];
    [pixellateFilter addTarget:movieWriter];
    
    [movieWriter startRecording];
    [movieFile startProcessing];
    
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [pixellateFilter removeTarget:movieWriter];
        [movieWriter finishRecording];
    });
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)updatePixelWidth:(id)sender
{
    pixellateFilter.fractionalWidthOfAPixel = [(UISlider *)sender value];
}

@end
