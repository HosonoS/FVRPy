/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Implementatin of Heart Rate Monitor app using Bluetooth Low Energy (LE) Heart Rate Service. This app demonstrats the use of CoreBluetooth APIs for LE devices.
 */

#import "HeartRateMonitorAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#define FVR_DEVICE_NAME @"H2L-01-S100"

@implementation HeartRateMonitorAppDelegate

@synthesize window;
@synthesize heartRate;
@synthesize heartView;
@synthesize pulseTimer;
@synthesize scanSheet;
@synthesize heartRateMonitors;
@synthesize arrayController;
@synthesize manufacturer;
@synthesize connected;

#define PULSESCALE 1.2
#define PULSEDURATION 0.2

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.heartRate = 0;
    autoConnect = TRUE;   /* uncomment this line if you want to automatically connect to previosly known peripheral */
    self.heartRateMonitors = [NSMutableArray array];
       
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.];
    [self.heartView layer].position = CGPointMake( [[self.heartView layer] frame].size.width / 2, [[self.heartView layer] frame].size.height / 2 );
    [self.heartView layer].anchorPoint = CGPointMake(0.5, 0.5);
    [NSAnimationContext endGrouping];

    //下１行勝手に足した
    //dispatch_queue_t que = dispatch_queue_create("hoge.hoge", DISPATCH_QUEUE_SERIAL);
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    if( autoConnect )
    {
        [self startScan];
    }
}

- (void) dealloc
{
    [self stopScan];
    
    [peripheral setDelegate:nil];
    //ここでリリース
    NSLog(@"ここでリリース2");
    [peripheral release];
    
    [heartRateMonitors release];
        
    [manager release];
    
    [super dealloc];
}

/* 
 Disconnect peripheral when application terminate 
*/
- (void) applicationWillTerminate:(NSNotification *)notification
{
    if(peripheral)
    {
        NSLog(@"キャンセル呼ばれた");
        [manager cancelPeripheralConnection:peripheral];
    }
}

#pragma mark - Scan sheet methods

/* 
 Open scan sheet to discover heart rate peripherals if it is LE capable hardware 
*/
- (IBAction)openScanSheet:(id)sender 
{
    if( [self isLECapableHardware] )
    {
        NSLog(@"Hellooooooo");
        autoConnect = TRUE;
        [arrayController removeObjects:heartRateMonitors];
        [window beginSheet:self.scanSheet completionHandler:^(NSModalResponse returnCode) {
            [self sheetDidEnd:self.scanSheet returnCode:returnCode contextInfo:nil];
        } ];
        [self startScan];
    }

    sock = socket(AF_INET, SOCK_DGRAM, 0);
    
    addr.sin_family = AF_INET;
    addr.sin_port = htons(12345);
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    
    //sendto(sock, "HELLO", 5, 0, (struct sockaddr *)&addr, sizeof(addr));
    
    //close(sock);
}

/*
 Close scan sheet once device is selected
*/
- (IBAction)closeScanSheet:(id)sender
{
    [window endSheet:self.scanSheet returnCode:NSAlertFirstButtonReturn];
}

/*
 Close scan sheet without choosing any device
*/
- (IBAction)cancelScanSheet:(id)sender
{
    [window endSheet:self.scanSheet returnCode:NSAlertSecondButtonReturn];
}

/* 
 This method is called when Scan sheet is closed. Initiate connection to selected heart rate peripheral
*/
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo 
{
    [self stopScan];
    if( returnCode == NSAlertFirstButtonReturn )
    {
        NSIndexSet *indexes = [self.arrayController selectionIndexes];
        if ([indexes count] != 0) 
        {
            NSUInteger anIndex = [indexes firstIndex];
            peripheral = [self.heartRateMonitors objectAtIndex:anIndex];
            [peripheral retain];
            [indicatorButton setHidden:FALSE];
            [progressIndicator setHidden:FALSE];
            [progressIndicator startAnimation:self];
            [connectButton setTitle:@"Cancel"];
            [manager connectPeripheral:peripheral options:nil];
        }
    }
}

#pragma mark - Connect Button

/*
 This method is called when connect button pressed and it takes appropriate actions depending on device connection state
 */
- (IBAction)connectButtonPressed:(id)sender
{
    notifyCheck = false;
    
    if(peripheral && (peripheral.state == CBPeripheralStateConnected))
    { 
        /* Disconnect if it's already connected */
        NSLog(@"キャンセル呼ばれた２");
        [manager cancelPeripheralConnection:peripheral]; 
    }
    else if (peripheral)
    {
        /* Device is not connected, cancel pendig connection */
        [indicatorButton setHidden:TRUE];
        [progressIndicator setHidden:TRUE];
        [progressIndicator stopAnimation:self];
        [connectButton setTitle:@"Connect"];
        NSLog(@"キャンセル呼ばれた３");
        [manager cancelPeripheralConnection:peripheral];
        [self openScanSheet:nil];
    }
    else
    {   /* No outstanding connection, open scan sheet */
        [self openScanSheet:nil];
    }
}

#pragma mark - Heart Rate Data

/* 
 Update UI with heart rate data received from device
 */
/*
- (void) updateWithHRMData:(NSData *)data 
{
    const uint8_t *reportData = [data bytes];
    uint16_t bpm = 0;
    
    if ((reportData[0] & 0x01) == 0) 
    {
        // uint8 bpm
        bpm = reportData[1];
    } 
    else 
    {
        // uint16 bpm
        bpm = CFSwapInt16LittleToHost(*(uint16_t *)(&reportData[1]));
    }
    
    uint16_t oldBpm = self.heartRate;
    self.heartRate = bpm;
    if (oldBpm == 0 && bpm != 0) 
    {
        [self pulse];
        self.pulseTimer = [NSTimer scheduledTimerWithTimeInterval:(60. / heartRate) target:self selector:@selector(pulse) userInfo:nil repeats:NO];
    }
}
*/

/*
 Update pulse UI
 */

/*
- (void) pulse 
{
    CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    
    pulseAnimation.toValue = [NSNumber numberWithFloat:PULSESCALE];
    pulseAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    
    pulseAnimation.duration = PULSEDURATION;
    pulseAnimation.repeatCount = 1;
    pulseAnimation.autoreverses = YES;
    pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    [[heartView layer] addAnimation:pulseAnimation forKey:@"scale"];
    
    if (heartRate == 0) 
    {
        [self.pulseTimer invalidate];
        self.pulseTimer = nil;
    } 
    else
    {
        self.pulseTimer = [NSTimer scheduledTimerWithTimeInterval:(60. / heartRate) target:self selector:@selector(pulse) userInfo:nil repeats:NO];
    }
}
*/

#pragma mark - Start/Stop Scan methods

/*
 Uses CBCentralManager to check whether the current platform/hardware supports Bluetooth LE. An alert is raised if Bluetooth LE is not enabled or is not supported.
 */
- (BOOL) isLECapableHardware
{
    NSString * state = nil;
    
    switch ([manager state]) 
    {
        case CBManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBManagerStatePoweredOn:
            return TRUE;
        case CBManagerStateUnknown:
            NSLog(@"State Unknown");
        default:
            return FALSE;
            
    }
    
    NSLog(@"Central manager state: %@", state);
    
    [self cancelScanSheet:nil];
    
    //ここでリリース
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:state];
    [alert addButtonWithTitle:@"OK"];
    [alert setIcon:[[[NSImage alloc] initWithContentsOfFile:@"AppIcon"] autorelease]];
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
        return;
    }];
    return FALSE;
}

/*
 Request CBCentralManager to scan for heart rate peripherals using service UUID 0x180D
 */
- (void) startScan 
{
    //[manager scanForPeripheralsWithServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"FE59"]] options:nil];
    [manager scanForPeripheralsWithServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"]] options:nil];
    //[manager scanForPeripheralsWithServices:nil options:nil];
    
}

/*
 Request CBCentralManager to stop scanning for heart rate peripherals
 */
- (void) stopScan 
{
    [manager stopScan];
}

#pragma mark - CBCentralManager delegate methods
/*
 Invoked whenever the central manager's state is updated.
 */
- (void) centralManagerDidUpdateState:(CBCentralManager *)central 
{
    [self isLECapableHardware];
}
    
/*
 Invoked when the central discovers heart rate peripheral while scanning.
*/
- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)aPeripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI 
{
    //NSString *peripheralName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
    NSString *peripheralUUID = aPeripheral.identifier.UUIDString;
    NSLog(@"%@",peripheralUUID);
    NSString *deviceName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
    
    
    if([deviceName isEqualToString:FVR_DEVICE_NAME]){
        peripheral = aPeripheral;
        NSLog(@"Discovered!!!");
        //[manager connectPerihperal:peripheral options:nil];
        [self stopScan];
        
        [manager connectPeripheral:peripheral options:nil];
     }
    
    NSMutableArray *peripherals = [self mutableArrayValueForKey:@"heartRateMonitors"];
    //NSMutableArray *peripherals = [self mutableArrayValueForKey:[advertisementData objectForKey:@"kCBAdvDataLocalName"]];
    if( ![self.heartRateMonitors containsObject:aPeripheral] )
        [peripherals addObject:aPeripheral];
    
    /* Retreive already known devices */
    if(autoConnect)
    {
        [manager retrievePeripheralsWithIdentifiers:[NSArray arrayWithObject:(id)aPeripheral.identifier]];
    }
    
}

/*
 Invoked when the central manager retrieves the list of known peripherals.
 Automatically connect to first known peripheral
 */
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"Retrieved peripheral: %lu - %@", [peripherals count], peripherals);
    
    [self stopScan];
    
    /* If there are any known devices, automatically connect to it.*/
    if([peripherals count] >=1)
    {
        [indicatorButton setHidden:FALSE];
        [progressIndicator setHidden:FALSE];
        [progressIndicator startAnimation:self];
        peripheral = [peripherals objectAtIndex:0];
        [peripheral retain];
        [connectButton setTitle:@"Cancel"];
        //元の読み出し
        [manager connectPeripheral:peripheral options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
        [manager connectPeripheral:peripheral options:nil];
    }
}

/*
 Invoked whenever a connection is succesfully created with the peripheral. 
 Discover available services on the peripheral
 */
- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)aPeripheral 
{    
    [aPeripheral setDelegate:self];
    [aPeripheral discoverServices:nil];
	
    
	self.connected = @"Connected";
    [connectButton setTitle:@"Disconnect"];
    [indicatorButton setHidden:TRUE];
    [progressIndicator setHidden:TRUE];
    [progressIndicator stopAnimation:self];
    
}

/*
 Invoked whenever an existing connection with the peripheral is torn down. 
 Reset local variables
 */


- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
	self.connected = @"Not connected";
    [connectButton setTitle:@"Connect"];
    self.manufacturer = @"";
    self.heartRate = 0;
    
    if( peripheral )
    {
        [peripheral setDelegate:nil];
        NSLog(@"ここでリリース");
        [peripheral release];
        peripheral = nil;
    }
}


/*
 Invoked whenever the central manager fails to create a connection with the peripheral.
 */


- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    NSLog(@"Fail to connect to peripheral: %@ with error = %@", aPeripheral, [error localizedDescription]);
    [connectButton setTitle:@"Connect"]; 
    if( peripheral )
    {
        [peripheral setDelegate:nil];
        //ここでリリース
        NSLog(@"ここでリリース1");
        [peripheral release];
        peripheral = nil;
    }
}


#pragma mark - CBPeripheral delegate methods
/*
 Invoked upon completion of a -[discoverServices:] request.
 Discover available characteristics on interested services
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error 
{
    for (CBService *aService in aPeripheral.services) 
    {
        NSLog(@"Service found with UUID: %@", aService.UUID);
    }
    
    NSArray *services = aPeripheral.services;
    //NSLog(@"Found %lu services! :%@", (unsigned long)services.count, services);
    [peripheral discoverCharacteristics:nil forService:services[0]];
    
    
}

/*
 Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 Perform appropriate operations on interested characteristics
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if(error){
        NSLog(@"error %@ didDiscoverCharacteristicsForService",error);
        return;
    }
    
    NSArray *characteristics = service.characteristics;
    
    if(!notifyCheck){
        [aPeripheral setNotifyValue:YES forCharacteristic:characteristics[1]];
        notifyCheck = true;
    }
    [aPeripheral readValueForCharacteristic:characteristics[1]];
}

/*
 Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error 
{
    //エラーチェック
    if(error){
        NSLog(@"error %@",error);
        return;
    }
    
    [aPeripheral readValueForCharacteristic:characteristic];
    
    NSString *sensorData = [[NSString alloc] initWithBytes:[characteristic.value bytes] length:[characteristic.value length] encoding:NSUTF8StringEncoding];
    //NSString *message = [NSString stringWithFormat:@"%@", sensorData];

    //char sensorDataPython = *(char *) [sensorData UTF8String];
    sendData = [sensorData UTF8String];
    
    NSLog(@"%@",sensorData);

    sendto(sock, sendData, [sensorData length], 0, (struct sockaddr *)&addr, sizeof(addr));

}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"Notify状態更新失敗...error:%@", error);
    }
    else {
        NSLog(@"Notify状態更新成功！ isNotifying:%d", characteristic.isNotifying);
    }
}

@end
