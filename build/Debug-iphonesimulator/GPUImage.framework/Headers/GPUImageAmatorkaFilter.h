#import "GPUImageFilterGroup.h"

@class GPUImagePicture;

/** A photo filter based on Photoshop action by Amatorka
    http://amatorka.deviantart.com/art/Amatorka-Action-2-121069631
 */

// Note: If you want to use this effect you have to add lookup_amatorka.png
//       from Resources folder to your application bundle.

@interface GPUImageAmatorkaFilter : GPUImageFilterGroup
{
    GPUImagePicture *lookupImageSource;
}

@end
