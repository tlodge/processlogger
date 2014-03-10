//
//  ProcessLogger.m
//  appmon
//
//  Created by Tom Lodge on 03/03/2014.
//  Copyright (c) 2014 Tom Lodge. All rights reserved.
//

#import "ProcessLogger.h"
#include <ifaddrs.h>
#include <net/if.h>
#include <mach/mach_time.h>

@interface ProcessLogger ()
@property(nonatomic, retain) NSString* server_url;
@property(nonatomic, assign) int interval;
@end

@implementation ProcessLogger

@synthesize lastLog;

+(ProcessLogger *) logger{
    static ProcessLogger* logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[ProcessLogger alloc] init];
    });
    return logger;
}

-(id) initWithURL:(NSString*) url andInterval: (int) interval{
    self = [super init];
    self.server_url = url;
    self.interval = interval;
    return self;
}


-(NSArray *) processes{
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0};
    size_t miblen = 4;
    
    size_t size;
    int st = sysctl(mib, miblen, NULL, &size, NULL, 0);
    
    struct kinfo_proc * process = NULL;
    struct kinfo_proc * newprocess = NULL;
    
    do {
        
        size += size / 10;
        newprocess = realloc(process, size);
        
        if (!newprocess){
            
            if (process){
                free(process);
            }
            
            return nil;
        }
        
        process = newprocess;
        st = sysctl(mib, miblen, process, &size, NULL, 0);
        
    } while (st == -1 && errno == ENOMEM);
    
    if (st == 0){
        
        if (size % sizeof(struct kinfo_proc) == 0){
            int nprocess = size / sizeof(struct kinfo_proc);
            
            if (nprocess){
                
                NSMutableArray * array = [[NSMutableArray alloc] init];
                
                for (int i = nprocess - 1; i >= 0; i--){
                    
                    NSString *name = [[NSString alloc] initWithFormat:@"%s", process[i].kp_proc.p_comm];
                    
                    NSNumber *starttime = [NSNumber numberWithLong: process[i].kp_proc.p_un.__p_starttime.tv_sec];
                    
                    NSDictionary* dict = [[NSDictionary alloc] initWithObjects:@[name, starttime] forKeys:@[@"name", @"starttime"]];
                   
                    [array addObject:dict];
                }
                
                free(process);
                NSSortDescriptor* stime = [[NSSortDescriptor alloc] initWithKey:@"starttime" ascending:NO];
            
                
                [array sortUsingDescriptors:[NSArray arrayWithObject: stime]];
                return array;
            }
        }
    }
    return nil;
}


- (int)uptime
{
    struct timeval boottime;
    
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    
    size_t size = sizeof(boottime);
    
    time_t now;
    
    time_t uptime = -1;
    
    (void)time(&now);
    
    if (sysctl(mib, 2, &boottime, &size, NULL, 0) != -1 && boottime.tv_sec != 0)
    {
        uptime = now - boottime.tv_sec;
    }
    return (int)uptime;
}

- (NSArray *)counters
{
    BOOL   success;
    struct ifaddrs *addrs;
    const struct ifaddrs *cursor;
    const struct if_data *networkStatisc;
    
    unsigned long WiFiSent = 0;
    unsigned long WiFiReceived = 0;
    unsigned long WWANSent = 0;
    unsigned long WWANReceived = 0;
    
    NSString *name;
    
    success = getifaddrs(&addrs) == 0;
    if (success)
    {
        cursor = addrs;
        while (cursor != NULL)
        {
            name=[NSString stringWithFormat:@"%s",cursor->ifa_name];
            
            if (cursor->ifa_addr->sa_family == AF_LINK)
            {
                if ([name hasPrefix:@"en"])
                {
                    networkStatisc = (const struct if_data *) cursor->ifa_data;
                    WiFiSent+=networkStatisc->ifi_obytes;
                    WiFiReceived+=networkStatisc->ifi_ibytes;
                }
                if ([name hasPrefix:@"pdp_ip"])
                {
                    networkStatisc = (const struct if_data *) cursor->ifa_data;
                    WWANSent+=networkStatisc->ifi_obytes;
                    WWANReceived+=networkStatisc->ifi_ibytes;
                }
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    
    const int kMB = 1024*1024;
    
    return [NSArray arrayWithObjects:[NSNumber numberWithLong:WiFiSent / kMB], [NSNumber numberWithLong:WiFiReceived/kMB],[NSNumber numberWithLong:WWANSent/kMB],[NSNumber numberWithLong:WWANReceived/kMB], nil];
}

-(NSDictionary *) sample{
    
    NSArray *myprocesses    = [self processes];
    NSArray *counters   = [[ProcessLogger logger] counters];
    
    NSDictionary *network   = [NSDictionary dictionaryWithObjects:@[counters[0], counters[1], counters[2], counters[3]] forKeys:@[@"wifiup", @"wifidown", @"cellup", @"celldown"]];
    
    NSString* uptime        = [Util tsToString:[[ProcessLogger logger] uptime]];
    NSString* battery       = [NSString stringWithFormat:@"%.f", (float)[[UIDevice currentDevice] batteryLevel]];
    
    NSDictionary *datadict = [NSDictionary dictionaryWithObjects:@[myprocesses,network,uptime,battery] forKeys:@[@"processes", @"network", @"uptime", @"battery"]];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:datadict options:0 error:nil];
    
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [self logToFile:jsonString];
    return datadict;
}

-(void) logToServer{
    
    NSDictionary* datadict = [self sample];
    NSError *error = nil;
    NSData *processes = [NSJSONSerialization dataWithJSONObject:datadict options:0 error:&error];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]init];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setURL:[NSURL URLWithString:self.server_url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"%d", [processes length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:processes];
    
    NSHTTPURLResponse* urlResponse = nil;
    
    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse: &urlResponse error:&error];
    
    if (response != nil){
        if(error == nil) {
            lastLog= [[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]]integerValue];
            NSString *result = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
            
            //[[NSNotificationCenter defaultCenter] postNotificationName:@"logged" object:nil];
            NSLog(@"%@", result);
        }
    }
}

- (NSString *)documentsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return (paths.count)? paths[0] : nil;
}

-(void) logToFile:(NSString*)content{
    
    NSString *fileName = [NSString stringWithFormat:@"%@/samples.json", [self documentsDirectory]];
    
    NSLog(@"file name is %@", fileName);
    
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:fileName];
    if (fh){
        [fh seekToEndOfFile];
        [fh writeData:[content dataUsingEncoding:NSUTF8StringEncoding]];
        [fh closeFile];
        NSLog(@"appended data to file!");
    }
    else{
        NSError *error = nil;
        [content writeToFile:fileName atomically:NO encoding:NSUTF8StringEncoding error:&error];
        NSLog(@"created new file!");
    }
}

@end
