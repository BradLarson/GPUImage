#import "GPUImageFilterGroup.h"

@class GPUImagePicture;

/** A photo filter based on Photoshop action by Miss Etikate:
    http://miss-etikate.deviantart.com/art/Photoshop-Action-15-120151961
 */

// Note: If you want to use this effect you have to add lookup_miss_etikate.png
//       from Resources folder to your application bundle.

@interface GPUImageMissEtikateFilter : GPUImageFilterGroup
{
    GPUImagePicture *lookupImageSource;
}

@end
