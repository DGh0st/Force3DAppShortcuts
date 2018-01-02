#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSliderTableCell.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface FASRootListController : PSListController <MFMailComposeViewControllerDelegate>

@end

@interface PSRootController
+(void)setPreferenceValue:(id)value specifier:(id)specifier;
@end

@interface FASSliderCell : PSSliderTableCell <UIAlertViewDelegate, UITextFieldDelegate>
-(void)presentAlert;
@end