//  GrowlTunes.c
//  GrowlTunesPlugin
//
//  Created by rudy on 11/27/05.
//  Copyright 2005-2007, The Growl Project. All rights reserved.


/**\
|**|	includes
\**/

#include "iTunesVisualAPI.h"
#include "iTunesAPI.h"
#import "GTPController.h"

/**\
|**|	typedef's, struct's, enum's, etc.
\**/

#ifndef GROWLTUNES_EXPORT
#define GROWLTUNES_EXPORT __attribute__((visibility("default")))
#endif

#define kTVisualPluginName              CFSTR("GrowlTunes")
#define	kTVisualPluginCreator           'GRWL'
#define kBundleID						CFSTR("info.growl.growltunesplugin")

#define	kTVisualPluginMajorVersion		1
#define	kTVisualPluginMinorVersion		0
#define	kTVisualPluginReleaseStage		finalStage
#define	kTVisualPluginNonFinalRelease	0


#define GTP CFSTR("info.growl.growltunes")

void GetVisualName( ITUniStr255 name );

/**\
|**|	exported function prototypes
\**/

extern OSStatus iTunesPluginMainMachO(OSType message, PluginMessageInfo *messageInfo, void *refCon);

static void RequestArtwork( VisualPluginData * visualPluginData )
{
    OSStatus status = PlayerRequestCurrentTrackCoverArt( visualPluginData->appCookie, visualPluginData->appProc );
}

/*
	Name: VisualPluginHandler
	Function: handles the event loop that iTunes provides through the iTunes visual plugin api
*/
static OSStatus VisualPluginHandler(OSType message, VisualPluginMessageInfo *messageInfo, void *refCon)
{
	OSStatus         err = noErr;
	VisualPluginData *visualPluginData;
	visualPluginData = (VisualPluginData *)refCon;

	
	if (message != 'vrnd') 
	{
		char *string = (char *)&message;
		NSLog(@"%s %c%c%c%c\n", __FUNCTION__, string[0], string[1], string[2], string[3]);
	}
	

	err = noErr;

	switch (message) 
	{
		/*
			Sent when the visual plugin is registered.  The plugin should do minimal
			memory allocations here.  The resource fork of the plugin is still available.
		*/
		case kVisualPluginInitMessage:
			visualPluginData = (VisualPluginData *)calloc(1, sizeof(VisualPluginData));
			if (!visualPluginData) 
			{
				err = memFullErr;
				break;
			}

			visualPluginData->appCookie	= messageInfo->u.initMessage.appCookie;
			visualPluginData->appProc	= messageInfo->u.initMessage.appProc;
            
            messageInfo->u.initMessage.unused = kPluginWantsToBeLeftOpen;
			messageInfo->u.initMessage.refCon = (void *)visualPluginData;

			break;

		/*
			Sent when the visual plugin is unloaded
		*/
		case kVisualPluginCleanupMessage:
			if (visualPluginData)
				free(visualPluginData);
			break;

		/*
			Sent when the visual plugin is enabled.  iTunes currently enables all
			loaded visual plugins.  The plugin should not do anything here.
		*/
		case kVisualPluginEnableMessage:
		case kVisualPluginDisableMessage:
			break;

		/*
			Sent if the plugin requests idle messages.  Do this by setting the kVisualWantsIdleMessages
			option in the RegisterVisualMessage.options field.
		*/
		case kVisualPluginIdleMessage:
			break;

		/*
			Sent if the plugin requests the ability for the user to configure it.  Do this by setting
			the kVisualWantsConfigure option in the RegisterVisualMessage.options field.
		*/
		case kVisualPluginConfigureMessage: 
		{
			//TODO: set this up to bring up the GTP settings dialog
			//run the cocoa dialog through the GTPC
			[[GTPController sharedInstance] showSettingsWindow];
			break;
		}

		/*
			Sent when the player starts.
		*/
		case kVisualPluginPlayMessage: 
		case kVisualPluginChangeTrackMessage:
		{
            
            visualPluginData->playing = true;
            if (messageInfo->u.playMessage.trackInfo)
				visualPluginData->trackInfo = *messageInfo->u.playMessage.trackInfo;
			else
				memset(&visualPluginData->trackInfo, 0, sizeof(visualPluginData->trackInfo));
			
			if (messageInfo->u.playMessage.streamInfo)
				visualPluginData->streamInfo = *messageInfo->u.playMessage.streamInfo;
			else
				memset(&visualPluginData->streamInfo, 0, sizeof(visualPluginData->streamInfo));
            
            
			GTPNotification *notification = [[GTPController sharedInstance] notification];
			[notification setVisualPluginData:visualPluginData];
			[notification setState:(message == kVisualPluginPlayMessage)];
            
            RequestArtwork( visualPluginData );
			break;
		}
            
		/*
			Sent when the player changes the current track information.  This
			is used when the information about a track changes,or when the CD
			moves onto the next track.  The visual plugin should update any displayed
			information about the currently playing song.
		*/
		case kVisualPluginCoverArtMessage:
		{
            //Get cover art
            GTPNotification *notification = [[GTPController sharedInstance] notification];
            CFDataRef coverArt = messageInfo->u.coverArtMessage.coverArt;
            OSType format = messageInfo->u.coverArtMessage.coverArtFormat;
            
            if(coverArt)
            {
                NSImage *imageArt = [[[NSImage alloc] initWithData:(NSData*)coverArt] autorelease];
                notification.artwork = [imageArt TIFFRepresentation];
            }
            
            if(!notification.artwork)
                notification.artwork = [[[NSWorkspace sharedWorkspace] iconForApplication:@"iTunes"] TIFFRepresentation];
            
			[[GTPController sharedInstance] sendNotification:nil];

            break;
		}

		/*
			Sent when the player stops.
		*/
		case kVisualPluginStopMessage:
			visualPluginData->playing = false;
			break;

		/*
			Sent when the player changes position.
		*/
		case kVisualPluginSetPositionMessage:
			break;

		default:
			err = unimpErr;
			break;
	}

	return err;
}

void GetVisualName( ITUniStr255 name )
{
	CFIndex length = CFStringGetLength( kTVisualPluginName );
    
	name[0] = (UniChar)length;
	CFStringGetCharacters( kTVisualPluginName, CFRangeMake( 0, length ), &name[1] );
}

/*
	Name: RegisterVisualPlugin
	Function: registers GrowlTunes with the iTunes plugin api
*/
static OSStatus RegisterVisualPlugin(PluginMessageInfo *messageInfo)
{
	PlayerMessageInfo playerMessageInfo;

	memset(&playerMessageInfo.u.registerVisualPluginMessage, 0, sizeof(playerMessageInfo.u.registerVisualPluginMessage));

	GetVisualName( playerMessageInfo.u.registerVisualPluginMessage.name );

	SetNumVersion(&playerMessageInfo.u.registerVisualPluginMessage.pluginVersion, kTVisualPluginMajorVersion, kTVisualPluginMinorVersion, kTVisualPluginReleaseStage, kTVisualPluginNonFinalRelease);

	playerMessageInfo.u.registerVisualPluginMessage.options        = kVisualWantsConfigure;
	playerMessageInfo.u.registerVisualPluginMessage.handler        = (VisualPluginProcPtr)VisualPluginHandler;
	playerMessageInfo.u.registerVisualPluginMessage.registerRefCon = NULL;
	playerMessageInfo.u.registerVisualPluginMessage.creator        = kTVisualPluginCreator;

	return PlayerRegisterVisualPlugin(messageInfo->u.initMessage.appCookie, messageInfo->u.initMessage.appProc, &playerMessageInfo);
}

/*
	Name: iTunesPluginMainMachO
	Function: the main entrypoint for the plugin, handles the init and dealloc messages that are given to it by iTunes
*/
GROWLTUNES_EXPORT OSStatus iTunesPluginMainMachO(OSType message, PluginMessageInfo *messageInfo, void *refCon)
{
#pragma unused(refCon)
	OSStatus		err = noErr;
	switch (message) 
	{
		case kPluginInitMessage:
			err = RegisterVisualPlugin(messageInfo);

			[[GTPController sharedInstance] setup];
			
			break;

		case kPluginCleanupMessage:
			err = noErr;

			break;

		default:
			err = unimpErr;
			break;
	}
	
	return err;
}
