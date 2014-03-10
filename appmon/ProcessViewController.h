//
//  ProcessViewController.h
//  appmon
//
//  Created by Tom Lodge on 03/03/2014.
//  Copyright (c) 2014 Tom Lodge. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProcessLogger.h"
#import "ProcessCell.h"
#import "Util.h"

@interface ProcessViewController : UITableViewController
@property(nonatomic, strong) NSArray *processes;
@end
