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
		case GPUIMAGE_GAMMA: cell.textLabel.text = @"Gamma"; break;
        case GPUIMAGE_COLORINVERT: cell.textLabel.text = @"Color invert"; break;
		case GPUIMAGE_SEPIA: cell.textLabel.text = @"Sepia tone"; break;
		case GPUIMAGE_PIXELLATE: cell.textLabel.text = @"Pixellate"; break;
		case GPUIMAGE_SOBELEDGEDETECTION: cell.textLabel.text = @"Sobel edge detection"; break;
		case GPUIMAGE_DISSOLVE: cell.textLabel.text = @"Dissolve blend"; break;
		case GPUIMAGE_MULTIPLY: cell.textLabel.text = @"Multiply blend"; break;
    case GPUIMAGE_OVERLAY: cell.textLabel.text = @"Overlay blend"; break;
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
