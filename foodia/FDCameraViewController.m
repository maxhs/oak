//
//  FDCameraViewController.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/30/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "FDPost.h"
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "FDAppDelegate.h"
#import "FDPhotoLibraryViewController.h"

static void *AVCamFocusModeObserverContext = &AVCamFocusModeObserverContext;

@interface FDCameraViewController () <UIGestureRecognizerDelegate, UIAlertViewDelegate> {
    UIAlertView *noPhotosAlert;
    BOOL photoLibraryEnumeration;
    BOOL iPhone5;
    UITapGestureRecognizer *singleTap;
    UITapGestureRecognizer *doubleTap;
    UIImage *originalImage;
    BOOL photoFromLibrary;
    NSArray *filterArray;
}

@property (weak, nonatomic) IBOutlet UIImageView *filterScrollViewBackground;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundTopFrame;
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates;
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer orPoint:(CGPoint)thePoint;
-(IBAction)libraryButtonTapped;
@end

@implementation FDCameraViewController

@synthesize captureManager;
@synthesize captureVideoPreviewLayer;
@synthesize isPreview = _isPreview;
@synthesize photoPreviewImageView;
@synthesize cropImage = _cropImage;

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
    
    filterArray = [NSArray arrayWithObjects:noneFilter, crispFilter, aleFilter, brightFilter, fadeFilter, meyerFilter, saucedFilter, springFilter, softEleganceFilter, sepiaFilter, grayscaleFilter, nil];
}

- (void)viewDidLoad
{
    if ([UIScreen mainScreen].bounds.size.height == 568){
        iPhone5 = YES;
    } else {
        iPhone5 = NO;
    }
    [(FDAppDelegate*)[UIApplication sharedApplication].delegate setIsTakingPhoto:YES];
    self.filterScrollView.transform = CGAffineTransformMakeTranslation(320, 0);
    self.isPreview = NO;
    photoFromLibrary = NO;
    photoLibraryEnumeration = NO;
    self.libraryButton.layer.cornerRadius = 3.0f;
    self.libraryButton.layer.borderColor = kColorLightBlack.CGColor;
    self.libraryButton.layer.borderWidth = 1.0f;
    self.libraryButton.clipsToBounds = YES;
    self.libraryButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    [self setUpLibraryButton];    
    
    [self.backgroundTopFrame setBackgroundColor:[UIColor colorWithWhite:.3 alpha:1]];
    
    // Add a single tap gesture to focus on the point tapped, then lock focus
    singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToContinouslyAutoFocus:orPoint:)];
    [singleTap setDelegate:self];
    [singleTap setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:singleTap];
    
    // Add a double tap gesture to reset the focus mode to continuous auto focus
    doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToContinouslyAutoFocus:orPoint:)];
    [doubleTap setDelegate:self];
    [doubleTap setNumberOfTapsRequired:2];
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.view addGestureRecognizer:doubleTap];
    
    [self.cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.useButton setTitle:@"USE" forState:UIControlStateNormal];
    [self.useButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.useButton.clipsToBounds = YES;
    [self.useButton addTarget:self action:@selector(useImage) forControlEvents:UIControlEventTouchUpInside];
    [self.useButton setAlpha:0.0];
    [self.cancelButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:14]];
    [self.useButton.titleLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:14]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cleanupCameraCapture)
                                                 name:@"CleanupCameraCapture"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setUpCamera)
                                                 name:@"StartCameraCapture"
                                               object:nil];
}

- (void)setUpCamera {
    NSLog(@"should be setting up the camera");
    if (!originalImage) originalImage = [[UIImage alloc] init];
    stillCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetPhoto cameraPosition:AVCaptureDevicePositionBack];
    // Create the focus mode UI overlay
    //[self addObserver:self forKeyPath:@"captureManager.videoInput.device.focusMode" options:NSKeyValueObservingOptionNew context:AVCamFocusModeObserverContext];
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
    [stillCamera prepareForImageCapture];
    [stillCamera startCameraCapture];
    //[stillCamera performSelectorInBackground:@selector(startCameraCapture) withObject:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:YES];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.view setBackgroundColor:[UIColor colorWithWhite:.3 alpha:1]];
    if (self.isPreview) {
        [self.filterScrollView setHidden:NO];
        [self.cancelButton setTitle:@"RETAKE" forState:UIControlStateNormal];
        [self.cancelButton removeTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
        [self.cancelButton addTarget:self action:@selector(retake) forControlEvents:UIControlEventTouchUpInside];
        [self.useButton setAlpha:1.0];
        [self.photoPreviewImageView setAlpha:1.0];
        [singleTap setEnabled:NO];
        [doubleTap setEnabled:NO];
        [self.libraryButton setHidden:YES];
        [self.takePhotoButton setAlpha:0.0];
        photoFromLibrary = YES;
    }
    [super viewWillAppear:animated];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.isPreview) {
        [self setUpCamera];
        [self createFilterArray];
        int index = 0;
        for (GPUImageFilter *thisFilter in filterArray){
            UIView *filterButtonView = [self addFilter:thisFilter withIndex:index];
            [self.filterScrollView addSubview:filterButtonView];
            index ++;
        }
        [self addFiltersToView];
        if (iPhone5) {
            [self tapToContinouslyAutoFocus:nil orPoint:CGPointMake(165,225)];
        } else {
            [self tapToContinouslyAutoFocus:nil orPoint:CGPointMake(165,190)];
        }
    }
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return ! ([touch.view isKindOfClass:[UIControl class]]);
}

- (IBAction)captureStillImage:(id)sender
{
    [UIView animateWithDuration:.25 animations:^{
        [self.takePhotoButton setAlpha:0.0];
    }];

    [self.cancelButton setTitle:@"RETAKE" forState:UIControlStateNormal];
    [self.cancelButton removeTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton addTarget:self action:@selector(retake) forControlEvents:UIControlEventTouchUpInside];
    // Capture a still image
    
    [stillCamera capturePhotoAsImageProcessedUpToFilter:filter withCompletionHandler:^(UIImage *filteredImage, NSError *error) {
        if (!error){
            originalImage = filteredImage;
            CGSize bounds = CGSizeMake(320,320); // Considering image is shown in 320*320
            CGRect rect = CGRectMake(0, -(80), 320, 320); //rectangle area to be cropped
            float widthFactor = rect.size.width * (filteredImage.size.width/bounds.width);
            float heightFactor = rect.size.height * (filteredImage.size.height/bounds.height);
            float factorX = rect.origin.x * (filteredImage.size.width/bounds.width);
            float factorY = rect.origin.y * (filteredImage.size.height/bounds.height);
            CGRect factoredRect = CGRectMake(factorX,factorY,widthFactor,heightFactor);
            _cropImage = [UIImage imageWithCGImage:CGImageCreateWithImageInRect([filteredImage CGImage], factoredRect)];
            
            [self.photoPreviewImageView setImage:_cropImage];
            [UIView animateWithDuration:.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                [self.useButton setAlpha:1.0];
                [self.photoPreviewImageView setAlpha:1.0];
                [self.libraryButton setAlpha:0.0];
            }completion:^(BOOL finished) {
                [singleTap setEnabled:NO];
                [doubleTap setEnabled:NO];
                [self.libraryButton setHidden:YES];
                self.isPreview = YES;
                [stillCamera pauseCameraCapture];
            }];
        }
     }];
}

- (void)retake {
    if (self.isPreview) {
        [self setUpCamera];
    } else {
        [stillCamera resumeCameraCapture];
    }
    
    filterArray = nil;
    [self createFilterArray];
    self.isPreview = NO;
    photoFromLibrary = NO;
    [self.libraryButton setHidden:NO];
    [UIView animateWithDuration:.25 animations:^{
        [self.photoPreviewImageView setAlpha:0.0];
        [self.takePhotoButton setAlpha:1.0];
        [self.useButton setAlpha:0.0];
        [self.libraryButton setAlpha:1.0];
    }];
    
    [singleTap setEnabled:YES];
    [doubleTap setEnabled:YES];
    if (_cropImage) _cropImage = nil;
    if (originalImage) originalImage = nil;
    if (self.photoPreviewImageView) self.photoPreviewImageView.image = nil;
    [stillCamera removeAllTargets];
    [filter removeAllTargets];
    [filter deleteOutputTexture];
    
    filter = [filterArray objectAtIndex:0];
    [stillCamera addTarget:filter];
    [filter addTarget:(GPUImageView *)self.view];
    [filter prepareForImageCapture];
    
    [self.cancelButton setTitle:@"BACK" forState:UIControlStateNormal];
    [self.cancelButton removeTarget:self action:@selector(retake) forControlEvents:UIControlEventTouchUpInside];
    [self.cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
}

//set up filters
- (void) addFiltersToView{
    [self.filterScrollView setContentSize:CGSizeMake((filterArray.count*66)-6,62)];
    
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
    filterButton.layer.borderColor = kColorLightBlack.CGColor;
    filterButton.layer.shouldRasterize = YES;
    filterButton.layer.rasterizationScale = [UIScreen mainScreen].scale;
    UILabel *filterLabel = [[UILabel alloc] init];
    [filterLabel setFont:[UIFont fontWithName:kHelveticaNeueThin size:13]];
    
    [filterLabel setBackgroundColor:[UIColor clearColor]];
    [filterLabel setTextAlignment:NSTextAlignmentCenter];
    
    [view addSubview:filterButton];
    [view addSubview:filterLabel];
    [filterLabel setTextColor:[UIColor whiteColor]];
    if (iPhone5){
        [filterLabel setFrame:CGRectMake(-2,78,62,18)];
        [filterButton setFrame:CGRectMake(0,16,60,60)];
    } else {
        [filterLabel setFrame:CGRectMake(-2,50,62,18)];
        [filterButton setFrame:CGRectMake(0,6,60,60)];
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

- (void) selectFilter:(UIButton*)button {
    [filter removeAllTargets];
    [stillCamera removeAllTargets];
    
    if (self.isPreview) {
        [self.photoPreviewImageView setImage:[(GPUImageFilter*)[filterArray objectAtIndex:button.tag] imageByFilteringImage:_cropImage]];
    } else {
        //reset GPUImage to apply newly selected filter
        filter = [filterArray objectAtIndex:button.tag];
        [stillCamera addTarget:filter];
        [filter addTarget:(GPUImageView *)self.view];
        [filter prepareForImageCapture];
    }
}

- (void)useImage {
    [FDPost.userPost setPhotoImage:self.photoPreviewImageView.image];
    if (self.shouldBeEditing) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateNewPostVC" object:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self performSegueWithIdentifier:@"NewPost" sender:self];
    }
}

- (IBAction)cancel{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
    if (self.shouldBeEditing){
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [(FDAppDelegate*)[UIApplication sharedApplication].delegate setIsTakingPhoto:NO];
    [self.filterScrollView setHidden:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self cleanupCameraCapture];
}

- (void)viewDidUnload {
    filterArray = nil;
    [super viewDidUnload];
}

- (void)cleanupCameraCapture {
    NSLog(@"should be cleaning up the campera capture setup");

    if (stillCamera){
        [stillCamera stopCameraCapture];
        stillCamera = nil;
    }
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
    if (iPhone5){
        if (point.y < 390 && point.y > 70) {
            [self actuallyFocus:point];
        }
    } else {
        if (point.y > 26 && point.y < 346) {
            [self actuallyFocus:point];
        }
    }
}

-(void)actuallyFocus:(CGPoint)point {
    UIView *squareView = [[UIView alloc] initWithFrame:CGRectMake(point.x-50,point.y-50,100,100)];
    UIImageView *focusSquare = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"focusSquare"]];
    [squareView addSubview:focusSquare];
    [self.view addSubview:squareView];
    [squareView setBackgroundColor:[UIColor clearColor]];
    [UIView animateWithDuration:.075 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        focusSquare.transform = CGAffineTransformMakeScale(.7, .7);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:1.5 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            squareView.transform = CGAffineTransformMakeScale(1.15, 1.15);
        } completion:^(BOOL finished){
            [squareView removeFromSuperview];
        }];
    }];
}

// Change to continuous auto focus. The camera will focus at the point choosen.
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer orPoint:(CGPoint)thePoint
{
    CGPoint tapPoint;
    if (thePoint.x && thePoint.y) {
        tapPoint = thePoint;
    } else {
        tapPoint = [gestureRecognizer locationInView:self.view];
    }
    [self animateFocusSquare:tapPoint];
    
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

-(void)setUpLibraryButton {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        if (![group numberOfAssets]){
            
        } else {
                [group enumerateAssetsAtIndexes:[NSIndexSet indexSetWithIndex:[group numberOfAssets]-1]
                                        options:0
                                     usingBlock:^(ALAsset *myAsset, NSUInteger index, BOOL *innerStop) {
                                         
                                         // The end of the enumeration is signaled by asset == nil.
                                         if (myAsset) {
                                             
                                             UIImageOrientation orientation = UIImageOrientationUp;
                                             NSNumber* orientationValue = [myAsset valueForProperty:@"ALAssetPropertyOrientation"];
                                             if (orientationValue != nil) {
                                                 orientation = [orientationValue intValue];
                                             }
                                            [self.libraryButton setImage:[UIImage imageWithCGImage:[myAsset thumbnail] scale:1.0 orientation:UIImageOrientationUp] forState:UIControlStateNormal];
                                         }
                                     }];
        }
    }
                             failureBlock: ^(NSError *error) {
                                 /*[[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"But you'll need either a camera or some images in your Photo Library in order to post on FOODIA." delegate:self cancelButtonTitle:@"Okey Dokey" otherButtonTitles:nil] show];*/
                             }];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [alertView dismissWithClickedButtonIndex:buttonIndex animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)libraryButtonTapped{
    if (self.shouldBeEditing){
        UIStoryboard *storyboard;
        if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && iPhone5)){
            storyboard = [UIStoryboard storyboardWithName:@"iPhone5"
                                                   bundle:nil];
        } else {
            storyboard = [UIStoryboard storyboardWithName:@"iPhone"
                                                   bundle:nil];
        }
        FDPhotoLibraryViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"PhotoLibrary"];
        vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [vc setShouldBeEditing:YES];
        [self presentViewController:vc animated:YES completion:nil];
    } else{
        [self performSegueWithIdentifier:@"ShowLibrary" sender:self];
    }
}

@end
