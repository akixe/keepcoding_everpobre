#import "AOANote.h"
#import "AOALocation.h"
@interface AOANote ()<CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation AOANote

@synthesize locationManager = _locationManager;

-(BOOL) hasLocation
{
    return (nil != self.location);
}

+(NSArray *) observableKeyNames{
    return @[@"creationDate", @"name", @"notebook", @"photo", @"location"];
}

+(instancetype) noteWithName:(NSString *) name notebook:(AOANotebook *) notebook context: (NSManagedObjectContext *) context{
    AOANote *n = [NSEntityDescription insertNewObjectForEntityForName:[AOANote entityName] inManagedObjectContext:context];
    
    n.creationDate = [NSDate date];
    n.notebook = notebook;
    n.modificationDate = [NSDate date];
    n.name = name;
    
    return n;
}

#pragma mark - Init
-(void) awakeFromInsert
{
    [super awakeFromInsert];
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    if (((status == kCLAuthorizationStatusAuthorizedWhenInUse) || (status == kCLAuthorizationStatusNotDetermined)) && [CLLocationManager locationServicesEnabled]){

        
        //Tenemos localización
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;

        //Para que funcione en ios7 y 8 es necesario llamar a requestWhenInUseAuthorization y espear la respuesta con el método de delegado locationManager:didChangeAuthorizationStatus
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0 && status != kCLAuthorizationStatusAuthorizedWhenInUse){
            [self.locationManager requestWhenInUseAuthorization];
            //realizaremos llamada startUpdatingLocation en el método delegado locationManager:didChangeAuthorizationStatus
        } else {
            [self.locationManager startUpdatingLocation];
        }

        
        //Límite de tiempo para obtener localicazión
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self zapLocationManager];
        });
    }
}


#pragma mark - CLLocationManagerDelegate
-(void)     locationManager: (CLLocationManager *) manager
         didUpdateLocations: (nonnull NSArray<CLLocation *> *)locations
{
    [self zapLocationManager];
    if(![self hasLocation]){
        CLLocation *location = [locations lastObject];
        self.location = [AOALocation locationWithCLLocation:location forNote:self];
    } else {
        NSLog(@"No se ha obtenido localización");
    }
    
    
    
}

- (void)locationManager:(CLLocationManager*)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined: {
            NSLog(@"User still thinking..");
        } break;
        case kCLAuthorizationStatusDenied: {
            NSLog(@"User hates you");
        } break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways: {
            [_locationManager startUpdatingLocation]; //Will update location immediately
        } break;
        default:
            break;
    }
}



#pragma mark - Utils
-(void) zapLocationManager
{
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil; //Por los bugs que hay
    self.locationManager = nil;
}
@end
