//
//  FDCameraViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/30/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDCameraViewController.h"
#import "AVCamCaptureManager.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "FDPost.h"
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "FDAppDelegate.h"

static void *AVCamFocusModeObserverContext = &AVCamFocusModeObserverContext;

@interface FDCameraViewController () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet UIScrollView *filterScrollView;
@property (strong, nonatomic) IBOutlet UIImageView *filterScrollViewBackground;
@property (strong, nonatomic) GPUImageOutput<GPUImageInput> *selectedFilter;
@property (strong, nonatomic) NSArray *filterArray;
@property (strong, nonatomic) UIImage *originalImage;
@property (strong, nonatomic) UIImage *cropImage;
@property (strong, nonatomic) UILabel *focusLabel;
@property (strong, nonatomic) UIView *squareImageView;
@property (strong, nonatomic) UITapGestureRecognizer *singleTap;
@property (strong, nonatomic) UITapGestureRecognizer *doubleTap;
@property BOOL isPreview;

- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates;
- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer;
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer;
@end

@implementation FDCameraViewController

@synthesize captureManager;
@synthesize captureVideoPreviewLayer;
@synthesize isPreview = _isPreview;
@synthesize photoPreviewImageView;

- (NSString *)stringForFocusMode:(AVCaptureFocusMode)focusMode
{
	NSString *focusString = @"";
	
	switch (focusMode) {
		case AVCaptureFocusModeLocked:
			focusString = @"Locked";
			break;
		case AVCaptureFocusModeAutoFocus:
			focusString = @"Auto Focus";
			break;
		case AVCaptureFocusModeContinuousAutoFocus:
			focusString = @"Focusing";
			break;
	}
	
	return focusString;
}

- (void)createFilterArray {
    GPUImageOutput<GPUImageInput> *noneFilter = [[GPUImageBrightnessFilter alloc] init];
    GPUImageOutput<GPUImageInput> *crispFilter = [[GPUImageAmatorkaFilter alloc] init];
    GPUImageOutput<GPUImageInput> *brightFilter = [[GPUImageBrightFilter alloc] init];
    GPUImageOutput<GPUImageInput> *aleFilter = [[GPUImageAleFilter alloc] init];
    GPUImageOutput<GPUImageInput> *meyerFilter = [[GPUImageMeyerFilter alloc] init];
    GPUImageOutput<GPUImageInput> *saucedFilter = [[GPUImageTiltShiftFilter alloc] init];
    GPUImageOutput<GPUImageInput> *fadeFilter = [[GPUImageVignetteFilter alloc] init];
    GPUImageOutput<GPUImageInput> *springFilter = [[GPUImageMissEtikateFilter alloc] init];
    GPUImageOutput<GPUImageInput> *softEleganceFilter = [[GPUImageSoftEleganceFilter alloc] init];
    GPUImageOutput<GPUImageInput> *sepiaFilter = [[GPUImageSepiaFilter alloc] init];
    GPUImageOutput<GPUImageInput> *grayscaleFilter = [[GPUImageGrayscaleFilter alloc] init];
    
    self.filterArray = [NSArray arrayWithObjects:noneFilter, crispFilter, aleFilter, brightFilter, fadeFilter, meyerFilter, saucedFilter, springFilter, softEleganceFilter, sepiaFilter, grayscaleFilter, nil];
}

- (void)viewDidLoad
{
    [(FDAppDelegate*)[UIApplication sharedApplication].delegate setIsTakingPhoto:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:NO];
    self.filterScrollView.transform = CGAffineTransformMakeTranslation(320, 0);
    [self createFilterArray];
    self.isPreview = NO;
    int index = 0;
    for (GPUImageFilter *thisFilter in self.filterArray){
        UIView *filterButtonView = [self addFilter:thisFilter withIndex:index];
        [self.filterScrollView addSubview:filterButtonView];
        index ++;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cleanupCameraCapture)
                                                 name:@"CleanupCameraCapture"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setUpCamera)
                                                 name:@"StartCameraCapture"
                                               object:nil];
    
    // Create the focus mode UI overlay
    [self addObserver:self forKeyPath:@"captureManager.videoInput.device.focusMode" options:NSKeyValueObservingOptionNew context:AVCamFocusModeObserverContext];
    
    // Add a single tap gesture to focus on the point tapped, then lock focus
    self.singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToContinouslyAutoFocus:)];
    [self.singleTap setDelegate:self];
    [self.singleTap setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:self.singleTap];
    
    // Add a double tap gesture to reset the focus mode to continuous auto focus
    self.doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToContinouslyAutoFocus:)];
    [self.doubleTap setDelegate:self];
    [self.doubleTap setNumberOfTapsRequired:2];
    [self.singleTap requireGestureRecognizerToFail:self.doubleTap];
    [self.view addGestureRecognizer:self.doubleTap];
    
    [self.cancelButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.useButton setTitle:@"Use" forState:UIControlStateNormal];
    [self.useButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    self.useButton.clipsToBounds = YES;
    [self.useButton addTarget:self action:@selector(useImage) forControlEvents:UIControlEventTouchUpInside];
    [self.useButton setAlpha:0.0];
    
    if ([UIScreen mainScreen].bounds.size.height == 568) {
        self.squareImageView = [[UIView alloc] initWithFrame:CGRectMake(0,0,320,320)];
    } else {
        self.squareImageView = [[UIView alloc] initWithFrame:CGRectMake(0,27,320,320)];
    }

    [self.squareImageView setBackgroundColor:[UIColor clearColor]];
    self.squareImageView.layer.borderWidth = 1.5f;
    self.squareImageView.layer.borderColor = [UIColor darkGrayColor].CGColor;
    [self.view addSubview:self.squareImageView];
    [self setUpCamera];
    [super viewDidLoad];
}

- (void)setUpCamera {
    NSLog(@"should be setting up the camera");
    if ([UIScreen mainScreen].bounds.size.height == 568){
        stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1920x1080 cameraPosition:AVCaptureDevicePositionBack];
    } else {
        stillCamera = [[GPUImageStillCamera alloc] init];
    }
    
    stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    filter = [[GPUImageBrightnessFilter alloc] init];
    //    filter = [[GPUImageUnsharpMaskFilter alloc] init];
    //    [(GPUImageSketchFilter *)filter setTexelHeight:(1.0 / 1024.0)];
    //    [(GPUImageSketchFilter *)filter setTexelWidth:(1.0 / 768.0)];
    //    filter = [[GPUImageSmoothToonFilter alloc] init];
    //    filter = [[GPUImageSepiaFilter alloc] init];
    //    filter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0.5, 0.5, 0.5, 0.5)];
    //    secondFilter = [[GPUImageSepiaFilter alloc] init];
    //    terminalFilter = [[GPUImageSepiaFilter alloc] init];
    //    [filter addTarget:secondFilter];
    //    [secondFilter addTarget:terminalFilter];
    //    [filter prepareForImageCapture];
    //	  [terminalFilter prepareForImageCapture];
    //    [terminalFilter addTarget:filterView];
    //    [stillCamera.inputCamera lockForConfiguration:nil];
    //    [stillCamera.inputCamera setFlashMode:AVCaptureFlashModeOn];
    //    [stillCamera.inputCamera unlockForConfiguration];
    
    [stillCamera addTarget:filter];
    GPUImageView *filterView = (GPUImageView *)self.view;
    [filterView setFrame:[[UIScreen mainScreen] bounds]];
    [filter addTarget:filterView];
    [stillCamera startCameraCapture];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self addFiltersToView];
}

/*- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == AVCamFocusModeObserverContext) {
        // Update the focus UI overlay string when the focus mode changes
		//[focusModeLabel setText:[NSString stringWithFormat:@"%@", [self stringForFocusMode:(AVCaptureFocusMode)[[change objectForKey:NSKeyValueChangeNewKey] integerValue]]]];
	} else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}*/

- (IBAction)captureStillImage:(id)sender
{
    [UIView animateWithDuration:.25 animations:^{
        [self.takePhotoButton setAlpha:0.0];
    }];

    [self.cancelButton setTitle:@"Retake" forState:UIControlStateNormal];
    [self.cancelButton removeTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton addTarget:self action:@selector(retake) forControlEvents:UIControlEventTouchUpInside];
    
    // Capture a still image
    [stillCamera capturePhotoAsImageProcessedUpToFilter:filter withCompletionHandler:^(UIImage *filteredImage, NSError *error) {
        if (!error){
            self.isPreview = YES;
            self.originalImage = filteredImage;
            CGSize bounds = CGSizeMake(320,320); // Considering image is shown in 320*320
            CGRect rect = CGRectMake(0, -(self.view.frame.size.height/2-144), 320, 320); //rectangle area to be cropped
            
            float widthFactor = rect.size.width * (filteredImage.size.width/bounds.width);
            float heightFactor = rect.size.height * (filteredImage.size.height/bounds.height);
            float factorX = rect.origin.x * (filteredImage.size.width/bounds.width);
            float factorY = rect.origin.y * (filteredImage.size.height/bounds.height);
            CGRect factoredRect = CGRectMake(factorX,factorY,widthFactor,heightFactor);
            self.cropImage = [UIImage imageWithCGImage:CGImageCreateWithImageInRect([filteredImage CGImage], factoredRect)];
            
            [self.photoPreviewImageView setImage:self.cropImage];
            [self.photoPreviewImageView setHidden:NO];
            [UIView animateWithDuration:.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                if ([UIScreen mainScreen].bounds.size.height == 568){
                    [self.photoPreviewImageView setFrame:CGRectMake(0, 0, 320, 320)];
                } else {
                    [self.photoPreviewImageView setFrame:CGRectMake(0, 26, 320, 320)];
                }
                [self.useButton setAlpha:1.0];
                [self.photoPreviewImageView setAlpha:1.0];
                [self.squareImageView setAlpha:0.0];

            }completion:^(BOOL finished) {
                [self.singleTap setEnabled:NO];
                [self.doubleTap setEnabled:NO];
            }];
        }
     }];
}

- (void)retake {
    self.filterArray = nil;
    [self createFilterArray];
    self.isPreview = NO;
    [UIView animateWithDuration:.25 animations:^{
        [self.squareImageView setAlpha:1.0];
        [self.photoPreviewImageView setAlpha:0.0];
        [self.takePhotoButton setAlpha:1.0];
        [self.useButton setAlpha:0.0];
    }];
    [self.singleTap setEnabled:YES];
    [self.doubleTap setEnabled:YES];
    self.cropImage = nil;
    self.originalImage = nil;
    self.photoPreviewImageView.image = nil;
    [self.photoPreviewImageView setHidden:YES];
    [stillCamera removeAllTargets];
    [filter removeAllTargets];
    [filter deleteOutputTexture];
    
    filter = [self.filterArray objectAtIndex:0];
    [stillCamera addTarget:filter];
    [filter addTarget:(GPUImageView *)self.view];
    [filter prepareForImageCapture];
    
    [self.cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [self.cancelButton removeTarget:self action:@selector(retake) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
}

//set up filters
- (void) addFiltersToView{
    [self.filterScrollView setContentSize:CGSizeMake((self.filterArray.count*66)-6,62)];
    
    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.filterScrollView.transform = CGAffineTransformMakeTranslation(-20, 0);
        [self.filterScrollView setAlpha:1.0];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:.2 animations:^{
            self.filterScrollView.transform = CGAffineTransformIdentity;
        }];
    }];
    
    int anotherIndex = 0;
    for (UIView *view in self.filterScrollView.subviews) {
        [UIView animateWithDuration:.3 delay:.05*anotherIndex options:UIViewAnimationOptionCurveEaseInOut animations:^{
            view.transform = CGAffineTransformMakeTranslation(0, 100);
        } completion:^(BOOL finished) {
        }];
        anotherIndex ++;
    }
}

- (UIView*)addFilter:(GPUImageFilter*)filter withIndex:(int)x {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(x*66, -100, 70, 70)];
    UIButton *filterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    filterButton.layer.borderWidth = 1.0;
    filterButton.layer.borderColor = [UIColor colorWithWhite:.9 alpha:.5].CGColor;
    filterButton.layer.shouldRasterize = YES;
    filterButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    UILabel *filterLabel = [[UILabel alloc] init];
    [filterLabel setFont:[UIFont fontWithName:kAvenirMedium size:16]];
    [filterLabel setBackgroundColor:[UIColor clearColor]];
    [filterLabel setTextAlignment:NSTextAlignmentCenter];
    
    [view addSubview:filterButton];
    [view addSubview:filterLabel];
    if ([UIScreen mainScreen].bounds.size.height == 568){
        [filterLabel setFrame:CGRectMake(0,80,60,18)];
        [filterButton setFrame:CGRectMake(0,16,60,60)];
        [filterLabel setTextColor:[UIColor darkGrayColor]];
    } else {
        [filterLabel setFrame:CGRectMake(0,50,60,18)];
        [filterButton setFrame:CGRectMake(0,6,60,60)];
        [filterLabel setTextColor:[UIColor whiteColor]];
        filterLabel.shadowColor = [UIColor blackColor];
        filterLabel.shadowOffset = CGSizeMake(1,1);
    }
    
    switch (x) {
        case 0:
            [filterLabel setText:@"NONE"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"grapes.jpg"] forState:UIControlStateNormal];
            break;
        case 1:
            [filterLabel setText:@"CRISP"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"crisp.jpg"] forState:UIControlStateNormal];
            break;
        case 2:
            [filterLabel setText:@"ALE"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"ale.jpg"] forState:UIControlStateNormal];
            break;
        case 3:
            [filterLabel setText:@"BRIGHT"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"bright.jpg"] forState:UIControlStateNormal];
            break;
        case 4:
            [filterLabel setText:@"CHARRED"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"charred.jpg"] forState:UIControlStateNormal];
            break;
        case 5:
            [filterLabel setText:@"MEYER"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"meyer.jpg"] forState:UIControlStateNormal];
            break;
        case 6:
            [filterLabel setText:@"SAUCED"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"sauced.jpg"] forState:UIControlStateNormal];
            break;
        case 7:
            [filterLabel setText:@"SPRING"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"spring.jpg"] forState:UIControlStateNormal];
            break;
        case 8:
            [filterLabel setText:@"GLAZED"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"glazed.jpg"] forState:UIControlStateNormal];
            break;
        case 9:
            [filterLabel setText:@"HONEY"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"honey.jpg"] forState:UIControlStateNormal];
            break;
        case 10:
            [filterLabel setText:@"B&W"];
            [filterButton setBackgroundImage:[UIImage imageNamed:@"b&w.jpg"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }
    filterButton.imageView.layer.cornerRadius = 3.0;
    [filterButton addTarget:self action:@selector(selectFilter:) forControlEvents:UIControlEventTouchUpInside];
    [filterButton setTag:x];
    [filterButton.titleLabel setHidden:YES];
    return view;
}

- (void) selectFilter:(id)sender {
    UIButton *button = (UIButton *) sender;
    for (UIView *view in self.filterScrollView.subviews){
        for (UIButton *button in view.subviews)
            if ([button isKindOfClass:[UIButton class]]){
                button.layer.shadowColor = [UIColor clearColor].CGColor;
                button.layer.shadowOffset = CGSizeMake(0,3);
                button.layer.shadowOpacity = 0.0;
                button.layer.shadowRadius = 0.0;
            }
    }
    button.layer.shadowColor = [UIColor blackColor].CGColor;
    button.layer.shadowOffset = CGSizeMake(0,3);
    button.layer.shadowOpacity = .75f;
    button.layer.shadowRadius = 10.0;
    
    [filter removeAllTargets];
    [stillCamera removeAllTargets];
    
    if (self.isPreview) {
        [self.photoPreviewImageView setImage:[(GPUImageFilter*)[self.filterArray objectAtIndex:button.tag] imageByFilteringImage:self.cropImage]];
    } else {
        //reset GPUImage to apply newly selected filter
        filter = [self.filterArray objectAtIndex:button.tag];
        [stillCamera addTarget:filter];
        [filter addTarget:(GPUImageView *)self.view];
        [filter prepareForImageCapture];
    }
}

- (void)useImage {
    [FDPost.userPost setPhotoImage:self.photoPreviewImageView.image];
    [self savePostToLibrary:self.photoPreviewImageView.image];
    //[self savePostToLibrary:self.photoPreviewImageView.image];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:NO];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)savePostToLibrary:(UIImage*)imageToSave {
    NSLog(@"should be saving photo to library");
    NSString *albumName = @"FOODIA";
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc]init];
    [library addAssetsGroupAlbumWithName:albumName
                                  resultBlock:^(ALAssetsGroup *group) {
                                      
                                  }
                                 failureBlock:^(NSError *error) {
                                     NSLog(@"error adding album");
                                 }];
    
    __block ALAssetsGroup* groupToAddTo;
    [library enumerateGroupsWithTypes:ALAssetsGroupAlbum
                                usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                    if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
                                        
                                        groupToAddTo = group;
                                    }
                                }
                              failureBlock:^(NSError* error) {
                                  NSLog(@"failed to enumerate albums:\nError: %@", [error localizedDescription]);
                              }];
    
    //ensure images are properly rotated
    CGImageRef CGimageToSave = imageToSave.CGImage;
    //NSMutableDictionary *metadata = [info objectForKey:UIImagePickerControllerMediaMetadata];
    //[metadata setObject:@"1" forKey:@"Orientation"];
    [library writeImageToSavedPhotosAlbum:CGimageToSave orientation:ALAssetOrientationUp completionBlock:^(NSURL *assetURL, NSError *error) {
                                   if (error.code == 0) {
                                       // try to get the asset
                                       [library assetForURL:assetURL
                                                     resultBlock:^(ALAsset *asset) {
                                                         // assign the photo to the album
                                                         [groupToAddTo addAsset:asset];
                                                     }
                                                    failureBlock:^(NSError* error) {
                                                        NSLog(@"failed to retrieve image asset:\nError: %@ ", [error localizedDescription]);
                                                    }];
                                   }
                                   else {
                                       NSLog(@"saved image failed.\nerror code %i\n%@", error.code, [error localizedDescription]);
                                   }
                               }];
}

- (IBAction)cancel{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:NO];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    NSLog(@"view did disappear");
    [(FDAppDelegate*)[UIApplication sharedApplication].delegate setIsTakingPhoto:NO];
    [self removeObserver:self forKeyPath:@"captureManager.videoInput.device.focusMode" context:AVCamFocusModeObserverContext];
    self.filterArray = nil;
    [self cleanupCameraCapture];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:NO];
    [super viewDidDisappear:animated];
}

- (void)cleanupCameraCapture {
    NSLog(@"should be cleaning up the campera capture setup");
    [stillCamera stopCameraCapture];
    stillCamera = nil;
    if (captureManager) [captureManager stopRecording];
}

// Convert from view coordinates to camera coordinates, where {0,0} represents the top left of the picture area, and {1,1} represents
// the bottom right in landscape mode with the home button on the right.
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates
{
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = self.view.frame.size;
    
    if ([[captureManager stillImageConnection] isVideoMirrored]) {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }
    
    if ( [[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
		// Scale, switch x and y, and reverse x
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in [[[self captureManager] videoInput] ports]) {
            if ([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if ( [[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
						// If point is inside letterboxed area, do coordinate conversion; otherwise, don't change the default value returned (.5,.5)
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
							// Scale (accounting for the letterboxing on the left and right of the video preview), switch x and y, and reverse x
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
						// If point is inside letterboxed area, do coordinate conversion. Otherwise, don't change the default value returned (.5,.5)
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
							// Scale (accounting for the letterboxing on the top and bottom of the video preview), switch x and y, and reverse x
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
					// Scale, switch x and y, and reverse x
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2; // Account for cropped height
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2); // Account for cropped width
                        xc = point.y / frameSize.height;
                    }
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    return pointOfInterest;
}

// Auto focus at a particular point. The focus mode will change to locked once the auto focus happens.
/*- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint tapPoint = [gestureRecognizer locationInView:self.view];
    [self animateFocusSquare:tapPoint];
    CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:tapPoint];
    [captureManager autoFocusAtPoint:convertedFocusPoint];
}*/

-(void)animateFocusSquare:(CGPoint)point {
    if (point.y < 320){
        UIView *squareView = [[UIView alloc] initWithFrame:CGRectMake(point.x-60,point.y-60,120,120)];
        [squareView setBackgroundColor:[UIColor clearColor]];
        [squareView.layer setBorderColor:[UIColor colorWithWhite:1 alpha:.7].CGColor];
        [squareView.layer setBorderWidth:1.f];
        [self.view addSubview:squareView];
        [UIView animateWithDuration:.125 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            [squareView setFrame:CGRectMake(point.x-40,point.y-40,80,80)];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:1.5 animations:^{
                squareView.transform = CGAffineTransformMakeScale(1.1, 1.1);
            } completion:^(BOOL finished){
                [squareView removeFromSuperview];
            }];
        }];
    }
}

// Change to continuous auto focus. The camera will constantly focus at the point choosen.
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint tapPoint = [gestureRecognizer locationInView:self.view];
    [self animateFocusSquare:tapPoint];
    CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:tapPoint];
    [captureManager autoFocusAtPoint:convertedFocusPoint];
    AVCaptureDevice *device = stillCamera.inputCamera;
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = self.view.frame.size;
    pointOfInterest = CGPointMake(tapPoint.y / frameSize.height, 1.f - (tapPoint.x / frameSize.width));
    
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            [device setFocusPointOfInterest:pointOfInterest];
            
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            
            if([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure])
            {
                
                [device setExposurePointOfInterest:pointOfInterest];
                [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            
            [device unlockForConfiguration];
        } else {
            NSLog(@"some sort of focus error");
        }
    }
}

@end
