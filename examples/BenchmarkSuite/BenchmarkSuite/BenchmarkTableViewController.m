#import "BenchmarkTableViewController.h"

typedef enum { GPUIMAGE_BENCHMARK_CPU, GPUIMAGE_BENCHMARK_COREIMAGE, GPUIMAGE_BENCHMARK_GPUIMAGE } GPUImageBenchmarkSection;

@implementation BenchmarkTableViewController

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
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

    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.frame.size.width, 60.0f)];
    
    UIButton *benchmarkButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    benchmarkButton.frame = CGRectMake(60.0f, 20.0f, 200.0f, 40.0f);
    [benchmarkButton setTitle:@"Run Benchmark" forState:UIControlStateNormal];
    [benchmarkButton addTarget:self action:@selector(runBenchmark) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];

    [self.tableView.tableHeaderView addSubview:benchmarkButton];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
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
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
    return NSLocalizedStringFromTable(@"Processing times", @"Localized", nil);

    return nil;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"StillImageBenchmarkCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) 
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        
        cell.detailTextLabel.textColor = [UIColor colorWithRed:50.0f/255.0f green:79.0f/255.0f blue:133.0f/255.0f alpha:1.0f];
        cell.detailTextLabel.highlightedTextColor = [UIColor whiteColor];			
    }
    
    switch (indexPath.row)
    {
        case GPUIMAGE_BENCHMARK_CPU:
        {
            cell.textLabel.text = NSLocalizedStringFromTable(@"CPU", @"Localized", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f ms", processingTimeForCPURoutine];
        }; break;
        case GPUIMAGE_BENCHMARK_COREIMAGE:
        {
            cell.textLabel.text = NSLocalizedStringFromTable(@"Core Image", @"Localized", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f ms", processingTimeForCoreImageRoutine];
        }; break;
        case GPUIMAGE_BENCHMARK_GPUIMAGE:
        {
            cell.textLabel.text = NSLocalizedStringFromTable(@"GPUImage", @"Localized", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f ms", processingTimeForGPUImageRoutine];
        }; break;
        default:
        {
            cell.textLabel.text = NSLocalizedStringFromTable(@"CPU", @"Localized", nil);
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f ms", processingTimeForCPURoutine];
        }
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}


#pragma mark -
#pragma mark Benchmarks

- (void)runBenchmark;
{
    
}

@end
