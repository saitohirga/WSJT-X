//
//  main.m
//  KVASD-installer
//
//  Created by Bill Somerville (G4WJS) on 22/11/2014.
//  Copyright (c) 2014 WSJT. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <AppleScriptObjC/AppleScriptObjC.h>

int main(int argc, const char * argv[])
{
    [[NSBundle mainBundle] loadAppleScriptObjectiveCScripts];
    return NSApplicationMain(argc, argv);
}
