//
//  Process.h
//  appmon
//
//  Created by Tom Lodge on 06/03/2014.
//  Copyright (c) 2014 Tom Lodge. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Process : NSObject
@property(nonatomic,strong) NSString  *name;
@property(nonatomic,assign) unsigned long starttime;
@end
