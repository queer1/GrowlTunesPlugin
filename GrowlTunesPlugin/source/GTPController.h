//
//  GTPController.h
//  GrowlTunes
//
//  Created by Rudy Richter on 9/27/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

#import "GrowlAbstractSingletonObject.h"
#import "GTPCommon.h"
#import "GTPSettingsWindowController.h"
#import "GTPNotification.h"

#import "SGHotKey.h"
#import "SGHotKeyCenter.h"
#import "SGKeyCombo.h"

@interface GTPController : GrowlAbstractSingletonObject <GrowlApplicationBridgeDelegate, GTPSettingsProtocol> 
{
	NSMutableDictionary *_settings;
	SGKeyCombo *_keyCombo;
	GTPNotification		*_notification;

	GTPSettingsWindowController *_settingsWindow;
}

- (void)setup;
- (void)showCurrentTrack:(id)sender;
- (void)showSettingsWindow;

#pragma mark Plug-ins

- (BOOL)appInBackground;
- (void)sendNotification:(id)sender;
- (NSData*)artworkForTitle:(NSString *)track byArtist:(NSString *)artist onAlbum:(NSString *)album composedBy:(NSString*)composer isCompilation:(BOOL)compilation;

@property (retain) NSMutableDictionary *settings;
@property (retain) GTPNotification *notification;
@property (retain) SGKeyCombo *keyCombo;
@end
