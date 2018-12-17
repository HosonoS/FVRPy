/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Interface file for Heart Rate Monitor app using Bluetooth Low Energy (LE) Heart Rate Service. This app demonstrats the use of CoreBluetooth APIs for LE devices.
 */

#import <Cocoa/Cocoa.h>
#import <CoreBluetooth/CoreBluetooth.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

@interface HeartRateMonitorAppDelegate : NSObject <NSApplicationDelegate, CBCentralManagerDelegate, CBPeripheralDelegate> 
{
    NSWindow *window;
    NSWindow *scanSheet;
    NSView *heartView;
    NSTimer *pulseTimer;
    NSArrayController *arrayController;
    
    CBCentralManager *manager;
    CBPeripheral *peripheral;
    CBPeripheral *fvr;
    
    NSString *sensorData;
    char *sendData;
    
    BOOL notifyCheck;
    
    int sock;

    struct sockaddr_in addr;
    
    NSMutableArray *heartRateMonitors;
    
    NSString *manufacturer;
    
    uint16_t heartRate;
    
    IBOutlet NSButton* connectButton;
    BOOL autoConnect;
    
    // Progress Indicator
    IBOutlet NSButton * indicatorButton;
    IBOutlet NSProgressIndicator *progressIndicator;    
}

//@property (strong, atomic,retain) CBCentral *manager;
//@property (strong, atomic, retain) CBPeripheral *peripheral;
//@property (assign,nonatomic) NSString *sensorData;

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *scanSheet;
@property (assign) IBOutlet NSView *heartView;
@property (assign) IBOutlet NSArrayController *arrayController;
@property (assign) uint16_t heartRate;
@property (retain) NSTimer *pulseTimer;
@property (retain) NSMutableArray *heartRateMonitors;
@property (copy) NSString *manufacturer;
@property (copy) NSString *connected;

- (IBAction) openScanSheet:(id) sender;
- (IBAction) closeScanSheet:(id)sender;
- (IBAction) cancelScanSheet:(id)sender;
- (IBAction) connectButtonPressed:(id)sender;

- (void) startScan;
- (void) stopScan;
- (BOOL) isLECapableHardware;

- (void) pulse;
- (void) updateWithHRMData:(NSData *)data;


@end
