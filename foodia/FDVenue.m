//
//  FDVenue.m
//  
//
//  Created by Max Haines-Stiles on 8/4/12.
//  Copyright (c) 2012 FOODIA. All rights reserved.
//

#import "FDVenue.h"

#import "FoursquareCategory.h"
#import "FDVenueContact.h"
#import "FDVenueLocation.h"

@implementation FDVenue

@synthesize categories;
@synthesize contact;
@synthesize FDVenueId;
@synthesize location;
@synthesize name;
@synthesize hours;
@synthesize isOpen;
@synthesize verified;
@synthesize tips, totalCheckins, hereNow;
@synthesize stats, url, menuUrl, reservationsUrl;
@synthesize posts;
@synthesize imageView;
@synthesize imageViewUrl;
@synthesize likes = likes_;

#pragma mark - MKAnnotation Properties

- (CLLocationCoordinate2D)coordinate {
    return CLLocationCoordinate2DMake(self.location.lat.floatValue, self.location.lng.floatValue);
}

- (NSString *)title {
    return self.name;
}
- (NSString *)subtitle {
    if (self.location.hasLocalityInfo) return self.location.locality;
    else return nil;
}

#pragma mark - Encoding / Decoding Methods

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.categories forKey:@"categories"];
    [encoder encodeObject:self.contact forKey:@"contact"];
    [encoder encodeObject:self.FDVenueId forKey:@"FDVenueId"];
    [encoder encodeObject:self.location forKey:@"location"];
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.hours forKey:@"hours"];
    [encoder encodeObject:self.statusHours forKey:@"statusHours"];
    [encoder encodeObject:[NSNumber numberWithBool:self.verified] forKey:@"verified"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init])) {
        self.categories = [decoder decodeObjectForKey:@"categories"];
        self.contact = [decoder decodeObjectForKey:@"contact"];
        self.FDVenueId = [decoder decodeObjectForKey:@"FDVenueId"];
        self.location = [decoder decodeObjectForKey:@"location"];
        self.name = [decoder decodeObjectForKey:@"name"];
        self.hours = [decoder decodeObjectForKey:@"hours"];
        self.statusHours = [decoder decodeObjectForKey:@"statusHours"];
        self.verified = [(NSNumber *)[decoder decodeObjectForKey:@"verified"] boolValue];
    }
    return self;
}

+ (FDVenue *)instanceFromDictionary:(NSDictionary *)aDictionary
{
    FDVenue *instance = [[FDVenue alloc] init];
    [instance setAttributesFromDictionary:aDictionary];
    return instance;
}

- (FDVenue *)setAttributesFromDictionary:(NSDictionary *)aDictionary
{

    if (![aDictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }

    [self setValuesForKeysWithDictionary:aDictionary];
    return self;
}

- (void)setValue:(id)value forKey:(NSString *)key
{

    if ([key isEqualToString:@"categories"]) {
        if ([value isKindOfClass:[NSArray class]])
        {
            NSMutableArray *myMembers = [NSMutableArray arrayWithCapacity:[value count]];
            for (id valueMember in value) {
                FoursquareCategory *populatedMember = [FoursquareCategory instanceFromDictionary:valueMember];
                [myMembers addObject:populatedMember];
            }
            self.categories = myMembers;
        }

    } else if ([key isEqualToString:@"hours"]) {
        NSMutableArray *unparsedHours = [NSMutableArray arrayWithCapacity:[value count]];
        for (NSDictionary *timeDict in [value valueForKey:@"timeframes"]){
            if (timeDict != nil)[unparsedHours addObject:timeDict];
        }
        self.hours = unparsedHours;
        if ([value objectForKey:@"isOpen"]) {
            self.isOpen = YES;
        } else {
            self.isOpen = NO;
        }
        self.statusHours = [value objectForKey:@"status"];
    } else if ([key isEqualToString:@"contact"]) {

        if ([value isKindOfClass:[NSDictionary class]]) {
            self.contact = [FDVenueContact instanceFromDictionary:value];
        }

    } else if ([key isEqualToString:@"location"]) {
        if ([value isKindOfClass:[NSDictionary class]]) {
            self.location = [FDVenueLocation instanceFromDictionary:value];
        }

    }  else if ([key isEqualToString:@"stats"]) {
        if ([value isKindOfClass:[NSDictionary class]]) {
            self.totalCheckins = [value objectForKey:@"checkinsCount"];
        }
        
    }  else if ([key isEqualToString:@"hereNow"]) {
        if ([value isKindOfClass:[NSDictionary class]]) {
            self.hereNow = [value objectForKey:@"count"];
        }
        
    }  else if ([key isEqualToString:@"url"]) {
        //good
        self.url = value;
        
    }  else if ([key isEqualToString:@"reservations"]) {
        //good
        if ([value isKindOfClass:[NSDictionary class]]) {
            self.reservationsUrl = [value objectForKey:@"url"];
        }
    } else if ([key isEqualToString:@"tips"]) {
        //NSLog(@"tips value: %@",value);
        if ([value isKindOfClass:[NSDictionary class]]) {
            self.tips = value;
        }
        
    }  else if ([key isEqualToString:@"menu"]) {
        //good
        if ([value isKindOfClass:[NSDictionary class]]) {
            self.menuUrl = [value objectForKey:@"mobileUrl"];
        }
        
    }  else if ([key isEqualToString:@"likes"]) {
        
        if ([value isKindOfClass:[NSDictionary class]]) {
            self.likes = value;
        }
        
    } else {
        [super setValue:value forKey:key];
    }
}


- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    if ([key isEqualToString:@"id"]) {
        [self setValue:value forKey:@"FDVenueId"];
    }
}

- (NSDictionary *)dictionaryRepresentation
{

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    if (self.categories) {
        [dictionary setObject:self.categories forKey:@"categories"];
    }

    if (self.hours) {
        [dictionary setObject:self.hours forKey:@"hours"];
        [dictionary setObject:self.statusHours forKey:@"status"];
    }
    
    if (self.contact) {
        [dictionary setObject:self.contact forKey:@"contact"];
    }

    if (self.FDVenueId) {
        [dictionary setObject:self.FDVenueId forKey:@"FDVenueId"];
    }

    if (self.location) {
        [dictionary setObject:self.location forKey:@"location"];
    }

    if (self.name) {
        [dictionary setObject:self.name forKey:@"name"];
    }
    
    if (self.menuUrl) {
        [dictionary setObject:self.menuUrl forKey:@"menuUrl"];
    }
    
    if (self.reservationsUrl) {
        [dictionary setObject:self.reservationsUrl forKey:@"reservationsUrl"];
    }
    
    if (self.stats) {
        [dictionary setObject:self.stats forKey:@"stats"];
    }
    
    if (self.totalCheckins) {
        [dictionary setObject:self.totalCheckins forKey:@"totalCheckins"];
    }
    
    if (self.hereNow) {
        [dictionary setObject:self.hereNow forKey:@"hereNow"];
    }
    if (self.url) {
        [dictionary setObject:self.url forKey:@"url"];
    }
    
    
    [dictionary setObject:[NSNumber numberWithBool:self.verified] forKey:@"verified"];

    return dictionary;

}

@end
