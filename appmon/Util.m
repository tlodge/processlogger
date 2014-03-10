//
//  Util.m
//  appmon
//
//  Created by Tom Lodge on 07/03/2014.
//  Copyright (c) 2014 Tom Lodge. All rights reserved.
//

#import "Util.h"

@implementation Util

+(NSString *) tsToString:(long) seconds{
    NSString* running;
    
    if (seconds < 60){ //seconds
        running = [NSString stringWithFormat:@"%lu sec", seconds];
    }else if (seconds < 60*60){// minutes
        running = [NSString stringWithFormat:@"%lu min", seconds / 60];
    }else if (seconds < 60 * 60 * 24){ //hours
        running = [NSString stringWithFormat:@"%lu hr", seconds / (60*60)];
    }
    else{ //days
        running = [NSString stringWithFormat:@"%lu days", seconds / (60*60*24)];
    }
    return running;
}

@end
