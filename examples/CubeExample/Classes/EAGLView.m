#import "EAGLView.h"

#import "ES2Renderer.h"

@implementation EAGLView

// You must implement this method
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

//The EAGL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder
{    
    if ((self = [super initWithCoder:coder]))
    {		
		// Set scaling to account for Retina display	
		if ([self respondsToSelector:@selector(setContentScaleFactor:)])
		{
			self.contentScaleFactor = [[UIScreen mainScreen] scale];
		}
		
        // Get the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;

        eaglLayer.opaque = TRUE;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];

		renderer = [[ES2Renderer alloc] init];
    }

    return self;
}

- (void)dealloc
{
    [renderer release];

    [super dealloc];
}

#pragma mark -
#pragma mark UIView layout methods

- (void)drawView:(id)sender
{
    [renderer renderByRotatingAroundX:0 rotatingAroundY:0];
}

- (void)layoutSubviews
{	
	NSLog(@"Scale factor: %f", self.contentScaleFactor);
    [renderer resizeFromLayer:(CAEAGLLayer*)self.layer];
    [self drawView:nil];
}

#pragma mark -
#pragma mark Touch-handling methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSMutableSet *currentTouches = [[[event touchesForView:self] mutableCopy] autorelease];
    [currentTouches minusSet:touches];
	
	// New touches are not yet included in the current touches for the view
	lastMovementPosition = [[touches anyObject] locationInView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
	CGPoint currentMovementPosition = [[touches anyObject] locationInView:self];
	[renderer renderByRotatingAroundX:(lastMovementPosition.x - currentMovementPosition.x) rotatingAroundY:(lastMovementPosition.y - currentMovementPosition.y)];
	lastMovementPosition = currentMovementPosition;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
	NSMutableSet *remainingTouches = [[[event touchesForView:self] mutableCopy] autorelease];
    [remainingTouches minusSet:touches];

	lastMovementPosition = [[remainingTouches anyObject] locationInView:self];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event 
{
	// Handle touches canceled the same as as a touches ended event
    [self touchesEnded:touches withEvent:event];
}

@end
