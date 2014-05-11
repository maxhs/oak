#import "GPUImageFilterGroup.h"

@class GPUImagePicture;

@interface GPUImageBrightFilter : GPUImageFilterGroup
{
    GPUImagePicture *lookupImageSource;
}

@end
