#import <Cocoa/Cocoa.h>
#import <GPUImage/GPUImage.h>

@interface ShaderDesignerWindowController : NSWindowController
{
    GPUImageFilter *testFilter;
    GPUImageAVCamera *inputCamera;
}

@property(readwrite, nonatomic) NSString *vertexShader;
@property(readwrite, nonatomic) NSString *fragmentShader;
@property(readwrite, nonatomic) NSString *compileLog;

@property (weak) IBOutlet GPUImageView *previewView;
@property (weak) IBOutlet GPUImageView *shaderOutputView;

@property (weak) IBOutlet NSTabView *displayTabView;
@property (weak) IBOutlet NSTabViewItem *displayTabItem;
@property (weak) IBOutlet NSTabViewItem *logTabItem;

@property (unsafe_unretained) IBOutlet NSTextView *vertexShaderTextView;
@property (unsafe_unretained) IBOutlet NSTextView *fragmentShaderTextView;

- (IBAction)compile:(id)sender;

- (IBAction)openVertexShader:(id)sender;
- (IBAction)openFragmentShader:(id)sender;
- (IBAction)saveVertexShader:(id)sender;
- (IBAction)saveFragmentShader:(id)sender;

@end
