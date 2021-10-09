@import Foundation;
@import UIKit;

#import <UserNotifications/UserNotifications.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
//#import <dlfcn.h>

#import "Tweak.h"
#import "AXNManager.h"

@interface BBServer : NSObject
+(instancetype)SLM_sharedInstance;
-(void)publishBulletin:(BBBulletin*)arg1 destinations:(unsigned long long)arg2;
@end

static BBServer *sharedServer;
extern dispatch_queue_t __BBServerQueue;

%hook BBServer
%new
+(id)SLM_sharedInstance {
    return sharedServer;
}
-(id)initWithQueue:(id)arg1 {
    sharedServer = %orig;
    return sharedServer;
}
%end

// Tried to replace NSTimer with PCPersistentTimer for better reliability, but that made it go to safe mode once in a while. More testing needed. Also, PCPersistentTimer is working accross reboots (even if the device is not jailbroken - it will fire.), so also need to disable that to prevent possible freezes (I assume).
// [Interesting feature: it has the ability to wake the device and perform the action if it is powered off at the time it is supposed to execute. has nothing to do with this tweak (that I can think of) but might come in handy in the future.] [Actually now that I think about it 2 months later, it could potentially be used to make notifications snoozing persistent through reboots even when in non-jailbroken modes (because 1st party apps notifications use this type of timer, such as alarms and reminders), but that would require a completly different implementation of the actual notification snoozing part. I tried to do this before and failed, and there's no much info on how notifications (BBBulletin, BBserver etc.) actually work. for this benfit alone, this would be way too much effort for me.]
@interface PCSimpleTimer : NSObject {
	NSRunLoop* _timerRunLoop;
}
-(id)userInfo;
-(void)scheduleInRunLoop:(id)arg1 ;
-(id)initWithFireDate:(id)arg1 serviceIdentifier:(id)arg2 target:(id)arg3 selector:(SEL)arg4 userInfo:(id)arg5 ;
-(void)invalidate;
-(BOOL)disableSystemWaking;
-(void)setDisableSystemWaking:(BOOL)arg1 ;
-(BOOL)isUserVisible;
-(void)setUserVisible:(BOOL)arg1 ;
@end

static BOOL dpkgInvalid = NO;
static BOOL enabled;
BOOL snooozedDeliverProminently;
//static BOOL enabledForDND; // DND START
static NSInteger segmentInterval;
static NSInteger chosenButton;
static BOOL deliverQuietlyWhilePlaying;
static BOOL snoozeByLocationEnabled;
PCSimpleTimer *lastTimer;

NSDictionary *prefs = nil;

#pragma mark localized strings
static NSBundle *tweakBundle;
static NSString *SNOOZEN, *SNOOZENS, *SNOOZE, *SNOOZED, *fMINUTES, *tMINUTES, *ffMINUTES, *oneHOUR, *twoHOURS, *threeHOURS, *fourHOURS, *sixHOURS, *eightHOURS, *twelveHOURS, *sTIME, *SNOOZEU, *SNOOZEF, *CANCEL, *TAPCHANGE, *STEPPER, *ARRIVELOCATION, *LEAVELOCATION, *LOCATION;

@interface PSSpecifier : NSObject
@property (nonatomic,retain) NSString * name;
@end

@interface UITableViewCellContentView : UIView
@end

@interface PUILocationServicesAuthLevelCell : UITableViewCell
@property (nonatomic, strong, readwrite) NSBundle *entityBundle;
@property (nonatomic, copy, readwrite) NSString *displayName;
@end

%group Settings
%hook PUILocationServicesAuthLevelCell
-(void)setSpecifier:(PSSpecifier *)arg1 {
    if ([arg1.name isEqualToString:@"SpringBoard"] || [arg1.name isEqualToString:@"Selenium"]) {
        /*UITableViewCellContentView *contentView;
        for (id cv in self.subviews) if ([cv isKindOfClass:[%c(UITableViewCellContentView) class]]) contentView = cv;*/
        [self.imageView setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/SeleniumPrefs.bundle/icon.png"]];
        arg1.name = @"Selenium";
    }
    %orig(arg1);
}
%end
%end

%group Selenium

#pragma mark Store dispatcher for future use

%hook SBNCNotificationDispatcher

-(id)init {
    %orig;
    [AXNManager sharedInstance].dispatcher = self.dispatcher;
    return self;
}

-(void)setDispatcher:(NCNotificationDispatcher *)arg1 {
    %orig;
    [AXNManager sharedInstance].dispatcher = arg1;
}

%end

#pragma mark Notification management

@interface NCNotificationMasterList
@property(retain, nonatomic) NSMutableArray *notificationSections;
@end
@interface NCNotificationStructuredSectionList
@property (nonatomic,copy) NSString * logDescription;
@property (nonatomic,readonly) NSArray * allNotificationRequests;
@end
@interface NCNotificationStructuredListViewController <clvc>
@property (nonatomic,assign) BOOL axnAllowChanges;
@property (nonatomic,retain) NCNotificationMasterList * masterList;
-(void)revealNotificationHistory:(BOOL)arg1 animated:(BOOL)arg2 ;
@end
%hook NCNotificationStructuredListViewController
%property (nonatomic,assign) BOOL axnAllowChanges;
-(id)init {
    %orig;
    [AXNManager sharedInstance].clvc = self;
    self.axnAllowChanges = NO;
    return self;
}

-(bool)insertNotificationRequest:(NCNotificationRequest *)req {
    if (self.axnAllowChanges) return %orig;     // This condition is true when Axon is updating filtered notifications for display.
    [[AXNManager sharedInstance] insertNotificationRequest:req];
    %orig;
    return YES;
}

-(bool)removeNotificationRequest:(NCNotificationRequest *)req {
    if (self.axnAllowChanges) return %orig;     // This condition is true when Axon is updating filtered notifications for display.
    [[AXNManager sharedInstance] removeNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) %orig;
    }

    %orig;

    return YES;
}

-(bool)modifyNotificationRequest:(NCNotificationRequest *)req {
    if (self.axnAllowChanges) return %orig;     // This condition is true when Axon is updating filtered notifications for display.

    [[AXNManager sharedInstance] modifyNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) %orig;
    }

    %orig;

    return YES;
}
%end

@interface NCNotificationViewControllerView : UIView
@end

@interface NCNotificationViewController : UIViewController {
    NCNotificationRequest* _notificationRequest;
}
@property (getter=_notificationViewControllerView,nonatomic,readonly) NCNotificationViewControllerView * notificationViewControllerView; 
@property (nonatomic,retain) NCNotificationRequest * notificationRequest;
@end

@protocol NCNotificationListViewDataSource <NSObject>
@end

@interface NCNotificationGroupList : NSObject <NCNotificationListViewDataSource>
@property (nonatomic,retain) NSMutableArray * orderedRequests;
@end 

@interface NCNotificationListView : UIScrollView
@property (assign,getter=isGrouped,nonatomic) BOOL grouped;
@property (assign,readwrite) NCNotificationGroupList<NCNotificationListViewDataSource> *dataSource;
@property(retain, nonatomic) NSMutableDictionary *visibleViews;
- (void)reloadHeaderView;
@end

@interface NCNotificationListCell : UIView {
	NCNotificationViewController* _contentViewController;
}
@property (nonatomic,retain) NCNotificationViewController * contentViewController;                          //@synthesize contentViewController=_contentViewController - In the implementation block
- (void)dateIsNow:(NSTimer *)timer ;
@end

@interface NCNotificationListCellActionButtonsView : UIView
@property (nonatomic,retain) UIStackView * buttonsStackView;
@property (nonatomic) BOOL shouldPerformDefaultAction;
+(id)_actionButtonDescriptionsForNotificationRequest:(id)arg1 sectionSettings:(id)arg2 cell:(id)arg3 ;
- (void)didTapSnooze:(UIButton *)arg1;
@end

@interface NCNotificationListCellActionButton : UIControl
@property (nonatomic,retain) UILabel * titleLabel;
@property (nonatomic,copy) NSString * title;
@end

NSString *bundleID;
/*static*/ NCNotificationListCell *snoozedCell;
/*static*/ NCNotificationRequest *argToDismiss;

NCNotificationRequest *reqToBeSnoozed;

UIView *newView;
UIButton *newButton;
UIImageView *iconView;

static NSDictionary *notifInfo;

@interface SBFUserAuthenticationController : NSObject
-(void)_setAuthState:(long long)arg1 ;
-(BOOL)isAuthenticated;
@end

@interface SBLockScreenManager : NSObject
@property (setter=_setUserAuthController:,getter=_userAuthController,nonatomic,retain) SBFUserAuthenticationController * userAuthController;
-(void)lockScreenViewControllerRequestsUnlock;
@end

%hook NCNotificationListCellActionButtonsView
-(void)layoutSubviews {
    %orig;
    if ([self.superview.superview.superview isKindOfClass:[%c(NCNotificationListCell) class]] && self.superview.superview.superview != snoozedCell)
    snoozedCell = self.superview.superview.superview;

    // Get the options StackView array
    NSArray<NCNotificationListCellActionButton *> *buttonsArray = self.buttonsStackView.arrangedSubviews;

    // Process only if 3 CellActionButton are present
    // Less than 3 means the left option pannel is opened or the right one is already processed
    if (buttonsArray.count == 3) {
        // Replace the View option
        buttonsArray[chosenButton].title = SNOOZE;
        [buttonsArray[chosenButton] removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents]; 
        [buttonsArray[chosenButton] addTarget:self action:@selector(didTapSnooze:) forControlEvents:UIControlEventTouchUpInside];
    } else if (buttonsArray.count == 2 && chosenButton == 1) {
        // Replace the View option
        buttonsArray[0].title = SNOOZE;
        [buttonsArray[0] removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents]; 
        [buttonsArray[0] addTarget:self action:@selector(didTapSnooze:) forControlEvents:UIControlEventTouchUpInside];
    }
}

-(void)configureCellActionButtonsForNotificationRequest:(id)arg1 sectionSettings:(id)arg2 cell:(id)arg3 {
    argToDismiss = arg1;
    bundleID = argToDismiss.sectionIdentifier;
    snoozedCell = arg3;
    reqToBeSnoozed = snoozedCell.contentViewController.notificationRequest;
    %orig;
}

%new
- (void)didTapSnooze:(UIButton *)arg1 {
    if (![[[%c(SBLockScreenManager) sharedInstance] _userAuthController] isAuthenticated]) {
        [[[%c(SBLockScreenManager) sharedInstance] _userAuthController] _setAuthState:3]; // Allowing the menu to show even if the device did not authenticate, by setting it to a specific state manually.
    }

    if ([self.superview.superview.superview isKindOfClass:[%c(NCNotificationListCell) class]] && self.superview.superview.superview != snoozedCell)
    snoozedCell = self.superview.superview.superview;

    notifInfo = @{@"id": reqToBeSnoozed, @"cell": snoozedCell};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.miwix.selenium.menu" object:nil userInfo:notifInfo];
}
%end

static double secondsLeft;

static NSString *configPath = @"/var/mobile/Library/Selenium/manager.plist";
static NSMutableDictionary *config;

static void storeSnoozed(NCNotificationRequest *request, BOOL shouldRemove, BOOL location) {
  NSString *req = [NSString stringWithFormat:@"%@", request];
  NSMutableArray *entries = [config[@"snoozedCache"] mutableCopy];
  bool add = YES;
  NSDictionary *remove = nil;
  for (NSMutableDictionary *entry in entries) {
    NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@";"] mutableCopy];
    [parts removeObject:parts[0]];
    NSString *combinedparts = [parts componentsJoinedByString:@";"];
    if ([req containsString:combinedparts]) {
        if (!shouldRemove) {
            NSDate *removeDate = [[NSDate alloc] initWithTimeInterval:604800 sinceDate:[request timestamp]];
            entry[@"timeToRemove"] = removeDate;
        }
        remove = entry;
        add = NO;
        //break;
    }
  }
  if (shouldRemove && (remove != nil)) {
    [entries removeObject:remove];
  }
  if (add) {
    NSMutableDictionary *info;
    NSDate *removeDate = [[NSDate alloc] initWithTimeInterval:604800 sinceDate:[request timestamp]];
    info = @{@"id": req, @"timeToRemove": removeDate, @"timeStamp": @(location ? -2 : 0)};
    [entries addObject:[info mutableCopy]];
  }
  [config setObject:entries forKey:@"snoozedCache"];
  [config writeToFile:configPath atomically:YES];
}

static void processEntry(NCNotificationRequest *request, double interval, NSDate *inputDate, CLCircularRegion *region, BOOL onArrive) {
  NSString *req = [NSString stringWithFormat:@"%@", request];
  NSMutableArray *entries = [config[@"entries"] mutableCopy];
  bool add = YES;
  NSDictionary *remove = nil;
  for (NSMutableDictionary *entry in entries) {
    NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@";"] mutableCopy];
    [parts removeObject:parts[0]];
    NSString *combinedparts = [parts componentsJoinedByString:@";"];
    if ([req containsString:combinedparts]) {
        if (interval < 0) {
            if (interval == -1) {
                entry[@"timeStamp"] = @([inputDate timeIntervalSince1970]);
            }
            else if (interval == -2) { //reserved for options that are not time-based
                entry[@"timeStamp"] = @(-2);
            }
        } else if (interval == 0) {
            remove = entry;
        } else {
            entry[@"timeStamp"] = @([[NSDate date] timeIntervalSince1970] + interval);
        }
        add = NO;
    }
  }
  if (remove) {
    [entries removeObject:remove];
  }
  if (add && region != nil) {
    NSLog(@"[Selenium] should save for location");
    NSDictionary *info;
    //if (interval == -2) {
        NSData *encodedBulletin = [NSKeyedArchiver archivedDataWithRootObject:request.bulletin];
        //NSData *encodedObserver = [NSKeyedArchiver archivedDataWithRootObject:request.observer];
        info = @{@"id": req, @"timeStamp": [NSNumber numberWithDouble:interval], @"regionIdentifier" : region.identifier, @"encodedBulletin" : encodedBulletin, /*@"encodedObserver" : encodedObserver,*/ @"onArrive" : [NSNumber numberWithBool:onArrive]}; //reserved for options that are not time-based
    //}
    if (info) {
      [entries addObject:[info mutableCopy]];
    }
  } else if (add) {
    //NSMutableArray *snoozedCache = [config[@"snoozedCache"] mutableCopy];
    @try {
        /*if (![[request.content.header lowercaseString] containsString:@"snoozed"])*/ storeSnoozed(request, NO, (interval == -2) ? YES : NO);
    }
    @catch ( NSException *exception ) {
          if (exception) {
            NSLog(@"[Selenium] ERROR:%@", exception);
          }
    }
    NSMutableDictionary *info;
    if (interval < 0) {
        if (interval == -1)
        info = @{@"id": req, @"timeStamp": @([inputDate timeIntervalSince1970])};
        /*else if (interval == -2) {
            NSData *encodedRegion = [NSKeyedArchiver archivedDataWithRootObject:region];
            info = [@{@"id": req, @"timeStamp": @([[NSNumber numberWithDouble:interval] doubleValue]), @"region": encodedRegion, @"onArrive" : @([[NSNumber numberWithBool:onArrive] doubleValue])} mutableCopy]; //reserved for options that are not time-based
        }*/
    } else if (interval != 0) {
        info = @{@"id": req, @"timeStamp": @([[NSDate date] timeIntervalSince1970] + interval)};
    }
    if (info) {
      [entries addObject:[info mutableCopy]];
    }
  }
  [config setObject:entries forKey:@"entries"];
  [config writeToFile:configPath atomically:YES];
}

@protocol NCNotificationManagementControllerSettingsDelegate <NSObject>
@optional
-(void)notificationManagementControllerDidDismissManagementView:(id)arg1;
@required
-(id)notificationManagementController:(id)arg1 sectionSettingsForSectionIdentifier:(id)arg2;
-(void)notificationManagementController:(id)arg1 setAllowsNotifications:(BOOL)arg2 forNotificationRequest:(id)arg3 withSectionIdentifier:(id)arg4;
-(void)notificationManagementController:(id)arg1 setDeliverQuietly:(BOOL)arg2 forNotificationRequest:(id)arg3 withSectionIdentifier:(id)arg4;
-(void)notificationManagementController:(id)arg1 setAllowsCriticalAlerts:(BOOL)arg2 forNotificationRequest:(id)arg3 withSectionIdentifier:(id)arg4;
@end

@protocol NCNotificationManagementController <NSObject>
@property (assign,nonatomic) id<NCNotificationManagementControllerSettingsDelegate> settingsDelegate; 
@required
-(void)setSettingsDelegate:(id<NCNotificationManagementControllerSettingsDelegate>)arg1;
-(id<NCNotificationManagementControllerSettingsDelegate>)settingsDelegate;
@end

@interface NCNotificationManagementAlertController : UIAlertController <NCNotificationManagementController> {
    	NCNotificationRequest* _request;
}
@property (nonatomic,retain) NCNotificationRequest * request;    
-(id)initWithRequest:(id)arg1 withPresentingView:(id)arg2 settingsDelegate:(id)arg3 ;
@end

@interface NCNotificationManagementBlueButton : UIButton
+(id)buttonWithTitle:(id)arg1 ;
-(void)setBackgroundColor:(id)arg1 ;
@end

@interface NCNotificationManagementViewController : UIViewController
@property (assign,nonatomic) id<NCNotificationManagementControllerSettingsDelegate> settingsDelegate;              //@synthesize settingsDelegate=_settingsDelegate - In the implementation block
+(id)notificationManagementAlertControllerForNotificationRequest:(id)arg1 withPresentingView:(id)arg2 settingsDelegate:(id)arg3 ;
@end

@interface NCNotificationManagementViewPresenter : NSObject <NCNotificationManagementControllerSettingsDelegate>
-(void)setNotificationManagementAlertViewController:(UIAlertController *)arg1 ;
@end

@interface NCNotificationManagementView : UIView /*<MTVisualStylingProviding>*/ {
    NCNotificationManagementBlueButton* _onOffToggleButton;
	NCNotificationManagementBlueButton* _deliveryButton;
}
@property (nonatomic,readonly) NCNotificationManagementBlueButton * deliveryButton;                 //@synthesize deliveryButton=_deliveryButton - In the implementation block
@property (nonatomic,readonly) NCNotificationManagementBlueButton * onOffToggleButton;              //@synthesize onOffToggleButton=_onOffToggleButton - In the implementation block
-(id)initWithIcon:(id)arg1 title:(id)arg2 subtitle:(id)arg3 sectionSettings:(id)arg4 criticalAlert:(BOOL)arg5 ;
@end

@interface UIHoursStepper : UIStepper
@property (nonatomic,retain) UIStackView *stepperLabel;
@property (nonatomic,retain) NCNotificationRequest *request;
@property (nonatomic,retain) NCNotificationListCell *cell;
//@property (nonatomic,retain) SBRingerPillView *pillView;
//@property (nonatomic,retain) UILabel *pillViewUntilLabel;
@property (nonatomic,retain) UIViewController *controllerToDismiss;    
@property (nonatomic,readwrite) BOOL grouped;    
@end

@implementation UIHoursStepper
@end

@interface SButton : UIButton
@property (nonatomic,retain) NCNotificationRequest *request;    
@property (nonatomic,retain) NCNotificationListCell *cell;    
@property (nonatomic,retain) SBRingerPillView *pillView;    
@property (nonatomic,retain) UILabel *pillViewUntilLabel;    
@property (nonatomic,retain) UIDatePicker *datePicker;
@property (nonatomic,retain) UIHoursStepper *stepper;
@property (nonatomic,retain) NSDate *pickerDate;
@property (nonatomic,retain) NSDate *stepperDate;
@property (nonatomic,retain) UIViewController *controllerToDismiss;    
@property (nonatomic,readwrite) BOOL grouped;    
@end

@implementation SButton
@end

@interface UIApplication ()
+(id)displayIdentifier;
@end

@interface SpringBoard : UIApplication
@end

@interface SpringBoard ()
@property (nonatomic,retain) NCNotificationRequest *requestForLocation;
@property (nonatomic,retain) CLLocationManager *seleniumLocationManager;
//@property (nonatomic,retain) WFLocationPickerViewController *seleniumLocationPickerViewController;
@property (nonatomic,retain) NSArray *requestsForLocation;
@property (nonatomic,assign) BOOL isNotifForLocationGrouped;
@property (nonatomic,assign) BOOL onArrive;
@property (strong, nonatomic) UIWindow *window;
-(UIImage *)imageWithView:(UIView *)view;
-(NSDate *)getStepperValue:(NSNumber *)number;
@end

#pragma mark DND start

/*#import "TweakCCSelenium.h"

static BOOL shouldSnooze;
static BOOL isEnabledForDND; // whether Selenium is enabled for DND (same value as the toggle in CC)
static BOOL isDNDEnabled; // whether DND itself is turned on or off
static CGRect ccBounds;

// to make notifications appear when finished
static void setStateForDND(NSString *state) {
	[config setObject:state forKey:@"EnabledForDND"];
	[config writeToFile:configPath atomically:YES];
}

/*static void processEntryDND(NCNotificationRequest *request) {
  NSString *req = [NSString stringWithFormat:@"%@", request];
  NSMutableArray *entries = [config[@"DND"] mutableCopy];
  bool add = YES;
  //NSDictionary *remove = nil;
  for (NSMutableDictionary *entry in entries) {
    NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@";"] mutableCopy];
    [parts removeObject:parts[0]];
    NSString *combinedparts = [parts componentsJoinedByString:@";"];
    if ([req containsString:combinedparts]) {
        add = NO;
    }
  }*/
  /*if (remove) {
    [entries removeObject:remove];
  }*/
/*  if (add) {
    storeSnoozed(request, NO);
    NSDictionary *info;
    info = @{@"id": req};
    if (info) {
      [entries addObject:info];
    }
  }
  [config setObject:entries forKey:@"DND"];
  //[config writeToFile:configPath atomically:YES];
  [[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionaryWithDictionary:config] forKey:@"dictionaryKey"];
}

static bool shouldStopRequest(NCNotificationRequest *request) {
  bool stop = NO;
  NSMutableArray *removeObjects = [[NSMutableArray alloc] init];
  for (NSDictionary *entry in (NSArray *)config[@"DND"]) {
    double interval = [[NSDate date] timeIntervalSince1970];
    if ([(NSString *)request.sectionIdentifier isEqualToString:(NSString *)entry[@"id"]] && (interval < [entry[@"timeStamp"] doubleValue] || [entry[@"timeStamp"] doubleValue] == -1)) {
      stop = YES;
    } else if (interval > [entry[@"timeStamp"] doubleValue] && [entry[@"timeStamp"] doubleValue] != -1) {
      [removeObjects addObject:entry];
    }
  }
  if (removeObjects) {
    [config[@"DND"] removeObjectsInArray:removeObjects];
    //[config writeToFile:configPath atomically:YES];
    [[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionaryWithDictionary:config] forKey:@"dictionaryKey"];
  }
  return stop;
}
*//*
@interface UIView (mxcl)
- (CCUIContentModuleContainerViewController *)parentViewController;
@end

@implementation UIView (mxcl)
- (CCUIContentModuleContainerViewController *)parentViewController {
    UIResponder *responder = self;
    while ([responder isKindOfClass:[UIView class]])
        responder = [responder nextResponder];
    return (CCUIContentModuleContainerViewController *)responder;
}
@end

// Toggle Notifications
%subclass CCUISeleniumButton : CCUIRoundButton
%property (nonatomic, retain) UIView *backgroundView;
%property (nonatomic, retain) CCUICAPackageView *packageView;
- (void)layoutSubviews {
  %orig;
  if (!self.packageView) {
    self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    self.backgroundView.userInteractionEnabled = NO;
    self.backgroundView.layer.cornerRadius = self.bounds.size.width/2;
    self.backgroundView.layer.masksToBounds = YES;
    self.backgroundView.backgroundColor = [UIColor systemBlueColor];//colorWithRed:174.0f/255.0f green:130.0f/255.0f blue:155.0f/255.0f alpha:1.0f];
    self.backgroundView.alpha = 0;
    [self addSubview:self.backgroundView];

    self.packageView = [[%c(CCUICAPackageView) alloc] initWithFrame:self.bounds];
    //self.packageView.package = [CAPackage packageWithContentsOfURL:[NSURL fileURLWithPath:@"/Library/Application Support/SeleniumExtra.bundle/StyleMode.ca"] type:kCAPackageTypeCAMLBundle options:nil error:nil];
    //[self.packageView setValue:(id)[UIImage imageWithContentsOfFile:@"/Library/Application Support/SeleniumExtra.bundle/Assets/icon.PNG"].CGImage forKey:@"_packageLayer"];
    //[self.packageView setStateName:@"dark"];
    [self addSubview:self.packageView];

    isEnabledForDND = [config[@"EnabledForDND"] boolValue] ? YES : NO;
    NSLog(@"[Selenium] 3 EnabledForDND: %@ isEnabledForDND: %@",config[@"EnabledForDND"],[config[@"EnabledForDND"] boolValue] ? @"YES" : @"NO");
    [self setHighlighted:isEnabledForDND];
    [self updateStateAnimated:NO];
  }
}
- (void)touchesEnded:(id)arg1 withEvent:(id)arg2 {
    %orig;
    isEnabledForDND = !isEnabledForDND;
    setStateForDND(isEnabledForDND ? @"YES" : @"NO");
    [self updateStateAnimated:YES];
}
%new
- (void)updateStateAnimated:(bool)animated {
    if (isEnabledForDND) {
        ((CCUILabeledRoundButton *)self.superview).subtitle = [NSString stringWithFormat:@"On"];
        //[self.packageView setStateName:@"dark"];
        if (animated) {
            [UIView animateWithDuration:0.2 delay:0 options:nil animations:^{
                self.backgroundView.alpha = 1;
            } completion:nil];
        } else {
            self.backgroundView.alpha = 1;
        }
    } else {
        ((CCUILabeledRoundButton *)self.superview).subtitle = @"Off";
        //[self.packageView setStateName:@"light"];
        if (animated) {
            [UIView animateWithDuration:0.2 delay:0 options:nil animations:^{
                    self.backgroundView.alpha = 0;
            } completion:nil];
        } else {
            self.backgroundView.alpha = 0;
        }
    }
}
%end

%hook CCUIContentModuleContainerViewController
%property (nonatomic, retain) CCUILabeledRoundButtonViewController *darkButton;
- (void)setExpanded:(bool)arg1 {
  %orig;
  if (arg1 && [self.moduleIdentifier containsString:@"donot"]) {
    ccBounds = self.view.superview.bounds;
    if (!self.darkButton) {
      self.darkButton = [[%c(CCUILabeledRoundButtonViewController) alloc] initWithGlyphImage:nil highlightColor:nil useLightStyle:NO];
      self.darkButton.buttonContainer = [[%c(CCUILabeledRoundButton) alloc] initWithGlyphImage:nil highlightColor:nil useLightStyle:NO];
      [self.darkButton.buttonContainer setFrame:CGRectMake(0, 0, 72, 91)];
      [self.darkButton.buttonContainer setBounds:CGRectMake(self.darkButton.buttonContainer.frame.origin.x, self.darkButton.buttonContainer.frame.origin.y, self.darkButton.buttonContainer.frame.size.width+10, self.darkButton.buttonContainer.frame.size.height)];
      self.darkButton.view = self.darkButton.buttonContainer;
      self.darkButton.buttonContainer.buttonView = [[%c(CCUISeleniumButton) alloc] initWithGlyphImage:nil highlightColor:nil useLightStyle:NO];
      [self.darkButton.buttonContainer addSubview:self.darkButton.buttonContainer.buttonView];
      self.darkButton.button = self.darkButton.buttonContainer.buttonView;

      self.darkButton.title = @"Snooze";
      if (isEnabledForDND) {
        self.darkButton.subtitle = [NSString stringWithFormat:@"On"];
        [((CCUISeleniumButton *)self.darkButton.buttonContainer.buttonView).packageView setStateName:@"On"];
      } else {
        self.darkButton.subtitle = @"Off";
        [((CCUISeleniumButton *)self.darkButton.buttonContainer.buttonView).packageView setStateName:@"Off"];
      }
      [self.darkButton setLabelsVisible:YES];

      [self.backgroundView addSubview:self.darkButton.buttonContainer];
    }
    [self.darkButton.buttonContainer updatePosition];
    self.darkButton.buttonContainer.alpha = 1;
  }
}
%end

%hook CCUILabeledRoundButton
%property (nonatomic, assign) bool centered;
- (void)setCenter:(CGPoint)center {
  if (self.centered) {
    return;
  } else {
    self.centered = YES;
    %orig;
  }
}
%new
- (void)updatePosition {
  self.centered = NO;
  CGPoint center;
  if ([self.title isEqual: @"Snooze"]) {
    if (ccBounds.size.width < ccBounds.size.height) {
      center.x = ccBounds.size.width/2;
      center.y = ccBounds.size.height-ccBounds.size.height*0.14;
    } else {
      center.x = ccBounds.size.width-ccBounds.size.width*0.14;
      center.y = ccBounds.size.height/2;
    }
  }
  [self setCenter:center];
}
%end

%hook DNDState
-(BOOL)isActive {
    if (isDNDEnabled != %orig) {
        isDNDEnabled = %orig;
        config = [NSMutableDictionary dictionaryWithContentsOfFile:configPath];
        isEnabledForDND = [config[@"EnabledForDND"] isEqualToString:@"YES"] ? YES : NO;
        if (%orig == YES) {
            [config setObject:[NSDate date] forKey:@"DNDStartTime"];
	        [config writeToFile:configPath atomically:YES];
        } else {
            [[AXNManager sharedInstance] showDNDNotificationRequests:config[@"entries"]];
        }
    }
    return %orig;
}
%end*/

#pragma mark DND end

@interface SBAlertItem : NSObject
@end

@interface _SBAlertController : UIAlertController
@property (assign,nonatomic) SBAlertItem * alertItem;
-(void)setAlertItem:(SBAlertItem *)arg1 ;
@end

@interface SBRingerPillView : UIView
@end

@interface UIInterfaceActionGroupView : UIView
@end

@interface _UIAlertControllerInterfaceActionGroupView : UIInterfaceActionGroupView
@end

@interface _UIAlertControllerShadowedScrollView : UIScrollView
@end

@interface _UIInterfaceActionGroupHeaderScrollView : _UIAlertControllerShadowedScrollView
@property (nonatomic,retain) UIView *contentView;
@end

@interface CLLocationManager ()
@property (nonatomic,copy) CLLocation *location;
+(CLLocationManager*)sharedManager;
+(int)authorizationStatus;
+(int)authorizationStatusForBundleIdentifier:(id)arg1 ;
+(void)setAuthorizationStatusByType:(int)arg1 forBundleIdentifier:(id)arg2 ;
+(void)setAuthorizationStatusByType:(int)arg1 forBundle:(id)arg2 ;
//+(void)setAuthorizationStatus:(BOOL)arg1 forBundleIdentifier:(id)arg2 ;
//+(void)setAuthorizationStatus:(BOOL)arg1 forBundle:(id)arg2 ;
-(void)requestWhenInUseAuthorizationWithPrompt;
-(BOOL)allowsBackgroundLocationUpdates;
-(void)setAllowsBackgroundLocationUpdates:(BOOL)arg1 ;
-(BOOL)showsBackgroundLocationIndicator;
-(void)setShowsBackgroundLocationIndicator:(BOOL)arg1 ;
@end

@interface CLSeleniumCircularRegion : CLCircularRegion
@property (nonatomic,retain) NSArray *requests;
@end

%subclass CLSeleniumCircularRegion : CLCircularRegion
%new
- (NSArray *)requests {
	return objc_getAssociatedObject(self, @selector(requests));
}

%new
- (void)setRequests:(NSArray *)value {
	objc_setAssociatedObject(self, @selector(requests), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%end

@interface WFLocationValue : NSObject
@property (nonatomic,readonly) NSString * legacyVariableString;
@property (nonatomic,readonly) NSString * locationName;
@property (nonatomic,readonly) CLPlacemark * placemark;
@property (getter=isCurrentLocation,nonatomic,readonly) BOOL currentLocation;
-(id)initWithPlacemark:(id)arg1 ;
-(id)initWithLocationName:(id)arg1 placemark:(id)arg2 ;
-(id)initWithCurrentLocation;
// %new
- (void)encodeWithCoder:(NSCoder *)encoder;
- (id)initWithCoder:(NSCoder *)decoder;
@end

@interface WFLocationPickerViewController : UIViewController
@property (nonatomic,retain) MKMapView * mapView;
@property (nonatomic,retain) WFLocationValue * value;
@property (assign,nonatomic) id delegate;
@property (nonatomic,retain) CLLocationManager * locationManager;
@property (nonatomic,retain) CLLocation * currentLocation;
@property (nonatomic,retain) UISearchBar * searchBar;
@property (nonatomic,retain) UITableView * tableView;
-(id)initWithPickerType:(unsigned long long)arg1 value:(id)arg2;
-(void)setAllowsPickingCurrentLocation:(BOOL)arg1;
-(void)setResolvesCurrentLocationToPlacemark:(BOOL)arg1;
-(void)setAllowsTextOnlyLocation:(BOOL)arg1;
-(int)currentAppLocationAuthorizationStatus;
-(void)setCurrentAppLocationAuthorizationStatus:(int)arg1 ;
@end

%hook WFLocationValue
%new
- (void)encodeWithCoder:(NSCoder *)encoder {
    //Encode properties, other class variables, etc
    [encoder encodeObject:self.legacyVariableString forKey:@"legacyVariableString"];
    [encoder encodeObject:self.locationName forKey:@"locationName"];
    [encoder encodeObject:self.placemark forKey:@"placemark"];
}

%new
- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [self init])) {
        //decode properties, other class vars
        self = [self initWithLocationName:[decoder decodeObjectForKey:@"locationName"] placemark:[decoder decodeObjectForKey:@"placemark"]];
    }
    return self;
}
%end

%hook CSCoverSheetViewController
-(void)viewDidDisappear:(BOOL)arg1 {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.miwix.selenium.donate" object:nil userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SLMEnableLock" object:self];
    %orig;
}

-(void)setInScreenOffMode:(BOOL)arg1 forAutoUnlock:(BOOL)arg2 fromUnlockSource:(int)arg3 {
    %orig(arg1,arg2,arg3);
    if (arg1)
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SLMEnableLock" object:self];
}
%end

@interface _LSQueryResult : NSObject
@end

@interface LSResourceProxy : _LSQueryResult
@property (nonatomic,readonly) NSDictionary * iconsDictionary;
@end

@interface LSBundleProxy : LSResourceProxy
@property (nonatomic,readonly) NSURL * bundleURL;
@property (nonatomic,readonly) NSString * canonicalExecutablePath;
+(id)bundleProxyForIdentifier:(id)arg1 ;
@end

@interface LSApplicationProxy : LSBundleProxy
@property (nonatomic,readonly) NSString * applicationIdentifier;
+(LSApplicationProxy *)applicationProxyForIdentifier:(id)arg1 ;
@end

@interface NSBundle ()
- (NSArray *)loadNibNamed:(NSString *)name 
                    owner:(id)owner 
                  options:(NSDictionary<UINibOptionsKey, id> *)options;
@end

@interface UINib ()
-(id)nibDataForPath:(id)arg1 ;
-(id)initWithData:(id)arg1 bundle:(id)arg2 ;
-(NSArray *)instantiateWithOwner:(id)ownerOrNil options:(NSDictionary<UINibOptionsKey, id> *)optionsOrNil;
@end

@interface UIStoryboard ()
@property (readonly) NSString * name;
-(BOOL)containsNibNamed:(id)arg1 ;
-(id)nibForViewControllerWithIdentifier:(id)arg1 ;
@end

@interface TTRIReminderLocationPickerViewController : UIViewController
@property (nonatomic,retain) MKMapView * mapView;
@property (assign,nonatomic) id delegate;
@property (nonatomic,retain) CLLocationManager * locationManager;
@property (nonatomic,retain) CLLocation * currentLocation;
@property (nonatomic,retain) UISearchBar * searchBar;
@property (nonatomic,retain) UITableView * tableView;
@end

%hook SpringBoard
%property (nonatomic,retain) NCNotificationRequest *requestForLocation;
%property (nonatomic,retain) CLLocationManager *seleniumLocationManager;
// %property (nonatomic,retain) WFLocationPickerViewController *seleniumLocationPickerViewController;
%property (nonatomic,retain) NSArray *requestsForLocation;
%property (nonatomic,assign) BOOL isNotifForLocationGrouped;
%property (nonatomic,assign) BOOL onArrive;
%property (strong, nonatomic) UIWindow *window;
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    NSLog(@"[Selenium] ButtonChange");

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDonateController:) name:@"com.miwix.selenium.donate" object:nil];

    config = [[NSMutableDictionary dictionaryWithContentsOfFile:configPath] mutableCopy];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showSeleniumMenu:) name:@"com.miwix.selenium.menu" object:nil];
    
    #pragma mark remove already snoozed notifications from entries
    NSMutableArray *entries = [config[@"entries"] mutableCopy];
    for (NSMutableDictionary *entry in entries) {
        if ([entry[@"timeStamp"] doubleValue] != -2) {
            if (([[NSDate date] timeIntervalSince1970] - [entry[@"timeStamp"] doubleValue]) >= 1 && [entry[@"timeStamp"] doubleValue] != -2) {
                NCNotificationRequest *expiredReq = entry[@"id"];
                processEntry(expiredReq, 0, nil, nil, nil);
            }
        } else {
            if (self.seleniumLocationManager == nil && snoozeByLocationEnabled == YES) {
                NSLog(@"[Selenium] initializing seleniumLocationManager");
                self.seleniumLocationManager = [[CLLocationManager alloc] init];
                [[self seleniumLocationManager] setDelegate:(id<CLLocationManagerDelegate>)self];
                [[self seleniumLocationManager] setDesiredAccuracy:kCLLocationAccuracyHundredMeters];
                [[self seleniumLocationManager] setAllowsBackgroundLocationUpdates:YES];
                [[self seleniumLocationManager] setPausesLocationUpdatesAutomatically:NO];
                [[self seleniumLocationManager] startUpdatingLocation];
                [[self seleniumLocationManager] requestLocation];
            }
        }
    }

    #pragma mark remove expired notifs from snoozedCache
    NSMutableArray *snoozedCache = [config[@"snoozedCache"] mutableCopy];
    for (NSMutableDictionary *snoozedNotif in snoozedCache) {
        //NSDate *timeStamp = [snoozedNotif objectForKey:@"timeToRemove"];
        if (([[NSDate date] timeIntervalSince1970] - [snoozedNotif[@"timeToRemove"] timeIntervalSince1970]) >= 1 && [snoozedNotif[@"timeStamp"] doubleValue] != -2) {
            NCNotificationRequest *snoozedNotifReq = snoozedNotif[@"id"];
            storeSnoozed(snoozedNotifReq, YES, NO);
        }
    }
}

%new
- (void)showDonateController:(NSNotification *)notification {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([[config objectForKey:@"firstTime"] isEqualToString:@"YES"]) {
            [config setValue:@"NO" forKey:@"firstTime"];
            [config writeToFile:configPath atomically:YES];
            UIViewController *donateController = [[UIViewController alloc] init];
            [[donateController view] setBackgroundColor:[UIColor systemBackgroundColor]];

            UIStackView *stackView = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, [donateController view].frame.size.width, [donateController view].frame.size.width)];
            stackView.axis = UILayoutConstraintAxisVertical;
            stackView.alignment = UIStackViewAlignmentCenter;
            stackView.distribution = UIStackViewDistributionEqualSpacing;
            stackView.layoutMarginsRelativeArrangement = YES;
            stackView.spacing = 15;

            UIImage *iconImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/SeleniumExtra.bundle/Assets/icon.PNG"];
            UIImageView *iconImageView = [[UIImageView alloc] initWithImage:iconImage];
            [iconImageView setFrame:CGRectMake(0, 0, 100.0f, 100.0f)];
            [iconImageView setTranslatesAutoresizingMaskIntoConstraints:YES];
            [iconImageView.widthAnchor constraintEqualToAnchor:nil constant:[[UIScreen mainScreen] bounds].size.width/4.0f].active = YES;
            [iconImageView.heightAnchor constraintEqualToAnchor:nil constant:[[UIScreen mainScreen] bounds].size.width/4.0f].active = YES;

            UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100.0f, 100.0f)];
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:@"Thank you for installing Selenium!\n I hope you'll enjoy it😁\n\n Selenium has been in the works for over 5 months, and is based on code from several open-source tweaks. Therefore, it is delivered to you completely free of charge🤑\n\n If you appreciate my work, please consider making a small donation."];
            [attributedText addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:17.0f weight:UIFontWeightHeavy] range:NSMakeRange(0,35)];
            [attributedText addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:17.0f] range:NSMakeRange(36,262)];
            textLabel.attributedText = attributedText;
            textLabel.textColor = [UIColor labelColor];
            textLabel.textAlignment = NSTextAlignmentCenter;
            textLabel.lineBreakMode = NSLineBreakByWordWrapping;
            textLabel.numberOfLines = 0;

            SButton *donateButton = [SButton buttonWithType:UIButtonTypeSystem];
            [donateButton setFrame:CGRectMake(0, 0, 250.0f, 50.0f)]; // Notch Series
            [donateButton setTranslatesAutoresizingMaskIntoConstraints:NO];
            [donateButton.widthAnchor constraintEqualToAnchor:nil constant:[[UIScreen mainScreen] bounds].size.width/1.5f].active = YES;
            [donateButton.heightAnchor constraintEqualToAnchor:nil constant:([[UIScreen mainScreen] bounds].size.width/1.5f)/5.0f].active = YES;
            [donateButton setTitle:@"Donate" forState:UIControlStateNormal];
            [donateButton setBackgroundColor:[UIColor colorWithRed:174.0f/255.0f green:130.0f/255.0f blue:155.0f/255.0f alpha:1.0f]];
            [[donateButton titleLabel] setFont:[UIFont systemFontOfSize:19]];
            [[donateButton layer] setCornerRadius:10.5];
            [donateButton setTintColor:[UIColor whiteColor]];
            [donateButton addTarget:self action:@selector(buttonDonate:) forControlEvents:UIControlEventTouchUpInside];
            donateButton.controllerToDismiss = donateController;

            SButton *closeButton = [SButton buttonWithType:UIButtonTypeClose];
            [closeButton setFrame:CGRectMake(0, 0, 30.0f, 30.0f)];
            [closeButton addTarget:self action:@selector(buttonDismiss:) forControlEvents:UIControlEventTouchUpInside];
            closeButton.controllerToDismiss = donateController;

            [stackView addArrangedSubview:iconImageView];
            [stackView addArrangedSubview:textLabel];
            [stackView addArrangedSubview:donateButton];
            [[donateController view] addSubview:stackView];
            [[donateController view] addSubview:closeButton];

            // Constraints
            [stackView setTranslatesAutoresizingMaskIntoConstraints:NO];
            [stackView.centerXAnchor constraintEqualToAnchor:[donateController view].centerXAnchor constant:0].active = YES;
            [stackView.centerYAnchor constraintEqualToAnchor:[donateController view].centerYAnchor constant:-10.0f].active = YES;
            [stackView.widthAnchor constraintEqualToAnchor:[donateController view].widthAnchor constant:[[UIScreen mainScreen] bounds].size.width/1.15f].active = YES;
            [textLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
            [textLabel.widthAnchor constraintEqualToAnchor:nil constant:[[UIScreen mainScreen] bounds].size.width/1.3f].active = YES;
            [closeButton setTranslatesAutoresizingMaskIntoConstraints:NO];
            [closeButton.topAnchor constraintEqualToAnchor:[donateController view].topAnchor constant:10.0f].active = YES;
            [closeButton.trailingAnchor constraintEqualToAnchor:[donateController view].trailingAnchor constant:-10.0f].active = YES;

            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:donateController animated:YES completion:nil];
            donateController.modalInPopover = YES;
        }
    });
}

%new
-(void)locationPicker:(WFLocationPickerViewController*)picker didFinishWithValue:(WFLocationValue*)location {
    [picker dismissViewControllerAnimated:YES completion:^{
        //[[CLLocationManager sharedManager] setAllowsBackgroundLocationUpdates:YES];
        //[[CLLocationManager sharedManager] setActivityType:CLActivityTypeFitness];
        //[[CLLocationManager sharedManager] setPausesLocationUpdatesAutomatically:YES];
        //[[CLLocationManager sharedManager] startMonitoringVisits];
        //[CLLocationManager setAuthorizationStatus:YES forBundleIdentifier:[%c(SpringBoard) displayIdentifier]];
        NSLog(@"[Selenium] significantLocationChangeMonitoringAvailable: %@",[CLLocationManager significantLocationChangeMonitoringAvailable] ? @"YES" : @"NO");
        //CLSeleniumCircularRegion *regionToUse = [[%c(CLSeleniumCircularRegion) alloc] initWithCenter:[location placemark].region.center radius:[location placemark].region.radius identifier:[location placemark].region.identifier];
        //CLCircularRegion *regionToUse = [[%c(CLCircularRegion) alloc] initWithCenter:[location placemark].region.center radius:[location placemark].region.radius identifier:[location placemark].region.identifier];
        CLCircularRegion *regionToUse = [location placemark].region;
        NSLog(@"[Selenium] isMonitoringAvailableForClass(%@): %@",[%c(CLCircularRegion) class] ,[CLLocationManager isMonitoringAvailableForClass:[%c(CLCircularRegion) class]] ? @"YES" : @"NO");
        if (self.onArrive) {
            [regionToUse self].notifyOnEntry = YES;
            [regionToUse self].notifyOnExit = NO;
        } else {
            [regionToUse self].notifyOnExit = YES;
            [regionToUse self].notifyOnEntry = NO;
        }
        if (self.requestForLocation != nil || self.requestsForLocation != nil) {
            if (self.isNotifForLocationGrouped) {
                [[AXNManager sharedInstance] hideNotificationRequests:self.requestsForLocation];
                for (NCNotificationRequest *reqToHide in self.requestsForLocation) {
                    if ([reqToHide.content.header containsString:SNOOZED]) {
                        NSString *string = [reqToHide.content.header componentsSeparatedByString:@" •"][0];
                        [reqToHide.content setValue:string forKey:@"_header"];
                    }
                    if (![reqToHide.content.header containsString:LOCATION]) {
                        NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", reqToHide.content.header, LOCATION];
                        [reqToHide.content setValue:newTitle forKey:@"_header"];
                    }
                    processEntry(reqToHide, -2, nil, regionToUse, self.onArrive);
                }
                //[(CLSeleniumCircularRegion*)regionToUse self].requests = self.requestsForLocation;
            } else {
                [[AXNManager sharedInstance] hideNotificationRequest:self.requestForLocation];
                if (![self.requestForLocation.content.header containsString:LOCATION]) {
                    NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", self.requestForLocation.content.header, LOCATION];
                    [self.requestForLocation.content setValue:newTitle forKey:@"_header"];
                }
                processEntry(self.requestForLocation, -2, nil, regionToUse, self.onArrive);
                //[(CLSeleniumCircularRegion*)regionToUse self].requests = @[self.requestForLocation];
            }
        } else {
            NSLog(@"[Selenium] No Notifications To Snooze For Location!");
            return;
        }
        [[CLLocationManager sharedManager] startMonitoringForRegion:regionToUse];
        NSLog(@"[Selenium] monitoredRegions count: %td",(NSUInteger)[[CLLocationManager sharedManager].monitoredRegions count]);
        NSLog(@"[Selenium] regionToUse: %@",regionToUse);
        self.onArrive = nil;
        self.isNotifForLocationGrouped = nil;
        self.requestForLocation = nil;
        self.requestsForLocation = nil;
    }];
}

%new
-(void)locationPickerDidCancel:(id)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
    /*for (CLRegion *region in [CLLocationManager sharedManager].monitoredRegions)
    [[CLLocationManager sharedManager] stopMonitoringForRegion:region];*/
}

%new
-(void)locationManager:(CLLocationManager *)arg1 didUpdateToLocation:(CLLocation *)arg2 fromLocation:(id)arg3 {
    NSLog(@"[Selenium] HI!");
    // if ([self seleniumLocationPickerViewController] != nil) self.seleniumLocationPickerViewController.currentLocation = arg2;
}

%new
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    NSLog(@"[Selenium] HI2!");
    // if ([self seleniumLocationPickerViewController] != nil) self.seleniumLocationPickerViewController.currentLocation = locations[0];
}

%new
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"[Selenium] HI2!");
}

%new
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"[Selenium] WE ARE IN A LOCATION");
    //if ([region isMemberOfClass:[%c(CLCircularRegion) class]]) {
        NSMutableArray *entries = [config[@"entries"] mutableCopy];
        for (NSDictionary *entry in entries) {
            if ([entry[@"timeStamp"] doubleValue] == -2) {
                if (entry[@"regionIdentifier"] == region.identifier) {
                    NSLog(@"[Selenium] match! (%@)",region.identifier);
                    BBBulletin *bulletin = [%c(BBBulletin) bulletinWithBulletin:(BBBulletin*)[NSKeyedUnarchiver unarchiveObjectWithData:[entry objectForKey:@"encodedBulletin"]]];
                    NSLog(@"[Selenium] bulletin: %@", bulletin != nil ? @"YES" : @"NO");
                    NSLog(@"[Selenium] matched bulletin: %@", bulletin);

                    dispatch_sync(__BBServerQueue, ^{
                        if (![[bulletin.header lowercaseString] containsString:LOCATION])
                        bulletin.header = [NSString stringWithFormat:@"%@ • %@",bulletin.header,LOCATION];
                        //if (shouldResetDate) request.bulletin.date = [NSDate date];
                        [[%c(BBServer) SLM_sharedInstance] publishBulletin:bulletin destinations:14];
                    });
                }
            }
            /*BBObserver *observer = (BBObserver*)[NSKeyedUnarchiver unarchiveObjectWithData:[entry objectForKey:@"encodedObserver"]];
            [%c(NCNotificationRequest) notificationRequestForBulletin:bulletin observer:observer sectionInfo:[%c(BBSectionInfo) defaultSectionInfoForSection: @"bulletin.section"] feed:(snooozedDeliverProminently ? 14 : 1) playLightsAndSirens:snooozedDeliverProminently];*/
        }
        /*[[AXNManager sharedInstance] showNotificationRequests:region.requests];
        [[CLLocationManager sharedManager] stopMonitoringForRegion:region];
        NSLog(@"[Selenium] monitoredRegions newCount: %td",(NSUInteger)[[CLLocationManager sharedManager].monitoredRegions count]);
        NSLog(@"[Selenium] WE ARE IN THE LOCATION");
        if ((NSUInteger)[[CLLocationManager sharedManager].monitoredRegions count] == 0)
            [manager stopUpdatingLocation];*/
    //}
}

%new
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"[Selenium] WE ARE OUT OF A LOCATION");
    //if ([region isMemberOfClass:[%c(CLCircularRegion) class]]) {
        NSMutableArray *entries = [config[@"entries"] mutableCopy];
        for (NSDictionary *entry in entries) {
            if ([entry[@"timeStamp"] doubleValue] == -2) {
                if (entry[@"regionIdentifier"] == region.identifier) {
                    NSLog(@"[Selenium] match! (%@)",region.identifier);
                    BBBulletin *bulletin = [%c(BBBulletin) bulletinWithBulletin:(BBBulletin*)[NSKeyedUnarchiver unarchiveObjectWithData:[entry objectForKey:@"encodedBulletin"]]];
                    NSLog(@"[Selenium] bulletin: %@", bulletin != nil ? @"YES" : @"NO");
                    NSLog(@"[Selenium] matched bulletin: %@", bulletin);

                    dispatch_sync(__BBServerQueue, ^{
                        if (![[bulletin.header lowercaseString] containsString:LOCATION])
                        bulletin.header = [NSString stringWithFormat:@"%@ • %@",bulletin.header,LOCATION];
                        //if (shouldResetDate) request.bulletin.date = [NSDate date];
                        [[%c(BBServer) SLM_sharedInstance] publishBulletin:bulletin destinations:14];
                    });
                }
            }
            /*BBObserver *observer = (BBObserver*)[NSKeyedUnarchiver unarchiveObjectWithData:[entry objectForKey:@"encodedObserver"]];
            [%c(NCNotificationRequest) notificationRequestForBulletin:bulletin observer:observer sectionInfo:[%c(BBSectionInfo) defaultSectionInfoForSection: @"bulletin.section"] feed:(snooozedDeliverProminently ? 14 : 1) playLightsAndSirens:snooozedDeliverProminently];*/
        }
        /*[[AXNManager sharedInstance] showNotificationRequests:region.requests];
        [[CLLocationManager sharedManager] stopMonitoringForRegion:region];
        NSLog(@"[Selenium] monitoredRegions newCount: %td",(NSUInteger)[[CLLocationManager sharedManager].monitoredRegions count]);
        NSLog(@"[Selenium] WE ARE OUT OF THE LOCATION");
        if ((NSUInteger)[[CLLocationManager sharedManager].monitoredRegions count] == 0)
            [manager stopUpdatingLocation];*/
    //}
}

%new
- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    NSLog(@"[Selenium] locationManagerDidPauseLocationUpdates");
}

/*%new
- (void)locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit {
    NSLog(@"[Selenium] locationManager didVisit");
}*/

%new
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSLog(@"[Selenium] didChangeAuthorizationStatus: %d", status);
    if (status == 4) {
        [[objc_getClass("SBLockScreenManager") sharedInstance] lockScreenViewControllerRequestsUnlock];
        [manager requestWhenInUseAuthorizationWithPrompt];
        [manager requestAlwaysAuthorization];
    }
}

/*%new
- (void)locationManager:(CLLocationManager *)manager authorizeCustom:(CLAuthorizationStatus)status {
    if (!approved) {
        UIWindow *prevKeyWindow = [UIApplication sharedApplication].keyWindow;
        UIWindow *window = [[UIWindow alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.bounds];
        window.windowLevel = UIWindowLevelAlert;
        self.window = window;
        UIViewController *vc = [[UIViewController alloc] init];
        window.rootViewController = vc;
                [window setHidden:YES];
                [prevKeyWindow makeKeyAndVisible];
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}*/

%new
- (void)showSeleniumMenu:(NSNotification *)notification {
    NCNotificationRequest *requestToProcess = notification.userInfo[@"id"];
    NCNotificationListCell *cellToCapture = notification.userInfo[@"cell"];
    NCNotificationListView *cellListView = (NCNotificationListView *)cellToCapture.superview;
    NCNotificationGroupList *groupList = cellListView.dataSource;
    NSMutableArray *reqsArray = [groupList.orderedRequests copy];

    UIAlertController *alert;

    BOOL grouped;
    if (cellListView.grouped && [cellListView.visibleViews count] > 1) {
        grouped = YES;
        alert = [UIAlertController alertControllerWithTitle:SNOOZENS message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    } else {
        grouped = NO;
        alert = [UIAlertController alertControllerWithTitle:SNOOZEN message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"SLMDisableLock" object:self];

    /*[alert addAction:[UIAlertAction actionWithTitle:@"Until DND is turned off" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (grouped){
            [[AXNManager sharedInstance] hideNotificationRequests:reqsArray];
        } else {
            [[AXNManager sharedInstance] hideNotificationRequest:requestToProcess];
            if (![requestToProcess.content.header containsString:@"DND"]) {
                NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", requestToProcess.content.header, @"DND"];
                [requestToProcess.content setValue:newTitle forKey:@"_header"];
            }
            processEntry(requestToProcess, -2, nil, nil, nil);
        }
    }]];*/
    // new menu
    // if (snoozeByLocationEnabled == NO) {
    //     //NCNotificationManagementAlertController *alertController = [[%c(NCNotificationManagementAlertController) alloc] initWithRequest:requestToProcess withPresentingView:nil settingsDelegate:nil];
    //         UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    //         CGFloat margin = 4.0F;

    //         _UIInterfaceActionGroupHeaderScrollView *alertScrollView;
    //         for (id view in [(_UIAlertControllerInterfaceActionGroupView*)[[[alertController view] subviews][0] subviews][0] subviews]) {
    //             if ([view isKindOfClass:[%c(UIView) class]]) {
    //                 for (id view2 in [view subviews]) {
    //                     if ([view2 isKindOfClass:[%c(_UIInterfaceActionGroupHeaderScrollView) class]]) {
    //                         alertScrollView = view2;
    //                         NSLog(@"[Selenium] Scroll View Found!!!");
    //                     }
    //                 }

    //             }
    //         }
    //         [alertScrollView setClipsToBounds:YES];
    //         [alertScrollView setUserInteractionEnabled:YES];

    //         [[alertController view] setClipsToBounds:YES];
    //         UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,0,0)];
    //         [alertScrollView addSubview:containerView];
    //         [containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
    //         [[alertController view] addConstraint:[NSLayoutConstraint constraintWithItem:[alertController view] attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
    //         [[alertController view] addConstraint:[NSLayoutConstraint constraintWithItem:[alertController view] attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
    //         [containerView setHidden:YES];
            
    //         [alertController setTitle:SNOOZEF];

    //         BOOL finished = NO;
    //         UIImageView *cellImage = nil;
    //         double widthInPoints = nil;
    //         double heightInPoints = nil;
    //         SButton *button2 = nil;
    //         //setup:
    //         //if (!cellImage) {
    //             cellImage = [[UIImageView alloc] init];
    //             cellImage.image = [self imageWithView:cellToCapture];
    //             widthInPoints = cellImage.image.size.width;
    //             heightInPoints = cellImage.image.size.height;
    //             [cellImage setFrame:CGRectMake(0, 0, widthInPoints, heightInPoints)];
    //             cellImage.contentMode = UIViewContentModeScaleAspectFit;
    //         //}

    //         /*if (!button2) */button2 = [SButton buttonWithType:UIButtonTypeSystem];

    //         if (grouped) {
    //         button2.frame = CGRectMake(10 + alertController.view.bounds.origin.x , alertController.view.bounds.origin.y+50, alertController.view.frame.size.width - margin * 4.0F - 20, heightInPoints);
    //             [cellImage setFrame:CGRectMake(button2.bounds.origin.x, button2.bounds.origin.y, button2.bounds.size.width-20, button2.bounds.size.height)];
    //         } else {
    //         button2.frame = CGRectMake(10 + alertController.view.bounds.origin.x , alertController.view.bounds.origin.y+50, alertController.view.frame.size.width - margin * 4.0F - 20, heightInPoints);
    //             [cellImage setFrame:CGRectMake(button2.bounds.origin.x, button2.bounds.origin.y, button2.bounds.size.width-20, button2.bounds.size.height)];
    //         }

    //         [button2 setBackgroundColor:[UIColor systemGrayColor]];
    //         [button2 setAlpha:0.1f];
    //         button2.layer.cornerRadius = 12.5;

    //         /*if (![button2 superview]) */[alertScrollView addSubview:button2];
    //         /*if (![cellImage superview]) */[alertScrollView addSubview:cellImage];
    //             [button2 setTranslatesAutoresizingMaskIntoConstraints:NO];
    //             [cellImage setTranslatesAutoresizingMaskIntoConstraints:NO];
    //             //[button2.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:50].active = YES;
    //             [button2.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:10].active = YES;
    //             [button2.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-10].active = YES;
    //             //[button2.heightAnchor constraintEqualToAnchor:cellImage.heightAnchor constant:grouped ? 30 : 15].active = YES;
    //             [cellImage.leadingAnchor constraintEqualToAnchor:button2.leadingAnchor constant:10].active = YES;
    //             [cellImage.topAnchor constraintEqualToAnchor:button2.topAnchor constant:10].active = YES;
    //             //[cellImage.heightAnchor constraintEqualToAnchor:cellImage.heightAnchor constant:-10].active = YES;
    //             //[button2.heightAnchor constraintEqualToAnchor:nil constant:heightInPoints+10].active = YES;
    //             //[button2.widthAnchor constraintEqualToAnchor:nil constant:widthInPoints+10].active = YES;
    //             //[cellImage.topAnchor constraintEqualToAnchor:button2.topAnchor constant:10].active = YES;
    //             [cellImage.centerYAnchor constraintEqualToAnchor:button2.centerYAnchor constant:0].active = YES;
    //             [cellImage.centerXAnchor constraintEqualToAnchor:button2.centerXAnchor constant:0].active = YES;
    //         cellImage.center = button2.center;

    //         #pragma mark stepper "cell"
    //         UIView *stepperFrame = [[UIView alloc] initWithFrame:CGRectMake(10 + containerView.bounds.origin.x , containerView.bounds.origin.y+60+(heightInPoints+10), [alertController view].bounds.size.width - margin * 4.0F - 20, 50)];
    //         [stepperFrame setBackgroundColor:[UIColor systemGrayColor]];
    //         [stepperFrame setAlpha:0.1];
    //         stepperFrame.layer.cornerRadius = 12.5;
    //         UIHoursStepper *stepper = [[UIHoursStepper alloc] init];
    //         stepper.minimumValue = 1; //15m, 30m, 45m, 1h, 2h, 3h, 4h, 6h, 8h, 12h
    //         stepper.maximumValue = 10;
    //         [stepper addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    //         [alertScrollView addSubview:stepperFrame];
    //         [stepperFrame setTranslatesAutoresizingMaskIntoConstraints:YES];
    //         [stepperFrame.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:10].active = YES;
    //         [stepperFrame.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-10].active = YES;
    //         [stepperFrame.topAnchor constraintEqualToAnchor:button2.bottomAnchor constant:10].active = YES;
    //         [stepperFrame.heightAnchor constraintEqualToAnchor:nil constant:50].active = YES;
    //         //[alertScrollView addSubview:stepper];
    //         CGFloat stepperMargin = CGRectGetHeight(stepperFrame.frame)-CGRectGetHeight(stepper.frame);
    //         UIStackView *stackView = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, stepperFrame.frame.size.width - stepperMargin, stepperFrame.frame.size.height)];
    //         stackView.axis = UILayoutConstraintAxisHorizontal;
    //         stackView.center = stepperFrame.center;
    //         stackView.distribution = UIStackViewDistributionEqualSpacing;
    //         stackView.alignment = UIStackViewAlignmentCenter;
    //         CGFloat stepperX = CGRectGetWidth(stepperFrame.frame)-CGRectGetWidth(stepper.frame)-stepperMargin;
    //         CGFloat stepperY = stepperFrame.frame.origin.y+(CGRectGetHeight(stepperFrame.frame)-CGRectGetHeight(stepper.frame)-stepperMargin);
    //         //stepper.frame = CGRectMake(stepperX+stepperMargin, stepperY, 0, 0);
    //         CGFloat stepperLabelY = (CGRectGetHeight(stepperFrame.frame)/2)-(CGRectGetHeight(stepper.frame)/2);
    //         UILabel *stepperLabel = [[UILabel alloc] initWithFrame:CGRectMake(stepperFrame.frame.origin.x+stepperMargin, stepperFrame.frame.origin.y-stepperLabelY*2, stepperFrame.frame.size.width-stepperMargin, stepperFrame.frame.size.height-(stepperLabelY-stepperFrame.frame.size.height))];
    //         UILabel *stepperUntilLabel = [[UILabel alloc] initWithFrame:CGRectMake(stepperLabel.frame.origin.x+stepperLabel.frame.size.height, stepperFrame.frame.origin.y-stepperLabelY*2, stepperFrame.frame.size.width-stepperMargin, stepperFrame.frame.size.height-(stepperLabelY-stepperFrame.frame.size.height))];
    //         //[alertScrollView addSubview:stepperLabel];
    //         if ([[NSUserDefaults standardUserDefaults] objectForKey:@"lastStepperLabelText"]) {
    //             stepperLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastStepperLabelText"];
    //             stepper.value = [(NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"lastStepperValue"] doubleValue];
    //         } else {
    //             stepperLabel.text = fMINUTES;
    //             stepper.value = 1;
    //         }
    //         //[stepperLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
    //         NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    //         formatter.formatterBehavior = NSDateFormatterBehavior10_4;
    //         formatter.dateStyle = NSDateFormatterShortStyle;
    //         formatter.timeStyle = NSDateFormatterShortStyle;
    //         [formatter setDateFormat:@"HH:mm"];
    //         NSString *result = [formatter stringForObjectValue:[self getStepperValue:[NSNumber numberWithFloat:stepper.value]]];
    //         NSMutableArray *parts = [SNOOZEU componentsSeparatedByString:@" "];
    //         [parts removeObject:parts[0]];
    //         NSString *UNTIL = [parts componentsJoinedByString:@" "];
    //         UIFont *systemFont = [UIFont systemFontOfSize:13.0f];
    //         NSDictionary *attribsSnoozedForUntilLabel = @{
    //                         NSForegroundColorAttributeName:[UIColor systemBlueColor],
    //                         NSFontAttributeName:systemFont
    //                         };
    //         NSMutableAttributedString *attributedSnoozedForUntilLabel = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@",UNTIL,result] attributes:attribsSnoozedForUntilLabel];
    //         stepperUntilLabel.attributedText = attributedSnoozedForUntilLabel;

    //         UIStackView *labelStackView = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, stepperFrame.frame.size.width - stepperMargin, stepperFrame.frame.size.height)];
    //         labelStackView.axis = UILayoutConstraintAxisVertical;
    //         labelStackView.center = stepperFrame.center;
    //         labelStackView.distribution = UIStackViewDistributionEqualSpacing;
    //         labelStackView.alignment = UIStackViewAlignmentLeading;
    //         [labelStackView addArrangedSubview:stepperLabel];
    //         [labelStackView addArrangedSubview:stepperUntilLabel];
    //         stepper.stepperLabel = labelStackView;

    //         [stackView addArrangedSubview:labelStackView];
    //         [stackView addArrangedSubview:stepper];
    //         [alertScrollView addSubview:stackView];

    //         SButton *snoozeButton = [SButton buttonWithType:UIButtonTypeSystem];
    //         // snoozeButton.frame = CGRectMake(10 + containerView.bounds.origin.x, containerView.bounds.origin.y + (/*picker*/90 - 2) + 50, [alertController view].bounds.size.width - margin * 4.0F - 20, 50);
    //         [snoozeButton setBackgroundColor:[UIColor systemBlueColor]];
    //         [snoozeButton setTitle:SNOOZE forState:UIControlStateNormal];
    //         snoozeButton.titleLabel.font = [UIFont systemFontOfSize:19];
    //         [snoozeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    //         snoozeButton.request = requestToProcess;
    //         snoozeButton.controllerToDismiss = alertController;
    //         snoozeButton.cell = cellToCapture;
    //         snoozeButton.grouped = grouped;
    //         snoozeButton.stepperDate = [self performSelector:@selector(getStepperValue:) withObject:[NSNumber numberWithFloat:stepper.value]];
    //         snoozeButton.stepper = stepper;
    //         [snoozeButton addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
    //         [snoozeButton addTarget:self action:@selector(buttonUpCancel:) forControlEvents:UIControlEventTouchDragExit];
    //         [snoozeButton addTarget:self action:@selector(stepperButtonUp:) forControlEvents:UIControlEventTouchUpInside];
    //         snoozeButton.layer.cornerRadius = 10.5;

    //         SButton *sTimeButton = [SButton buttonWithType:UIButtonTypeSystem];
    //         [sTimeButton setBackgroundColor:[[UIColor systemBlueColor] colorWithAlphaComponent:38.0f/255.0f]];
    //         [sTimeButton setTitle:sTIME forState:UIControlStateNormal];
    //         [sTimeButton setImage:[UIImage systemImageNamed:@"timer"] forState:UIControlStateNormal];
    //         // [sTimeButton setImage:[UIImage systemImageNamed:@"stopwatch.fill"] forState:UIControlStateNormal];
    //         sTimeButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    //         CGSize sizeOfImage = [sTIME sizeWithFont:[UIFont systemFontOfSize:14]];
    //         sTimeButton.imageEdgeInsets = UIEdgeInsetsMake(4, 0, 4, 0);
    //         sTimeButton.titleLabel.font = [UIFont systemFontOfSize:14];
    //         [sTimeButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    //         sTimeButton.layer.cornerRadius = 10.5;

    //         [alertScrollView addSubview:snoozeButton];
    //         [alertScrollView addSubview:sTimeButton];

    //         snoozeButton.frame = CGRectMake(10 + containerView.bounds.origin.x, containerView.bounds.origin.y + /*picker*/70 + stepperFrame.frame.size.height + button2.frame.size.height, [alertController view].bounds.size.width - margin * 4.0F - 20, 50);
    //         [snoozeButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    //         [snoozeButton.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:10].active = YES;
    //         [snoozeButton.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-10].active = YES;
    //         [snoozeButton.topAnchor constraintEqualToAnchor:stepperFrame.bottomAnchor constant:10].active = YES;
    //         [snoozeButton.heightAnchor constraintEqualToAnchor:nil constant:50].active = YES;

    //         sTimeButton.frame = CGRectMake(10 + containerView.bounds.origin.x, containerView.bounds.origin.y + /*picker*/70 + stepperFrame.frame.size.height + button2.frame.size.height, [alertController view].bounds.size.width - margin * 4.0F - 20, 60);
    //         [sTimeButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    //         [sTimeButton.centerXAnchor constraintEqualToAnchor:containerView.centerXAnchor constant:0].active = YES;
    //         [sTimeButton.topAnchor constraintEqualToAnchor:snoozeButton.bottomAnchor constant:8].active = YES;
    //         // [sTimeButton.heightAnchor constraintEqualToAnchor:nil constant:25].active = YES;
    //         [NSLayoutConstraint constraintWithItem:sTimeButton
    //                                      attribute:NSLayoutAttributeHeight
    //                                      relatedBy:NSLayoutRelationEqual 
    //                                         toItem:snoozeButton
    //                                      attribute:NSLayoutAttributeHeight
    //                                     multiplier:0.6
    //                                       constant:0].active = YES;
    //         sTimeButton.contentEdgeInsets = UIEdgeInsetsMake(0.0f, 5.25f, 0.0f, 10.5f);

    //         //UIPopoverPresentationController *popoverController = alertController.popoverPresentationController;
    //         //popoverController.sourceView = [alertController view];
    //         //popoverController.sourceRect = [[alertController view] bounds];

    //         [alertScrollView setContentSize:CGSizeMake(alertScrollView.superview.bounds.size.width, (snoozeButton.frame.origin.y-button2.frame.origin.y)+snoozeButton.frame.size.height+40)];
    //         if ([alertController view].bounds.size.height > [alertController view].bounds.size.width)
    //         [[alertController view] addConstraint:[NSLayoutConstraint constraintWithItem:[alertController view] attribute:NSLayoutAttributeBottomMargin relatedBy:NSLayoutRelationEqual toItem:snoozeButton attribute:NSLayoutAttributeBottom multiplier:1.0 constant:75+38]];
    //         else
    //         [[alertController view] addConstraint:[NSLayoutConstraint constraintWithItem:alertScrollView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:[alertController view] attribute:NSLayoutAttributeHeight multiplier:1.0 constant:-25/*([[UIScreen mainScreen] bounds].size.height)-25*/]];

    //         //if (!finished) {
    //             finished = YES;
    //         //    goto setup;
    //         //} else {
    //             [alertController addAction:[UIAlertAction actionWithTitle:CANCEL style:UIAlertActionStyleCancel handler:nil]];
    //             [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
    //         //}

    //         sTimeButton.layer.cornerRadius = sTimeButton.layer.bounds.size.height / 4;
    // } else {
        if ([CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] != 2 && snoozeByLocationEnabled == YES) [alert addAction:[UIAlertAction actionWithTitle:ARRIVELOCATION style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                /*NSBundle *bundle = [NSBundle bundleWithURL:[%c(LSApplicationProxy) applicationProxyForIdentifier:@"com.apple.reminders"].bundleURL];
                [bundle load];
                UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"TTRIReminderLocationPickerViewController" bundle:bundle];
                [bundle loadNibNamed:@"TTRIReminderLocationPickerViewController" owner:self options:nil];
                TTRIReminderLocationPickerViewController *reminderLocationViewController = [[UIViewController alloc] initWithNibName:@"TTRIReminderLocationPickerViewController" bundle:bundle];*/

            WFLocationPickerViewController *locationViewController = [[%c(WFLocationPickerViewController) alloc] initWithPickerType:1 value:[[%c(WFLocationValue) alloc] initWithCurrentLocation]];
            // self.seleniumLocationPickerViewController = locationViewController;
            locationViewController.locationManager = [CLLocationManager sharedManager];
            //locationViewController.locationManager = [CLLocationManager sharedManager];
            locationViewController.locationManager.delegate = (id<CLLocationManagerDelegate>)self;
            [locationViewController.locationManager requestWhenInUseAuthorizationWithPrompt];
            [locationViewController.locationManager requestAlwaysAuthorization];
            [locationViewController.locationManager startUpdatingLocation];
            [locationViewController loadView];
            [locationViewController setAutomaticallyAdjustsScrollViewInsets:NO];
            self.onArrive = YES;
            self.isNotifForLocationGrouped = grouped;
            if (grouped)
            self.requestsForLocation = reqsArray;
            else
            self.requestForLocation = requestToProcess;
            locationViewController.delegate = self;
            [locationViewController setAllowsPickingCurrentLocation:YES];
            [locationViewController setResolvesCurrentLocationToPlacemark:YES];
            locationViewController.currentLocation = [[CLLocationManager sharedManager] location];
            locationViewController.modalInPopover = YES;
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:locationViewController];

            // preseinting the picker
            if ([CLLocationManager authorizationStatus] != 3) {
                //[(id<CLLocationManagerDelegate>)self locationManager:locationViewController.locationManager didChangeAuthorizationStatus:4];
                [[objc_getClass("SBLockScreenManager") sharedInstance] lockScreenViewControllerRequestsUnlock];
            }
            else
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:nc animated:YES completion:^{
                // That picker was not made to be working on SpringBoard, so it is expected for some things to be broken.
                // One of these things is "Current Location", which returns "Unavailable" no matter how it is configured.
                // The workaround is to search for "Current Location" manually when location picker shows up - however, we can 
                // load an instance of MKLocalSearch which is used throughout the system to search locations, 
                // and save the result to "Current Location" property of the picker view controller.
                //
                // We can only do it after the picker view controller presentation is complete, so we can get the string "Current Location" in the system's language.
                //
                NSString *currentLocationString = locationViewController.tableView.visibleCells[0].textLabel.text;
                MKLocalSearchRequest *searchRequest = [[MKLocalSearchRequest alloc] init];
                searchRequest.naturalLanguageQuery = currentLocationString;
                searchRequest.region = locationViewController.mapView.region;
                MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:searchRequest];
                [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
                    if (response) {
                        MKMapItem *item = response.mapItems[0];
                        CLLocationCoordinate2D coordinate = item.placemark.coordinate;
                        locationViewController.currentLocation = item.placemark.location;
                        NSLog(@"[Selenium] response: %@",response);
                    } else {
                        NSLog(@"[Selenium] error: %@",error);
                    }
                }];
            }];
            /*NSString *path = [%c(LSApplicationProxy) applicationProxyForIdentifier:@"com.apple.reminders"].bundleURL.resourceSpecifier;
            //path = [path stringByAppendingPathComponent:@"Base.lproj/"];
            NSLog(@"[Selenium] path: %@",path);
            NSBundle *bundle = [NSBundle bundleWithPath:path];
            [bundle load];
            NSLog(@"[Selenium] [NSBundle bundle]: %@",[bundle bundleIdentifier]);
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"TTRIReminderLocationPickerViewController" bundle:bundle];
            NSLog(@"[Selenium] storyboard: %@, [storyboard name]: %@",storyboard,[storyboard name]);
            TTRIReminderLocationPickerViewController *detailViewController = [storyboard instantiateViewControllerWithIdentifier:@"TTRIReminderLocationPickerViewController"];
            NSLog(@"[Selenium] detailViewController: %@",detailViewController);
            NSLog(@"[Selenium] detailViewController class: %@",[detailViewController class]);
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:detailViewController animated:YES completion:nil];*/

            /*NSBundle *bundle = [NSBundle bundleWithURL:[%c(LSApplicationProxy) applicationProxyForIdentifier:@"com.apple.reminders"].bundleURL];
            [bundle load];
            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"TTRIReminderLocationPickerViewController" bundle:bundle];
            TTRIReminderLocationPickerViewController *reminderLocationViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"TTRIReminderLocationPickerViewController"];
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:reminderLocationViewController animated:YES completion:nil];*/

            /*NSString *path = [%c(LSApplicationProxy) applicationProxyForIdentifier:@"com.apple.reminders"].bundleURL.resourceSpecifier;
            NSLog(@"[Selenium] path: %@",path);
            NSBundle *bundle = [NSBundle bundleWithURL:[%c(LSApplicationProxy) applicationProxyForIdentifier:@"com.apple.reminders"].bundleURL];
            [bundle load];
            UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"TTRIReminderLocationPickerViewController" bundle:bundle];
            NSLog(@"[Selenium] containsNibNamed: %@",[mainStoryboard containsNibNamed:@"TTRIReminderLocationPickerViewController"] ? @"YES" : @"NO");
            //TTRIReminderLocationPickerViewController *reminderLocationViewController;// = [[UINavigationController alloc] initWithNibName:@"TTRIReminderLocationPickerViewController" bundle:bundle];
            TTRIReminderLocationPickerViewController *reminderLocationViewController = [[%c(TTRIReminderLocationPickerViewController) alloc] initWithNibName:@"TTRIReminderLocationPickerViewController" bundle:bundle];
            //[reminderLocationViewController setAutomaticallyAdjustsScrollViewInsets:NO];
            [reminderLocationViewController awakeFromNib];
            NSLog(@"[Selenium] reminderLocationViewController: %@",reminderLocationViewController);
            NSLog(@"[Selenium] reminderLocationViewController class: %@",[reminderLocationViewController class]);
            //[[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:reminderLocationViewController animated:YES completion:nil];*/
        }]];
        if ([CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] != 2 && snoozeByLocationEnabled == YES) [alert addAction:[UIAlertAction actionWithTitle:LEAVELOCATION style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            WFLocationPickerViewController *locationViewController = [[%c(WFLocationPickerViewController) alloc] initWithPickerType:1 value:[[%c(WFLocationValue) alloc] initWithCurrentLocation]];
            locationViewController.locationManager = [CLLocationManager sharedManager];
            locationViewController.locationManager.delegate = (id<CLLocationManagerDelegate>)self;
            [locationViewController.locationManager requestWhenInUseAuthorizationWithPrompt];
            [locationViewController.locationManager requestAlwaysAuthorization];
            [locationViewController.locationManager startUpdatingLocation];
            [locationViewController loadView];
            [locationViewController setAutomaticallyAdjustsScrollViewInsets:NO];
            self.onArrive = NO;
            self.isNotifForLocationGrouped = grouped;
            if (grouped)
            self.requestsForLocation = reqsArray;
            else
            self.requestForLocation = requestToProcess;
            locationViewController.delegate = self;
            [locationViewController setAllowsPickingCurrentLocation:YES];
            [locationViewController setResolvesCurrentLocationToPlacemark:YES];
            locationViewController.currentLocation = [[CLLocationManager sharedManager] location];
            locationViewController.modalInPopover = YES;
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:locationViewController];

            // preseinting the picker
            if ([CLLocationManager authorizationStatus] != 3)
            [[objc_getClass("SBLockScreenManager") sharedInstance] lockScreenViewControllerRequestsUnlock];
            else
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:nc animated:YES completion:^{
                // That picker was not made to be working on SpringBoard, so it is expected for some things to be broken.
                // One of these things is "Current Location", which returns "Unavailable" no matter how it is configured.
                // The workaround is to search for "Current Location" manually when location picker shows up - however, we can 
                // load an instance of MKLocalSearch which is used throughout the system to search locations, 
                // and save the result to "Current Location" property of the picker view controller.
                //
                // We can only do it after the picker view controller presentation is complete, so we can get the string "Current Location" in the system's language.
                //
                NSString *currentLocationString = locationViewController.tableView.visibleCells[0].textLabel.text;
                MKLocalSearchRequest *searchRequest = [[MKLocalSearchRequest alloc] init];
                searchRequest.naturalLanguageQuery = currentLocationString;
                searchRequest.region = locationViewController.mapView.region;
                MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:searchRequest];
                [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
                    if (response) {
                        MKMapItem *item = response.mapItems[0];
                        CLLocationCoordinate2D coordinate = item.placemark.coordinate;
                        locationViewController.currentLocation = item.placemark.location;
                    }
                }];
            }];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:STEPPER style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            //NCNotificationManagementAlertController *alertController = [[%c(NCNotificationManagementAlertController) alloc] initWithRequest:requestToProcess withPresentingView:nil settingsDelegate:nil];
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            CGFloat margin = 4.0F;

            _UIInterfaceActionGroupHeaderScrollView *alertScrollView;
            for (id view in [(_UIAlertControllerInterfaceActionGroupView*)[[[alertController view] subviews][0] subviews][0] subviews]) {
                if ([view isKindOfClass:[%c(UIView) class]]) {
                    for (id view2 in [view subviews]) {
                        if ([view2 isKindOfClass:[%c(_UIInterfaceActionGroupHeaderScrollView) class]]) {
                            alertScrollView = view2;
                            NSLog(@"[Selenium] Scroll View Found!!!");
                        }
                    }

                }
            }
            [alertScrollView setClipsToBounds:YES];
            [alertScrollView setUserInteractionEnabled:YES];

            [[alertController view] setClipsToBounds:YES];
            UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,0,0)];
            [alertScrollView addSubview:containerView];
            [containerView setTranslatesAutoresizingMaskIntoConstraints:NO];
            [[alertController view] addConstraint:[NSLayoutConstraint constraintWithItem:[alertController view] attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0]];
            [[alertController view] addConstraint:[NSLayoutConstraint constraintWithItem:[alertController view] attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:containerView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
            [containerView setHidden:YES];
            
            [alertController setTitle:SNOOZEF];

            BOOL finished = NO;
            UIImageView *cellImage = nil;
            double widthInPoints = nil;
            double heightInPoints = nil;
            SButton *button2 = nil;
            //setup:
            //if (!cellImage) {
                cellImage = [[UIImageView alloc] init];
                cellImage.image = [self imageWithView:cellToCapture];
                widthInPoints = cellImage.image.size.width;
                heightInPoints = cellImage.image.size.height;
                [cellImage setFrame:CGRectMake(0, 0, widthInPoints, heightInPoints)];
                cellImage.contentMode = UIViewContentModeScaleAspectFit;
            //}

            /*if (!button2) */button2 = [SButton buttonWithType:UIButtonTypeSystem];

            if (grouped) {
            button2.frame = CGRectMake(10 + alertController.view.bounds.origin.x , alertController.view.bounds.origin.y+50, alertController.view.frame.size.width - margin * 4.0F - 20, heightInPoints);
                [cellImage setFrame:CGRectMake(button2.bounds.origin.x, button2.bounds.origin.y, button2.bounds.size.width-20, button2.bounds.size.height)];
            } else {
            button2.frame = CGRectMake(10 + alertController.view.bounds.origin.x , alertController.view.bounds.origin.y+50, alertController.view.frame.size.width - margin * 4.0F - 20, heightInPoints);
                [cellImage setFrame:CGRectMake(button2.bounds.origin.x, button2.bounds.origin.y, button2.bounds.size.width-20, button2.bounds.size.height)];
            }

            [button2 setBackgroundColor:[UIColor systemGrayColor]];
            [button2 setAlpha:0.1f];
            button2.layer.cornerRadius = 12.5;

            /*if (![button2 superview]) */[alertScrollView addSubview:button2];
            /*if (![cellImage superview]) */[alertScrollView addSubview:cellImage];
                [button2 setTranslatesAutoresizingMaskIntoConstraints:NO];
                [cellImage setTranslatesAutoresizingMaskIntoConstraints:NO];
                //[button2.topAnchor constraintEqualToAnchor:containerView.topAnchor constant:50].active = YES;
                [button2.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:10].active = YES;
                [button2.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-10].active = YES;
                //[button2.heightAnchor constraintEqualToAnchor:cellImage.heightAnchor constant:grouped ? 30 : 15].active = YES;
                [cellImage.leadingAnchor constraintEqualToAnchor:button2.leadingAnchor constant:10].active = YES;
                [cellImage.topAnchor constraintEqualToAnchor:button2.topAnchor constant:10].active = YES;
                //[cellImage.heightAnchor constraintEqualToAnchor:cellImage.heightAnchor constant:-10].active = YES;
                //[button2.heightAnchor constraintEqualToAnchor:nil constant:heightInPoints+10].active = YES;
                //[button2.widthAnchor constraintEqualToAnchor:nil constant:widthInPoints+10].active = YES;
                //[cellImage.topAnchor constraintEqualToAnchor:button2.topAnchor constant:10].active = YES;
                [cellImage.centerYAnchor constraintEqualToAnchor:button2.centerYAnchor constant:0].active = YES;
                [cellImage.centerXAnchor constraintEqualToAnchor:button2.centerXAnchor constant:0].active = YES;
            cellImage.center = button2.center;

            #pragma mark stepper "cell"
            UIView *stepperFrame = [[UIView alloc] initWithFrame:CGRectMake(10 + containerView.bounds.origin.x , containerView.bounds.origin.y+60+(heightInPoints+10), [alertController view].bounds.size.width - margin * 4.0F - 20, 50)];
            [stepperFrame setBackgroundColor:[UIColor systemGrayColor]];
            [stepperFrame setAlpha:0.1];
            stepperFrame.layer.cornerRadius = 12.5;
            UIHoursStepper *stepper = [[UIHoursStepper alloc] init];
            stepper.minimumValue = 1; //15m, 30m, 45m, 1h, 2h, 3h, 4h, 6h, 8h, 12h
            stepper.maximumValue = 10;
            [stepper addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
            [alertScrollView addSubview:stepperFrame];
            [stepperFrame setTranslatesAutoresizingMaskIntoConstraints:YES];
            [stepperFrame.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:10].active = YES;
            [stepperFrame.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-10].active = YES;
            [stepperFrame.topAnchor constraintEqualToAnchor:button2.bottomAnchor constant:10].active = YES;
            [stepperFrame.heightAnchor constraintEqualToAnchor:nil constant:50].active = YES;
            //[alertScrollView addSubview:stepper];
            CGFloat stepperMargin = CGRectGetHeight(stepperFrame.frame)-CGRectGetHeight(stepper.frame);
            UIStackView *stackView = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, stepperFrame.frame.size.width - stepperMargin, stepperFrame.frame.size.height)];
            stackView.axis = UILayoutConstraintAxisHorizontal;
            stackView.center = stepperFrame.center;
            stackView.distribution = UIStackViewDistributionEqualSpacing;
            stackView.alignment = UIStackViewAlignmentCenter;
            CGFloat stepperX = CGRectGetWidth(stepperFrame.frame)-CGRectGetWidth(stepper.frame)-stepperMargin;
            CGFloat stepperY = stepperFrame.frame.origin.y+(CGRectGetHeight(stepperFrame.frame)-CGRectGetHeight(stepper.frame)-stepperMargin);
            //stepper.frame = CGRectMake(stepperX+stepperMargin, stepperY, 0, 0);
            CGFloat stepperLabelY = (CGRectGetHeight(stepperFrame.frame)/2)-(CGRectGetHeight(stepper.frame)/2);
            UILabel *stepperLabel = [[UILabel alloc] initWithFrame:CGRectMake(stepperFrame.frame.origin.x+stepperMargin, stepperFrame.frame.origin.y-stepperLabelY*2, stepperFrame.frame.size.width-stepperMargin, stepperFrame.frame.size.height-(stepperLabelY-stepperFrame.frame.size.height))];
            UILabel *stepperUntilLabel = [[UILabel alloc] initWithFrame:CGRectMake(stepperLabel.frame.origin.x+stepperLabel.frame.size.height, stepperFrame.frame.origin.y-stepperLabelY*2, stepperFrame.frame.size.width-stepperMargin, stepperFrame.frame.size.height-(stepperLabelY-stepperFrame.frame.size.height))];
            //[alertScrollView addSubview:stepperLabel];
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"lastStepperLabelText"]) {
                stepperLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastStepperLabelText"];
                stepper.value = [(NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"lastStepperValue"] doubleValue];
            } else {
                stepperLabel.text = fMINUTES;
                stepper.value = 1;
            }
            //[stepperLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.formatterBehavior = NSDateFormatterBehavior10_4;
            formatter.dateStyle = NSDateFormatterShortStyle;
            formatter.timeStyle = NSDateFormatterShortStyle;
            [formatter setDateFormat:@"HH:mm"];
            NSString *result = [formatter stringForObjectValue:[self getStepperValue:[NSNumber numberWithFloat:stepper.value]]];
            NSMutableArray *parts = [SNOOZEU componentsSeparatedByString:@" "];
            [parts removeObject:parts[0]];
            NSString *UNTIL = [parts componentsJoinedByString:@" "];
            UIFont *systemFont = [UIFont systemFontOfSize:13.0f];
            NSDictionary *attribsSnoozedForUntilLabel = @{
                            NSForegroundColorAttributeName:[UIColor systemBlueColor],
                            NSFontAttributeName:systemFont
                            };
            NSMutableAttributedString *attributedSnoozedForUntilLabel = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@",UNTIL,result] attributes:attribsSnoozedForUntilLabel];
            stepperUntilLabel.attributedText = attributedSnoozedForUntilLabel;

            UIStackView *labelStackView = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, stepperFrame.frame.size.width - stepperMargin, stepperFrame.frame.size.height)];
            labelStackView.axis = UILayoutConstraintAxisVertical;
            labelStackView.center = stepperFrame.center;
            labelStackView.distribution = UIStackViewDistributionEqualSpacing;
            labelStackView.alignment = UIStackViewAlignmentLeading;
            [labelStackView addArrangedSubview:stepperLabel];
            [labelStackView addArrangedSubview:stepperUntilLabel];
            stepper.stepperLabel = labelStackView;

            [stackView addArrangedSubview:labelStackView];
            [stackView addArrangedSubview:stepper];
            [alertScrollView addSubview:stackView];

            SButton *button = [SButton buttonWithType:UIButtonTypeSystem];
            button.frame = CGRectMake(10 + containerView.bounds.origin.x, containerView.bounds.origin.y + (/*picker*/90 - 2) + 50, [alertController view].bounds.size.width - margin * 4.0F - 20, 50);
            [button setBackgroundColor:[UIColor systemBlueColor]];
            [button setTitle:SNOOZE forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:19];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            button.request = requestToProcess;
            button.controllerToDismiss = alertController;
            button.cell = cellToCapture;
            button.grouped = grouped;
            button.stepperDate = [self performSelector:@selector(getStepperValue:) withObject:[NSNumber numberWithFloat:stepper.value]];
            button.stepper = stepper;
            [button addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
            [button addTarget:self action:@selector(buttonUpCancel:) forControlEvents:UIControlEventTouchDragExit];
            [button addTarget:self action:@selector(stepperButtonUp:) forControlEvents:UIControlEventTouchUpInside];
            button.layer.cornerRadius = 10.5;
            [alertScrollView addSubview:button];

            button.frame = CGRectMake(10 + containerView.bounds.origin.x, containerView.bounds.origin.y + /*picker*/70 + stepperFrame.frame.size.height + button2.frame.size.height, [alertController view].bounds.size.width - margin * 4.0F - 20, 50);
            [button setTranslatesAutoresizingMaskIntoConstraints:NO];
            [button.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor constant:10].active = YES;
            [button.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-10].active = YES;
            [button.topAnchor constraintEqualToAnchor:stepperFrame.bottomAnchor constant:10].active = YES;
            [button.heightAnchor constraintEqualToAnchor:nil constant:50].active = YES;

            //UIPopoverPresentationController *popoverController = alertController.popoverPresentationController;
            //popoverController.sourceView = [alertController view];
            //popoverController.sourceRect = [[alertController view] bounds];

            [alertScrollView setContentSize:CGSizeMake(alertScrollView.superview.bounds.size.width, (button.frame.origin.y-button2.frame.origin.y)+button.frame.size.height+40)];
            if ([alertController view].bounds.size.height > [alertController view].bounds.size.width)
            [[alertController view] addConstraint:[NSLayoutConstraint constraintWithItem:[alertController view] attribute:NSLayoutAttributeBottomMargin relatedBy:NSLayoutRelationEqual toItem:button attribute:NSLayoutAttributeBottom multiplier:1.0 constant:75]];
            else
            [[alertController view] addConstraint:[NSLayoutConstraint constraintWithItem:alertScrollView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:[alertController view] attribute:NSLayoutAttributeHeight multiplier:1.0 constant:-25/*([[UIScreen mainScreen] bounds].size.height)-25*/]];

            //if (!finished) {
                finished = YES;
            //    goto setup;
            //} else {
                [alertController addAction:[UIAlertAction actionWithTitle:CANCEL style:UIAlertActionStyleCancel handler:nil]];
                [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
            //}
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:sTIME style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            //NCNotificationManagementAlertController *alertController = [[%c(NCNotificationManagementAlertController) alloc] initWithRequest:requestToProcess withPresentingView:nil settingsDelegate:nil];
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            [alertController setTitle:SNOOZEF];
            NSLocale *locale = [NSLocale currentLocale];
            UIDatePicker *picker = [[UIDatePicker alloc] init];
            picker.locale = locale; 
            [picker setDatePickerMode:UIDatePickerModeDateAndTime];
            [picker setMinuteInterval:segmentInterval];
            #pragma mark setMinimumDate fix
            NSDateFormatter *testFormatter = [[NSDateFormatter alloc] init];
            testFormatter.formatterBehavior = NSDateFormatterBehavior10_4;
            testFormatter.dateStyle = NSDateFormatterShortStyle;
            testFormatter.timeStyle = NSDateFormatterShortStyle;
            [testFormatter setDateFormat:@"HH"];
            NSString *stringResult = [testFormatter stringForObjectValue:[NSDate date]];
            NSString *stringResultStart = [NSString stringWithFormat:@"%@:00:00",stringResult];
            [testFormatter setDateFormat:@"Z"];
            NSString *stringResultZone = [testFormatter stringForObjectValue:[NSDate date]];
            [testFormatter setDateFormat:@"yyyy-MM-dd'T'"];
            NSString *stringResultRest = [testFormatter stringForObjectValue:[NSDate date]];
            [testFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
            NSString *stringResultLoopStart = [NSString stringWithFormat:@"%@%@%@",stringResultRest,stringResultStart,stringResultZone];
            NSDate *minimumDate = [testFormatter dateFromString:stringResultLoopStart];
            for (char i=0; i<((60/segmentInterval)+1); i++) {
                if ([[NSDate date] timeIntervalSinceDate:minimumDate] < 0) {
                    break;
                } else {
                    minimumDate = [NSDate dateWithTimeInterval:(segmentInterval*60) sinceDate:minimumDate];
                }
            }
            [picker setMinimumDate:minimumDate/*[NSDate dateWithTimeInterval:300 sinceDate:[NSDate date]]*/];
            [picker setMaximumDate:[NSDate dateWithTimeInterval:604800 sinceDate:requestToProcess.timestamp]];
            [[alertController view] addSubview:picker];

            SButton *button = [SButton buttonWithType:UIButtonTypeSystem];
            CGFloat margin = 4.0F;
            button.frame = CGRectMake(10 + [alertController view].bounds.origin.x, [alertController view].bounds.origin.y + ((picker.frame.size.height+40) - 2) + 50, [alertController view].frame.size.width - margin * 4.0F - 20, 50);
            [button setBackgroundColor:[UIColor systemBlueColor]];
            [button setTitle:SNOOZE forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:19];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            button.request = requestToProcess;
            button.controllerToDismiss = alertController;
            button.pickerDate = [self performSelector:@selector(getDatePickerValue:) withObject:picker];
            button.datePicker = picker;
            button.cell = cellToCapture;
            button.grouped = grouped;
            [button addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
            [button addTarget:self action:@selector(buttonUpCancel:) forControlEvents:UIControlEventTouchDragExit];
            [button addTarget:self action:@selector(buttonUp:) forControlEvents:UIControlEventTouchUpInside];
            button.layer.cornerRadius = 10.5;
            [[alertController view] addSubview:button];

            UIImageView *cellImage = [[UIImageView alloc] init];
            cellImage.image = [self imageWithView:cellToCapture];
            double widthInPoints = cellImage.image.size.width;
            double heightInPoints = cellImage.image.size.height;
            [cellImage setFrame:CGRectMake(0, 0, widthInPoints, heightInPoints)];
            cellImage.contentMode = UIViewContentModeScaleAspectFit;
            
            SButton *button2 = [SButton buttonWithType:UIButtonTypeSystem];
            button2.frame = CGRectMake(10 + [alertController view].bounds.origin.x , [alertController view].bounds.origin.y+50, [alertController view].frame.size.width - margin * 4.0F - 20, heightInPoints+10);

            if (grouped) {
                [cellImage setFrame:CGRectMake(button2.bounds.origin.x, button2.bounds.origin.y, button2.bounds.size.width-15, button2.bounds.size.height)];
            } else {
                [cellImage setFrame:CGRectMake(button2.bounds.origin.x, button2.bounds.origin.y, button2.bounds.size.width-30, button2.bounds.size.height)];
            }

            [button2 setBackgroundColor:[UIColor systemGrayColor]];
            [button2 setAlpha:0.1f];
            button2.layer.cornerRadius = 12.5;

            [[alertController view] addSubview:button2];
            [[alertController view] addSubview:cellImage];
            cellImage.center = button2.center;

            picker.center = CGPointMake(button.center.x, picker.center.y+50+heightInPoints);
            button.frame = CGRectMake(10 + [alertController view].bounds.origin.x, [alertController view].bounds.origin.y + (picker.frame.size.height+30) + button2.frame.size.height, [alertController view].frame.size.width - margin * 4.0F - 20, 50);

            UIPopoverPresentationController *popoverController = alertController.popoverPresentationController;
            popoverController.sourceView = [alertController view];
            popoverController.sourceRect = [[alertController view] bounds];

            //[[alertController view] addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:[alertController view] attribute:NSLayoutAttributeBottomMargin multiplier:1.0 constant:-76.0f]];
            [[alertController view] addConstraint:[NSLayoutConstraint constraintWithItem:[alertController view] attribute:NSLayoutAttributeBottomMargin relatedBy:NSLayoutRelationEqual toItem:button attribute:NSLayoutAttributeBottom multiplier:1.0 constant:75]];

            // That's how you should do it in iOS 12 - We are able to do that because of how we set ARCHS in Makefile.
            [alertController addAction:[UIAlertAction actionWithTitle:CANCEL style:UIAlertActionStyleCancel handler:nil]];
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];

            // That's how you should do it in iOS 13.
            /*for (UIWindow *window in [UIApplication sharedApplication].windows) {
                if (window.isKeyWindow) {
                    [alertController addAction:[UIAlertAction actionWithTitle:CANCEL style:UIAlertActionStyleCancel handler:nil]];
                    [window.rootViewController presentViewController:alertController animated:YES completion:nil];
                    break;
                }
            }*/

            #pragma mark pill view
            UIFont *boldFont = [UIFont boldSystemFontOfSize:13.0f];
            SBRingerPillView *view = [[%c(SBRingerPillView) alloc] init];
            view.frame = CGRectMake(0,-56,196,50);
            UIButton *pillViewButton = [UIButton buttonWithType:UIButtonTypeSystem];
            pillViewButton.frame = CGRectMake(0, 0, 196, 50);
            [pillViewButton addTarget:self action:@selector(tappedToChange:) forControlEvents:UIControlEventTouchUpInside];

            UILabel *pillSnoozedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,9,100,15.6667)];
            NSDictionary *attribsSnoozedLabel = @{
                            NSForegroundColorAttributeName:[UIColor secondaryLabelColor],
                            NSFontAttributeName:boldFont
                            };
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:SNOOZED attributes:attribsSnoozedLabel];
            pillSnoozedLabel.attributedText = attributedText;
            pillSnoozedLabel.textAlignment = NSTextAlignmentCenter;
            pillSnoozedLabel.textColor = [UIColor secondaryLabelColor];
            CGSize expectedSnoozedLabelSize = [SNOOZED sizeWithAttributes:@{NSFontAttributeName:boldFont}];
            pillSnoozedLabel.frame = CGRectMake(pillSnoozedLabel.frame.origin.x,pillSnoozedLabel.frame.origin.y,expectedSnoozedLabelSize.width,expectedSnoozedLabelSize.height);
            
            UILabel *pillSnoozedForUntilLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,9,100,15.6667)];
            NSDictionary *attribsSnoozedForUntilLabel = @{
                            NSForegroundColorAttributeName:[UIColor systemBlueColor],
                            NSFontAttributeName:boldFont
                            };
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.formatterBehavior = NSDateFormatterBehavior10_4;
            formatter.dateStyle = NSDateFormatterShortStyle;
            formatter.timeStyle = NSDateFormatterShortStyle;
            [formatter setDateFormat:@"HH:mm"];
            NSString *result = [formatter stringForObjectValue:button.pickerDate];
            NSMutableArray *parts = [SNOOZEU componentsSeparatedByString:@" "];
            [parts removeObject:parts[0]];
            NSString *UNTIL = [parts componentsJoinedByString:@" "];
            NSMutableAttributedString *attributedSnoozedForUntilLabel = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@",UNTIL,result] attributes:attribsSnoozedLabel];
            pillSnoozedForUntilLabel.attributedText = attributedSnoozedForUntilLabel;
            pillSnoozedForUntilLabel.textAlignment = NSTextAlignmentCenter;
            pillSnoozedForUntilLabel.textColor = [UIColor systemBlueColor];
            CGSize expectedSnoozedForUntilLabelSize = [[NSString stringWithFormat:@"%@%@",UNTIL,result] sizeWithAttributes:@{NSFontAttributeName:boldFont}];
            pillSnoozedForUntilLabel.frame = CGRectMake(pillSnoozedForUntilLabel.frame.origin.x,pillSnoozedForUntilLabel.frame.origin.y,expectedSnoozedForUntilLabelSize.width,expectedSnoozedForUntilLabelSize.height);
            button.pillViewUntilLabel = pillSnoozedForUntilLabel;

            UILabel *pillTapToChangeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,25.6667,100,15.6667)];
            NSDictionary *attribsTapToChangeLabel = @{
                            NSForegroundColorAttributeName:[UIColor tertiaryLabelColor],
                            NSFontAttributeName:boldFont
                            };
            NSMutableAttributedString *attributedTapToChangeText = [[NSMutableAttributedString alloc] initWithString:TAPCHANGE attributes:attribsSnoozedLabel];
            pillTapToChangeLabel.attributedText = attributedTapToChangeText;
            pillTapToChangeLabel.textAlignment = NSTextAlignmentCenter;
            pillTapToChangeLabel.textColor = [UIColor tertiaryLabelColor];
            [view addSubview:pillSnoozedLabel];
            [view addSubview:pillSnoozedForUntilLabel];
            [view addSubview:pillTapToChangeLabel];
            [view addSubview:pillViewButton];

            CGFloat combinedSize;
            view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
            combinedSize = expectedSnoozedLabelSize.width+4+expectedSnoozedForUntilLabelSize.width;
            CGFloat combinedOneX = view.frame.size.width/2 - combinedSize/2;
            if ([UIApplication sharedApplication].userInterfaceLayoutDirection == 0) {
                CGFloat combinedTwoX = combinedOneX + pillSnoozedLabel.frame.size.width+4;
                pillSnoozedLabel.frame = CGRectMake(combinedOneX, 9, pillSnoozedLabel.frame.size.width, pillSnoozedLabel.frame.size.height);
                pillSnoozedForUntilLabel.frame = CGRectMake(combinedTwoX, 9, pillSnoozedForUntilLabel.frame.size.width, pillSnoozedForUntilLabel.frame.size.height);
            } else {
                CGFloat combinedTwoX = combinedOneX + pillSnoozedForUntilLabel.frame.size.width+4;
                pillSnoozedLabel.frame = CGRectMake(combinedTwoX, 9, pillSnoozedLabel.frame.size.width, pillSnoozedLabel.frame.size.height);
                pillSnoozedForUntilLabel.frame = CGRectMake(combinedOneX, 9, pillSnoozedForUntilLabel.frame.size.width, pillSnoozedForUntilLabel.frame.size.height);
            }
            pillTapToChangeLabel.center = CGPointMake(view.frame.size.width/2, pillTapToChangeLabel.center.y);

            button.pillView = view;
        }]];

        [alert addAction:[UIAlertAction actionWithTitle:CANCEL style:UIAlertActionStyleCancel handler:nil]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    // } // new menu end
}

%new
- (UIImage *) imageWithView:(UIView *)viewB {
    NCNotificationListView *superView = (NCNotificationListView *)viewB.superview;
    UIView *view;

    if (superView.grouped && [superView.visibleViews count] > 1) {
        view = superView;
    } else {
        view = [(NCNotificationListCell*)viewB contentViewController].notificationViewControllerView;
        //view = viewB;
    }

    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:view.bounds.size];
	static UIImage *imageRender;/* = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    }];*/

    if (view.alpha == 0) {
	    renderer = nil;
        return imageRender;
    } else {
        imageRender = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
            [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
        }];
	    renderer = nil;
        return imageRender;
    }
}

%new
-(NSDate *)getDatePickerValue:(UIDatePicker *)sender {
    return [sender date];
}

%new
-(void)valueChanged:(id)sender {
    UIHoursStepper *stepper = (UIHoursStepper *)sender;

    switch ((int)stepper.value) {
        case 1:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = fMINUTES;
            break;
        case 2:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = tMINUTES;
            break;
        case 3:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = ffMINUTES;
            break;
        case 4:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = oneHOUR;
            break;
        case 5:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = twoHOURS;
            break;
        case 6:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = threeHOURS;
            break;
        case 7:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = fourHOURS;
            break;
        case 8:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = sixHOURS;
            break;
        case 9:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = eightHOURS;
            break;
        case 10:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = twelveHOURS;
            break;
    }
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithFloat:stepper.value] forKey:@"lastStepperValue"];
    [[NSUserDefaults standardUserDefaults] setObject:[(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text forKey:@"lastStepperLabelText"];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.formatterBehavior = NSDateFormatterBehavior10_4;
    formatter.dateStyle = NSDateFormatterShortStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    [formatter setDateFormat:@"HH:mm"];
    NSString *result = [formatter stringForObjectValue:[self getStepperValue:[NSNumber numberWithFloat:stepper.value]]];
    NSMutableArray *parts = [SNOOZEU componentsSeparatedByString:@" "];
    [parts removeObject:parts[0]];
    NSString *UNTIL = [parts componentsJoinedByString:@" "];
    [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews lastObject].text = [NSString stringWithFormat:@"%@%@",UNTIL,result];
}

%new
-(NSDate *)getStepperValue:(NSNumber *)number {
    int doubleNumber = [number intValue];

    switch (doubleNumber) {
        case 1:
            return [NSDate dateWithTimeIntervalSinceNow:900];
        case 2:
            return [NSDate dateWithTimeIntervalSinceNow:1800];
        case 3:
            return [NSDate dateWithTimeIntervalSinceNow:2700];
        case 4:
            return [NSDate dateWithTimeIntervalSinceNow:3600];
        case 5:
            return [NSDate dateWithTimeIntervalSinceNow:7200];
        case 6:
            return [NSDate dateWithTimeIntervalSinceNow:10800];
        case 7:
            return [NSDate dateWithTimeIntervalSinceNow:14400];
        case 8:
            return [NSDate dateWithTimeIntervalSinceNow:21600];
        case 9:
            return [NSDate dateWithTimeIntervalSinceNow:28800];
        case 10:
            return [NSDate dateWithTimeIntervalSinceNow:43200];
    }
}

%new
-(void)tappedToChange:(UIButton *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SLMDisableLock" object:self];

    NSDictionary* userInfo = [lastTimer userInfo];
    if ([userInfo[@"grouped"] intValue] == 1) {
        for (NCNotificationRequest *request in userInfo[@"requests"]) {
            processEntry(request, 0, nil, nil, nil);
        }
        [[AXNManager sharedInstance] showNotificationRequests:userInfo[@"requests"]];
    } else {
        NCNotificationRequest *request = (NCNotificationRequest *)userInfo[@"request"];
        processEntry(request, 0, nil, nil, nil);
        [[AXNManager sharedInstance] showNotificationRequest:request];
    }
    [lastTimer invalidate];
    lastTimer = nil;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.miwix.selenium.menu" object:nil userInfo:notifInfo];
    });
}

%new
-(void)buttonDonate:(UIButton *)sender {
    SButton *senderFix = sender;
    [senderFix.controllerToDismiss dismissViewControllerAnimated:YES completion:nil];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/donate/?hosted_button_id=DSAQ8SXMGFUNU"]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.miwix.selenium.resume.home" object:nil userInfo:nil];
}

%new
-(void)buttonDismiss:(UIButton *)sender {
    SButton *senderFix = sender;
    [senderFix.controllerToDismiss dismissViewControllerAnimated:YES completion:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.miwix.selenium.resume.home" object:nil userInfo:nil];
}

%new
-(void)buttonDown:(UIButton *)sender {
    [UIView animateWithDuration:0.2 delay:0 options:nil animations:^{
        sender.alpha = 0.5f;
    } completion:nil];
}

%new
-(void)buttonUpCancel:(UIButton *)sender {
    [UIView animateWithDuration:0.2 delay:0 options:nil animations:^{
        sender.alpha = 1.0f;
    } completion:nil];
}

%new
-(void)stepperButtonUp:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SLMEnableLock" object:self];

    SButton *senderFix = sender;
    NSDate *value = [self performSelector:@selector(getStepperValue:) withObject:[NSNumber numberWithFloat:senderFix.stepper.value]];

        #pragma mark pill view
        UIFont *boldFont = [UIFont boldSystemFontOfSize:13.0f];
        SBRingerPillView *view = [[%c(SBRingerPillView) alloc] init];
        view.frame = CGRectMake(0,-56,196,50);
        UIButton *pillViewButton = [UIButton buttonWithType:UIButtonTypeSystem];
        pillViewButton.frame = CGRectMake(0, 0, 196, 50);
        [pillViewButton addTarget:self action:@selector(tappedToChange:) forControlEvents:UIControlEventTouchUpInside];

        UILabel *pillSnoozedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,9,100,15.6667)];
        NSDictionary *attribsSnoozedLabel = @{
                          NSForegroundColorAttributeName:[UIColor secondaryLabelColor],
                          NSFontAttributeName:boldFont
                          };
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:SNOOZED attributes:attribsSnoozedLabel];
        pillSnoozedLabel.attributedText = attributedText;
        pillSnoozedLabel.textAlignment = NSTextAlignmentCenter;
        pillSnoozedLabel.textColor = [UIColor secondaryLabelColor];
        CGSize expectedSnoozedLabelSize = [SNOOZED sizeWithAttributes:@{NSFontAttributeName:boldFont}];
        pillSnoozedLabel.frame = CGRectMake(pillSnoozedLabel.frame.origin.x,pillSnoozedLabel.frame.origin.y,expectedSnoozedLabelSize.width,expectedSnoozedLabelSize.height);
        
        UILabel *pillSnoozedForUntilLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,9,100,15.6667)];
        NSDictionary *attribsSnoozedForUntilLabel = @{
                          NSForegroundColorAttributeName:[UIColor systemBlueColor],
                          NSFontAttributeName:boldFont
                          };
        NSMutableAttributedString *attributedSnoozedForUntilLabel = [[NSMutableAttributedString alloc] initWithString:[(NSArray<UILabel*>*)senderFix.stepper.stepperLabel.arrangedSubviews firstObject].text attributes:attribsSnoozedLabel];
        pillSnoozedForUntilLabel.attributedText = attributedSnoozedForUntilLabel;
        pillSnoozedForUntilLabel.textAlignment = NSTextAlignmentCenter;
        pillSnoozedForUntilLabel.textColor = [UIColor systemBlueColor];
        CGSize expectedSnoozedForUntilLabelSize = [[(NSArray<UILabel*>*)senderFix.stepper.stepperLabel.arrangedSubviews firstObject].text sizeWithAttributes:@{NSFontAttributeName:boldFont}];
        pillSnoozedForUntilLabel.frame = CGRectMake(pillSnoozedForUntilLabel.frame.origin.x,pillSnoozedForUntilLabel.frame.origin.y,expectedSnoozedForUntilLabelSize.width,expectedSnoozedForUntilLabelSize.height);

        UILabel *pillTapToChangeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,25.6667,100,15.6667)];
        NSDictionary *attribsTapToChangeLabel = @{
                          NSForegroundColorAttributeName:[UIColor tertiaryLabelColor],
                          NSFontAttributeName:boldFont
                          };
        NSMutableAttributedString *attributedTapToChangeText = [[NSMutableAttributedString alloc] initWithString:TAPCHANGE attributes:attribsSnoozedLabel];
        pillTapToChangeLabel.attributedText = attributedTapToChangeText;
        pillTapToChangeLabel.textAlignment = NSTextAlignmentCenter;
        pillTapToChangeLabel.textColor = [UIColor tertiaryLabelColor];
        [view addSubview:pillSnoozedLabel];
        [view addSubview:pillSnoozedForUntilLabel];
        [view addSubview:pillTapToChangeLabel];
        [view addSubview:pillViewButton];
        CGFloat combinedSize;
        view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
        combinedSize = expectedSnoozedLabelSize.width+4+expectedSnoozedForUntilLabelSize.width;
        CGFloat combinedOneX = view.frame.size.width/2 - combinedSize/2;
        if ([UIApplication sharedApplication].userInterfaceLayoutDirection == 0) {
            CGFloat combinedTwoX = combinedOneX + pillSnoozedLabel.frame.size.width+4;
            pillSnoozedLabel.frame = CGRectMake(combinedOneX, 9, pillSnoozedLabel.frame.size.width, pillSnoozedLabel.frame.size.height);
            pillSnoozedForUntilLabel.frame = CGRectMake(combinedTwoX, 9, pillSnoozedForUntilLabel.frame.size.width, pillSnoozedForUntilLabel.frame.size.height);
        } else {
            CGFloat combinedTwoX = combinedOneX + pillSnoozedForUntilLabel.frame.size.width+4;
            pillSnoozedLabel.frame = CGRectMake(combinedTwoX, 9, pillSnoozedLabel.frame.size.width, pillSnoozedLabel.frame.size.height);
            pillSnoozedForUntilLabel.frame = CGRectMake(combinedOneX, 9, pillSnoozedForUntilLabel.frame.size.width, pillSnoozedForUntilLabel.frame.size.height);
        }
        pillTapToChangeLabel.center = CGPointMake(view.frame.size.width/2, pillTapToChangeLabel.center.y);
        UIWindow *window;
        for (int i=0; i<([[UIApplication sharedApplication].windows count]-1); i++) {
            if ([[UIApplication sharedApplication].windows[i] isMemberOfClass:[%c(SBCoverSheetWindow) class]]) {
                window = [UIApplication sharedApplication].windows[i];
                break;
            }
        }
        [window addSubview:view];
        [UIView animateWithDuration:0.33f animations:^{
            view.frame = CGRectMake(0,44,196,50);
            view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
            pillTapToChangeLabel.center = CGPointMake(view.frame.size.width/2, pillTapToChangeLabel.center.y);
        } completion:^(BOOL finished) {
            [NSTimer scheduledTimerWithTimeInterval:2.0f
                target:[NSBlockOperation blockOperationWithBlock:^{
                    [UIView animateWithDuration:0.33f animations:^{
                        view.frame = CGRectMake(0,-56,196,50);
                        view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
                        pillTapToChangeLabel.center = CGPointMake(view.frame.size.width/2, pillTapToChangeLabel.center.y);
                    } completion:^(BOOL finished) {
                        [view removeFromSuperview];
                    }];
                }]
                selector:@selector(main)
                userInfo:nil
                repeats:NO
            ];
        }];

    [UIView animateWithDuration:0.2 delay:0 options:nil animations:^{
        senderFix.alpha = 1.0f;
    } completion:nil];
    [senderFix.controllerToDismiss dismissViewControllerAnimated:YES completion:nil];

    NCNotificationListView *cellListView = (NCNotificationListView *)senderFix.cell.superview;
    NCNotificationGroupList *groupList = cellListView.dataSource;
    NSMutableArray *reqsArray = [groupList.orderedRequests copy];

    if (senderFix.grouped) {
        [[AXNManager sharedInstance] hideNotificationRequests:reqsArray];
        for (NCNotificationRequest *request in reqsArray) {
            if ([request.content.header containsString:LOCATION]) {
                NSString *string = [request.content.header componentsSeparatedByString:@" •"][0];
                [request.content setValue:string forKey:@"_header"];
            }
            if (![request.content.header containsString:SNOOZED]) {
                NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", request.content.header, SNOOZED];
                [request.content setValue:newTitle forKey:@"_header"];
            }
            processEntry(request, -1, value, nil, nil);
        }
        NSDictionary* userInfo = @{@"requests" : reqsArray, @"grouped" : [NSNumber numberWithBool:senderFix.grouped]};
        lastTimer = [[PCSimpleTimer alloc] initWithFireDate:value
                            serviceIdentifier:@"com.miwix.selenium.service"
                            target:self
                            selector:@selector(timerOperations:)
                            userInfo:userInfo];
        [lastTimer setDisableSystemWaking:YES];
        NSLog(@"[Selenium] isUserVisible: %@",[lastTimer isUserVisible] ? @"YES" : @"NO");
        [lastTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];
    } else {
        [[AXNManager sharedInstance] hideNotificationRequest:senderFix.request];
        if ([senderFix.request.content.header containsString:LOCATION]) {
            NSString *string = [senderFix.request.content.header componentsSeparatedByString:@" •"][0];
            [senderFix.request.content setValue:string forKey:@"_header"];
        }
        if (![senderFix.request.content.header containsString:SNOOZED]) {
            NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", senderFix.request.content.header, SNOOZED];
            [senderFix.request.content setValue:newTitle forKey:@"_header"];
        }
        #pragma mark PCPersistentTimer setup
        NSDictionary* userInfo = @{@"request" : senderFix.request, @"grouped" : [NSNumber numberWithBool:senderFix.grouped]};
        lastTimer = [[PCSimpleTimer alloc] initWithFireDate:value
                            serviceIdentifier:@"com.miwix.selenium.service"
                            target:self
                            selector:@selector(timerOperations:)
                            userInfo:userInfo];
        [lastTimer setDisableSystemWaking:YES];
        NSLog(@"[Selenium] isUserVisible: %@",[lastTimer isUserVisible] ? @"YES" : @"NO");
        [lastTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];

        processEntry(senderFix.request, -1, value, nil, nil);
    }
}

%new
-(void)buttonUp:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SLMEnableLock" object:self];

    SButton *senderFix = sender;
    senderFix.pickerDate = [self performSelector:@selector(getDatePickerValue:) withObject:senderFix.datePicker];

        #pragma mark pill view
        UIFont *boldFont = [UIFont boldSystemFontOfSize:13.0f];
        SBRingerPillView *view = [[%c(SBRingerPillView) alloc] init];
        view.frame = CGRectMake(0,-56,196,50);
        UIButton *pillViewButton = [UIButton buttonWithType:UIButtonTypeSystem];
        pillViewButton.frame = CGRectMake(0, 0, 196, 50);
        [pillViewButton addTarget:self action:@selector(tappedToChange:) forControlEvents:UIControlEventTouchUpInside];

        UILabel *pillSnoozedLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,9,100,15.6667)];
        NSDictionary *attribsSnoozedLabel = @{
                          NSForegroundColorAttributeName:[UIColor secondaryLabelColor],
                          NSFontAttributeName:boldFont
                          };
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:SNOOZED attributes:attribsSnoozedLabel];
        pillSnoozedLabel.attributedText = attributedText;
        pillSnoozedLabel.textAlignment = NSTextAlignmentCenter;
        pillSnoozedLabel.textColor = [UIColor secondaryLabelColor];
        CGSize expectedSnoozedLabelSize = [SNOOZED sizeWithAttributes:@{NSFontAttributeName:boldFont}];
        pillSnoozedLabel.frame = CGRectMake(pillSnoozedLabel.frame.origin.x,pillSnoozedLabel.frame.origin.y,expectedSnoozedLabelSize.width,expectedSnoozedLabelSize.height);
        
        UILabel *pillSnoozedForUntilLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,9,100,15.6667)];
        NSDictionary *attribsSnoozedForUntilLabel = @{
                          NSForegroundColorAttributeName:[UIColor systemBlueColor],
                          NSFontAttributeName:boldFont
                          };
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.formatterBehavior = NSDateFormatterBehavior10_4;
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
        [formatter setDateFormat:@"HH:mm"];
        NSString *result = [formatter stringForObjectValue:senderFix.pickerDate];
        NSMutableArray *parts = [SNOOZEU componentsSeparatedByString:@" "];
        [parts removeObject:parts[0]];
        NSString *UNTIL = [parts componentsJoinedByString:@" "];
        NSMutableAttributedString *attributedSnoozedForUntilLabel = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@",UNTIL,result] attributes:attribsSnoozedLabel];
        pillSnoozedForUntilLabel.attributedText = attributedSnoozedForUntilLabel;
        pillSnoozedForUntilLabel.textAlignment = NSTextAlignmentCenter;
        pillSnoozedForUntilLabel.textColor = [UIColor systemBlueColor];
        CGSize expectedSnoozedForUntilLabelSize = [[NSString stringWithFormat:@"%@%@",UNTIL,result] sizeWithAttributes:@{NSFontAttributeName:boldFont}];
        pillSnoozedForUntilLabel.frame = CGRectMake(pillSnoozedForUntilLabel.frame.origin.x,pillSnoozedForUntilLabel.frame.origin.y,expectedSnoozedForUntilLabelSize.width,expectedSnoozedForUntilLabelSize.height);

        UILabel *pillTapToChangeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,25.6667,100,15.6667)];
        NSDictionary *attribsTapToChangeLabel = @{
                          NSForegroundColorAttributeName:[UIColor tertiaryLabelColor],
                          NSFontAttributeName:boldFont
                          };
        NSMutableAttributedString *attributedTapToChangeText = [[NSMutableAttributedString alloc] initWithString:TAPCHANGE attributes:attribsSnoozedLabel];
        pillTapToChangeLabel.attributedText = attributedTapToChangeText;
        pillTapToChangeLabel.textAlignment = NSTextAlignmentCenter;
        pillTapToChangeLabel.textColor = [UIColor tertiaryLabelColor];
        [view addSubview:pillSnoozedLabel];
        [view addSubview:pillSnoozedForUntilLabel];
        [view addSubview:pillTapToChangeLabel];
        [view addSubview:pillViewButton];
        CGFloat combinedSize;
        view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
        combinedSize = expectedSnoozedLabelSize.width+4+expectedSnoozedForUntilLabelSize.width;
        CGFloat combinedOneX = view.frame.size.width/2 - combinedSize/2;
        if ([UIApplication sharedApplication].userInterfaceLayoutDirection == 0) {
            CGFloat combinedTwoX = combinedOneX + pillSnoozedLabel.frame.size.width+4;
            pillSnoozedLabel.frame = CGRectMake(combinedOneX, 9, pillSnoozedLabel.frame.size.width, pillSnoozedLabel.frame.size.height);
            pillSnoozedForUntilLabel.frame = CGRectMake(combinedTwoX, 9, pillSnoozedForUntilLabel.frame.size.width, pillSnoozedForUntilLabel.frame.size.height);
        } else {
            CGFloat combinedTwoX = combinedOneX + pillSnoozedForUntilLabel.frame.size.width+4;
            pillSnoozedLabel.frame = CGRectMake(combinedTwoX, 9, pillSnoozedLabel.frame.size.width, pillSnoozedLabel.frame.size.height);
            pillSnoozedForUntilLabel.frame = CGRectMake(combinedOneX, 9, pillSnoozedForUntilLabel.frame.size.width, pillSnoozedForUntilLabel.frame.size.height);
        }
        pillTapToChangeLabel.center = CGPointMake(view.frame.size.width/2, pillTapToChangeLabel.center.y);
        UIWindow *window;
        for (int i=0; i<([[UIApplication sharedApplication].windows count]-1); i++) {
            if ([[UIApplication sharedApplication].windows[i] isMemberOfClass:[%c(SBCoverSheetWindow) class]]) {
                window = [UIApplication sharedApplication].windows[i];
                break;
            }
        }
        [window addSubview:view];
        [UIView animateWithDuration:0.33f animations:^{
            view.frame = CGRectMake(0,44,196,50);
            view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
            pillTapToChangeLabel.center = CGPointMake(view.frame.size.width/2, pillTapToChangeLabel.center.y);
        } completion:^(BOOL finished) {
            [NSTimer scheduledTimerWithTimeInterval:2.0f
                target:[NSBlockOperation blockOperationWithBlock:^{
                    [UIView animateWithDuration:0.33f animations:^{
                        view.frame = CGRectMake(0,-56,196,50);
                        view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
                        pillTapToChangeLabel.center = CGPointMake(view.frame.size.width/2, pillTapToChangeLabel.center.y);
                    } completion:^(BOOL finished) {
                        [view removeFromSuperview];
                    }];
                }]
                selector:@selector(main)
                userInfo:nil
                repeats:NO
            ];
        }];

    [UIView animateWithDuration:0.2 delay:0 options:nil animations:^{
        senderFix.alpha = 1.0f;
    } completion:nil];
    [senderFix.controllerToDismiss dismissViewControllerAnimated:YES completion:nil];

    NCNotificationListView *cellListView = (NCNotificationListView *)senderFix.cell.superview;
    NCNotificationGroupList *groupList = cellListView.dataSource;
    NSMutableArray *reqsArray = [groupList.orderedRequests copy];

    if(senderFix.grouped) {
        [[AXNManager sharedInstance] hideNotificationRequests:reqsArray];
        for (NCNotificationRequest *request in reqsArray) {
            if ([request.content.header containsString:LOCATION]) {
                NSString *string = [request.content.header componentsSeparatedByString:@" •"][0];
                [request.content setValue:string forKey:@"_header"];
            }
            if (![request.content.header containsString:SNOOZED]) {
                NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", request.content.header, SNOOZED];
                [request.content setValue:newTitle forKey:@"_header"];
            }
            processEntry(request, -1, senderFix.pickerDate, nil, nil);
        }
        NSDictionary* userInfo = @{@"requests" : reqsArray, @"grouped" : [NSNumber numberWithBool:senderFix.grouped]};
        lastTimer = [[PCSimpleTimer alloc] initWithFireDate:senderFix.pickerDate
                            serviceIdentifier:@"com.miwix.selenium.service"
                            target:self
                            selector:@selector(timerOperations:)
                            userInfo:userInfo];
        [lastTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];
    } else {
        [[AXNManager sharedInstance] hideNotificationRequest:senderFix.request];
        if ([senderFix.request.content.header containsString:LOCATION]) {
            NSString *string = [senderFix.request.content.header componentsSeparatedByString:@" •"][0];
            [senderFix.request.content setValue:string forKey:@"_header"];
        }
        if (![senderFix.request.content.header containsString:SNOOZED]) {
            NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", senderFix.request.content.header, SNOOZED];
            [senderFix.request.content setValue:newTitle forKey:@"_header"];
        }
        #pragma mark PCPersistentTimer setup
        NSDictionary* userInfo = @{@"request" : senderFix.request, @"grouped" : [NSNumber numberWithBool:senderFix.grouped]};
        lastTimer = [[PCSimpleTimer alloc] initWithFireDate:senderFix.pickerDate
                            serviceIdentifier:@"com.miwix.selenium.service"
                            target:self
                            selector:@selector(timerOperations:)
                            userInfo:userInfo];
        [lastTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];

        processEntry(senderFix.request, -1, senderFix.pickerDate, nil, nil);
    }
}

#pragma mark PCPersistentTimer selector
%new
-(void)timerOperations:(id)timer {
    NSDictionary* userInfo = [(PCSimpleTimer *)timer userInfo];
    if ([userInfo[@"grouped"] intValue] == 1) {
        for (NCNotificationRequest *request in userInfo[@"requests"]) {
            processEntry(request, 0, nil, nil, nil);
            if (snooozedDeliverProminently)
            dispatch_sync(__BBServerQueue, ^{
                if (!([[request.content.header lowercaseString] containsString:SNOOZED] || ![[request.bulletin.header lowercaseString] containsString:SNOOZED]))
                request.bulletin.header = [NSString stringWithFormat:@"%@ • %@",request.content.header,SNOOZED];
                //if (shouldResetDate) request.bulletin.date = [NSDate date];
                [[%c(BBServer) SLM_sharedInstance] publishBulletin:request.bulletin destinations:14];
            });
        }
        if (!snooozedDeliverProminently)
        [[AXNManager sharedInstance] showNotificationRequests:userInfo[@"requests"]];
    } else {
        NCNotificationRequest *request = (NCNotificationRequest *)userInfo[@"request"];
        processEntry(request, 0, nil, nil, nil);
        if (snooozedDeliverProminently)
        dispatch_sync(__BBServerQueue, ^{
            if (!([[request.content.header lowercaseString] containsString:SNOOZED] || ![[request.bulletin.header lowercaseString] containsString:SNOOZED]))
            request.bulletin.header = [NSString stringWithFormat:@"%@ • %@",request.content.header,SNOOZED];
            //if (shouldResetDate) request.bulletin.date = [NSDate date];
            [[%c(BBServer) SLM_sharedInstance] publishBulletin:request.bulletin destinations:14];
        });
        else
        [[AXNManager sharedInstance] showNotificationRequest:request];
    }
    [timer invalidate];
}
%end

/*@interface DNDState : NSObject
@end

%hook DNDState
-(BOOL)isActive {
    BOOL isDNDActive = %orig;
    if (isDNDActive == NO) {
        NSMutableArray *entries = [config[@"entries"] mutableCopy];
        for (NSMutableDictionary *entry in entries) {
            NSString *timeStampString = [NSString stringWithFormat:@"%@", entry[@"timeStamp"]];
            if ([timeStampString isEqualToString:@"-2"]) {
                [[AXNManager sharedInstance] showNotificationRequest:(NCNotificationRequest *)entry[@"id"]];
                processEntry((NCNotificationRequest *)entry[@"id"], 0, nil, nil, nil);
            }
        }
    }
    return %orig;
}
%end*/ //DND START

%hook NCNotificationRequest
+(id)_notificationRequestForBulletin:(id)arg1 observer:(id)arg2 sectionInfo:(id)arg3 feed:(unsigned long long)arg4 playLightsAndSirens:(BOOL)arg5 hasPlayLightsAndSirens:(BOOL)arg6 {
    %orig;
    NSLog(@"[Selenium] notificationRequestForBulletin: %@ observer: %@ sectionInfo: %@ feed: %llu playLightsAndSirens hasPlayLightsAndSirens", [arg1 class], [arg2 class], [arg3 class], arg4);
    //NSLog(@"[Selenium] sectionInfo: %@", arg3);
    return %orig;
}
+(id)notificationRequestForBulletin:(id)arg1 observer:(id)arg2 sectionInfo:(id)arg3 feed:(unsigned long long)arg4 {
    %orig;
    NSLog(@"[Selenium] notificationRequestForBulletin: %@ observer: %@ sectionInfo: %@ feed: %llu", [arg1 class], [arg2 class], [arg3 class], arg4);
    //NSLog(@"[Selenium] sectionInfo: %@", arg3);
    return %orig;
}
+(id)notificationRequestForBulletin:(id)arg1 observer:(id)arg2 sectionInfo:(id)arg3 feed:(unsigned long long)arg4 playLightsAndSirens:(BOOL)arg5 {
    %orig;
    NSLog(@"[Selenium] notificationRequestForBulletin: %@ observer: %@ sectionInfo: %@ feed: %llu playLightsAndSirens", [arg1 class], [arg2 class], [arg3 class], arg4);
    //NSLog(@"[Selenium] sectionInfo: %@", arg3);
    return %orig;
}
%end
%hook CSNotificationDispatcher
- (void)postNotificationRequest:(NCNotificationRequest *)arg1 {
    /*if (isEnabledForDND && isDNDEnabled && [arg1.timestamp compare:config[@"DNDStartTime"]] == NSOrderedDescending && ![[arg1.content.header lowercaseString] isEqualToString:@"do not disturb"]) {
        NCNotificationRequest *argFix = arg1;
        NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", argFix.content.header, @"DND"];
        [argFix.content setValue:newTitle forKey:@"_header"];
        %orig(argFix);
        [[AXNManager sharedInstance] hideNotificationRequest:argFix];
        processEntry(argFix, -2, nil, nil, nil);
        return;
    }*/ //DND START
    NSString *req = [NSString stringWithFormat:@"%@", arg1];
    NSMutableArray *entries = [config[@"entries"] mutableCopy];
    for (NSMutableDictionary *entry in entries) {
        NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@";"] mutableCopy];
        [parts removeObject:parts[0]];
        NSString *combinedparts = [parts componentsJoinedByString:@";"];
        if ([req containsString:combinedparts]) {
            if ([entry[@"timeStamp"] doubleValue] == -2) {
                NCNotificationRequest *argFix = arg1;
                NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", arg1.content.header, LOCATION];
                [argFix.content setValue:newTitle forKey:@"_header"];
                %orig(argFix);
                [[AXNManager sharedInstance] hideNotificationRequest:argFix];
                //[[CLLocationManager sharedManager] setAllowsBackgroundLocationUpdates:YES];
                //[[CLLocationManager sharedManager] setActivityType:CLActivityTypeFitness];
                //[[CLLocationManager sharedManager] setPausesLocationUpdatesAutomatically:YES];
                //[[CLLocationManager sharedManager] startMonitoringVisits];
                NSLog(@"[Selenium] monitoredRegions count: %td",(NSUInteger)[[CLLocationManager sharedManager].monitoredRegions count]);
                //NSData *encodedRegion = [entry objectForKey:@"region"];
                /*CLSeleniumCircularRegion *regionToUse = (CLSeleniumCircularRegion*)[NSKeyedUnarchiver unarchiveObjectWithData:encodedRegion];
                if ([entry[@"onArrive"] boolValue] == YES) {
                    [(CLRegion*)regionToUse self].notifyOnEntry = YES;
                    [(CLRegion*)regionToUse self].notifyOnExit = NO;
                } else {
                    [(CLRegion*)regionToUse self].notifyOnExit = YES;
                    [(CLRegion*)regionToUse self].notifyOnEntry = NO;
                }
                [(CLSeleniumCircularRegion*)regionToUse self].requests = @[argFix];
                [[CLLocationManager sharedManager] startMonitoringForRegion:regionToUse];*/
            } else { // DND START  // and location, for now
                NCNotificationRequest *argFix = arg1;
                NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", argFix.content.header, SNOOZED];
                [argFix.content setValue:newTitle forKey:@"_header"];
                %orig(argFix);
                [[AXNManager sharedInstance] hideNotificationRequest:argFix];
                secondsLeft = [entry[@"timeStamp"] doubleValue] - [[NSDate date] timeIntervalSince1970] + 1;
                NSDictionary* userInfo = @{@"request" : argFix};
                lastTimer = [[PCSimpleTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:secondsLeft]
                                    serviceIdentifier:@"com.miwix.selenium.service"
                                    target:self
                                    selector:@selector(timerOperations:)
                                    userInfo:userInfo];
                [lastTimer scheduleInRunLoop:[NSRunLoop mainRunLoop]];
            }
            return;
        }
    }
    NSMutableArray *snoozedNotifs = [config[@"snoozedCache"] mutableCopy];
    for (NSMutableDictionary *entry in snoozedNotifs) {
        NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@";"] mutableCopy];
        [parts removeObject:parts[0]];
        NSString *combinedparts = [parts componentsJoinedByString:@";"];
        if ([req containsString:combinedparts]) {
            NCNotificationRequest *argFix = arg1;
            /*if ([entry[@"timeStamp"] doubleValue] == -2) { //DND START
                if (![argFix.content.header containsString:@"DND"]) {
                    NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", argFix.content.header, @"DND"];
                    [argFix.content setValue:newTitle forKey:@"_header"];
                }
            } else {*/
            if ([argFix.content.header containsString:LOCATION]) {
                NSString *string = [argFix.content.header componentsSeparatedByString:@" •"][0];
                [argFix.content setValue:string forKey:@"_header"];
            }
                if (![argFix.content.header containsString:SNOOZED]) {
                    NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", argFix.content.header, SNOOZED];
                    [argFix.content setValue:newTitle forKey:@"_header"];
                }
            //}
            %orig(argFix);
            return;
        }
    }
    %orig;
}

#pragma mark PCPersistentTimer selector
%new
-(void)timerOperations:(id)timer {
    NSDictionary* userInfo = [(PCSimpleTimer *)timer userInfo];
    NCNotificationRequest *request = (NCNotificationRequest *)userInfo[@"request"];
    processEntry(request, 0, nil, nil, nil);
    dispatch_sync(__BBServerQueue, ^{
        if (!([[request.content.header lowercaseString] containsString:SNOOZED] || ![[request.bulletin.header lowercaseString] containsString:SNOOZED]))
        request.bulletin.header = [NSString stringWithFormat:@"%@ • %@",request.content.header,SNOOZED];
        //request.bulletin.date = [NSDate date];
        [[%c(BBServer) SLM_sharedInstance] publishBulletin:request.bulletin destinations:14];
    });
    //[[AXNManager sharedInstance] showNotificationRequest:request];
    [timer invalidate];
}
%end

// prevent snoozed indicator from appearing as grouped notifications title.
%hook NCNotificationListCoalescingHeaderCell
%property (nonatomic,copy) NSString * title;
+(double)coalescingHeaderCellHeightForWidth:(double)arg1 title:(NSString *)arg2 {
    if ([[arg2 lowercaseString] containsString:SNOOZED] || [[arg2 lowercaseString] containsString:LOCATION]) {
        NSString *string = [arg2 componentsSeparatedByString:@" •"][0];
        return %orig(arg1,string);
    } else {
        return %orig(arg1,arg2);
    }
}

-(void)setTitle:(NSString *)arg1 {
    if ([[arg1 lowercaseString] containsString:SNOOZED] || [[arg1 lowercaseString] containsString:LOCATION]) {
        NSString *string = [arg1 componentsSeparatedByString:@" •"][0];
        %orig(string);
    } else {
        %orig(arg1);
    }
}
%end

@interface SBDashBoardIdleTimerProvider : NSObject
-(void)addDisabledIdleTimerAssertionReason:(id)arg1 ;
-(void)removeDisabledIdleTimerAssertionReason:(id)arg1 ;
@end

%hook SBDashBoardIdleTimerProvider
- (instancetype)initWithDelegate:(id)arg1 {
    %orig;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(turnOffAutoLock) name:@"SLMDisableLock" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(turnOnAutoLock) name:@"SLMEnableLock" object:nil];
    return self;
}

%new
- (void)turnOffAutoLock {
    [self addDisabledIdleTimerAssertionReason:@"com.miwix.selenium"];
}

%new
- (void)turnOnAutoLock {
    [self removeDisabledIdleTimerAssertionReason:@"com.miwix.selenium"];
}
%end
%end

%group AxonFix // Trying to fix Axon compatibility issues
#import "AXNRequestWrapper.h"
%hook AXNManager
-(void)updateCountForBundleIdentifier:(NSString *)bundleIdentifier {
    NSMutableArray *allNotifs = [config[@"entries"] mutableCopy];
    NSInteger snoozedCount = 0;
    for (id entry in allNotifs) {
        NSArray *sectionId = [entry[@"id"] componentsSeparatedByString:@"sectionId: "];
        NSMutableArray *parts = [[sectionId[1] componentsSeparatedByString:@"; "] mutableCopy];
        NSString *snoozedBundleID = (NSString*)parts[0];
        if ([bundleIdentifier isEqualToString:snoozedBundleID]) snoozedCount++;
    }

    NSArray *requests = [self requestsForBundleIdentifier:bundleIdentifier];
    NSInteger count = [requests count];
    if (count == 0) {
        self.countCache[bundleIdentifier] = @(0);
        return;
    }

    if ([self.dispatcher.notificationStore respondsToSelector:@selector(coalescedNotificationForRequest:)]) {
        count = 0;
        NSMutableArray *coalescedNotifications = [NSMutableArray new];
        for (NCNotificationRequest *req in requests) {
            NCCoalescedNotification *coalesced = [self coalescedNotificationForRequest:req];
            if (!coalesced) {
                count++;
                continue;
            }

            if (![coalescedNotifications containsObject:coalesced]) {
                count += [coalesced.notificationRequests count];
                [coalescedNotifications addObject:coalesced];
            }
        }
    }

    self.countCache[bundleIdentifier] = @(count-snoozedCount);
}

-(void)showNotificationRequest:(id)req {
    NSMutableArray *allNotifs = [config[@"entries"] mutableCopy];
    NCNotificationRequest *request = req;
    NSString *reqString = [NSString stringWithFormat:@"%@",req];
    if ([[request.content.header lowercaseString] containsString:@"snoozed"]) {
        for (id entry in allNotifs) {
            NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@"timestamp: "] mutableCopy];
            NSString *identifier = (NSString*)parts[1];
            if ([reqString containsString:identifier]) return;
        }
    }

    %orig;
    [self updateCountForBundleIdentifier:[(NCNotificationRequest*)req sectionIdentifier]];
    [self.view refresh];
    // updating app notification count every time a notification of the same bundle identifier is shown.
}

-(void)hideNotificationRequest:(id)req {
    %orig;
    [self updateCountForBundleIdentifier:[(NCNotificationRequest*)req sectionIdentifier]];
    [self.view refresh];
    // updating app notification count every time a notification of the same bundle identifier is hidden.
}

-(void)clearAll:(NSString *)bundleIdentifier {
    NSMutableArray __block *notificationsToClear = [[NSMutableArray alloc] init];
    NSMutableArray __block *snoozingNotifications = [[NSMutableArray alloc] init];
    if (self.notificationRequests[bundleIdentifier]) {
        for (AXNRequestWrapper *wrappedRequest in self.notificationRequests[bundleIdentifier]) {
            NCNotificationRequest *request = [wrappedRequest request];
            NSMutableArray *allNotifs = [config[@"entries"] mutableCopy];
            NSString *reqString;
            reqString = [NSString stringWithFormat:@"%@",request];
            if ([[request.content.header lowercaseString] containsString:@"snoozed"]) {
                for (id entry in allNotifs) {
                    NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@"timestamp: "] mutableCopy];
                    NSString *identifier = (NSString*)parts[1];
                    if ([reqString containsString:identifier]) [snoozingNotifications addObject:request];
                }
            } else [notificationsToClear addObject:request];
        }
        [self.dispatcher destination:nil requestsClearingNotificationRequests:notificationsToClear];
    }

    NSMutableArray __block *notificationsToSave = [[NSMutableArray alloc] init];
    for (NCNotificationRequest *req in snoozingNotifications) {
        [notificationsToClear addObject:[AXNRequestWrapper wrapRequest:req]];
    }

    self.notificationRequests[bundleIdentifier] = notificationsToSave;
}

-(void)clearAll {
    for (NSString *item in [self.notificationRequests allKeys]) {
        [self clearAll:item];
    }
}
%end
%end

%group deliverQuietly
@interface SBMediaController : NSObject
+(id)sharedInstance;
-(BOOL)isPlaying;
@end

%hook SBNCScreenController // Controls whether the screen should wake up for a notification when it is arriving.
-(void)turnOnScreenForNotificationRequest:(id)arg1 {
	if ([[%c(SBMediaController) sharedInstance] isPlaying]) {
		return;
	}
	%orig;
}
%end

%hook SBNCSoundController // Controls whether a sound will be played (and what sound) for a notification when it is arriving.
-(void)playSoundForNotificationRequest:(id)arg1 presentingDestination:(id)arg2 {
	if ([[%c(SBMediaController) sharedInstance] isPlaying]) {
		return;
	}
	%orig;
}
%end

%hook SBNotificationBannerDestination // Displays a banner for a notification when it is arriving.
-(void)postNotificationRequest:(id)arg1 {
	if ([[%c(SBMediaController) sharedInstance] isPlaying]) {
		return;
	}
	%orig;
}
%end
%end

static void loadPrefs() {
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.miwix.seleniumprefs.plist"];
    if ( [prefs objectForKey:@"TweakisEnabled"] ? [[prefs objectForKey:@"TweakisEnabled"] boolValue] : YES ) {
		enabled = YES;
		snooozedDeliverProminently = [[prefs objectForKey:@"snooozedDeliverProminently"] boolValue];
		segmentInterval = [[prefs objectForKey:@"segmentInterval"] intValue];
		chosenButton = [[prefs objectForKey:@"chosenButton"] intValue];
        deliverQuietlyWhilePlaying = [[prefs objectForKey:@"deliverQuietlyWhilePlaying"] boolValue];
        snoozeByLocationEnabled = [[prefs objectForKey:@"snoozeByLocation"] boolValue];
        if (deliverQuietlyWhilePlaying == YES) %init(deliverQuietly);
        if (snoozeByLocationEnabled == YES) {
            NSMutableArray *entries = [config[@"entries"] mutableCopy];
            for (NSMutableDictionary *entry in entries) {
                if ([entry[@"timeStamp"] doubleValue] == -2) {
                    NCNotificationRequest *expiredReq = entry[@"id"];
                    processEntry(expiredReq, 0, nil, nil, nil);
                }
            }
        }
	}
}

#import <dlfcn.h>

%ctor{
    loadPrefs();
    NSLog(@"[Selenium] init");

    #pragma mark localized strings
    tweakBundle = [NSBundle bundleWithPath:@"/Library/Application Support/SeleniumExtra.bundle"];
    SNOOZEN = [tweakBundle localizedStringForKey:@"SNOOZEN" value:@"" table:nil];
    SNOOZENS = [tweakBundle localizedStringForKey:@"SNOOZENS" value:@"" table:nil];
    SNOOZE = [tweakBundle localizedStringForKey:@"SNOOZE" value:@"" table:nil];
    SNOOZED = [tweakBundle localizedStringForKey:@"SNOOZED" value:@"" table:nil];
    fMINUTES = [tweakBundle localizedStringForKey:@"fMINUTES" value:@"" table:nil];
    tMINUTES = [tweakBundle localizedStringForKey:@"tMINUTES" value:@"" table:nil];
    ffMINUTES = [tweakBundle localizedStringForKey:@"ffMINUTES" value:@"" table:nil];
    oneHOUR = [tweakBundle localizedStringForKey:@"oneHOUR" value:@"" table:nil];
    twoHOURS = [tweakBundle localizedStringForKey:@"twoHOURS" value:@"" table:nil];
    threeHOURS = [tweakBundle localizedStringForKey:@"threeHOURS" value:@"" table:nil];
    fourHOURS = [tweakBundle localizedStringForKey:@"fourHOURS" value:@"" table:nil];
    sixHOURS = [tweakBundle localizedStringForKey:@"sixHOURS" value:@"" table:nil];
    eightHOURS = [tweakBundle localizedStringForKey:@"eightHOURS" value:@"" table:nil];
    twelveHOURS = [tweakBundle localizedStringForKey:@"twelveHOURS" value:@"" table:nil];
    sTIME = [tweakBundle localizedStringForKey:@"sTIME" value:@"" table:nil];
    SNOOZEU = [tweakBundle localizedStringForKey:@"SNOOZEU" value:@"" table:nil];
    SNOOZEF = [tweakBundle localizedStringForKey:@"SNOOZEF" value:@"" table:nil];
    CANCEL = [tweakBundle localizedStringForKey:@"CANCEL" value:@"" table:nil];
    TAPCHANGE = [tweakBundle localizedStringForKey:@"TAPCHANGE" value:@"" table:nil];
    STEPPER = [tweakBundle localizedStringForKey:@"STEPPER" value:@"" table:nil];
    ARRIVELOCATION = [tweakBundle localizedStringForKey:@"ARRIVELOCATION" value:@"" table:nil];
    LEAVELOCATION = [tweakBundle localizedStringForKey:@"LEAVELOCATION" value:@"" table:nil];
    LOCATION = [tweakBundle localizedStringForKey:@"LOCATION" value:@"" table:nil];

    static NSString *configPath = @"/var/mobile/Library/Selenium/manager.plist";

    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setObject:[NSNumber numberWithInt:501] forKey:NSFileOwnerAccountID];
    [attributes setObject:[NSNumber numberWithInt:501] forKey:NSFileGroupOwnerAccountID];

    NSFileManager *manager = [NSFileManager defaultManager];

    if (![manager fileExistsAtPath:configPath]) {
        if(![manager fileExistsAtPath:configPath.stringByDeletingLastPathComponent isDirectory:nil]) {
            [manager createDirectoryAtPath:configPath.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:attributes error:NULL];
        }
        [manager createFileAtPath:configPath contents:nil attributes:attributes];
        NSDate *date = [NSDate date];
        [@{@"entries":@[],@"snoozedCache":@[],@"firstTime":@"YES",@"EnabledForDND":@"NO",@"DNDStartTime":date} writeToFile:configPath atomically:YES];
    }
    config = [NSMutableDictionary dictionaryWithContentsOfFile:configPath];
    //isEnabledForDND = [config[@"EnabledForDND"] boolValue] ? YES : NO; //DND START

    dpkgInvalid = ![[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/com.miwix.selenium.list"];
    if (!dpkgInvalid) dpkgInvalid = ![[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/com.miwix.selenium.md5sums"];
    if (enabled && !dpkgInvalid) {
        NSLog(@"[Selenium] [NSBundle mainBundle]: %@",[[NSBundle mainBundle] bundleIdentifier]);
        if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]) %init(Selenium);
        else %init(Settings);
        if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/me.nepeta.axonreborn.md5sums"]) %init(AxonFix); // Initiate Axon compatibility fix if Axon Reborn is installed.
    }

    NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
	NSUInteger count = args.count;
	if (count != 0) {
		NSString *executablePath = args[0];
		if (executablePath) {
			NSString *processName = [executablePath lastPathComponent];
			BOOL isSpringBoard = [processName isEqualToString:@"SpringBoard"];
			BOOL isApplication = [executablePath rangeOfString:@"/Application"].location != NSNotFound;
			if (isSpringBoard || isApplication) {
				/* WorkflowKit */
				dlopen("System/Library/PrivateFrameworks/WorkflowKit.framework/WorkflowKit", RTLD_LAZY);
				/* WorkflowUI */
    			dlopen("System/Library/PrivateFrameworks/WorkflowUI.framework/WorkflowUI", RTLD_LAZY);
			}
		}
    }

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.miwix.seleniumprefs/settingschanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    %init;
}
