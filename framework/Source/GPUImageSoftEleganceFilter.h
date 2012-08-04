#import "GPUImageFilterGroup.h"

@class GPUImagePicture;

/** A photo filter based on Soft Elegance Photoshop action
    http://h-d-stock.deviantart.com/art/H-D-A-soft-elegance-70107603
 */

// Note: If you want to use this effect you have to add 
//       lookup_soft_elegance_1.png and lookup_soft_elegance_2.png
//       from Resources folder to your application bundle.

@interface GPUImageSoftEleganceFilter : GPUImageFilterGroup
{
    GPUImagePicture *lookupImageSource1;
    GPUImagePicture *lookupImageSource2;
}

@end
