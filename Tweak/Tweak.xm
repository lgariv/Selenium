#import "Tweak.h"
#import "AXNManager.h"
#import "CustomUIStepper.h"

BOOL dpkgInvalid = NO;
BOOL initialized = NO;
BOOL enabled;
BOOL enabledForDND;
BOOL vertical;
BOOL badgesEnabled;
BOOL badgesShowBackground;
BOOL hapticFeedback;
BOOL darkMode;
BOOL fadeEntireCell;
NSInteger sortingMode;
NSInteger selectionStyle;
NSInteger style;
NSInteger showByDefault;
NSInteger alignment;
NSInteger verticalPosition;
CGFloat spacing;

NSDictionary *prefs = nil;

#pragma mark localized strings
static NSBundle *tweakBundle;
static NSString *SNOOZEN;
static NSString *SNOOZENS;
static NSString *SNOOZE;
static NSString *SNOOZED;
static NSString *fMINUTES;
static NSString *oneHOUR;
static NSString *fourHOURS;
static NSString *eightHOURS;
static NSString *sTIME;
static NSString *SNOOZEU;
static NSString *CANCEL;
static NSString *TAPCHANGE;

void updateViewConfiguration() {
    if (initialized && [AXNManager sharedInstance].view) {
        [AXNManager sharedInstance].view.hapticFeedback = hapticFeedback;
        [AXNManager sharedInstance].view.badgesEnabled = badgesEnabled;
        [AXNManager sharedInstance].view.badgesShowBackground = badgesShowBackground;
        [AXNManager sharedInstance].view.selectionStyle = selectionStyle;
        [AXNManager sharedInstance].view.sortingMode = sortingMode;
        [AXNManager sharedInstance].view.style = style;
        [AXNManager sharedInstance].view.darkMode = darkMode;
        [AXNManager sharedInstance].view.showByDefault = showByDefault;
        [AXNManager sharedInstance].view.spacing = spacing;
        [AXNManager sharedInstance].view.alignment = alignment;
    }
}

%group Axon

#pragma mark Legibility color

%hook SBFLockScreenDateView

-(id)initWithFrame:(CGRect)arg1 {
    %orig;
    if (self.legibilitySettings && self.legibilitySettings.primaryColor) {
        [AXNManager sharedInstance].fallbackColor = [self.legibilitySettings.primaryColor copy];
    }
    return self;
}

-(void)setLegibilitySettings:(_UILegibilitySettings *)arg1 {
    %orig;
    if (self.legibilitySettings && self.legibilitySettings.primaryColor) {
        [AXNManager sharedInstance].fallbackColor = [self.legibilitySettings.primaryColor copy];
    }
}

%end

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

#pragma mark Inject the Axon view into NC

#pragma mark disabled

/*%hook SBDashBoardNotificationAdjunctListViewController

%property (nonatomic, retain) AXNView *axnView;


-(BOOL)hasContent {
    return YES;
}

%end*/

#pragma mark disabled

// iOS13 Support
/*%hook CSNotificationAdjunctListViewController
%property (nonatomic, retain) AXNView *axnView;
%end*/

#pragma mark Notification management

%hook NCNotificationCombinedListViewController

%property (nonatomic,assign) BOOL axnAllowChanges;

/* Store this object for future use. */

-(id)init {
    %orig;
    [AXNManager sharedInstance].clvc = self;
    self.axnAllowChanges = NO;
    return self;
}

/* Replace notification management functions with our logic. */

-(bool)insertNotificationRequest:(NCNotificationRequest *)req forCoalescedNotification:(id)arg2 {
    if (self.axnAllowChanges) return %orig;     // This condition is true when Axon is updating filtered notifications for display.
    [[AXNManager sharedInstance] insertNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) %orig;
    }

    if (![AXNManager sharedInstance].view.selectedBundleIdentifier && showByDefault == 1) {
        [[AXNManager sharedInstance].view reset];
    }

    return YES;
}

-(bool)removeNotificationRequest:(NCNotificationRequest *)req forCoalescedNotification:(id)arg2 {
    if (self.axnAllowChanges) return %orig;     // This condition is true when Axon is updating filtered notifications for display.

    NSString *identifier = [[req notificationIdentifier] copy];

    [[AXNManager sharedInstance] removeNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) %orig;
    }

    if ([AXNManager sharedInstance].view.showingLatestRequest && identifier &&
    [[[AXNManager sharedInstance].latestRequest notificationIdentifier] isEqualToString:identifier]) {
        %orig;
    }

    return YES;
}

-(bool)modifyNotificationRequest:(NCNotificationRequest *)req forCoalescedNotification:(id)arg2 {
    if (self.axnAllowChanges) return %orig;     // This condition is true when Axon is updating filtered notifications for display.

    NSString *identifier = [[req notificationIdentifier] copy];

    [[AXNManager sharedInstance] modifyNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) %orig;
    }

    if ([AXNManager sharedInstance].view.showingLatestRequest && identifier &&
    [[[AXNManager sharedInstance].latestRequest notificationIdentifier] isEqualToString:identifier]) {
        %orig;
    }

    return YES;
}

-(bool)hasContent {
    if ([AXNManager sharedInstance].view.list && [[AXNManager sharedInstance].view.list count] > 0) return YES;
    return %orig;
}

-(void)viewDidAppear:(BOOL)animated {
    %orig;
    [[AXNManager sharedInstance].view reset];
    [[AXNManager sharedInstance].view refresh];
}

/* Fix pull to clear all tweaks. */

-(void)_clearAllPriorityListNotificationRequests {
    [[AXNManager sharedInstance].dispatcher destination:nil requestsClearingNotificationRequests:[self allNotificationRequests]];
}

-(void)_clearAllNotificationRequests {
    [[AXNManager sharedInstance].dispatcher destination:nil requestsClearingNotificationRequests:[self allNotificationRequests]];
}

-(void)clearAll {
    [[AXNManager sharedInstance].dispatcher destination:nil requestsClearingNotificationRequests:[self axnNotificationRequests]];
}

/* Compatibility thing for other tweaks. */

%new
-(id)axnNotificationRequests {
    NSMutableOrderedSet *allRequests = [NSMutableOrderedSet new];
    for (NSString *key in [[AXNManager sharedInstance].notificationRequests allKeys]) {
        [allRequests addObjectsFromArray:[[AXNManager sharedInstance] requestsForBundleIdentifier:key]];
    }
    return allRequests;
}

%new
-(void)revealNotificationHistory:(BOOL)revealed {
  [self setDidPlayRevealHaptic:YES];
  [self forceNotificationHistoryRevealed:revealed animated:NO];
  [self setNotificationHistorySectionNeedsReload:YES];
  [self _reloadNotificationHistorySectionIfNecessary];
  if (!revealed && [self respondsToSelector:@selector(clearAllCoalescingControlsCells)]) [self clearAllCoalescingControlsCells];
}

%end

// iOS13 Support
@interface NCNotificationMasterList
@property(retain, nonatomic) NSMutableArray *notificationSections;
@end
@interface NCNotificationStructuredSectionList
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
    [[AXNManager sharedInstance].view refresh];

    /*if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) %orig;
    }*/
    %orig;

    if (![AXNManager sharedInstance].view.selectedBundleIdentifier && showByDefault == 1) {
        [[AXNManager sharedInstance].view reset];
    }

    return YES;
}

-(bool)removeNotificationRequest:(NCNotificationRequest *)req {
    if (self.axnAllowChanges) return %orig;     // This condition is true when Axon is updating filtered notifications for display.

    //NSString *identifier = [[req notificationIdentifier] copy];

    [[AXNManager sharedInstance] removeNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) %orig;
    }

    //if ([AXNManager sharedInstance].view.showingLatestRequest && identifier &&
    //[[[AXNManager sharedInstance].latestRequest notificationIdentifier] isEqualToString:identifier]) {
        %orig;
    //}

    return YES;
}

-(bool)modifyNotificationRequest:(NCNotificationRequest *)req {
    if (self.axnAllowChanges) return %orig;     // This condition is true when Axon is updating filtered notifications for display.

    //NSString *identifier = [[req notificationIdentifier] copy];

    [[AXNManager sharedInstance] modifyNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) %orig;
    }

    //if ([AXNManager sharedInstance].view.showingLatestRequest && identifier &&
    //[[[AXNManager sharedInstance].latestRequest notificationIdentifier] isEqualToString:identifier]) {
        %orig;
    //}

    return YES;
}

-(void)viewDidAppear:(BOOL)animated {
    %orig;
    [[AXNManager sharedInstance].view reset];
    [[AXNManager sharedInstance].view refresh];
}

%new
-(id)axnNotificationRequests {
    NSMutableOrderedSet *allRequests = [NSMutableOrderedSet new];
    for (NSString *key in [[AXNManager sharedInstance].notificationRequests allKeys]) {
        [allRequests addObjectsFromArray:[[AXNManager sharedInstance] requestsForBundleIdentifier:key]];
    }
    return allRequests;
}

%new
-(NSSet *)allNotificationRequests {
  NSArray *array = [NSMutableArray new];
  NCNotificationMasterList *masterList = [self masterList];
  for(NCNotificationStructuredSectionList *item in [masterList notificationSections]) {
    array = [array arrayByAddingObjectsFromArray:[item allNotificationRequests]];
  }
  return [[NSSet alloc] initWithArray:array];
}

%new
-(void)revealNotificationHistory:(BOOL)revealed {
  [self revealNotificationHistory:revealed animated:true];
}

%end
@interface SBFStaticWallpaperView : UIView 
@property (nonatomic, retain) NSString *displayedImageHashString;
@end
%hook SBFStaticWallpaperView

-(void)_setDisplayedImage:(UIImage *)image
{
    %orig;
        //[[AXNManager sharedInstance] updateWallpaperColors:image];
}

%end

#pragma mark my additions

@interface NCNotificationViewController : UIViewController {
    NCNotificationRequest* _notificationRequest;
}
@property (nonatomic,retain) NCNotificationRequest * notificationRequest;                                                                                                                                                    //@synthesize notificationRequest=_notificationRequest - In the implementation block
@end

@protocol NCNotificationListViewDataSource <NSObject>
@end

@interface NCNotificationGroupList : NSObject <NCNotificationListViewDataSource>
@property (nonatomic,retain) NSMutableArray * orderedRequests;                                          //@synthesize orderedRequests=_orderedRequests - In the implementation block
@end 

@interface NCNotificationListView : UIScrollView
@property (assign,getter=isGrouped,nonatomic) BOOL grouped;                                                                          //@synthesize grouped=_grouped - In the implementation block
@property (assign,readwrite) NCNotificationGroupList<NCNotificationListViewDataSource> *dataSource;                                                 //@synthesize dataSource=_dataSource - In the implementation block
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
- (void)swipedUp:(id)arg1;
@end

@interface NCNotificationListCellActionButton : UIControl
@property (nonatomic,retain) UILabel * titleLabel;                                                                       //@synthesize titleLabel=_titleLabel - In the implementation block
@end

@interface UIView (FUCK)
@property (nonatomic,copy) NSString * title;                                                                             //@synthesize title=_title - In the implementation block
@end

NSString *bundleID;
NCNotificationListCell *snoozedCell;
NCNotificationRequest *argToDismiss;

NCNotificationRequest *reqToBeSnoozed;

UIView *newView;
UIButton *newButton;
UIImageView *iconView;

static NSDictionary *info;

%hook NCNotificationListCellActionButtonsView
-(void)layoutSubviews {
    %orig;

    // Get the options StackView array
    NSArray<NCNotificationListCellActionButton *> *buttonsArray = self.buttonsStackView.arrangedSubviews;

    // Process only if 3 CellActionButton are present
    // Less than 3 means the left option pannel is opened or the right one is already processed
    if (buttonsArray.count == 3) {
        // Replace the View option 
        buttonsArray[1].title = SNOOZE;
        [buttonsArray[1] removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents]; 
        [buttonsArray[1] addTarget:self action:@selector(swipedUp:) forControlEvents:UIControlEventTouchUpInside];
        /*[iconView removeFromSuperview];
        if (!iconView) {
            iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,buttonsArray[1].frame.size.width,buttonsArray[1].frame.size.height)];
            //iconView.bounds = CGRectMake(0,0,buttonsArray[1].bounds.size.width,buttonsArray[1].bounds.size.height);
            iconView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            iconView.contentMode = UIViewContentModeScaleAspectFit;
            iconView.image = [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/SeleniumPrefs.bundle/iconGreen.PNG"];
            iconView.translatesAutoresizingMaskIntoConstraints = YES;
        } else iconView.frame = CGRectMake(0,0,buttonsArray[1].frame.size.width,buttonsArray[1].frame.size.height);
        [buttonsArray[1] insertSubview:iconView aboveSubview:buttonsArray[1].titleLabel];*/
    }
}

/*-(void)_configureActionButtonsForActionButtonDescriptions:(id)arg1 cell:(id)arg2 {
    NSLog(@"[SELENIUM] arg1: %@ arg2: %@",[arg1 class],[arg2 class]);
    %orig;
}*/

-(void)configureCellActionButtonsForNotificationRequest:(id)arg1 sectionSettings:(id)arg2 cell:(id)arg3 {
    argToDismiss = arg1;
    bundleID = argToDismiss.sectionIdentifier;
    snoozedCell = arg3;
    reqToBeSnoozed = snoozedCell.contentViewController.notificationRequest;
    NSLog(@"snoozedCell: %@", snoozedCell);
    /*if (!newView) {
        newView = [[UIView alloc] init];
        [newView setBackgroundColor:[UIColor whiteColor]];
    }
    if (newButton) {
        [newButton removeFromSuperview];
    }
    [newView setFrame:CGRectMake(0, 50, 375, 30)];
    newButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [newButton setTitle:snoozedCell.contentViewController.notificationRequest.content.message forState:UIControlStateNormal];
    [newButton setFrame:newView.bounds];
    [newView addSubview:newButton];
    [[[UIApplication sharedApplication] windows][0] addSubview:newView];*/
    %orig;
}

%new
- (void)swipedUp:(id)arg1 {
    info = @{@"id": reqToBeSnoozed, @"cell": snoozedCell};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.miwix.selenium.menu" object:nil userInfo:info];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}
%end

//static double minutesLeft;
static double secondsLeft;

//static NSString *configPath = @"/var/mobile/Library/Selenium/config.plist";
//NSMutableDictionary *config = [[[NSUserDefaults standardUserDefaults] objectForKey:@"dictionaryKey"] mutableCopy];

static void storeSnoozed(NCNotificationRequest *request, BOOL shouldRemove) {
  NSMutableDictionary *config = [[[NSUserDefaults standardUserDefaults] objectForKey:@"dictionaryKey"] mutableCopy];
  NSString *req = [NSString stringWithFormat:@"%@", request];
  NSMutableArray *entries = [config[@"snoozedCache"] mutableCopy];
  bool add = YES;
  NSDictionary *remove = nil;
  for (NSMutableDictionary __strong *entry in entries) {
    entry = [entry mutableCopy];
    NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@";"] mutableCopy];
    [parts removeObject:parts[0]];
    NSString *combinedparts = [parts componentsJoinedByString:@";"];
    if ([req containsString:combinedparts]) {
        NSDate *removeDate = [[NSDate alloc] initWithTimeInterval:604800 sinceDate:[(NCNotificationRequest *)request timestamp]];
        #pragma mark storeSnoozed crash
        entry[@"timeToRemove"] = removeDate;
        remove = entry;
        add = NO;
        //break;
    }
  }
  if (shouldRemove && (remove != nil)) {
    [entries removeObject:remove];
  }
  if (add) {
    NSDictionary *info;
    NSDate *removeDate = [[NSDate alloc] initWithTimeInterval:604800 sinceDate:request.timestamp];
    info = @{@"id": req, @"timeToRemove": removeDate};
    [entries addObject:info];
  }
  [config setValue:entries forKey:@"snoozedCache"];
  //[config writeToFile:configPath atomically:YES];
  [[NSUserDefaults standardUserDefaults] setObject:config forKey:@"dictionaryKey"];
}

static void processEntry(NCNotificationRequest *request, double interval, NSDate *inputDate) {
  NSMutableDictionary *config = [[[NSUserDefaults standardUserDefaults] objectForKey:@"dictionaryKey"] mutableCopy];
  NSString *req = [NSString stringWithFormat:@"%@", request];
  NSMutableArray *entries = [config[@"entries"] mutableCopy];
  bool add = YES;
  NSDictionary *remove = nil;
  for (NSMutableDictionary __strong *entry in entries) {
  //for (NSDictionary __strong *entry in entries) {
    entry = [entry mutableCopy];
    NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@";"] mutableCopy];
    [parts removeObject:parts[0]];
    NSString *combinedparts = [parts componentsJoinedByString:@";"];
    if ([req containsString:combinedparts]) {
        if (interval < 0) {
            if (interval == -1) {
                entry[@"timeStamp"] = @([inputDate timeIntervalSince1970]);
            }
            /*else if (interval == -2) { //reserved for options that are not time-based
                entry[@"timeStamp"] = @(-2);
            }*/
        } else if (interval == 0) {
            remove = entry;
        } else {
            #pragma mark storeSnoozed crash
            entry[@"timeStamp"] = @([[NSDate date] timeIntervalSince1970] + interval);
        }
        add = NO;
    }
  }
  if (remove) {
    [entries removeObject:remove];
  }
  if (add) {
    storeSnoozed(request, NO);
    NSDictionary *info;
    if (interval < 0) {
        if (interval == -1)
        info = @{@"id": req, @"timeStamp": @([inputDate timeIntervalSince1970])};
        /*else if (interval == -2)
        info = @{@"id": req, @"timeStamp": @(-2)};*/
    } else if (interval != 0) {
        info = @{@"id": req, @"timeStamp": @([[NSDate date] timeIntervalSince1970] + interval)};
    }
    if (info) {
      [entries addObject:info];
    }
  }
  [config setValue:entries forKey:@"entries"];
  //[config writeToFile:configPath atomically:YES];
  [[NSUserDefaults standardUserDefaults] setObject:config forKey:@"dictionaryKey"];
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
-(id)initWithRequest:(id)arg1 withPresentingView:(id)arg2 settingsDelegate:(id)arg3 ;                                                         //@synthesize request=_request - In the implementation block
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

@interface SButton : UIButton
@property (nonatomic,retain) NCNotificationRequest *request;    
@property (nonatomic,retain) NCNotificationListCell *cell;    
@property (nonatomic,retain) SBRingerPillView *pillView;    
@property (nonatomic,retain) UILabel *pillViewUntilLabel;    
@property (nonatomic,retain) UIDatePicker *datePicker;
@property (nonatomic,retain) NSDate *pickerDate;
@property (nonatomic,retain) UIAlertController *controllerToDismiss;    
@property (nonatomic,readwrite) BOOL grouped;    
@end

@implementation SButton
@end

@interface SpringBoard : UIApplication
@end

@interface SpringBoard ()
- (UIImage *) imageWithView:(UIView *)view;
@end

// Tried to replace NSTimer with PCPersistentTimer for better reliability, but that made it go to safe mode once in a while. More testing needed. Also, PCPersistentTimer is working accross reboots (even if the device is not jailbroken - it will fire.), so also need to disable that to prevent possible freezes (I assume).
// [Interesting feature: it has the ability to wake the device and perform the action if it is powered off at the time it is supposed to execute. has nothing to do with this tweak (that I can think of) but might come in handy in the future.]
@interface PCSimpleTimer : NSObject {
	NSRunLoop* _timerRunLoop;
}
-(id)userInfo;
-(void)scheduleInRunLoop:(id)arg1 ;
-(id)initWithFireDate:(id)arg1 serviceIdentifier:(id)arg2 target:(id)arg3 selector:(SEL)arg4 userInfo:(id)arg5 ;
@end

/*@interface PCPersistentTimer : NSObject {
    PCSimpleTimer* _simpleTimer;
	id _userInfo;
}
-(id)initWithFireDate:(id)arg1 serviceIdentifier:(id)arg2 target:(id)arg3 selector:(SEL)arg4 userInfo:(id)arg5 ;
-(void)scheduleInRunLoop:(id)arg1 ;
-(id)userInfo;
@end*/

#pragma mark DND start

/*#import "TweakCCDUNE.h"

// to make notifications appear when finished
static void setStateForDND(bool state) {
    NSDictionary *isEnabled;
    if (state) {
        isEnabled = @{@"DNDEnabled": @YES};
    } else {
        isEnabled = @{@"DNDEnabled": @NO};
    }
	[config setValue:isEnabled forKey:@"DNDEnabled"];
	//[config writeToFile:configPath atomically:YES];
	[[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionaryWithDictionary:config] forKey:@"dictionaryKey"];
}*/

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
  [config setValue:entries forKey:@"DND"];
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
*/
/*@interface UIView (mxcl)
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

static BOOL shouldSnooze;
static BOOL isDNDEnabled;
static BOOL isDuneEnabled;
static CGRect ccBounds;

// Toggle Notifications
static void setDuneEnabled(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  setStateForDND(YES);
}

static void setDuneDisabled(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  setStateForDND(NO);
}

static void duneEnabled() {
  CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("xyz.skitty.dune.enabled"), nil, nil, true);
  shouldSnooze = YES;
}

static void duneDisabled() {
  CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("xyz.skitty.dune.disabled"), nil, nil, true);
  shouldSnooze = NO;
}

static void preferencesChanged();

%subclass CCUIDuneButton : CCUIRoundButton
%property (nonatomic, retain) UIView *backgroundView;
%property (nonatomic, retain) CCUICAPackageView *packageView;
- (void)layoutSubviews {
  %orig;
  if (!self.packageView) {
    self.backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    self.backgroundView.userInteractionEnabled = NO;
    self.backgroundView.layer.cornerRadius = self.bounds.size.width/2;
    self.backgroundView.layer.masksToBounds = YES;
    self.backgroundView.backgroundColor = [UIColor systemBlueColor];
    self.backgroundView.alpha = 0;
    [self addSubview:self.backgroundView];

    self.packageView = [[%c(CCUICAPackageView) alloc] initWithFrame:self.bounds];
    self.packageView.package = [CAPackage packageWithContentsOfURL:[NSURL fileURLWithPath:@"/Library/Application Support/Dune/StyleMode.ca"] type:kCAPackageTypeCAMLBundle options:nil error:nil];
    [self.packageView setStateName:@"dark"];
    [self addSubview:self.packageView];

    [self setHighlighted:NO];
    [self updateStateAnimated:NO];
  }
}
- (void)touchesEnded:(id)arg1 withEvent:(id)arg2 {
  %orig;
  if (isDuneEnabled) {
    duneDisabled();
    setStateForDND(NO);
  } else {
    duneEnabled();
    setStateForDND(YES);
  }

  preferencesChanged();
  [self updateStateAnimated:YES];
}
%new
- (void)updateStateAnimated:(bool)animated {
  if (!isDuneEnabled) {
    ((CCUILabeledRoundButton *)self.superview).subtitle = [NSString stringWithFormat:@"On"];
    [self.packageView setStateName:@"On"];
    if (animated) {
      [UIView animateWithDuration:0.2 delay:0 options:nil animations:^{
        self.backgroundView.alpha = 1;
      } completion:nil];
    } else {
      self.backgroundView.alpha = 1;
    }
  } else {
    ((CCUILabeledRoundButton *)self.superview).subtitle = @"Off";
    [self.packageView setStateName:@"Off"];
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
      self.darkButton.buttonContainer.buttonView = [[%c(CCUIDuneButton) alloc] initWithGlyphImage:nil highlightColor:nil useLightStyle:NO];
      [self.darkButton.buttonContainer addSubview:self.darkButton.buttonContainer.buttonView];
      self.darkButton.button = self.darkButton.buttonContainer.buttonView;

      self.darkButton.title = @"Snooze";
      if (isDuneEnabled) {
        self.darkButton.subtitle = [NSString stringWithFormat:@"On"];
        [((CCUIDuneButton *)self.darkButton.buttonContainer.buttonView).packageView setStateName:@"On"];
      } else {
        self.darkButton.subtitle = @"Off";
        [((CCUIDuneButton *)self.darkButton.buttonContainer.buttonView).packageView setStateName:@"Off"];
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
  isDNDEnabled = %orig;
  return %orig;
}
%end
*/
#pragma mark DND end

@interface SBAlertItem : NSObject
@end

@interface _SBAlertController : UIAlertController
@property (assign,nonatomic) SBAlertItem * alertItem;                                             //@synthesize alertItem=_alertItem - In the implementation block
-(void)setAlertItem:(SBAlertItem *)arg1 ;
@end

@interface SBRingerPillView : UIView
@end

@interface UIHoursStepper : SButton
@end

@implementation UIHoursStepper
@end

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    NSMutableDictionary *config = [[[NSUserDefaults standardUserDefaults] objectForKey:@"dictionaryKey"] mutableCopy];
    //config = [NSMutableDictionary dictionaryWithContentsOfFile:configPath];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMuteMenu:) name:@"com.miwix.selenium.menu" object:nil];
    
    NSMutableArray *entries = [config[@"entries"] mutableCopy];
    for (NSMutableDictionary *entry in entries) {
        if (([[NSDate date] timeIntervalSince1970] - [entry[@"timeStamp"] doubleValue]) >= 1) {
            NCNotificationRequest *expiredReq = entry[@"id"];
            processEntry(expiredReq, 0, nil);
        }
    }
    NSMutableArray *snoozedCache = [config[@"snoozedCache"] mutableCopy];
    for (NSMutableDictionary *snoozedNotif in snoozedCache) {
        if (([[NSDate date] timeIntervalSince1970] - [snoozedNotif[@"timeToRemove"] timeIntervalSince1970]) >= 1) {
            NCNotificationRequest *snoozedNotifReq = snoozedNotif[@"id"];
            storeSnoozed(snoozedNotifReq, YES);
        }
    }
}

%new
- (void)showMuteMenu:(NSNotification *)notification {
    NCNotificationRequest *requestToProcess = notification.userInfo[@"id"];
    NCNotificationListCell *cellToCapture = notification.userInfo[@"cell"];
    NCNotificationListView *cellListView = (NCNotificationListView *)cellToCapture.superview;
    NCNotificationGroupList *groupList = cellListView.dataSource;
    NSMutableArray *reqsArray = [groupList.orderedRequests copy];

    UIAlertController *alert;

    BOOL grouped;
    if (cellListView.grouped) {
        grouped = YES;
        alert = [UIAlertController alertControllerWithTitle:SNOOZENS message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    } else {
        grouped = NO;
        alert = [UIAlertController alertControllerWithTitle:SNOOZEN message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    }

  [alert addAction:[UIAlertAction actionWithTitle:fMINUTES style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    if (grouped){
        [[AXNManager sharedInstance] hideNotificationRequests:reqsArray];
        for (NCNotificationRequest *request in reqsArray) {
            if (![request.content.header containsString:SNOOZED]) {
                NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", request.content.header, SNOOZED];
                [request.content setValue:newTitle forKey:@"_header"];
            }
            processEntry(request, 900, nil);
        }

        NSDictionary* userInfo = @{@"requests" : reqsArray, @"grouped" : [NSNumber numberWithBool:grouped]};
        PCSimpleTimer *timerShow = [[PCSimpleTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:900]
                            serviceIdentifier:@"com.miwix.selenium.service"
                            target:self
                            selector:@selector(timerOperations:)
                            userInfo:userInfo];
        [timerShow scheduleInRunLoop:[NSRunLoop mainRunLoop]];

        /*NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:900]
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             for (NCNotificationRequest *request in reqsArray) {
                                                                processEntry(request, 0, nil);
                                                             }
                                                             [[AXNManager sharedInstance] showNotificationRequests:reqsArray];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];*/
    } else {
        [[AXNManager sharedInstance] hideNotificationRequest:requestToProcess];
        if (![requestToProcess.content.header containsString:SNOOZED]) {
            NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", requestToProcess.content.header, SNOOZED];
            [requestToProcess.content setValue:newTitle forKey:@"_header"];
        }

        NSDictionary* userInfo = @{@"request" : requestToProcess, @"grouped" : [NSNumber numberWithBool:grouped]};
        PCSimpleTimer *timerShow = [[PCSimpleTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:900]
                            serviceIdentifier:@"com.miwix.selenium.service"
                            target:self
                            selector:@selector(timerOperations:)
                            userInfo:userInfo];
        [timerShow scheduleInRunLoop:[NSRunLoop mainRunLoop]];

        /*NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:900]
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             processEntry(requestToProcess, 0, nil);
                                                             [[AXNManager sharedInstance] showNotificationRequest:requestToProcess];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];*/
        processEntry(requestToProcess, 900, nil);
    }
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
        NSMutableAttributedString *attributedSnoozedForUntilLabel = [[NSMutableAttributedString alloc] initWithString:fMINUTES attributes:attribsSnoozedLabel];
        pillSnoozedForUntilLabel.attributedText = attributedSnoozedForUntilLabel;
        pillSnoozedForUntilLabel.textAlignment = NSTextAlignmentCenter;
        pillSnoozedForUntilLabel.textColor = [UIColor systemBlueColor];
        CGSize expectedSnoozedForUntilLabelSize = [fMINUTES sizeWithAttributes:@{NSFontAttributeName:boldFont}];
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
        UIWindow *window;
        for (int i=0; i<([[UIApplication sharedApplication].windows count]-1); i++) {
            if ([[UIApplication sharedApplication].windows[i] isMemberOfClass:[%c(SBCoverSheetWindow) class]]) {
                window = [UIApplication sharedApplication].windows[i];
                break;
            }
        }
        [window addSubview:view];
        [view addSubview:pillSnoozedLabel];
        [view addSubview:pillSnoozedForUntilLabel];
        [view addSubview:pillTapToChangeLabel];
        [view addSubview:pillViewButton];
        CGFloat combinedSize;
        view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
        //pillSnoozedLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedLabel.center.y);
        //pillSnoozedForUntilLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedForUntilLabel.center.y);
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
        [UIView animateWithDuration:0.33f animations:^{
            view.frame = CGRectMake(0,44,196,50);
            view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
            //pillSnoozedLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedLabel.center.y);
            //pillSnoozedForUntilLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedForUntilLabel.center.y);
            pillTapToChangeLabel.center = CGPointMake(view.frame.size.width/2, pillTapToChangeLabel.center.y);
        } completion:^(BOOL finished) {
            [NSTimer scheduledTimerWithTimeInterval:2.0f
                target:[NSBlockOperation blockOperationWithBlock:^{
                    [UIView animateWithDuration:0.33f animations:^{
                        view.frame = CGRectMake(0,-56,196,50);
                        view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
                        //pillSnoozedLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedLabel.center.y);
                        //pillSnoozedForUntilLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedForUntilLabel.center.y);
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
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:oneHOUR style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    if (grouped){
        [[AXNManager sharedInstance] hideNotificationRequests:reqsArray];
        for (NCNotificationRequest *request in reqsArray) {
            if (![request.content.header containsString:SNOOZED]) {
                NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", request.content.header, SNOOZED];
                [request.content setValue:newTitle forKey:@"_header"];
            }
            processEntry(request, 3600, nil);
        }

        NSDictionary* userInfo = @{@"requests" : reqsArray, @"grouped" : [NSNumber numberWithBool:grouped]};
        PCSimpleTimer *timerShow = [[PCSimpleTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:3600]
                            serviceIdentifier:@"com.miwix.selenium.service"
                            target:self
                            selector:@selector(timerOperations:)
                            userInfo:userInfo];
        [timerShow scheduleInRunLoop:[NSRunLoop mainRunLoop]];

        /*NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:3600]
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             for (NCNotificationRequest *request in reqsArray) {
                                                                processEntry(request, 0, nil);
                                                             }
                                                             [[AXNManager sharedInstance] showNotificationRequests:reqsArray];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];*/
    } else {
        [[AXNManager sharedInstance] hideNotificationRequest:requestToProcess];
        if (![requestToProcess.content.header containsString:SNOOZED]) {
            NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", requestToProcess.content.header, SNOOZED];
            [requestToProcess.content setValue:newTitle forKey:@"_header"];
        }

        NSDictionary* userInfo = @{@"request" : requestToProcess, @"grouped" : [NSNumber numberWithBool:grouped]};
        PCSimpleTimer *timerShow = [[PCSimpleTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:3600]
                            serviceIdentifier:@"com.miwix.selenium.service"
                            target:self
                            selector:@selector(timerOperations:)
                            userInfo:userInfo];
        [timerShow scheduleInRunLoop:[NSRunLoop mainRunLoop]];

        /*NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:3600]
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             processEntry(requestToProcess, 0, nil);
                                                             [[AXNManager sharedInstance] showNotificationRequest:requestToProcess];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];*/
        processEntry(requestToProcess, 3600, nil);
    }
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
        NSMutableAttributedString *attributedSnoozedForUntilLabel = [[NSMutableAttributedString alloc] initWithString:oneHOUR attributes:attribsSnoozedLabel];
        pillSnoozedForUntilLabel.attributedText = attributedSnoozedForUntilLabel;
        pillSnoozedForUntilLabel.textAlignment = NSTextAlignmentCenter;
        pillSnoozedForUntilLabel.textColor = [UIColor systemBlueColor];
        CGSize expectedSnoozedForUntilLabelSize = [oneHOUR sizeWithAttributes:@{NSFontAttributeName:boldFont}];
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
        UIWindow *window;
        for (int i=0; i<([[UIApplication sharedApplication].windows count]-1); i++) {
            if ([[UIApplication sharedApplication].windows[i] isMemberOfClass:[%c(SBCoverSheetWindow) class]]) {
                window = [UIApplication sharedApplication].windows[i];
                break;
            }
        }
        [window addSubview:view];
        [view addSubview:pillSnoozedLabel];
        [view addSubview:pillSnoozedForUntilLabel];
        [view addSubview:pillTapToChangeLabel];
        [view addSubview:pillViewButton];
        CGFloat combinedSize;
        view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
        //pillSnoozedLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedLabel.center.y);
        //pillSnoozedForUntilLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedForUntilLabel.center.y);
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
        [UIView animateWithDuration:0.33f animations:^{
            view.frame = CGRectMake(0,44,196,50);
            view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
            //pillSnoozedLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedLabel.center.y);
            //pillSnoozedForUntilLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedForUntilLabel.center.y);
            pillTapToChangeLabel.center = CGPointMake(view.frame.size.width/2, pillTapToChangeLabel.center.y);
        } completion:^(BOOL finished) {
            [NSTimer scheduledTimerWithTimeInterval:2.0f
                target:[NSBlockOperation blockOperationWithBlock:^{
                    [UIView animateWithDuration:0.33f animations:^{
                        view.frame = CGRectMake(0,-56,196,50);
                        view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
                        //pillSnoozedLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedLabel.center.y);
                        //pillSnoozedForUntilLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedForUntilLabel.center.y);
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
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:fourHOURS style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    if (grouped){
        [[AXNManager sharedInstance] hideNotificationRequests:reqsArray];
        for (NCNotificationRequest *request in reqsArray) {
            if (![request.content.header containsString:SNOOZED]) {
                NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", request.content.header, SNOOZED];
                [request.content setValue:newTitle forKey:@"_header"];
            }
            processEntry(request, 14400, nil);
        }

        NSDictionary* userInfo = @{@"requests" : reqsArray, @"grouped" : [NSNumber numberWithBool:grouped]};
        PCSimpleTimer *timerShow = [[PCSimpleTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:14400]
                            serviceIdentifier:@"com.miwix.selenium.service"
                            target:self
                            selector:@selector(timerOperations:)
                            userInfo:userInfo];
        [timerShow scheduleInRunLoop:[NSRunLoop mainRunLoop]];

        /*NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:14400]
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             for (NCNotificationRequest *request in reqsArray) {
                                                                processEntry(request, 0, nil);
                                                             }
                                                             [[AXNManager sharedInstance] showNotificationRequests:reqsArray];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];*/
    } else {
        [[AXNManager sharedInstance] hideNotificationRequest:requestToProcess];
        if (![requestToProcess.content.header containsString:SNOOZED]) {
            NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", requestToProcess.content.header, SNOOZED];
            [requestToProcess.content setValue:newTitle forKey:@"_header"];
        }

        NSDictionary* userInfo = @{@"request" : requestToProcess, @"grouped" : [NSNumber numberWithBool:grouped]};
        PCSimpleTimer *timerShow = [[PCSimpleTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:14400]
                            serviceIdentifier:@"com.miwix.selenium.service"
                            target:self
                            selector:@selector(timerOperations:)
                            userInfo:userInfo];
        [timerShow scheduleInRunLoop:[NSRunLoop mainRunLoop]];

        /*NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:14400]
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             processEntry(requestToProcess, 0, nil);
                                                             [[AXNManager sharedInstance] showNotificationRequest:requestToProcess];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];*/
        processEntry(requestToProcess, 14400, nil);
    }
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
        NSMutableAttributedString *attributedSnoozedForUntilLabel = [[NSMutableAttributedString alloc] initWithString:fourHOURS attributes:attribsSnoozedLabel];
        pillSnoozedForUntilLabel.attributedText = attributedSnoozedForUntilLabel;
        pillSnoozedForUntilLabel.textAlignment = NSTextAlignmentCenter;
        pillSnoozedForUntilLabel.textColor = [UIColor systemBlueColor];
        CGSize expectedSnoozedForUntilLabelSize = [fourHOURS sizeWithAttributes:@{NSFontAttributeName:boldFont}];
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
        UIWindow *window;
        for (int i=0; i<([[UIApplication sharedApplication].windows count]-1); i++) {
            if ([[UIApplication sharedApplication].windows[i] isMemberOfClass:[%c(SBCoverSheetWindow) class]]) {
                window = [UIApplication sharedApplication].windows[i];
                break;
            }
        }
        [window addSubview:view];
        [view addSubview:pillSnoozedLabel];
        [view addSubview:pillSnoozedForUntilLabel];
        [view addSubview:pillTapToChangeLabel];
        [view addSubview:pillViewButton];
        CGFloat combinedSize;
        view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
        //pillSnoozedLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedLabel.center.y);
        //pillSnoozedForUntilLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedForUntilLabel.center.y);
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
        [UIView animateWithDuration:0.33f animations:^{
            view.frame = CGRectMake(0,44,196,50);
            view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
            //pillSnoozedLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedLabel.center.y);
            //pillSnoozedForUntilLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedForUntilLabel.center.y);
            pillTapToChangeLabel.center = CGPointMake(view.frame.size.width/2, pillTapToChangeLabel.center.y);
        } completion:^(BOOL finished) {
            [NSTimer scheduledTimerWithTimeInterval:2.0f
                target:[NSBlockOperation blockOperationWithBlock:^{
                    [UIView animateWithDuration:0.33f animations:^{
                        view.frame = CGRectMake(0,-56,196,50);
                        view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
                        //pillSnoozedLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedLabel.center.y);
                        //pillSnoozedForUntilLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedForUntilLabel.center.y);
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
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:eightHOURS style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    if (grouped){
        [[AXNManager sharedInstance] hideNotificationRequests:reqsArray];
        for (NCNotificationRequest *request in reqsArray) {
            if (![request.content.header containsString:SNOOZED]) {
                NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", request.content.header, SNOOZED];
                [request.content setValue:newTitle forKey:@"_header"];
            }
            processEntry(request, 28800, nil);
        }

        NSDictionary* userInfo = @{@"requests" : reqsArray, @"grouped" : [NSNumber numberWithBool:grouped]};
        PCSimpleTimer *timerShow = [[PCSimpleTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:28800]
                            serviceIdentifier:@"com.miwix.selenium.service"
                            target:self
                            selector:@selector(timerOperations:)
                            userInfo:userInfo];
        [timerShow scheduleInRunLoop:[NSRunLoop mainRunLoop]];

        /*NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:28800]
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             for (NCNotificationRequest *request in reqsArray) {
                                                                processEntry(request, 0, nil);
                                                             }
                                                             [[AXNManager sharedInstance] showNotificationRequests:reqsArray];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];*/
    } else {
        [[AXNManager sharedInstance] hideNotificationRequest:requestToProcess];
        if (![requestToProcess.content.header containsString:SNOOZED]) {
            NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", requestToProcess.content.header, SNOOZED];
            [requestToProcess.content setValue:newTitle forKey:@"_header"];
        }

        NSDictionary* userInfo = @{@"request" : requestToProcess, @"grouped" : [NSNumber numberWithBool:grouped]};
        PCSimpleTimer *timerShow = [[PCSimpleTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:28800]
                            serviceIdentifier:@"com.miwix.selenium.service"
                            target:self
                            selector:@selector(timerOperations:)
                            userInfo:userInfo];
        [timerShow scheduleInRunLoop:[NSRunLoop mainRunLoop]];

        /*NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:28800]
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             processEntry(requestToProcess, 0, nil);
                                                             [[AXNManager sharedInstance] showNotificationRequest:requestToProcess];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];*/
        processEntry(requestToProcess, 28800, nil);
    }
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
        NSMutableAttributedString *attributedSnoozedForUntilLabel = [[NSMutableAttributedString alloc] initWithString:eightHOURS attributes:attribsSnoozedLabel];
        pillSnoozedForUntilLabel.attributedText = attributedSnoozedForUntilLabel;
        pillSnoozedForUntilLabel.textAlignment = NSTextAlignmentCenter;
        pillSnoozedForUntilLabel.textColor = [UIColor systemBlueColor];
        CGSize expectedSnoozedForUntilLabelSize = [eightHOURS sizeWithAttributes:@{NSFontAttributeName:boldFont}];
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
        UIWindow *window;
        for (int i=0; i<([[UIApplication sharedApplication].windows count]-1); i++) {
            if ([[UIApplication sharedApplication].windows[i] isMemberOfClass:[%c(SBCoverSheetWindow) class]]) {
                window = [UIApplication sharedApplication].windows[i];
                break;
            }
        }
        [window addSubview:view];
        [view addSubview:pillSnoozedLabel];
        [view addSubview:pillSnoozedForUntilLabel];
        [view addSubview:pillTapToChangeLabel];
        [view addSubview:pillViewButton];
        CGFloat combinedSize;
        view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
        //pillSnoozedLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedLabel.center.y);
        //pillSnoozedForUntilLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedForUntilLabel.center.y);
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
        [UIView animateWithDuration:0.33f animations:^{
            view.frame = CGRectMake(0,44,196,50);
            view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
            //pillSnoozedLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedLabel.center.y);
            //pillSnoozedForUntilLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedForUntilLabel.center.y);
            pillTapToChangeLabel.center = CGPointMake(view.frame.size.width/2, pillTapToChangeLabel.center.y);
        } completion:^(BOOL finished) {
            [NSTimer scheduledTimerWithTimeInterval:2.0f
                target:[NSBlockOperation blockOperationWithBlock:^{
                    [UIView animateWithDuration:0.33f animations:^{
                        view.frame = CGRectMake(0,-56,196,50);
                        view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
                        //pillSnoozedLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedLabel.center.y);
                        //pillSnoozedForUntilLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedForUntilLabel.center.y);
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
  }]];
  /*[alert addAction:[UIAlertAction actionWithTitle:@"Until DND is turned off" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    if (grouped){
        [[AXNManager sharedInstance] hideNotificationRequests:reqsArray];
    } else {
        [[AXNManager sharedInstance] hideNotificationRequest:requestToProcess];
        if (![requestToProcess.content.header containsString:SNOOZED]) {
            NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", requestToProcess.content.header, SNOOZED];
            [requestToProcess.content setValue:newTitle forKey:@"_header"];
        }
        processEntry(requestToProcess, -2, nil);
    }
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"Until I leave these location" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [[AXNManager sharedInstance] hideNotificationRequest:requestToProcess];
    if (![requestToProcess.content.header containsString:SNOOZED]) {
        NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", requestToProcess.content.header, SNOOZED];
        [requestToProcess.content setValue:newTitle forKey:@"_header"];
    }
    [NSTimer scheduledTimerWithTimeInterval:86400
                            target:[NSBlockOperation blockOperationWithBlock:^{processEntry(requestToProcess, 0, nil); [[AXNManager sharedInstance] showNotificationRequest:requestToProcess];}]
                            selector:@selector(main)
                            userInfo:nil
                            repeats:NO];
    processEntry(requestToProcess, 86400, nil);
  }]];*/

    [alert addAction:[UIAlertAction actionWithTitle:sTIME style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NCNotificationManagementAlertController *alertController = [[%c(NCNotificationManagementAlertController) alloc] initWithRequest:requestToProcess withPresentingView:nil settingsDelegate:nil];
        [alertController setTitle:SNOOZEU];
        //UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        NSLocale *locale = [NSLocale currentLocale];
        UIDatePicker *picker = [[UIDatePicker alloc] init];
        picker.locale = locale; 
        [picker setDatePickerMode:UIDatePickerModeDateAndTime];
        [picker setMinuteInterval:5];
        #pragma mark setMinimumDate fix test
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
        for (char i=0; i<13; i++) {
            if ([[NSDate date] timeIntervalSinceDate:minimumDate] < 0) {
                break;
            } else {
                minimumDate = [NSDate dateWithTimeInterval:300 sinceDate:minimumDate];
            }
        }
        [picker setMinimumDate:minimumDate/*[NSDate dateWithTimeInterval:300 sinceDate:[NSDate date]]*/];
        [picker setMaximumDate:[NSDate dateWithTimeInterval:604800 sinceDate:requestToProcess.timestamp]];
        [alertController.view addSubview:picker];

        SButton *button = [SButton buttonWithType:UIButtonTypeSystem];
        CGFloat margin = 4.0F;
        button.frame = CGRectMake(10 + alertController.view.bounds.origin.x, alertController.view.bounds.origin.y + ((picker.frame.size.height+40) - 2) + 50, alertController.view.frame.size.width - margin * 4.0F - 20, 50);
        [button setBackgroundColor:[UIColor systemBlueColor]];
        [button setTitle:SNOOZE forState:UIControlStateNormal];
        //[button setTitle:@"Snooze" forState:UIControlStateNormal];
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
        [alertController.view addSubview:button];

        UIImageView *myImage = [[UIImageView alloc] init];
        myImage.image = [self imageWithView:cellToCapture];
        double widthInPoints = myImage.image.size.width;
        double heightInPoints = myImage.image.size.height;
        [myImage setFrame:CGRectMake(0, 0, widthInPoints, heightInPoints)];
        myImage.contentMode = UIViewContentModeScaleAspectFit;
        
        SButton *button2 = [SButton buttonWithType:UIButtonTypeSystem];
        button2.frame = CGRectMake(10 + alertController.view.bounds.origin.x , alertController.view.bounds.origin.y+50, alertController.view.frame.size.width - margin * 4.0F - 20, heightInPoints+10);

        if (grouped) {
            [myImage setFrame:CGRectMake(button2.bounds.origin.x, button2.bounds.origin.y, button2.bounds.size.width-15, button2.bounds.size.height)];
        } else {
            [myImage setFrame:CGRectMake(button2.bounds.origin.x, button2.bounds.origin.y, button2.bounds.size.width-30, button2.bounds.size.height)];
        }

        [button2 setBackgroundColor:[UIColor systemGrayColor]];
        [button2 setAlpha:0.1f];
        button2.layer.cornerRadius = 12.5;

        [alertController.view addSubview:button2];
        [alertController.view addSubview:myImage];
        myImage.center = button2.center;

        picker.center = CGPointMake(button.center.x, picker.center.y+50+heightInPoints);
        button.frame = CGRectMake(10 + alertController.view.bounds.origin.x, alertController.view.bounds.origin.y + (picker.frame.size.height+30) + button2.frame.size.height, alertController.view.frame.size.width - margin * 4.0F - 20, 50);

        UIPopoverPresentationController *popoverController = alertController.popoverPresentationController;
        popoverController.sourceView = alertController.view;
        popoverController.sourceRect = [alertController.view bounds];

        [alertController.view addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:alertController.view attribute:NSLayoutAttributeBottomMargin multiplier:1.0 constant:-76.0f]];

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

        /*UIWindow *window;
        for (int i=0; i<([[UIApplication sharedApplication].windows count]-1); i++) {
            if ([[UIApplication sharedApplication].windows[i] isMemberOfClass:[%c(SBCoverSheetWindow) class]]) {
                window = [UIApplication sharedApplication].windows[i];
                break;
            }
        }
        [window addSubview:view];
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
        }];*/
        button.pillView = view;
    }]];

    /*[alert addAction:[UIAlertAction actionWithTitle:@"STEPPER" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NCNotificationManagementAlertController *alertController = [[%c(NCNotificationManagementAlertController) alloc] initWithRequest:requestToProcess withPresentingView:nil settingsDelegate:nil];
        CGFloat margin = 4.0F;
        
        [alertController setTitle:SNOOZEU];
        //UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIHoursStepper *picker = [[UIHoursStepper alloc] initWithFrame:CGRectMake(10 + alertController.view.bounds.origin.x, 80, alertController.view.frame.size.width - margin * 4.0F - 20, 50)];
        //[picker setDatePickerMode:UIDatePickerModeDateAndTime];
        //[picker setMinuteInterval:15];
        //[picker setMinimumDate:[NSDate dateWithTimeInterval:900 sinceDate:[NSDate date]]];
        //[picker setMaximumDate:[NSDate dateWithTimeInterval:604800 sinceDate:requestToProcess.timestamp]];
        [alertController.view addSubview:picker];

        SButton *button = [SButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(10 + alertController.view.bounds.origin.x, alertController.view.bounds.origin.y + ((picker.frame.size.height+40) - 2) + 50, alertController.view.frame.size.width - margin * 4.0F - 20, 50);
        [button setBackgroundColor:[UIColor systemBlueColor]];
        [button setTitle:SNOOZE forState:UIControlStateNormal];
        //[button setTitle:@"Snooze" forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:19];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.request = requestToProcess;
        button.controllerToDismiss = alertController;
        //button.pickerDate = picker.date;
        button.cell = cellToCapture;
        button.grouped = grouped;
        [button addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(buttonUpCancel:) forControlEvents:UIControlEventTouchDragExit];
        [button addTarget:self action:@selector(buttonUp:) forControlEvents:UIControlEventTouchUpInside];
        button.layer.cornerRadius = 10.5;
        [alertController.view addSubview:button];

        UIImageView *myImage = [[UIImageView alloc] init];
        myImage.image = [self imageWithView:cellToCapture];
        double widthInPoints = myImage.image.size.width;
        double heightInPoints = myImage.image.size.height;
        [myImage setFrame:CGRectMake(0, 0, widthInPoints, heightInPoints)];
        myImage.contentMode = UIViewContentModeScaleAspectFit;
        
        SButton *button2 = [SButton buttonWithType:UIButtonTypeSystem];
        button2.frame = CGRectMake(10 + alertController.view.bounds.origin.x , alertController.view.bounds.origin.y+50, alertController.view.frame.size.width - margin * 4.0F - 20, heightInPoints+10);

        if (grouped) {
            [myImage setFrame:CGRectMake(button2.bounds.origin.x, button2.bounds.origin.y, button2.bounds.size.width-15, button2.bounds.size.height)];
        } else {
            [myImage setFrame:CGRectMake(button2.bounds.origin.x, button2.bounds.origin.y, button2.bounds.size.width-30, button2.bounds.size.height)];
        }

        [button2 setBackgroundColor:[UIColor systemGrayColor]];
        [button2 setAlpha:0.1f];
        button2.layer.cornerRadius = 12.5;

        [alertController.view addSubview:button2];
        [alertController.view addSubview:myImage];
        myImage.center = button2.center;

        picker.center = CGPointMake(button.center.x, picker.center.y+50+heightInPoints);

        #pragma mark stepper "cell"
        UIView *stepperFrame = [[UIView alloc] initWithFrame:CGRectMake(10 + alertController.view.bounds.origin.x , alertController.view.bounds.origin.y+60+(heightInPoints+10), alertController.view.frame.size.width - margin * 4.0F - 20, 50)];
        [stepperFrame setBackgroundColor:[UIColor systemGrayColor]];
        [stepperFrame setAlpha:0.1];
        stepperFrame.layer.cornerRadius = 12.5;
        UIStepper *stepper = [[UIStepper alloc] init];
        [alertController.view addSubview:stepperFrame];
        //[alertController.view addSubview:stepper];
        CGFloat stepperMargin = CGRectGetHeight(stepperFrame.frame)-CGRectGetHeight(stepper.frame);
UIStackView *stackView = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, stepperFrame.frame.size.width - stepperMargin, stepperFrame.frame.size.width)];
stackView.axis = UILayoutConstraintAxisHorizontal;
stackView.center = stepperFrame.center;
stackView.distribution = UIStackViewDistributionEqualSpacing;
stackView.alignment = UIStackViewAlignmentCenter;
        CGFloat stepperX = CGRectGetWidth(stepperFrame.frame)-CGRectGetWidth(stepper.frame)-stepperMargin;
        CGFloat stepperY = stepperFrame.frame.origin.y+(CGRectGetHeight(stepperFrame.frame)-CGRectGetHeight(stepper.frame)-stepperMargin);
        //stepper.frame = CGRectMake(stepperX+stepperMargin, stepperY, 0, 0);
        CGFloat stepperLabelY = (CGRectGetHeight(stepperFrame.frame)/2)-(CGRectGetHeight(stepper.frame)/2);
        UILabel *stepperLabel = [[UILabel alloc] initWithFrame:CGRectMake(stepperFrame.frame.origin.x+stepperMargin, stepperFrame.frame.origin.y-stepperLabelY*2, stepperFrame.frame.size.width-stepperMargin, stepperFrame.frame.size.height-(stepperLabelY-stepperFrame.frame.size.height))];
        //[alertController.view addSubview:stepperLabel];
        stepperLabel.text = @"TEST";
        [stackView addArrangedSubview:stepperLabel];
        [stackView addArrangedSubview:stepper];
        [alertController.view addSubview:stackView];

        button.frame = CGRectMake(10 + alertController.view.bounds.origin.x, alertController.view.bounds.origin.y + (picker.frame.size.height+20) + stepperFrame.frame.size.height + button2.frame.size.height, alertController.view.frame.size.width - margin * 4.0F - 20, 50);
        UIPopoverPresentationController *popoverController = alertController.popoverPresentationController;
        popoverController.sourceView = alertController.view;
        popoverController.sourceRect = [alertController.view bounds];

        [alertController.view addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:alertController.view attribute:NSLayoutAttributeBottomMargin multiplier:1.0 constant:-76.0f]];

        [alertController addAction:[UIAlertAction actionWithTitle:CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        }]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
    }]];*/

    [alert addAction:[UIAlertAction actionWithTitle:CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        #pragma mark pill view
        /*UIFont *boldFont = [UIFont boldSystemFontOfSize:13.0f];
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
        NSMutableAttributedString *attributedSnoozedForUntilLabel = [[NSMutableAttributedString alloc] initWithString:fMINUTES attributes:attribsSnoozedLabel];
        pillSnoozedForUntilLabel.attributedText = attributedSnoozedForUntilLabel;
        pillSnoozedForUntilLabel.textAlignment = NSTextAlignmentCenter;
        pillSnoozedForUntilLabel.textColor = [UIColor systemBlueColor];
        CGSize expectedSnoozedForUntilLabelSize = [fMINUTES sizeWithAttributes:@{NSFontAttributeName:boldFont}];
        pillSnoozedForUntilLabel.frame = CGRectMake(pillSnoozedForUntilLabel.frame.origin.x,pillSnoozedForUntilLabel.frame.origin.y,expectedSnoozedForUntilLabelSize.width,expectedSnoozedForUntilLabelSize.height);
""
        UILabel *pillTapToChangeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,25.6667,100,15.6667)];
        NSDictionary *attribsTapToChangeLabel = @{
                          NSForegroundColorAttributeName:[UIColor tertiaryLabelColor],
                          NSFontAttributeName:boldFont
                          };
        NSMutableAttributedString *attributedTapToChangeText = [[NSMutableAttributedString alloc] initWithString:TAPCHANGE attributes:attribsSnoozedLabel];
        pillTapToChangeLabel.attributedText = attributedTapToChangeText;
        pillTapToChangeLabel.textAlignment = NSTextAlignmentCenter;
        pillTapToChangeLabel.textColor = [UIColor tertiaryLabelColor];
        UIWindow *window;
        for (int i=0; i<([[UIApplication sharedApplication].windows count]-1); i++) {
            if ([[UIApplication sharedApplication].windows[i] isMemberOfClass:[%c(SBCoverSheetWindow) class]]) {
                window = [UIApplication sharedApplication].windows[i];
                break;
            }
        }
        [window addSubview:view];
        [view addSubview:pillSnoozedLabel];
        [view addSubview:pillSnoozedForUntilLabel];
        [view addSubview:pillTapToChangeLabel];
        [view addSubview:pillViewButton];
        CGFloat combinedSize;
        view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
        //pillSnoozedLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedLabel.center.y);
        //pillSnoozedForUntilLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedForUntilLabel.center.y);
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
        [UIView animateWithDuration:0.33f animations:^{
            view.frame = CGRectMake(0,44,196,50);
            view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
            //pillSnoozedLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedLabel.center.y);
            //pillSnoozedForUntilLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedForUntilLabel.center.y);
            pillTapToChangeLabel.center = CGPointMake(view.frame.size.width/2, pillTapToChangeLabel.center.y);
        } completion:^(BOOL finished) {
            [NSTimer scheduledTimerWithTimeInterval:2.0f
                target:[NSBlockOperation blockOperationWithBlock:^{
                    [UIView animateWithDuration:0.33f animations:^{
                        view.frame = CGRectMake(0,-56,196,50);
                        view.center = CGPointMake([UIApplication sharedApplication].keyWindow.center.x, view.center.y);
                        //pillSnoozedLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedLabel.center.y);
                        //pillSnoozedForUntilLabel.center = CGPointMake(view.frame.size.width/2, pillSnoozedForUntilLabel.center.y);
                        pillTapToChangeLabel.center = CGPointMake(view.frame.size.width/2, pillTapToChangeLabel.center.y);
                    } completion:^(BOOL finished) {
                        [view removeFromSuperview];
                    }];
                }]
                selector:@selector(main)
                userInfo:nil
                repeats:NO
            ];
        }];*/
    }]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];

    // That's how you should do it in iOS 13.
    /*for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow) {
            [alert addAction:[UIAlertAction actionWithTitle:CANCEL style:UIAlertActionStyleCancel handler:nil]];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
            break;
        }
    }*/
}

%new
- (UIImage *) imageWithView:(UIView *)viewB {
    NCNotificationListView *superView = (NCNotificationListView *)viewB.superview;
    UIView *view;

    if (superView.grouped) {
        view = superView;
    } else {
        view = viewB;
    }

    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:view.bounds.size];
	
	UIImage *imageRender = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
	}];

	renderer = nil;
    return imageRender;
}

%new
-(NSDate *)getDatePickerValue:(UIDatePicker *)sender {
    return [sender date];
}

%new
-(void)tappedToChange:(UIButton *)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.miwix.selenium.menu" object:nil userInfo:info];
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
-(void)buttonUp:(id)sender {
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
            if (![request.content.header containsString:SNOOZED]) {
                NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", request.content.header, SNOOZED];
                [request.content setValue:newTitle forKey:@"_header"];
            }
            processEntry(request, -1, senderFix.pickerDate);
        }
        /*NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:senderFix.pickerDate
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             for (NCNotificationRequest *request in reqsArray) {
                                                                processEntry(request, 0, nil);
                                                             }
                                                             [[AXNManager sharedInstance] showNotificationRequests:reqsArray];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];*/
        NSDictionary* userInfo = @{@"requests" : reqsArray, @"grouped" : [NSNumber numberWithBool:senderFix.grouped]};
        PCSimpleTimer *timerShow = [[PCSimpleTimer alloc] initWithFireDate:senderFix.pickerDate
                            serviceIdentifier:@"com.miwix.selenium.service"
                            target:self
                            selector:@selector(timerOperations:)
                            userInfo:userInfo];
        [timerShow scheduleInRunLoop:[NSRunLoop mainRunLoop]];
    } else {
        [[AXNManager sharedInstance] hideNotificationRequest:senderFix.request];
        if (![senderFix.request.content.header containsString:SNOOZED]) {
            NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", senderFix.request.content.header, SNOOZED];
            [senderFix.request.content setValue:newTitle forKey:@"_header"];
        }
        #pragma mark PCPersistentTimer setup
        NSDictionary* userInfo = @{@"request" : senderFix.request, @"grouped" : [NSNumber numberWithBool:senderFix.grouped]};
        PCSimpleTimer *timerShow = [[PCSimpleTimer alloc] initWithFireDate:senderFix.pickerDate
                            serviceIdentifier:@"com.miwix.selenium.service"
                            target:self
                            selector:@selector(timerOperations:)
                            userInfo:userInfo];
        [timerShow scheduleInRunLoop:[NSRunLoop mainRunLoop]];

        #pragma mark NSTimer
        /*NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:senderFix.pickerDate
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             processEntry(senderFix.request, 0, nil);
                                                             [[AXNManager sharedInstance] showNotificationRequest:senderFix.request];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];*/

        processEntry(senderFix.request, -1, senderFix.pickerDate);

        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }

}

#pragma mark PCPersistentTimer selector
%new
-(void)timerOperations:(id)timer {
    NSDictionary* userInfo = [(PCSimpleTimer *)timer userInfo];
    if (userInfo[@"grouped"]) {
        for (NCNotificationRequest *request in userInfo[@"requests"]) {
            processEntry(request, 0, nil);
        }
        [[AXNManager sharedInstance] showNotificationRequests:userInfo[@"requests"]];
    } else {
        NCNotificationRequest *request = (NCNotificationRequest *)userInfo[@"request"];
        processEntry(request, 0, nil);
        [[AXNManager sharedInstance] showNotificationRequest:request];
    }
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
            NSString *timestampString = [NSString stringWithFormat:@"%@", entry[@"timeStamp"]];
            if ([timestampString isEqualToString:@"-2"]) {
                [[AXNManager sharedInstance] showNotificationRequest:(NCNotificationRequest *)entry[@"id"]];
                processEntry((NCNotificationRequest *)entry[@"id"], 0, nil);
            }
        }
    }
    return %orig;
}
%end*/

%hook CSNotificationDispatcher
- (void)postNotificationRequest:(NCNotificationRequest *)arg1 {
    NSMutableDictionary *config = [[[NSUserDefaults standardUserDefaults] objectForKey:@"dictionaryKey"] mutableCopy];
    NSString *req = [NSString stringWithFormat:@"%@", arg1];
    NSMutableArray *entries = [config[@"entries"] mutableCopy];
    for (NSMutableDictionary *entry in entries) {
        NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@";"] mutableCopy];
        [parts removeObject:parts[0]];
        NSString *combinedparts = [parts componentsJoinedByString:@";"];
        if ([req containsString:combinedparts]) {
            NCNotificationRequest *argFix = arg1;
            NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", argFix.content.header, SNOOZED];
            [argFix.content setValue:newTitle forKey:@"_header"];
            %orig(argFix);
            [[AXNManager sharedInstance] hideNotificationRequest:argFix];
            secondsLeft = [entry[@"timeStamp"] doubleValue] - [[NSDate date] timeIntervalSince1970] + 1;
            NSDictionary* userInfo = @{@"request" : argFix};
            PCSimpleTimer *timerShow = [[PCSimpleTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:secondsLeft]
                                serviceIdentifier:@"com.miwix.selenium.service"
                                target:self
                                selector:@selector(timerOperations:)
                                userInfo:userInfo];
            [timerShow scheduleInRunLoop:[NSRunLoop mainRunLoop]];
            /*NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:secondsLeft]
                                                          interval:nil
                                                           repeats:NO
                                                             block:(void (^)(NSTimer *timer))^{
                                                                 processEntry(argFix, 0, nil);
                                                                 [[AXNManager sharedInstance] showNotificationRequest:argFix];
                                                             }];
            [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];*/
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
            if (![argFix.content.header containsString:SNOOZED]) {
                NSString *newTitle = [NSString stringWithFormat:@"%@ • %@", argFix.content.header, SNOOZED];
                [argFix.content setValue:newTitle forKey:@"_header"];
            }
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
    processEntry(request, 0, nil);
    [[AXNManager sharedInstance] showNotificationRequest:request];
}
%end

%hook SBNCScreenController
-(void)turnOnScreenForNotificationRequest:(NCNotificationRequest *)arg1 {
    NSMutableDictionary *config = [[[NSUserDefaults standardUserDefaults] objectForKey:@"dictionaryKey"] mutableCopy];
    NSString *req = [NSString stringWithFormat:@"%@", arg1];
    NSMutableArray *entries = [config[@"entries"] mutableCopy];
    for (NSMutableDictionary *entry in entries) {
        NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@";"] mutableCopy];
        [parts removeObject:parts[0]];
        NSString *combinedparts = [parts componentsJoinedByString:@";"];
        if ([req containsString:combinedparts]) {
                secondsLeft = [entry[@"timeStamp"] doubleValue] - [[NSDate date] timeIntervalSince1970] + 1;
            [NSTimer scheduledTimerWithTimeInterval:secondsLeft
                                        target:[NSBlockOperation blockOperationWithBlock:^{%orig;}]
                                        selector:@selector(main)
                                        userInfo:nil
                                        repeats:NO
                                    ];
            return;
        }
    }
    %orig;
}
%end

%hook SBNCSoundController
-(void)playSoundForNotificationRequest:(id)arg1 presentingDestination:(id)arg2 {
    NSMutableDictionary *config = [[[NSUserDefaults standardUserDefaults] objectForKey:@"dictionaryKey"] mutableCopy];
    NSString *req = [NSString stringWithFormat:@"%@", arg1];
    NSMutableArray *entries = [config[@"entries"] mutableCopy];
    for (NSMutableDictionary *entry in entries) {
        NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@";"] mutableCopy];
        [parts removeObject:parts[0]];
        NSString *combinedparts = [parts componentsJoinedByString:@";"];
        if ([req containsString:combinedparts]) {
                secondsLeft = [entry[@"timeStamp"] doubleValue] - [[NSDate date] timeIntervalSince1970] + 1;
            [NSTimer scheduledTimerWithTimeInterval:secondsLeft
                                        target:[NSBlockOperation blockOperationWithBlock:^{%orig;}]
                                        selector:@selector(main)
                                        userInfo:nil
                                        repeats:NO
                                    ];
            return;
        }
    }
    %orig;
}
%end

%hook SBNotificationBannerDestination
-(void)_postNotificationRequest:(id)arg1 modal:(BOOL)arg2 completion:(/*^block*/id)arg3 {
    NSMutableDictionary *config = [[[NSUserDefaults standardUserDefaults] objectForKey:@"dictionaryKey"] mutableCopy];
    NSString *req = [NSString stringWithFormat:@"%@", arg1];
    NSMutableArray *entries = [config[@"entries"] mutableCopy];
    for (NSMutableDictionary *entry in entries) {
        NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@";"] mutableCopy];
        [parts removeObject:parts[0]];
        NSString *combinedparts = [parts componentsJoinedByString:@";"];
        if ([req containsString:combinedparts]) {
                secondsLeft = [entry[@"timeStamp"] doubleValue] - [[NSDate date] timeIntervalSince1970] + 1;
            [NSTimer scheduledTimerWithTimeInterval:secondsLeft
                                        target:[NSBlockOperation blockOperationWithBlock:^{%orig;}]
                                        selector:@selector(main)
                                        userInfo:nil
                                        repeats:NO
                                    ];
            return;
        }
    }
    %orig;
}
%end
%end

@interface NCNotificationContentView : NSObject
@end

@interface UIView (Private)
-(NSArray *)allSubviews;
@end

%group AxonVertical
%hook NCNotificationCombinedListViewController
%property (nonatomic,assign) BOOL axnAllowChanges;

-(UIEdgeInsets)insetMargins {
    if (verticalPosition == 0) return UIEdgeInsetsMake(0, -96, 0, 0);
    else return UIEdgeInsetsMake(0, 0, 0, -96);
}

-(CGSize)collectionView:(UICollectionView *)arg1 layout:(UICollectionViewLayout*)arg2 sizeForItemAtIndexPath:(id)arg3 {
    CGSize orig = %orig;
    UIView *view = [arg1 cellForItemAtIndexPath:arg3].contentView;
    for(id item in view.allSubviews) {
      if([item isKindOfClass:[objc_getClass("NCNotificationContentView") class]]) {
        return CGSizeMake(orig.width - 96, ((UIView *)item).frame.size.height+30);
      }
    }
    return CGSizeMake(orig.width - 96, orig.height);
}
%end

// iOS 13 Support
%hook NCNotificationStructuredListViewController
%property (nonatomic,assign) BOOL axnAllowChanges;
-(UIEdgeInsets)insetMargins {
    if (verticalPosition == 0) return UIEdgeInsetsMake(0, -96, 0, 0);
    else return UIEdgeInsetsMake(0, 0, 0, -96);
}
%end
%end

%group AxonHorizontal
%hook SBDashBoardCombinedListViewController
-(void)viewDidLoad{
    %orig;
    [AXNManager sharedInstance].sbclvc = self;
}
%end

// iOS 13 Support
%hook CSCombinedListViewController
-(void)viewDidLoad{
    %orig;
    [AXNManager sharedInstance].sbclvc = self;
}
%end
%end

/* Hide all notifications on open. */

static void displayStatusChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[AXNManager sharedInstance].view reset];
    [[AXNManager sharedInstance].view refresh];
}

static void *observer = NULL;

static void reloadPrefs() 
{
    if ([NSHomeDirectory() isEqualToString:@"/var/mobile"]) 
    {
        CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

        if (keyList) 
        {
            prefs = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, (CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));

            if (!prefs) 
            {
                prefs = [NSDictionary new];
            }
            CFRelease(keyList);
        }
    } 
    else 
    {
        prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
    }
}


static BOOL boolValueForKey(NSString *key, BOOL defaultValue) 
{
    return (prefs && [prefs objectForKey:key]) ? [[prefs objectForKey:key] boolValue] : defaultValue;
}

static void preferencesChanged() 
{
    CFPreferencesAppSynchronize((CFStringRef)kIdentifier);
    reloadPrefs();

    enabled = boolValueForKey(@"Enabled", YES);
    enabledForDND = boolValueForKey(@"Enabled", NO);
    vertical = boolValueForKey(@"Vertical", NO);
    hapticFeedback = boolValueForKey(@"HapticFeedback", YES);
    badgesEnabled = boolValueForKey(@"BadgesEnabled", YES);
    badgesShowBackground = boolValueForKey(@"BadgesShowBackground", YES);
    darkMode = boolValueForKey(@"DarkMode", NO);
    sortingMode = [prefs objectForKey:@"SortingMode"] ? [[prefs valueForKey:@"SortingMode"] intValue] : 0;
    selectionStyle = [prefs objectForKey:@"SelectionStyle"] ? [[prefs valueForKey:@"SelectionStyle"] intValue] : 0;
    style = [prefs objectForKey:@"Style"] ? [[prefs valueForKey:@"Style"] intValue] : 0;
    showByDefault = [prefs objectForKey:@"ShowByDefault"] ? [[prefs valueForKey:@"ShowByDefault"] intValue] : 0;
    alignment = [prefs objectForKey:@"Alignment"] ? [[prefs valueForKey:@"Alignment"] intValue] : 0;
    verticalPosition = [prefs objectForKey:@"VerticalPosition"] ? [[prefs valueForKey:@"VerticalPosition"] intValue] : 0;
    spacing = [prefs objectForKey:@"Spacing"] ? [[prefs valueForKey:@"Spacing"] floatValue] : 10.0;
    fadeEntireCell = boolValueForKey(@"FadeCell", YES);
    //BOOL dynamicBadges = boolValueForKey(@"dynamicBadges", YES);

    //[AXNManager sharedInstance].style = style;
    //[AXNManager sharedInstance].fadeEntireCell = fadeEntireCell;
    //[AXNManager sharedInstance].dynamicBadges = dynamicBadges;


    updateViewConfiguration();
}

%ctor{
    preferencesChanged();
    
    NSLog(@"[Selenium] init");

    #pragma mark localized strings
    tweakBundle = [NSBundle bundleWithPath:@"/Library/Application Support/SeleniumExtra.bundle"];
    SNOOZEN = [tweakBundle localizedStringForKey:@"SNOOZEN" value:@"" table:nil];
    SNOOZENS = [tweakBundle localizedStringForKey:@"SNOOZENS" value:@"" table:nil];
    SNOOZE = [tweakBundle localizedStringForKey:@"SNOOZE" value:@"" table:nil];
    SNOOZED = [tweakBundle localizedStringForKey:@"SNOOZED" value:@"" table:nil];
    fMINUTES = [tweakBundle localizedStringForKey:@"fMINUTES" value:@"" table:nil];
    oneHOUR = [tweakBundle localizedStringForKey:@"oneHOUR" value:@"" table:nil];
    fourHOURS = [tweakBundle localizedStringForKey:@"fourHOURS" value:@"" table:nil];
    eightHOURS = [tweakBundle localizedStringForKey:@"eightHOURS" value:@"" table:nil];
    sTIME = [tweakBundle localizedStringForKey:@"sTIME" value:@"" table:nil];
    SNOOZEU = [tweakBundle localizedStringForKey:@"SNOOZEU" value:@"" table:nil];
    CANCEL = [tweakBundle localizedStringForKey:@"CANCEL" value:@"" table:nil];
    TAPCHANGE = [tweakBundle localizedStringForKey:@"TAPCHANGE" value:@"" table:nil];

    #pragma mark my addition
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"dictionaryKey"] isKindOfClass:[%c(NSDictionary) class]]) {
        //[manager createFileAtPath:configPath contents:nil attributes:attributes];
        NSMutableDictionary *configInitial = [@{@"entries":@[],@"DND":@[],@"location":@[],@"snoozedCache":@[],@"DNDEnabled":@NO} mutableCopy];
        [[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionaryWithDictionary:configInitial] forKey:@"dictionaryKey"];
        NSLog(@"[Selenium] IF");
        NSLog(@"[Selenium] configInitial:%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"dictionaryKey"]);
    } else {
        NSLog(@"[Selenium] ELSE");
        NSLog(@"[Selenium] config:%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"dictionaryKey"]);
    }

    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        &observer,
        (CFNotificationCallback)preferencesChanged,
        (CFStringRef)@"com.miwix.selenium/ReloadPrefs",
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );

    if (enabled) {
        %init(Axon);
        if (!vertical) {
            %init(AxonHorizontal);
        } else {
            %init(AxonVertical);
        }
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, displayStatusChanged, CFSTR("com.apple.iokit.hid.displayStatus"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        return;
    }

    /*NSString *path = @"/var/mobile/Library/Selenium/config.plist";
    NSString *pathDefault = @"/Library/PreferenceBundles/AutoRedial.bundle/defaults.plist";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        [fileManager copyItemAtPath:pathDefault toPath:path error:nil];
    }*/


    //CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, setDuneEnabled, CFSTR("xyz.skitty.dune.enabled"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    //CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, setDuneDisabled, CFSTR("xyz.skitty.dune.disabled"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
