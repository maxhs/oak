//
//  Utilities.m
//
//  Created by Max Haines-Stiles on 1/6/13.
//  Copyright (c) 2013 FOODIA. All rights reserved.
//

#import "Utilities.h"
#import "Facebook.h"
#import "SDImageCache.h"
#import "FDAPIClient.h"

#define TMP NSTemporaryDirectory()
#define SECOND 1
#define MINUTE (60 * SECOND)
#define HOUR (60 * MINUTE)
#define DAY (24 * HOUR)
#define MONTH (30 * DAY)

@implementation Utilities

+ (BOOL)currentDeviceIsRetina {
    return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0));
}

+ (NSString *)accessToken {
    return [FBSession.activeSession accessToken];
}

+ (NSString *)userId {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookId];
}

+ (NSString *)avatarUrl {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsAvatarUrl];
}

+ (NSURL *)profileImageURLForFacebookID:(NSString *)fbid {
    NSString *URLString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=120&height=120&access_token=%@", fbid, [self accessToken]];
    return [NSURL URLWithString:URLString];
}

+ (NSString *)profileImagePathForUserId:(NSString *)uid {
    NSString *URLString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=120&height=120&access_token=%@", uid, [self accessToken]];
    return URLString;
}

+ (NSURL *)profileImageURLForCurrentUser {
    if ([self userId] && [self accessToken]){
        NSString *URLString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=120&height=120&access_token=%@", [self userId], [self accessToken]];
        return [NSURL URLWithString:URLString];
    } else {
        return [NSURL URLWithString:[self avatarUrl]];
    }
}

+ (void)cacheUserProfileImage {
    [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:[Utilities profileImageURLForCurrentUser].absoluteString];
}

+ (NSString*)timeIntervalSinceStartDate:(NSDate*)date
{
    //Calculate the delta in seconds between the two dates
    NSTimeInterval delta = [[NSDate date] timeIntervalSinceDate:date];
    
    if (delta < 1 * MINUTE)
    {
        return [NSString stringWithFormat:@"%ds", (int)delta];
    }
    if (delta < 2 * MINUTE)
    {
        return @"1min";
    }
    if (delta < 45 * MINUTE)
    {
        int minutes = floor((double)delta/MINUTE);
        return [NSString stringWithFormat:@"%dm", minutes];
    }
    if (delta < 90 * MINUTE)
    {
        return @"1h";
    }
    if (delta < 24 * HOUR)
    {
        int hours = floor((double)delta/HOUR);
        return [NSString stringWithFormat:@"%dh", hours];
    }
    /*if (delta < 48 * HOUR)
    {
        return @"yesterday";
    }*/
    if (delta < 365 * DAY)
    {
        int days = floor((double)delta/DAY);
        return [NSString stringWithFormat:@"%dd", days];
    }
    else
    {
        int years = floor((double)delta/MONTH/12.0);
        return years <= 1 ? @"1y" : [NSString stringWithFormat:@"%dy", years];
    }
}

+ (NSString*)verboseTimeIntervalSinceStartDate:(NSDate*)date
{
    //Calculate the delta in seconds between the two dates
    NSTimeInterval delta = [[NSDate date] timeIntervalSinceDate:date];
    
    if (delta < 1 * MINUTE)
    {
        return [NSString stringWithFormat:@"%d seconds ago", (int)delta];
    }
    if (delta < 2 * MINUTE)
    {
        return @"1 min ago";
    }
    if (delta < 45 * MINUTE)
    {
        int minutes = floor((double)delta/MINUTE);
        return minutes <= 1 ? @"1 minute ago" : [NSString stringWithFormat:@"%d minutes ago", minutes];
    }
    if (delta < 90 * MINUTE)
    {
        return @"1 hour ago";
    }
    if (delta < 24 * HOUR)
    {
        int hours = floor((double)delta/HOUR);
        return hours <= 1 ? @"1 hour ago" : [NSString stringWithFormat:@"%d hours ago", hours];
    }
    /*if (delta < 48 * HOUR)
     {
     return @"yesterday";
     }*/
    if (delta < 30 * DAY)
    {
        int days = floor((double)delta/DAY);
        return days <= 1 ? @"1 day ago" : [NSString stringWithFormat:@"%d days ago", days];
    }
    if (delta < 12 * MONTH)
    {
        int months = floor((double)delta/MONTH);
        return months <= 1 ? @"1 month ago" : [NSString stringWithFormat:@"%d months ago", months];
    }
    else
    {
        int years = floor((double)delta/MONTH/12.0);
        return years <= 1 ? @"1 year ago" : [NSString stringWithFormat:@"%d years ago", years];
    }
}

+ (NSString*)postedAt:(NSDate *)date{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    //[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateFormat:@"MMM dd, yyyy 'at' h:mm a"];
    
    NSString *formattedDateString = [dateFormatter stringFromDate:date];
    return formattedDateString;
}

+ (void)alertWithTitle:(NSString *)title message:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

+ (void) cacheImage: (NSString *) ImageURLString
{
    NSURL *ImageURL = [NSURL URLWithString: ImageURLString];

    // Generate a unique path to a resource representing the image you want
    NSString *filename = [ImageURLString lastPathComponent];//
    NSString *uniquePath = [TMP stringByAppendingPathComponent: filename];

    // Check for file existence
    if(![[NSFileManager defaultManager] fileExistsAtPath: uniquePath])
    {
        // The file doesn't exist, we should get a copy of it

        // Fetch image
        NSData *data = [[NSData alloc] initWithContentsOfURL: ImageURL];
        UIImage *image = [[UIImage alloc] initWithData: data];


        // Is it PNG or JPG/JPEG?
        // Running the image representation function writes the data from the image to a file
        if([ImageURLString rangeOfString: @".png" options: NSCaseInsensitiveSearch].location != NSNotFound) {
                [UIImagePNGRepresentation(image) writeToFile: uniquePath atomically: YES];
        } else if( [ImageURLString rangeOfString: @".jpg" options: NSCaseInsensitiveSearch].location != NSNotFound || [ImageURLString rangeOfString: @".jpeg" options: NSCaseInsensitiveSearch].location != NSNotFound) {
                          [UIImageJPEGRepresentation(image, 100) writeToFile: uniquePath atomically: YES];
        }
    }
}

+ (UIImage *) getCachedImage: (NSString *) ImageURLString
{
    NSString *filename = [ImageURLString lastPathComponent];
    NSString *uniquePath = [TMP stringByAppendingPathComponent: filename];
    
    UIImage *image;
    
    // Check for a cached version
    if([[NSFileManager defaultManager] fileExistsAtPath: uniquePath])
    {
        image = [UIImage imageWithContentsOfFile: uniquePath]; // this is the cached image
    }
    else
    {
        // get a new one
        [self cacheImage: ImageURLString];
        image = [UIImage imageWithContentsOfFile: uniquePath];
    }
    
    return image;
}
+ (UIImage *) deleteCachedImage: (NSString *) ImageURLString
{
    NSString *filename = [ImageURLString lastPathComponent];
    NSString *uniquePath = [TMP stringByAppendingPathComponent: filename];
    
    UIImage *image;
    
    // Check for a cached version
    if([[NSFileManager defaultManager] fileExistsAtPath: uniquePath])
    {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath: uniquePath error:&error];
    }
    
    return image;
}

@end
