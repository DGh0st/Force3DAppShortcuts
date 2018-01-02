#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>

extern "C" void AudioServicesPlaySystemSoundWithVibration(SystemSoundID inSystemSoundID, id unknown, NSDictionary *options);

@interface SBUIAppIconForceTouchController : NSObject
-(void)_setupWithGestureRecognizer:(id)arg1;
-(void)_presentAnimated:(BOOL)arg1 withCompletionHandler:(id)arg2;
-(void)dismissAnimated:(BOOL)arg1 withCompletionHandler:(id)arg2;
-(void)_peekAnimated:(BOOL)arg1 withRelativeTouchForce:(CGFloat)arg2 allowSmoothing:(BOOL)arg3;
-(void)setDataSource:(id)arg1;
-(void)setDelegate:(id)arg1;
@end

@interface SBIconController {
	SBUIAppIconForceTouchController *_appIconForceTouchController;
}
+(id)sharedInstance;
-(void)_dismissAppIconForceTouchControllerIfNecessaryAnimated:(BOOL)arg1 withCompletionHandler:(id)arg2;
-(BOOL)_appIconForceTouchGestureRecognizerShouldBegin;
@end

@interface SBIconView : UIView
@property (nonatomic,retain) UIGestureRecognizer * editingGestureRecognizer;
@property (nonatomic,retain) UIGestureRecognizer * appIconForceTouchGestureRecognizer;
-(void)_handleSecondHalfLongPressTimer:(id)arg1;
-(void)cancelLongPressTimer;
@end

@interface FBSystemService
+(id)sharedInstance;
-(void)exitAndRelaunch:(BOOL)arg1;
@end

#define kIdentifier @"com.dgh0st.force3dappshortcuts"
#define kSettingsPath @"/var/mobile/Library/Preferences/com.dgh0st.force3dappshortcuts.plist"
#define kSettingsChangedNotification (CFStringRef)@"com.dgh0st.force3dappshortcuts/settingschanged"
#define kRespringNotification (CFStringRef)@"com.dgh0st.force3dappshortcuts/respring"

typedef enum GestureType : NSInteger {
	doubleTap = 0,
	swipeUp,
	swipeDown,
	swipeLeft,
	swipeRight
} GestureType;

static BOOL isEnabled = YES;

static CGFloat longPressDuration = 0.2;
static CGFloat peekDuration = 0.175;
static CGFloat peekTouchForce = 0.5;

static GestureType editingGesture = swipeUp;

static BOOL isVibrationEnabled = YES;
static NSInteger vibrationDuration = 25;
static CGFloat vibrationIntensity = 0.75;

static void reloadPrefs() {
	CFPreferencesAppSynchronize((CFStringRef)kIdentifier);

	NSDictionary *prefs = nil;
	if ([NSHomeDirectory() isEqualToString:@"/var/mobile"]) {
		CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (keyList != nil) {
			prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, (CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			if (prefs == nil)
				prefs = [NSDictionary dictionary];
			CFRelease(keyList);
		}
	} else {
		prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
	}

	isEnabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : YES;

	longPressDuration =  [prefs objectForKey:@"longPressDuration"] ? [[prefs objectForKey:@"longPressDuration"] floatValue] : 0.2;
	peekDuration = [prefs objectForKey:@"peekDuration"] ? [[prefs objectForKey:@"peekDuration"] floatValue] : 0.175;
	peekTouchForce = [prefs objectForKey:@"peekTouchForce"] ? [[prefs objectForKey:@"peekTouchForce"] floatValue] : 0.5;

	editingGesture = [prefs objectForKey:@"editingGesture"] ? ((GestureType)[[prefs objectForKey:@"editingGesture"] intValue]) : swipeUp;

	isVibrationEnabled =  [prefs objectForKey:@"isVibrationEnabled"] ? [[prefs objectForKey:@"isVibrationEnabled"] boolValue] : YES;
	vibrationDuration =  [prefs objectForKey:@"vibrationDuration"] ? [[prefs objectForKey:@"vibrationDuration"] intValue] : 25;
	vibrationIntensity =  [prefs objectForKey:@"vibrationIntensity"] ? [[prefs objectForKey:@"vibrationIntensity"] floatValue] : 0.75;
}

static void respringDevice() {
	[[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
}

static void hapticFeedback() {
	if (isVibrationEnabled) {
		NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
	   	NSMutableArray* array = [NSMutableArray array];
		[array addObject:[NSNumber numberWithBool:YES]];
		[array addObject:[NSNumber numberWithInt:vibrationDuration]];
		[dictionary setObject:array forKey:@"VibePattern"];
		[dictionary setObject:[NSNumber numberWithFloat:vibrationIntensity] forKey:@"Intensity"];
		AudioServicesPlaySystemSoundWithVibration(4095, nil, dictionary);
	}
}

%hook SBIconView
%property (nonatomic, retain) UIGestureRecognizer * editingGestureRecognizer;

-(void)setLocation:(NSInteger)arg1 {
	if (isEnabled) {
		// remove previous gesture and add our own gesture for 3D touch shorcuts
		if (self.appIconForceTouchGestureRecognizer != nil)
			[self removeGestureRecognizer:self.appIconForceTouchGestureRecognizer];
		self.appIconForceTouchGestureRecognizer = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_handle3DTouchLongPress:)] autorelease];
		((UILongPressGestureRecognizer  *)self.appIconForceTouchGestureRecognizer).minimumPressDuration = longPressDuration;

		// remove previous gesture and add different gesture for editing
		if (self.editingGestureRecognizer != nil)
			[self removeGestureRecognizer:self.editingGestureRecognizer];
		if (editingGesture == swipeUp || editingGesture == swipeDown || editingGesture == swipeLeft || editingGesture == swipeRight) {
			self.editingGestureRecognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_handleEditingeditingGestureRecognizer:)] autorelease];
			if (editingGesture == swipeUp)
				((UISwipeGestureRecognizer *)self.editingGestureRecognizer).direction = UISwipeGestureRecognizerDirectionUp;
			else if (editingGesture == swipeDown)
				((UISwipeGestureRecognizer *)self.editingGestureRecognizer).direction = UISwipeGestureRecognizerDirectionDown;
			else if (editingGesture == swipeLeft)
				((UISwipeGestureRecognizer *)self.editingGestureRecognizer).direction = UISwipeGestureRecognizerDirectionLeft;
			else
				((UISwipeGestureRecognizer *)self.editingGestureRecognizer).direction = UISwipeGestureRecognizerDirectionRight;
			[self addGestureRecognizer:self.editingGestureRecognizer];
		} else if (editingGesture == doubleTap) {
			self.editingGestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_handleEditingeditingGestureRecognizer:)] autorelease];
			((UITapGestureRecognizer *)self.editingGestureRecognizer).numberOfTapsRequired = 2;
		}
		[self addGestureRecognizer:self.editingGestureRecognizer];
	}

	%orig(arg1);
}

%new
-(void)_handle3DTouchLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
	SBIconController *_iconController = [%c(SBIconController) sharedInstance];
	if ([_iconController _appIconForceTouchGestureRecognizerShouldBegin] && gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		// stop from going into editing mode
		[(SBIconView *)gestureRecognizer.view cancelLongPressTimer];

		// create shortcuts and peek
		SBUIAppIconForceTouchController *_forceTouchAppController = [[[%c(SBUIAppIconForceTouchController) alloc] init] autorelease];
		[_forceTouchAppController setDelegate:_iconController];
		[_forceTouchAppController setDataSource:_iconController];
		MSHookIvar<SBUIAppIconForceTouchController *>(_iconController, "_appIconForceTouchController") = _forceTouchAppController;
		[_forceTouchAppController _setupWithGestureRecognizer:gestureRecognizer];
		[_forceTouchAppController _peekAnimated:YES withRelativeTouchForce:peekTouchForce allowSmoothing:NO];

		// display shortcuts after a delay
		[self performSelector:@selector(_display3DTouchShortcuts:) withObject:_forceTouchAppController afterDelay:peekDuration];
	}
}

%new
-(void)_display3DTouchShortcuts:(SBUIAppIconForceTouchController *)forceTouchAppController {
	if (forceTouchAppController != nil) {
		if (self.appIconForceTouchGestureRecognizer.state == UIGestureRecognizerStateBegan || self.appIconForceTouchGestureRecognizer.state == UIGestureRecognizerStateChanged || self.appIconForceTouchGestureRecognizer.state == UIGestureRecognizerStateEnded || self.appIconForceTouchGestureRecognizer.state == UIGestureRecognizerStateRecognized) {
			// haptic feedback
			hapticFeedback();
			
			// display shortcut menu
			[forceTouchAppController _presentAnimated:YES withCompletionHandler:nil];
		} else {
			// dismiss peeked shortcuts
			[forceTouchAppController dismissAnimated:YES withCompletionHandler:nil];
		}
	}
}

%new
-(void)_handleEditingeditingGestureRecognizer:(UISwipeGestureRecognizer *)gestureRecognizer {
	// go into editing mode
	[self _handleSecondHalfLongPressTimer:nil];
}

-(void)_updateJitter {
	// just incase anything goes wrong (code from RevealMenu)
	[[%c(SBIconController) sharedInstance] _dismissAppIconForceTouchControllerIfNecessaryAnimated:YES withCompletionHandler:nil];
	%orig();
}
%end

%hook SBIconController
-(void)appIconForceTouchController:(id)arg1 didDismissForGestureRecognizer:(id)arg2 {
	%orig(arg1, arg2);

	MSHookIvar<SBUIAppIconForceTouchController *>(self, "_appIconForceTouchController") = nil;
}
%end

%dtor {
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, kSettingsChangedNotification, NULL);
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, kRespringNotification, NULL);
}

%ctor {
	reloadPrefs();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, kSettingsChangedNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)respringDevice, kRespringNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}