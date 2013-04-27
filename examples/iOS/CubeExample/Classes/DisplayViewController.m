#import "DisplayViewController.h"

@interface DisplayViewController ()

@end

@implementation DisplayViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    

    return self;
}

- (void)dealloc
{
    [renderer release];
    
    [super dealloc];
}

- (void)loadView
{    
    CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];	
	GPUImageView *primaryView = [[GPUImageView alloc] initWithFrame:mainScreenFrame];
	self.view = primaryView;

    renderer = [[ES2Renderer alloc] initWithSize:[primaryView sizeInPixels]];

    textureInput = [[GPUImageTextureInput alloc] initWithTexture:renderer.outputTexture size:[primaryView sizeInPixels]];
    filter = [[GPUImagePixellateFilter alloc] init];
    [(GPUImagePixellateFilter *)filter setFractionalWidthOfAPixel:0.01];

//    filter = [[GPUImageGaussianBlurFilter alloc] init];
//    [(GPUImageGaussianBlurFilter *)filter setBlurSize:3.0];

    [textureInput addTarget:filter];
    [filter addTarget:primaryView];
    
    [renderer setNewFrameAvailableBlock:^{
        float currentTimeInMilliseconds = [[NSDate date] timeIntervalSinceDate:startTime] * 1000.0;
        
        [textureInput processTextureWithFrameTime:CMTimeMake((int)currentTimeInMilliseconds, 1000)];
    }];
    
    [renderer startCameraCapture];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)drawView:(id)sender
{
    [renderer renderByRotatingAroundX:0 rotatingAroundY:0];
}

#pragma mark -
#pragma mark Touch-handling methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSMutableSet *currentTouches = [[[event touchesForView:self.view] mutableCopy] autorelease];
    [currentTouches minusSet:touches];
	
	// New touches are not yet included in the current touches for the view
	lastMovementPosition = [[touches anyObject] locationInView:self.view];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
	CGPoint currentMovementPosition = [[touches anyObject] locationInView:self.view];
	[renderer renderByRotatingAroundX:(currentMovementPosition.x - lastMovementPosition.x) rotatingAroundY:(lastMovementPosition.y - currentMovementPosition.y)];
	lastMovementPosition = currentMovementPosition;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
	NSMutableSet *remainingTouches = [[[event touchesForView:self.view] mutableCopy] autorelease];
    [remainingTouches minusSet:touches];
    
	lastMovementPosition = [[remainingTouches anyObject] locationInView:self.view];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event 
{
	// Handle touches canceled the same as as a touches ended event
    [self touchesEnded:touches withEvent:event];
}


@end
