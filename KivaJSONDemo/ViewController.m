@interface NSDictionary(JSONCategories)
+(NSDictionary*)dictionaryWithContentsOfJSONURLString:
(NSString*)urlAddress;
-(NSData*)toJSON;
@end

@implementation NSDictionary(JSONCategories)
+(NSDictionary*)dictionaryWithContentsOfJSONURLString:
(NSString*)urlAddress
{
    NSData* data = [NSData dataWithContentsOfURL:
                    [NSURL URLWithString: urlAddress] ];
    __autoreleasing NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:data
                                                options:kNilOptions error:&error];
    if (error != nil) return nil;
    return result;
}

-(NSData*)toJSON
{
    NSError* error = nil;
    id result = [NSJSONSerialization dataWithJSONObject:self
                                                options:kNilOptions error:&error];
    if (error != nil) return nil;
    return result;    
}
@end

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //1
#define kLatestKivaLoansURL [NSURL URLWithString:@"http://api.kivaws.org/v1/loans/search.json?status=fundraising"] //2

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    dispatch_async(kBgQueue, ^{
        NSData *data = [NSData dataWithContentsOfURL:kLatestKivaLoansURL];
        [self performSelectorOnMainThread:@selector(fetchData:) withObject:data waitUntilDone:YES];
    });
}


- (void)fetchData:(NSData *)responseData{
    //parse out the json data
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData
                                                         options:kNilOptions
                                                           error:&error];
    NSArray *latestLoans = [json objectForKey:@"loans"];
    NSLog(@"loans %@", latestLoans);
    
    
    //Get the latest loan
    NSDictionary *loan = [latestLoans objectAtIndex:0];
    
    //Get the funded amount and loan amount
    NSNumber *fundedAmount = [loan objectForKey:@"funded_amount"];
    NSNumber *loanAmount = [loan objectForKey:@"loan_amount"];
    
    float outstandingAmount = [loanAmount floatValue] - [fundedAmount floatValue];
    
    //Set the label apppropriately
    
    self.humanReadable.text = [NSString stringWithFormat:@"Latest loan: %@ from %@ needs anouther $%.2f to persue their entrepreneural dream", [loan objectForKey:@"name"], [[loan objectForKey:@"location"] objectForKey:@"country"], outstandingAmount];
    
    
    //build an info object and convert to json
    NSDictionary *info = @{
                           @"who": [loan objectForKey:@"name"],
                           @"where": [[loan objectForKey:@"location"] objectForKey:@"country"],
                           @"what": [NSNumber numberWithFloat:outstandingAmount]
                           };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:info options:NSJSONWritingPrettyPrinted error:&error];
    
    self.jsonSummary.text = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    
}

@end
