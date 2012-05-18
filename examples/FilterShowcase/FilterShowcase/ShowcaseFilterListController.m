#import "ShowcaseFilterListController.h"
#import "ShowcaseFilterViewController.h"

@interface ShowcaseFilterListController ()

@end

@implementation ShowcaseFilterListController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Filter List";
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return GPUIMAGE_NUMFILTERS;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger index = [indexPath row];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FilterCell"];
	if (cell == nil) 
	{
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"FilterCell"];
		cell.textLabel.textColor = [UIColor blackColor];
	}		
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
	switch (index)
	{
		case GPUIMAGE_SATURATION: cell.textLabel.text = @"Saturation"; break;
		case GPUIMAGE_CONTRAST: cell.textLabel.text = @"Contrast"; break;
		case GPUIMAGE_BRIGHTNESS: cell.textLabel.text = @"Brightness"; break;
		case GPUIMAGE_EXPOSURE: cell.textLabel.text = @"Exposure"; break;
        case GPUIMAGE_RGB: cell.textLabel.text = @"RGB"; break;
		case GPUIMAGE_SHARPEN: cell.textLabel.text = @"Sharpen"; break;
		case GPUIMAGE_UNSHARPMASK: cell.textLabel.text = @"Unsharp mask"; break;
		case GPUIMAGE_GAMMA: cell.textLabel.text = @"Gamma"; break;
		case GPUIMAGE_HAZE: cell.textLabel.text = @"Haze"; break;
        case GPUIMAGE_HISTOGRAM: cell.textLabel.text = @"Histogram"; break;
		case GPUIMAGE_THRESHOLD: cell.textLabel.text = @"Threshold"; break;
		case GPUIMAGE_ADAPTIVETHRESHOLD: cell.textLabel.text = @"Adaptive threshold"; break;
        case GPUIMAGE_CROP: cell.textLabel.text = @"Crop"; break;
        case GPUIMAGE_TRANSFORM: cell.textLabel.text = @"Transform (2-D)"; break;
        case GPUIMAGE_TRANSFORM3D: cell.textLabel.text = @"Transform (3-D)"; break;
		case GPUIMAGE_MASK: cell.textLabel.text = @"Mask"; break;
        case GPUIMAGE_COLORINVERT: cell.textLabel.text = @"Color invert"; break;
        case GPUIMAGE_GRAYSCALE: cell.textLabel.text = @"Grayscale"; break;
		case GPUIMAGE_SEPIA: cell.textLabel.text = @"Sepia tone"; break;
		case GPUIMAGE_PIXELLATE: cell.textLabel.text = @"Pixellate"; break;
		case GPUIMAGE_POLARPIXELLATE: cell.textLabel.text = @"Polar pixellate"; break;
		case GPUIMAGE_CROSSHATCH: cell.textLabel.text = @"Crosshatch"; break;
		case GPUIMAGE_SOBELEDGEDETECTION: cell.textLabel.text = @"Sobel edge detection"; break;
		case GPUIMAGE_PREWITTEDGEDETECTION: cell.textLabel.text = @"Prewitt edge detection"; break;
		case GPUIMAGE_CANNYEDGEDETECTION: cell.textLabel.text = @"Canny edge detection"; break;
		case GPUIMAGE_XYGRADIENT: cell.textLabel.text = @"XY derivative"; break;
		case GPUIMAGE_HARRISCORNERDETECTION: cell.textLabel.text = @"Harris corner detection"; break;
		case GPUIMAGE_SKETCH: cell.textLabel.text = @"Sketch"; break;
		case GPUIMAGE_TOON: cell.textLabel.text = @"Toon"; break;
		case GPUIMAGE_SMOOTHTOON: cell.textLabel.text = @"Smooth toon"; break;
		case GPUIMAGE_TILTSHIFT: cell.textLabel.text = @"Tilt shift"; break;
		case GPUIMAGE_CGA: cell.textLabel.text = @"CGA colorspace"; break;
		case GPUIMAGE_CONVOLUTION: cell.textLabel.text = @"3x3 convolution"; break;
		case GPUIMAGE_EMBOSS: cell.textLabel.text = @"Emboss"; break;
		case GPUIMAGE_POSTERIZE: cell.textLabel.text = @"Posterize"; break;
		case GPUIMAGE_SWIRL: cell.textLabel.text = @"Swirl"; break;
		case GPUIMAGE_BULGE: cell.textLabel.text = @"Bulge"; break;
		case GPUIMAGE_PINCH: cell.textLabel.text = @"Pinch"; break;
		case GPUIMAGE_STRETCH: cell.textLabel.text = @"Stretch"; break;
        case GPUIMAGE_PERLINNOISE: cell.textLabel.text = @"Perlin noise"; break;
        case GPUIMAGE_VORONI: cell.textLabel.text = @"Voroni"; break;
        case GPUIMAGE_MOSAIC: cell.textLabel.text = @"Mosaic"; break;
		case GPUIMAGE_CHROMAKEY: cell.textLabel.text = @"Chroma key (green)"; break;
		case GPUIMAGE_DISSOLVE: cell.textLabel.text = @"Dissolve blend"; break;
		case GPUIMAGE_SCREENBLEND: cell.textLabel.text = @"Screen blend"; break;
		case GPUIMAGE_COLORBURN: cell.textLabel.text = @"Color burn blend"; break;
		case GPUIMAGE_COLORDODGE: cell.textLabel.text = @"Color dodge blend"; break;
		case GPUIMAGE_MULTIPLY: cell.textLabel.text = @"Multiply blend"; break;
	    case GPUIMAGE_OVERLAY: cell.textLabel.text = @"Overlay blend"; break;
	    case GPUIMAGE_LIGHTEN: cell.textLabel.text = @"Lighten blend"; break;
	    case GPUIMAGE_DARKEN: cell.textLabel.text = @"Darken blend"; break;
	    case GPUIMAGE_EXCLUSIONBLEND: cell.textLabel.text = @"Exclusion blend"; break;
	    case GPUIMAGE_DIFFERENCEBLEND: cell.textLabel.text = @"Difference blend"; break;
		case GPUIMAGE_SUBTRACTBLEND: cell.textLabel.text = @"Subtract blend"; break;
	    case GPUIMAGE_HARDLIGHTBLEND: cell.textLabel.text = @"Hard light blend"; break;
	    case GPUIMAGE_SOFTLIGHTBLEND: cell.textLabel.text = @"Soft light blend"; break;
        case GPUIMAGE_KUWAHARA: cell.textLabel.text = @"Kuwahara"; break;
        case GPUIMAGE_VIGNETTE: cell.textLabel.text = @"Vignette"; break;
        case GPUIMAGE_GAUSSIAN: cell.textLabel.text = @"Gaussian blur"; break;
        case GPUIMAGE_FASTBLUR: cell.textLabel.text = @"Fast blur"; break;
        case GPUIMAGE_MEDIAN: cell.textLabel.text = @"Median (3x3)"; break;
        case GPUIMAGE_BILATERAL: cell.textLabel.text = @"Bilateral blur"; break;
        case GPUIMAGE_BOXBLUR: cell.textLabel.text = @"Box blur"; break;
        case GPUIMAGE_GAUSSIAN_SELECTIVE: cell.textLabel.text = @"Gaussian selective blur"; break;
		case GPUIMAGE_CUSTOM: cell.textLabel.text = @"Custom"; break;
        case GPUIMAGE_FILECONFIG: cell.textLabel.text = @"Filter Chain"; break;
        case GPUIMAGE_FILTERGROUP: cell.textLabel.text = @"Filter Group"; break;
	}
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ShowcaseFilterViewController *filterViewController = [[ShowcaseFilterViewController alloc] initWithFilterType:indexPath.row];
    [self.navigationController pushViewController:filterViewController animated:YES];
}

@end
