#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>

extern "C" void AudioServicesPlaySystemSoundWithVibration(SystemSoundID inSystemSoundID, id unknown, NSDictionary *options);

@interface SBUIIconForceTouchIconViewWrapperView : UIView
@end

@interface SBUIIconForceTouchWrapperViewController : UIViewController
@end

@interface SBUIIconForceTouchViewController : UIViewController {
	SBUIIconForceTouchWrapperViewController *_primaryViewController;
	SBUIIconForceTouchWrapperViewController *_secondaryViewController;
	SBUIIconForceTouchIconViewWrapperView *_iconViewWrapperViewBelow;
	SBUIIconForceTouchIconViewWrapperView *_iconViewWrapperViewAbove;
}
@end

@interface SBUIIconForceTouchController : NSObject {
	SBUIIconForceTouchViewController *_iconForceTouchViewController;
}
+(BOOL)_isPeekingOrShowing;
@end

@interface SBUIAppIconForceTouchController : NSObject {
	SBUIIconForceTouchController *_iconForceTouchController;
}
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
-(void)_cancelAppIconForceTouchGestureAndBeginEditing;
-(BOOL)isEditing;
@end

@interface SBIconView : UIView
@property (nonatomic,retain) UIGestureRecognizer * editingGestureRecognizer;
@property (nonatomic,retain) UIGestureRecognizer * appIconForceTouchGestureRecognizer;
@property (nonatomic,assign) BOOL didPresentAfterPeek;
-(void)_handleSecondHalfLongPressTimer:(id)arg1;
-(void)cancelLongPressTimer;
-(void)cancelDrag;
-(SBUIIconForceTouchViewController *)_iconForceTouchViewController;
-(void)_configureLongPress3DTouchGesture;
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

static BOOL isAutoDismissEnabled = YES;

static GestureType editingGesture = swipeUp;

static BOOL isVibrationEnabled = YES;
static NSInteger vibrationDuration = 30;
static CGFloat vibrationIntensity = 2.0;

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
		prefs = [[NSDictionary alloc] initWithContentsOfFile:kSettingsPath];
	}

	isEnabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : YES;

	longPressDuration =  [prefs objectForKey:@"longPressDuration"] ? [[prefs objectForKey:@"longPressDuration"] floatValue] : 0.2;
	peekDuration = [prefs objectForKey:@"peekDuration"] ? [[prefs objectForKey:@"peekDuration"] floatValue] : 0.175;
	peekTouchForce = [prefs objectForKey:@"peekTouchForce"] ? [[prefs objectForKey:@"peekTouchForce"] floatValue] : 0.5;

	isAutoDismissEnabled = [prefs objectForKey:@"isAutoDismissEnabled"] ? [[prefs objectForKey:@"isAutoDismissEnabled"] boolValue] : YES;

	editingGesture = [prefs objectForKey:@"editingGesture"] ? ((GestureType)[[prefs objectForKey:@"editingGesture"] intValue]) : swipeUp;

	isVibrationEnabled =  [prefs objectForKey:@"isVibrationEnabled"] ? [[prefs objectForKey:@"isVibrationEnabled"] boolValue] : YES;
	vibrationDuration =  [prefs objectForKey:@"vibrationDuration"] ? [[prefs objectForKey:@"vibrationDuration"] intValue] : 30;
	vibrationIntensity =  [prefs objectForKey:@"vibrationIntensity"] ? [[prefs objectForKey:@"vibrationIntensity"] floatValue] : 2.0;

	[prefs release];
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

// Zenith Compatibility (it requires an oldView property)
@interface Force3DLongPressGestureRecognizer : UILongPressGestureRecognizer
@property (nonatomic, retain) UIView *oldView;
@end

@implementation Force3DLongPressGestureRecognizer
-(id)initWithTarget:(id)arg1 action:(SEL)arg2 {
	self = [super initWithTarget:arg1 action:arg2];
	if (self != nil)
		self.oldView = nil;
	return self;
}

-(void)dealloc {
	self.oldView = nil;

	[super dealloc];
}
@end

%hook SBIconView
%property (nonatomic, retain) UIGestureRecognizer * editingGestureRecognizer;
%property (nonatomic, assign) BOOL didPresentAfterPeek;

// Fixes gestures not being registered the first time homescreeen is invoked
-(id)initWithContentType:(NSUInteger)arg1 {
	self = %orig(arg1);
	if (isEnabled && self != nil)
		[self _configureLongPress3DTouchGesture];
	return self;
}

-(void)setLocation:(NSInteger)arg1 {
	if (isEnabled)
		[self _configureLongPress3DTouchGesture];

	%orig(arg1);
}

-(void)_updateIconImageViewAnimated:(BOOL)arg1 {
	if (isEnabled)
		[self _configureLongPress3DTouchGesture];

	%orig(arg1);
}

-(void)_applyEditingStateAnimated:(BOOL)arg1 {
	if (isEnabled)
		[self _configureLongPress3DTouchGesture];

	%orig(arg1);
}

%new
-(void)_configureLongPress3DTouchGesture {
	if (![[%c(SBIconController) sharedInstance] isEditing]) {
		// remove previous gesture and add our own gesture for 3D touch shorcuts
		if (self.appIconForceTouchGestureRecognizer != nil)
			[self removeGestureRecognizer:self.appIconForceTouchGestureRecognizer];
		self.appIconForceTouchGestureRecognizer = [[[Force3DLongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_handle3DTouchLongPress:)] autorelease];
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
	} else {
		// remove previous gestures
		if (self.appIconForceTouchGestureRecognizer != nil)
			[self removeGestureRecognizer:self.appIconForceTouchGestureRecognizer];
		if (self.editingGestureRecognizer != nil)
			[self removeGestureRecognizer:self.editingGestureRecognizer];
	}
}

%new
-(void)_handle3DTouchLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
	SBIconController *_iconController = [%c(SBIconController) sharedInstance];
	if ([_iconController isEditing])
		return; // do nothing when editing enabled
	if ([_iconController _appIconForceTouchGestureRecognizerShouldBegin] && gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		// stop from going into editing mode or dragging mode
		SBIconView *iconView = (SBIconView *)gestureRecognizer.view;
		if ([iconView respondsToSelector:@selector(cancelLongPressTimer)])
			[iconView cancelLongPressTimer];
		else if ([iconView respondsToSelector:@selector(cancelDrag)])
			[iconView cancelDrag];

		// create shortcuts and peek
		SBUIAppIconForceTouchController *_forceTouchAppController = [[[%c(SBUIAppIconForceTouchController) alloc] init] autorelease];
		[_forceTouchAppController setDelegate:_iconController];
		[_forceTouchAppController setDataSource:_iconController];
		MSHookIvar<SBUIAppIconForceTouchController *>(_iconController, "_appIconForceTouchController") = _forceTouchAppController;
		[_forceTouchAppController _setupWithGestureRecognizer:gestureRecognizer];
		[_forceTouchAppController _peekAnimated:YES withRelativeTouchForce:peekTouchForce allowSmoothing:NO];

		self.didPresentAfterPeek = NO;

		// display shortcuts after a delay
		[self performSelector:@selector(_display3DTouchShortcuts:) withObject:_forceTouchAppController afterDelay:peekDuration];
	} else if (!self.didPresentAfterPeek && gestureRecognizer.state == UIGestureRecognizerStateChanged) {
		// dismiss peeked shortcut if finger left icon view
		SBUIAppIconForceTouchController *_forceTouchAppController = MSHookIvar<SBUIAppIconForceTouchController *>([%c(SBIconController) sharedInstance], "_appIconForceTouchController");
		CGPoint location = [gestureRecognizer locationInView:self];
		if (!CGRectContainsPoint(self.bounds, location))
			[_forceTouchAppController dismissAnimated:YES withCompletionHandler:nil];
	} else if (isAutoDismissEnabled && (gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateRecognized)) {
		// auto dimiss shortcuts menu if finger lifted outside the shortcuts menu view
		SBUIAppIconForceTouchController *_forceTouchAppController = MSHookIvar<SBUIAppIconForceTouchController *>([%c(SBIconController) sharedInstance], "_appIconForceTouchController");
		if (_forceTouchAppController != nil) {
			SBUIIconForceTouchViewController *_iconForceTouchViewController = [self _iconForceTouchViewController];
			if (_iconForceTouchViewController != nil) {
				BOOL shouldDismiss = NO;

				SBUIIconForceTouchWrapperViewController *_primaryViewController = MSHookIvar<SBUIIconForceTouchWrapperViewController *>(_iconForceTouchViewController, "_primaryViewController");
				if (_primaryViewController != nil) {
					// dismiss if not within the shortcuts view
					CGPoint location = [gestureRecognizer locationInView:_primaryViewController.view];
					shouldDismiss = !CGRectContainsPoint(_primaryViewController.view.bounds, location);
				}

				if (shouldDismiss) {
					SBUIIconForceTouchWrapperViewController *_secondaryViewController = MSHookIvar<SBUIIconForceTouchWrapperViewController *>(_iconForceTouchViewController, "_secondaryViewController");
					if (_secondaryViewController != nil) {
						// dismiss if not within the shortcuts view
						CGPoint location = [gestureRecognizer locationInView:_secondaryViewController.view];
						shouldDismiss = !CGRectContainsPoint(_secondaryViewController.view.bounds, location);
					}
				}

				if (shouldDismiss)
					[_forceTouchAppController dismissAnimated:YES withCompletionHandler:nil];
			}
		}
	}
}

%new
-(void)_display3DTouchShortcuts:(SBUIAppIconForceTouchController *)forceTouchAppController {
	self.didPresentAfterPeek = YES;

	if (forceTouchAppController != nil) {
		if (self.appIconForceTouchGestureRecognizer.state == UIGestureRecognizerStateBegan || self.appIconForceTouchGestureRecognizer.state == UIGestureRecognizerStateChanged || self.appIconForceTouchGestureRecognizer.state == UIGestureRecognizerStateEnded || self.appIconForceTouchGestureRecognizer.state == UIGestureRecognizerStateRecognized) {
			SBUIIconForceTouchViewController *_iconForceTouchViewController = [self _iconForceTouchViewController];
			if (_iconForceTouchViewController != nil) {
				BOOL shouldPresent = NO;

				SBUIIconForceTouchIconViewWrapperView *_iconViewWrapperViewAbove = MSHookIvar<SBUIIconForceTouchIconViewWrapperView *>(_iconForceTouchViewController, "_iconViewWrapperViewAbove");
				if (_iconViewWrapperViewAbove != nil) {
					// display if within the icon view
					CGPoint location = [self.appIconForceTouchGestureRecognizer locationInView:_iconViewWrapperViewAbove];
					shouldPresent = CGRectContainsPoint(_iconViewWrapperViewAbove.bounds, location);
				}

				if (!shouldPresent) {
					SBUIIconForceTouchIconViewWrapperView *_iconViewWrapperViewBelow = MSHookIvar<SBUIIconForceTouchIconViewWrapperView *>(_iconForceTouchViewController, "_iconViewWrapperViewBelow");
					if (_iconViewWrapperViewBelow != nil) {
						// display if within the icon view
						CGPoint location = [self.appIconForceTouchGestureRecognizer locationInView:_iconViewWrapperViewBelow];
						shouldPresent = CGRectContainsPoint(_iconViewWrapperViewBelow.bounds, location);
					}
				}

				if (shouldPresent) {
					// haptic feedback
					hapticFeedback();

					// display shortcut menu
					[forceTouchAppController _presentAnimated:YES withCompletionHandler:nil];
					return;
				}
			}
			// dismiss peeked shortcuts (if execution ever reaches this point then it means something went wrong)
			[forceTouchAppController dismissAnimated:YES withCompletionHandler:nil];
		} else {
			// dismiss peeked shortcuts
			[forceTouchAppController dismissAnimated:YES withCompletionHandler:nil];
		}
	}
}

%new
-(SBUIIconForceTouchViewController *)_iconForceTouchViewController {
	SBUIAppIconForceTouchController *_forceTouchAppController = MSHookIvar<SBUIAppIconForceTouchController *>([%c(SBIconController) sharedInstance], "_appIconForceTouchController");
	if (_forceTouchAppController != nil) {
		SBUIIconForceTouchController *_iconForceTouchController = MSHookIvar<SBUIIconForceTouchController *>(_forceTouchAppController, "_iconForceTouchController");
		if (_iconForceTouchController != nil)
			return (SBUIIconForceTouchViewController *)MSHookIvar<SBUIIconForceTouchViewController *>(_iconForceTouchController, "_iconForceTouchViewController");
	}
	return nil;
}

%new
-(void)_handleEditingeditingGestureRecognizer:(UISwipeGestureRecognizer *)gestureRecognizer {
	// go into editing mode
	if ([self respondsToSelector:@selector(_handleSecondHalfLongPressTimer:)])
		[self _handleSecondHalfLongPressTimer:nil];
	else if ([[%c(SBIconController) sharedInstance] respondsToSelector:@selector(_cancelAppIconForceTouchGestureAndBeginEditing)])
		[[%c(SBIconController) sharedInstance] _cancelAppIconForceTouchGestureAndBeginEditing];
}

-(void)_updateJitter {
	// just incase anything goes wrong (code from RevealMenu)
	if (isEnabled)
		[[%c(SBIconController) sharedInstance] _dismissAppIconForceTouchControllerIfNecessaryAnimated:YES withCompletionHandler:nil];

	%orig();
}

-(void)setHighlighted:(BOOL)arg1 {
	%orig(arg1);

	if (arg1 && isEnabled && ![[%c(SBIconController) sharedInstance] isEditing]) {
		if ([self respondsToSelector:@selector(cancelLongPressTimer)])
			[self cancelLongPressTimer];
		else if ([self respondsToSelector:@selector(cancelDrag)])
			[self cancelDrag];
	}
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