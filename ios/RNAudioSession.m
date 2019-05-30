//
//  RNAudioSession.m
//  RNAudioSession
//
//  Created by Johan Kasperi (DN) on 2018-03-02.
//

#import "RNAudioSession.h"
#import <React/RCTLog.h>
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import <AVFoundation/AVFoundation.h>

@implementation RNAudioSession
@synthesize bridge = _bridge;

static NSDictionary *_categories;
static NSDictionary *_options;
static NSDictionary *_modes;

+ (void)initialize {
    _categories = @{
        @"Ambient": AVAudioSessionCategoryAmbient,
        @"SoloAmbient": AVAudioSessionCategorySoloAmbient,
        @"Playback": AVAudioSessionCategoryPlayback,
        @"Record": AVAudioSessionCategoryRecord,
        @"PlayAndRecord": AVAudioSessionCategoryPlayAndRecord,
        @"MultiRoute": AVAudioSessionCategoryMultiRoute
   };
    _options = @{
        @"MixWithOthers": @(AVAudioSessionCategoryOptionMixWithOthers),
        @"DuckOthers": @(AVAudioSessionCategoryOptionDuckOthers),
        @"InterruptSpokenAudioAndMixWithOthers": @(AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers),
        @"AllowBluetooth": @(AVAudioSessionCategoryOptionAllowBluetooth),
        @"AllowBluetoothA2DP": @(AVAudioSessionCategoryOptionAllowBluetoothA2DP),
        @"AllowAirPlay": @(AVAudioSessionCategoryOptionAllowAirPlay),
        @"DefaultToSpeaker": @(AVAudioSessionCategoryOptionDefaultToSpeaker)
    };
    _modes = @{
        @"Default": AVAudioSessionModeDefault,
        @"VoiceChat": AVAudioSessionModeVoiceChat,
        @"VideoChat": AVAudioSessionModeVideoChat,
        @"GameChat": AVAudioSessionModeGameChat,
        @"VideoRecording": AVAudioSessionModeVideoRecording,
        @"Measurement": AVAudioSessionModeMeasurement,
        @"MoviePlayback": AVAudioSessionModeMoviePlayback,
        @"SpokenAudio": AVAudioSessionModeSpokenAudio
    };
}

RCT_EXPORT_MODULE();

- (instancetype)init {
    self = [super init];

    if ( self ) {
        NSLog(@"RNAudioSession init");
    	
		NSLog(@"Set up audio session observer");
		//check audio routes
		[AVAudioSession sharedInstance];
		// Register for Route Change notifications
		[[NSNotificationCenter defaultCenter] addObserver: self
												selector: @selector(handleRouteChange:)
													name: AVAudioSessionRouteChangeNotification
													object: nil];
		
		AVAudioSession *session = [ AVAudioSession sharedInstance ];
		AVAudioSessionPortDescription *input = [[session.currentRoute.inputs count]?session.currentRoute.inputs:nil objectAtIndex:0];
		AVAudioSessionPortDescription *output = [[session.currentRoute.outputs count]?session.currentRoute.outputs:nil objectAtIndex:0];
		
		NSString *inputStr = input.portType ? input.portType : @"";
		NSString *outputStr = output.portType ? output.portType : @"";

		NSLog(@"Initial audio routes");
		NSLog(@"input %@", inputStr);
		NSLog(@"output %@", outputStr);

		[self.bridge.eventDispatcher sendAppEventWithName:@"AudioRouteChanged" body:@{@"input": inputStr, @"output": outputStr, @"reason": @""}];

    }
    return self;
}

RCT_EXPORT_METHOD(category:(RCTResponseSenderBlock)callback)
{
    callback(@[[AVAudioSession sharedInstance].category]);
}

RCT_EXPORT_METHOD(options:(RCTResponseSenderBlock)callback)
{
    callback(@[[NSNumber numberWithInteger:[AVAudioSession sharedInstance].categoryOptions]]);
}

RCT_EXPORT_METHOD(mode:(RCTResponseSenderBlock)callback)
{
    callback(@[[AVAudioSession sharedInstance].mode]);
}

RCT_EXPORT_METHOD(setActive:(BOOL)active resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setActive:active withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    if (error) {
        reject(@"setActive", @"Could not set active.", error);
    } else {
        resolve(@[]);
    }
}

RCT_EXPORT_METHOD(setCategory:(NSString *)category options:(NSString *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString* cat = _categories[category];
    if (cat != nil && [[AVAudioSession sharedInstance].availableCategories containsObject:cat]) {
        NSError *error = nil;
        if (_options[options] != nil) {
            [[AVAudioSession sharedInstance] setCategory:cat withOptions:_options[options] error:&error];
        } else {
            [[AVAudioSession sharedInstance] setCategory:cat error:&error];
        }
        if (error) {
            reject(@"setCategory", @"Could not set category.", error);
        } else {
            resolve(@[]);
        }
    } else {
        NSDictionary *userInfo = @{
            NSLocalizedDescriptionKey: @"Could not set AVAudioSession category.",
            NSLocalizedFailureReasonErrorKey: @"The given category is not supported on this device.",
            NSLocalizedRecoverySuggestionErrorKey: @"Try another category."
        };
        NSError *error = [NSError errorWithDomain:@"RNAudioSession" code:-1 userInfo:userInfo];
        reject(@"setCategory", @"Could not set category.", error);
    }
}

RCT_EXPORT_METHOD(setMode:(NSString *)mode resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString* mod = _modes[mode];
    if (mod != nil && [[AVAudioSession sharedInstance].availableModes containsObject:mod]) {
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setMode:mod error:&error];
        if (error) {
            reject(@"setMode", @"Could not set mode.", error);
        } else {
            resolve(@[]);
        }
    } else {
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: @"Could not set AVAudioSession mode.",
                                   NSLocalizedFailureReasonErrorKey: @"The given mode is not supported on this device.",
                                   NSLocalizedRecoverySuggestionErrorKey: @"Try another mode."
                                   };
        NSError *error = [NSError errorWithDomain:@"RNAudioSession" code:-1 userInfo:userInfo];
        reject(@"setMode", @"Could not set mode.", error);
    }
}

RCT_EXPORT_METHOD(setCategoryAndMode:(NSString *)category mode:(NSString *)mode options:(NSString *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSString* cat = _categories[category];
    NSString* mod = _modes[mode];
    if (cat != nil && mod != nil && _options[options] != nil && [[AVAudioSession sharedInstance].availableCategories containsObject:cat] && [[AVAudioSession sharedInstance].availableModes containsObject:mod]) {
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setCategory:cat mode:mod options:_options[options] error:&error];
        if (error) {
            reject(@"setCategoryAndMode", @"Could not set category and mode.", error);
        } else {
            resolve(@[]);
        }
    } else {
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: @"Could not set AVAudioSession category and mode.",
                                   NSLocalizedFailureReasonErrorKey: @"The given category or mode is not supported on this device.",
                                   NSLocalizedRecoverySuggestionErrorKey: @"Try another category or mode."
                                   };
        NSError *error = [NSError errorWithDomain:@"RNAudioSession" code:-1 userInfo:userInfo];
        reject(@"setCategoryAndMode", @"Could not set category and mode.", error);
    }
}


-(void) handleRouteChange:(NSNotification*)notification{
  NSLog(@"Audio route changed");
  AVAudioSession *session = [ AVAudioSession sharedInstance ];
  NSString* seccReason = @"";
  NSInteger  reason = [[[notification userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
  
  switch (reason) {
    case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
      seccReason = @"The route changed because no suitable route is now available for the specified category.";
      break;
    case AVAudioSessionRouteChangeReasonWakeFromSleep:
      seccReason = @"The route changed when the device woke up from sleep.";
      break;
    case AVAudioSessionRouteChangeReasonOverride:
      seccReason = @"The output route was overridden by the app.";
      break;
    case AVAudioSessionRouteChangeReasonCategoryChange:
      seccReason = @"The category of the session object changed.";
      break;
    case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
      seccReason = @"The previous audio output path is no longer available.";
      break;
    case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
      seccReason = @"A preferred new audio output path is now available.";
      break;
    case AVAudioSessionRouteChangeReasonUnknown:
    default:
      seccReason = @"The reason for the change is unknown.";
      break;
  }
  AVAudioSessionPortDescription *input = [[session.currentRoute.inputs count]?session.currentRoute.inputs:nil objectAtIndex:0];
  AVAudioSessionPortDescription *output = [[session.currentRoute.outputs count]?session.currentRoute.outputs:nil objectAtIndex:0];
  
  NSString *inputStr = input.portType ? input.portType : @"";
  NSString *outputStr = output.portType ? output.portType : @"";
  
  NSLog(@"Change reason %@", seccReason);
  NSLog(@"input %@", inputStr);
  NSLog(@"output %@", outputStr);
  
  [self.bridge.eventDispatcher sendAppEventWithName:@"AudioRouteChanged" body:@{@"input": inputStr, @"output": outputStr, @"reason": seccReason}];
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

@end
