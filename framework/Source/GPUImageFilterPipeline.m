#import "GPUImageFilterPipeline.h"

@interface GPUImageFilterPipeline ()

- (BOOL) _parseConfiguration:(NSDictionary *)configuration;
- (void) _refreshFilters;

@end

@implementation GPUImageFilterPipeline

@synthesize filters = _filters, input = _input, output = _output;

#pragma mark Config file init

- (id) initWithConfiguration:(NSDictionary*) configuration input:(GPUImageOutput*)input output:(id <GPUImageInput>)output {
    self = [super init];
    if (self) {
        self.input = input;
        self.output = output;
        if (![self _parseConfiguration:configuration]) {
            NSLog(@"Sorry, a parsing error occurred.");
            abort();
        }
        [self _refreshFilters];
    }
    return self;
}

- (id) initWithConfigurationFile:(NSURL*) configuration input:(GPUImageOutput*)input output:(id <GPUImageInput>)output {
    return [self initWithConfiguration:[NSDictionary dictionaryWithContentsOfURL:configuration] input:input output:output];
}

- (BOOL) _parseConfiguration:(NSDictionary *)configuration {
    NSArray *filters = [configuration objectForKey:@"Filters"];
    if (!filters) return NO;
    
    NSError *regexError = nil;
    NSRegularExpression *parsingRegex = [NSRegularExpression regularExpressionWithPattern:@"(float|CGPoint|NSString)\\((.*?)(?:,\\s*(.*?))*\\)"
                                                                                  options:0
                                                                                    error:&regexError];
    
    // It's faster to put them into an array and then pass it to the filters property than it is to call [self addFilter:] every time
    NSMutableArray *orderedFilters = [NSMutableArray arrayWithCapacity:[filters count]];
    for (NSDictionary *filter in filters) {
        NSString *filterName = [filter objectForKey:@"FilterName"];
        Class theClass = NSClassFromString(filterName);
        GPUImageFilter *genericFilter = [[theClass alloc] init];
        // Set up the properties
        NSDictionary *filterAttributes;
        if ((filterAttributes = [filter objectForKey:@"Attributes"])) {
            for (NSString *propertyKey in filterAttributes) {
                // Set up the selector
                SEL theSelector = NSSelectorFromString(propertyKey);
                NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[theClass instanceMethodSignatureForSelector:theSelector]];
                [inv setSelector:theSelector];
                [inv setTarget:genericFilter];
                
                // Parse the argument
                NSString *stringValue = nil;
                NSString *string = [filterAttributes objectForKey:propertyKey];
                NSTextCheckingResult *parse = [parsingRegex firstMatchInString:string
                                                                       options:0
                                                                         range:NSMakeRange(0, [string length])];
                NSLog(@"Ranges: %d", parse.numberOfRanges);
                NSString *modifier = [string substringWithRange:[parse rangeAtIndex:1]];
                if ([modifier isEqualToString:@"float"]) {
                    // Float modifier, one argument
                    CGFloat value = [[string substringWithRange:[parse rangeAtIndex:2]] floatValue];
                    [inv setArgument:&value atIndex:2];
                } else if ([modifier isEqualToString:@"CGPoint"]) {
                    // CGPoint modifier, two float arguments
                    CGFloat x = [[string substringWithRange:[parse rangeAtIndex:2]] floatValue];
                    CGFloat y = [[string substringWithRange:[parse rangeAtIndex:3]] floatValue];
                    CGPoint value = CGPointMake(x, y);
                    [inv setArgument:&value atIndex:2];
                } else if ([modifier isEqualToString:@"NSString"]) {
                    // NSString modifier, one string argument
                    stringValue = [[string substringWithRange:[parse rangeAtIndex:2]] copy];
                    [inv setArgument:&stringValue atIndex:2];
                } else {
                    return NO;
                }
                
                [inv invoke];
            }
        }
        [orderedFilters addObject:genericFilter];
    }
    self.filters = orderedFilters;
    
    return YES;
}

#pragma mark Regular init

- (id) initWithOrderedFilters:(NSArray*) filters input:(GPUImageOutput*)input output:(id <GPUImageInput>)output {
    self = [super init];
    if (self) {
        self.input = input;
        self.output = output;
        self.filters = [NSMutableArray arrayWithArray:filters];
        [self _refreshFilters];
    }
    return self;
}

- (void) addFilter:(GPUImageFilter*)filter atIndex:(NSUInteger)insertIndex {
    [self.filters insertObject:filter atIndex:insertIndex];
    [self _refreshFilters];
}

- (void) addFilter:(GPUImageFilter*)filter {
    [self.filters addObject:filter];
    [self _refreshFilters];
}

- (void) replaceFilterAtIndex:(NSUInteger)index withFilter:(GPUImageFilter*)filter {
    [self.filters replaceObjectAtIndex:index withObject:filter];
    [self _refreshFilters];
}

- (void) removeFilterAtIndex:(NSUInteger)index {
    [self.filters removeObjectAtIndex:index];
    [self _refreshFilters];
}

- (void) removeAllFilters {
    [self.filters removeAllObjects];
    [self _refreshFilters];
}

- (void) replaceAllFilters:(NSArray*) newFilters {
    self.filters = [NSMutableArray arrayWithArray:newFilters];
    [self _refreshFilters];
}

- (void) _refreshFilters {
    
    id prevFilter = self.input;
    GPUImageFilter *theFilter = nil;
    
    for (int i = 0; i < [self.filters count]; i++) {
        theFilter = [self.filters objectAtIndex:i];
        [prevFilter removeAllTargets];
        [prevFilter addTarget:theFilter];
        prevFilter = theFilter;
    }
    
    [prevFilter removeAllTargets];

    if (self.output != nil) {
        [prevFilter addTarget:self.output];
    }
}

- (UIImage *) currentFilteredFrame {
    return [(GPUImageFilter*)[_filters lastObject] imageFromCurrentlyProcessedOutput];
}

- (CGImageRef) newCGImageFromCurrentFilteredFrame {
    return [(GPUImageFilter*)[_filters lastObject] newCGImageFromCurrentlyProcessedOutput];
}

@end
