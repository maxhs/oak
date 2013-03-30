//
//  FDPost.m
//  foodia
//
//  Created by Max Haines-Stiles on 12/22/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDPost.h"
#import "FDUser.h"
#import "FDComment.h"
#import "FDAPIClient.h"

@implementation FDPost

static FDPost *userPost;

+ (void)initialize {
    if (self == [FDPost class]){
        userPost = [FDPost new];
        userPost.likers = nil;
        userPost.viewers = nil;
    }
}

+ (FDPost *)userPost {
    return userPost;
}

+ (void)setUserPost:(FDPost *)post {
    userPost = post;
}

+ (void)resetUserPost {
    userPost = [FDPost new];
}

- (NSDate *)postedAt {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.epochTime.floatValue];
    return date;
}

- (NSDate *)recommendedAt {
    return [NSDate dateWithTimeIntervalSince1970:self.recommendedEpochTime.floatValue];
}

- (NSURL *)feedImageURL {
    NSString *tempString = [self.feedImageUrlString stringByReplacingOccurrencesOfString:@"s3.amazonaws.com/foodia-uploads" withString:@"d39yp5dq001uwq.cloudfront.net"];
    return [NSURL URLWithString:tempString];
}
- (NSURL *)detailImageURL {
        NSString *tempString = [self.detailImageUrlString stringByReplacingOccurrencesOfString:@"s3.amazonaws.com/foodia-uploads" withString:@"d39yp5dq001uwq.cloudfront.net"];
    return [NSURL URLWithString:tempString];
}
- (NSURL *)featuredImageURL {
        NSString *tempString = [self.featuredImageUrlString stringByReplacingOccurrencesOfString:@"s3.amazonaws.com/foodia-uploads" withString:@"d39yp5dq001uwq.cloudfront.net"];
    return [NSURL URLWithString:tempString];
}
- (CLLocation *)location {
    if (self.longitude == nil || self.latitude == nil) {
        return nil;
    }
    
    return [[CLLocation alloc] initWithLatitude:self.latitude.floatValue
                                      longitude:self.longitude.floatValue];
}

- (void)setLocation:(CLLocation *)location {
    self.latitude = @(location.coordinate.latitude);
    self.longitude = @(location.coordinate.longitude);
}

- (void)setVenue:(FDVenue *)venue {
    if (venue) self.venue = venue;
}

- (BOOL)hasPhoto {
    return [self.feedImageUrlString length];
}

- (BOOL)hasDetailPhoto {
    return [self.detailImageUrlString length];
}

- (NSString *)socialString {
    NSMutableArray *stringArray = [NSMutableArray array];
    
    if ([self.category isEqualToString:@"Shopping"] && self.foodiaObject.length) {
        [stringArray addObject:[NSString stringWithFormat:@"Shopping for %@", self.foodiaObject]];
    } else if (self.foodiaObject.length) {
        [stringArray addObject:[NSString stringWithFormat:@"%@ %@", self.category, self.foodiaObject]];
    } else {
        [stringArray addObject:[NSString stringWithFormat:@"%@", self.category]];
    }
    
    if ([self.locationName length]) {
        [stringArray addObject:[NSString stringWithFormat:@"at %@",  self.locationName]];
    }
    
    if ([self.withFriends count] > 1) {
        if (self.withFriends.count == 2) {
            [stringArray addObject:[NSString stringWithFormat:@"with %@ and 1 other", 
                                    [self.withFriends.anyObject name]]];
        } else {
            [stringArray addObject:[NSString stringWithFormat:@"with %@ and %d others", 
                                    [self.withFriends.anyObject name], 
                                    self.withFriends.count-1]];
        }
    } else if (self.withFriends.count == 1) {
        [stringArray addObject:[NSString stringWithFormat:@"with %@", 
                                [[self.withFriends anyObject] name]]];
    }
    
    return [stringArray componentsJoinedByString:@" "];
}

- (NSString *)detailString {
    NSMutableArray *detailArray = [NSMutableArray array];
    
    [detailArray addObject:[NSString stringWithFormat:@"%@ is ", self.user.name]];
    if ([self.category isEqualToString:@"Shopping"] && self.foodiaObject.length) {
        [detailArray addObject:[NSString stringWithFormat:@"shopping for %@ ", self.foodiaObject]];
    } else if (self.foodiaObject.length) {
        [detailArray addObject:[NSString stringWithFormat:@"%@ %@ ", [self.category lowercaseString], self.foodiaObject]];
    } else {
        [detailArray addObject:[NSString stringWithFormat:@"%@ ", [self.category lowercaseString]]];
    }
    
    if ([self.locationName length]) {
        [detailArray addObject:[NSString stringWithFormat:@"at %@ ",  self.locationName]];
    }
    
    if ([self.withFriends count]) {
        NSMutableArray *nameArray = [[NSMutableArray alloc] initWithArray:self.withFriends.allObjects];
        if (self.withFriends.count == 1) {
            [detailArray addObject:[NSString stringWithFormat:@"with %@.",[[nameArray objectAtIndex:0] name]]];
        } else if (self.withFriends.count == 2) {
            [detailArray addObject:[NSString stringWithFormat:@"with %@ and %@.",[[nameArray objectAtIndex:0] name], [[nameArray objectAtIndex:1] name]]];
        } else {
            [detailArray addObject:[NSString stringWithFormat:@"with %@",[[nameArray objectAtIndex:0] name]]];
            int i;
            int delimiter = [nameArray count];
             for (i = 1; i<(delimiter-1);i++) {
                [detailArray addObject:[NSString stringWithFormat:@", %@", [[nameArray objectAtIndex:i] name]]];
             }
             [detailArray addObject:[NSString stringWithFormat:@", and %@.", [nameArray.lastObject name]]];
        }
    }
    
    return [detailArray componentsJoinedByString:@""];
}

#pragma mark - MKAnnotation Methods

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(self.latitude.floatValue, self.longitude.floatValue);
}

- (NSString *)title {
    return self.locationName;
}

#pragma mark - Coding Methods

- (void)setValue:(id)value forKey:(NSString *)key {
    
    // set user
    if ([key isEqualToString:@"user"]) {
        FDUser *user = [[FDUser alloc] initWithDictionary:value];
        [self setUser:user];
    
    // set with friends
    } else if ([key isEqualToString:@"withFriends"]) {
        NSArray *dictionaries = (NSArray *)value;
        if (dictionaries){
            NSMutableSet *set = [NSMutableSet setWithCapacity:dictionaries.count];
            for (NSDictionary *friendDictionary in dictionaries) {
                FDUser *user = [[FDUser alloc] initWithDictionary:friendDictionary];
                [set addObject:user];
            }
            [self setWithFriends:set];
        }
        
    // set comments
    } else if ([key isEqualToString:@"comments"]) {
        NSArray *dictionaries = (NSArray *)value;
        if (dictionaries){
            NSMutableSet *set = [NSMutableSet setWithCapacity:dictionaries.count];
            [dictionaries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                FDComment *comment = [[FDComment alloc] initWithDictionary:obj];
            
                [set addObject:comment];
            }];
            [self setComments:set];
        }
    } else if([key isEqualToString:@"featured"]) {
    } else if([key isEqualToString:@"isfeatured"]) {
        self.featured = value;
    } else {
        [super setValue:value forKey:key];
        
    }
}
-(Boolean) isLikedByUser {
    if(self.likers.count != 0) {
        for (id object in [self.likers objectEnumerator]) {
            if([[[NSUserDefaults standardUserDefaults] objectForKey:kUserDefaultsFacebookId] isEqualToString:[object objectForKey:@"facebook_id"]]) {
                return true;
            }
        }
    }
    return false;
}

-(NSDictionary *) setLikers {
    NSDictionary *likers = self.likers;
    return likers;
}

//=========================================================== 
//  Keyed Archiving
//
//=========================================================== 
- (void)encodeWithCoder:(NSCoder *)encoder 
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:self.comments forKey:@"comments"];
    [encoder encodeObject:self.caption forKey:@"caption"];
    [encoder encodeObject:self.foodiaObject forKey:@"foodiaObject"];
    [encoder encodeObject:self.feedImageUrlString forKey:@"feedImageUrlString"];
    [encoder encodeObject:self.detailImageUrlString forKey:@"detailImageUrlString"];
    [encoder encodeObject:self.featuredImageUrlString forKey:@"featuredImageUrlString"];
    [encoder encodeObject:self.category forKey:@"category"];
    [encoder encodeObject:self.latitude forKey:@"latitude"];
    [encoder encodeObject:self.longitude forKey:@"longitude"];
    [encoder encodeObject:self.epochTime forKey:@"epochTime"];
    [encoder encodeObject:self.isRecommendedToUser forKey:@"isRecommendedToUser"];
    [encoder encodeObject:self.featured forKey:@"featured"];
    [encoder encodeObject:self.likeCount forKey:@"likeCount"];
    [encoder encodeObject:self.viewCount forKey:@"viewCount"];
    [encoder encodeObject:self.locationName forKey:@"locationName"];
    [encoder encodeObject:self.locationHours forKey:@"locationHours"];
    [encoder encodeObject:self.address forKey:@"address"];
    [encoder encodeObject:self.foursquareid forKey:@"foursquareid"];
    [encoder encodeObject:self.user forKey:@"user"];
    [encoder encodeObject:self.withFriends forKey:@"withFriends"];
    [encoder encodeObject:self.likers forKey:@"likers"];
    [encoder encodeObject:self.viewers forKey:@"viewers"];
    [encoder encodeObject:self.recommendedTo forKey:@"recommendedTo"];
    [encoder encodeObject:self.recommendedEpochTime forKey:@"recommendedEpochTime"];
    [encoder encodeObject:self.og forKey:@"og"];
    [encoder encodeObject:self.venue forKey:@"venue"];
    [encoder encodeObject:self.FDVenueId forKey:@"FDVenueId"];
}

- (id)initWithCoder:(NSCoder *)decoder 
{
    self = [super initWithCoder:decoder];
    if (self) {
        self.caption = [decoder decodeObjectForKey:@"caption"];
        self.comments = [decoder decodeObjectForKey:@"comments"];
        self.foodiaObject = [decoder decodeObjectForKey:@"foodiaObject"];
        self.feedImageUrlString = [decoder decodeObjectForKey:@"feedImageUrlString"];
        self.detailImageUrlString = [decoder decodeObjectForKey:@"detailImageUrlString"];
        self.featuredImageUrlString = [decoder decodeObjectForKey:@"featuredImageUrlString"];
        self.category = [decoder decodeObjectForKey:@"category"];
        self.latitude = [decoder decodeObjectForKey:@"latitude"];
        self.longitude = [decoder decodeObjectForKey:@"longitude"];
        self.epochTime = [decoder decodeObjectForKey:@"epochTime"];
        self.isRecommendedToUser = [decoder decodeObjectForKey:@"isRecommendedToUser"];
        self.featured = [decoder decodeObjectForKey:@"featured"];
        self.recCount = [decoder decodeObjectForKey:@"recCount"];
        self.likeCount = [decoder decodeObjectForKey:@"likeCount"];
        self.viewCount = [decoder decodeObjectForKey:@"viewCount"];
        self.locationName = [decoder decodeObjectForKey:@"locationName"];
        self.locationHours = [decoder decodeObjectForKey:@"locationHours"];
        self.address = [decoder decodeObjectForKey:@"address"];
        self.foursquareid = [decoder decodeObjectForKey:@"foursquareid"];
        self.user = [decoder decodeObjectForKey:@"user"];
        self.withFriends = [decoder decodeObjectForKey:@"withFriends"];
        self.likers = [decoder decodeObjectForKey:@"likers"];
        self.viewers = [decoder decodeObjectForKey:@"viewers"];
        self.recommendedEpochTime = [decoder decodeObjectForKey:@"recommendedEpochTime"];
        self.recommendedTo = [decoder decodeObjectForKey:@"recommendedTo"];
        self.og = [decoder decodeObjectForKey:@"og"];
        self.venue = [decoder decodeObjectForKey:@"venue"];
        self.FDVenueId = [decoder decodeObjectForKey:@"FDVenueId"];
    }
    return self;
}

@end
