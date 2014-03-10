//
//  RootInfoViewController.m
//  appmon
//
//  Created by Tom Lodge on 07/03/2014.
//  Copyright (c) 2014 Tom Lodge. All rights reserved.
//

#import "RootInfoViewController.h"

@interface RootInfoViewController ()

@end

@implementation RootInfoViewController

@synthesize processViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(monitorSystem:) userInfo:nil repeats:YES];
    
	// Do any additional setup after loading the view.
}

- (void)monitorSystem:(NSTimer *)timer {
    
    long now = [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]integerValue];
    
    NSDictionary *data = [[ProcessLogger logger] sample];
    
    NSDictionary *network   = [data objectForKey:@"network"];
    
    NSArray *processes      = [data objectForKey:@"processes"];
    
    NSString *uptime        = [data objectForKey:@"uptime"];
    //NSString *battery       = [data objectForKey:@"battery"];
    
    _uptimeLabel.text = uptime;
    _wifiUpLabel.text = [NSString stringWithFormat:@"%@", [network objectForKey:@"wifiup"]];
    _wifiDownLabel.text = [NSString stringWithFormat:@"%@", [network objectForKey:@"wifidown"]];
    _cellUpLabel.text =[NSString stringWithFormat:@"%@", [network objectForKey:@"cellup"]];
    _cellDownLabel.text =[NSString stringWithFormat:@"%@", [network objectForKey:@"celldown"]];
    
   
    
    _lastLoggedLabel.text =  [NSString stringWithFormat:@"%@ ago", [Util tsToString:(now - [[ProcessLogger logger] lastLog])]];
    
    processViewController.processes = processes;
    [processViewController.tableView reloadData];
    //[self.tableView reloadData];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSDictionary *data = [[ProcessLogger logger] sample];
    NSArray *processes      = [data objectForKey:@"processes"];
    
    if ([segue.identifier isEqualToString:@"processview_embed"]){
        processViewController  = (ProcessViewController*) [segue destinationViewController];
        processViewController.processes = processes;
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)logToServer:(id)sender {
    NSLog(@"Logging to server!!");
    [[ProcessLogger logger] logToServer];
}

@end
