#import "Tweak.h"
#import "AXNManager.h"

BOOL dpkgInvalid = NO;
BOOL initialized = NO;
BOOL enabled;
//BOOL enabledForDND; // DND START
NSInteger segmentInterval;

NSDictionary *prefs = nil;

#pragma mark localized strings
static NSBundle *tweakBundle;
static NSString *SNOOZEN;
static NSString *SNOOZENS;
static NSString *SNOOZE;
static NSString *SNOOZED;
static NSString *fMINUTES;
static NSString *tMINUTES;
static NSString *ffMINUTES;
static NSString *oneHOUR;
static NSString *fourHOURS;
static NSString *eightHOURS;
static NSString *sTIME;
static NSString *SNOOZEU;
static NSString *SNOOZEF;
static NSString *CANCEL;
static NSString *TAPCHANGE;
static NSString *STEPPER;

%group Selenium

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

#pragma mark Notification management

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

static NSDictionary *notifInfo;

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
    notifInfo = @{@"id": reqToBeSnoozed, @"cell": snoozedCell};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.miwix.selenium.menu" object:nil userInfo:notifInfo];
}
%end

//static double minutesLeft;
static double secondsLeft;

static NSString *configPath = @"/var/mobile/Library/Selenium/manager.plist";
//NSMutableDictionary *config = [[[NSUserDefaults standardUserDefaults] objectForKey:@"dictionaryKey"] mutableCopy];
//static NSString *configPath = @"/Library/Application Support/Selenium/manager.plist";
static NSMutableDictionary *config;

static void storeSnoozed(NCNotificationRequest *request, BOOL shouldRemove, BOOL dnd) {
  //NSMutableDictionary *config = [[[NSUserDefaults standardUserDefaults] objectForKey:@"dictionaryKey"] mutableCopy];
  NSString *req = [NSString stringWithFormat:@"%@", request];
  NSMutableArray *entries = [config[@"snoozedCache"] mutableCopy];
  bool add = YES;
  NSDictionary *remove = nil;
  for (NSMutableDictionary /*__strong*/ *entry in entries) {
    //entry = [entry mutableCopy];
    NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@";"] mutableCopy];
    [parts removeObject:parts[0]];
    NSString *combinedparts = [parts componentsJoinedByString:@";"];
    if ([req containsString:combinedparts]) {
        NSDate *removeDate = [[NSDate alloc] initWithTimeInterval:604800 sinceDate:[(NCNotificationRequest*)request timestamp]];
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
    NSDate *removeDate = [[NSDate alloc] initWithTimeInterval:604800 sinceDate:[(NCNotificationRequest*)request timestamp]];
    info = @{@"id": req, @"timeToRemove": removeDate, @"timeStamp": @(dnd ? -2 : 0)};
    [entries addObject:info];
  }
  [config setObject:entries forKey:@"snoozedCache"];
  [config writeToFile:configPath atomically:YES];
  config = [NSMutableDictionary dictionaryWithContentsOfFile:configPath];
  //[[NSUserDefaults standardUserDefaults] setObject:config forKey:@"dictionaryKey"];
}

static void processEntry(NCNotificationRequest *request, double interval, NSDate *inputDate) {
  //NSMutableDictionary *config = [[[NSUserDefaults standardUserDefaults] objectForKey:@"dictionaryKey"] mutableCopy];
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
    storeSnoozed(request, NO, (interval == -2) ? YES : NO);
    NSDictionary *info;
    if (interval < 0) {
        if (interval == -1)
        info = @{@"id": req, @"timeStamp": @([inputDate timeIntervalSince1970])};
        else if (interval == -2)
        info = @{@"id": req, @"timeStamp": [NSNumber numberWithDouble:interval]}; //reserved for options that are not time-based
    } else if (interval != 0) {
        info = @{@"id": req, @"timeStamp": @([[NSDate date] timeIntervalSince1970] + interval)};
    }
    if (info) {
      [entries addObject:info];
    }
  }
  [config setObject:entries forKey:@"entries"];
  [config writeToFile:configPath atomically:YES];
  config = [NSMutableDictionary dictionaryWithContentsOfFile:configPath];
  //[[NSUserDefaults standardUserDefaults] setObject:config forKey:@"dictionaryKey"];
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

@interface SpringBoard : UIApplication
@end

@interface SpringBoard ()
- (UIImage *) imageWithView:(UIView *)view;
-(NSDate *)getStepperValue:(NSNumber *)number;
@end

// Tried to replace NSTimer with PCPersistentTimer for better reliability, but that made it go to safe mode once in a while. More testing needed. Also, PCPersistentTimer is working accross reboots (even if the device is not jailbroken - it will fire.), so also need to disable that to prevent possible freezes (I assume).
// [Interesting feature: it has the ability to wake the device and perform the action if it is powered off at the time it is supposed to execute. has nothing to do with this tweak (that I can think of) but might come in handy in the future.] [Actually now that I think about it 2 months later, it could potentially be used to make notifications snoozing persistent through reboots even when in non-jailbroken modes (because 1st party apps notifications use this type of timer, such as alarms and reminders), but that would require a completly different implementation of the actual notification snoozing part. I tried to do this before and failed, and there's no much info on how notifications (BBBulletin, BBserver etc.) actually work. for this benfit alone, this would be way too much effort for me.]
@interface PCSimpleTimer : NSObject {
	NSRunLoop* _timerRunLoop;
}
-(id)userInfo;
-(void)scheduleInRunLoop:(id)arg1 ;
-(id)initWithFireDate:(id)arg1 serviceIdentifier:(id)arg2 target:(id)arg3 selector:(SEL)arg4 userInfo:(id)arg5 ;
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
@property (assign,nonatomic) SBAlertItem * alertItem;                                             //@synthesize alertItem=_alertItem - In the implementation block
-(void)setAlertItem:(SBAlertItem *)arg1 ;
@end

@interface SBRingerPillView : UIView
@end

@interface SBUIChevronView : UIView
-(void)setColor:(UIColor *)arg1 ;
-(void)setState:(long long)arg1 animated:(BOOL)arg2;
-(void)setAnimationDuration:(double)arg1 ;
@end

%hook CSCoverSheetViewController
-(void)viewDidDisappear:(BOOL)arg1 {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.miwix.selenium.donate" object:nil userInfo:nil];
    %orig;
}
%end

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDonateController:) name:@"com.miwix.selenium.donate" object:nil];

    config = [NSMutableDictionary dictionaryWithContentsOfFile:configPath];
    //NSMutableDictionary *config = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"dictionaryKey"] mutableCopy];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMuteMenu:) name:@"com.miwix.selenium.menu" object:nil];
    
    #pragma mark remove already snoozed notifications from entries
    NSMutableArray *entries = [config[@"entries"] mutableCopy];
    for (NSMutableDictionary *entry in entries) {
        if ([entry[@"timeStamp"] doubleValue] != -2) {
            if (([[NSDate date] timeIntervalSince1970] - [entry[@"timeStamp"] doubleValue]) >= 1 && [entry[@"timeStamp"] doubleValue] != -2) {
                NCNotificationRequest *expiredReq = entry[@"id"];
                processEntry(expiredReq, 0, nil);
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
            //[stackView.heightAnchor constraintEqualToAnchor:[donateController view].widthAnchor constant:50.0f].active = YES;
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
- (void)animateTransition:(id)transitionContext {
    UIViewController* firstVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController* secondVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView* containerView = [transitionContext containerView];
    UIView* firstView = firstVC.view;
    UIView* secondView = secondVC.view;
        [containerView addSubview:secondView];
        secondView.frame = (CGRect){
            containerView.frame.origin.x,
            containerView.frame.origin.y + containerView.frame.size.height,
            containerView.frame.size
        };
        firstView.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
        [UIView animateWithDuration:1.0 animations:^{
            secondView.frame = containerView.frame;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
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

    /*[alert addAction:[UIAlertAction actionWithTitle:@"Until DND is turned off" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (grouped){
            [[AXNManager sharedInstance] hideNotificationRequests:reqsArray];
        } else {
            [[AXNManager sharedInstance] hideNotificationRequest:requestToProcess];
            if (![requestToProcess.content.header containsString:@"DND"]) {
                NSString *newTitle = [NSString stringWithFormat:@"%@ · %@", requestToProcess.content.header, @"DND"];
                [requestToProcess.content setValue:newTitle forKey:@"_header"];
            }
            processEntry(requestToProcess, -2, nil);
        }
    }]];*/
    /*[alert addAction:[UIAlertAction actionWithTitle:@"Until I leave these location" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    [[AXNManager sharedInstance] hideNotificationRequest:requestToProcess];
    if (![requestToProcess.content.header containsString:SNOOZED]) {
        NSString *newTitle = [NSString stringWithFormat:@"%@ · %@", requestToProcess.content.header, SNOOZED];
        [requestToProcess.content setValue:newTitle forKey:@"_header"];
    }
    [NSTimer scheduledTimerWithTimeInterval:86400
                            target:[NSBlockOperation blockOperationWithBlock:^{processEntry(requestToProcess, 0, nil); [[AXNManager sharedInstance] showNotificationRequest:requestToProcess];}]
                            selector:@selector(main)
                            userInfo:nil
                            repeats:NO];
    processEntry(requestToProcess, 86400, nil);
    }]];*/
    [alert addAction:[UIAlertAction actionWithTitle:STEPPER style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NCNotificationManagementAlertController *alertController = [[%c(NCNotificationManagementAlertController) alloc] initWithRequest:requestToProcess withPresentingView:nil settingsDelegate:nil];
        CGFloat margin = 4.0F;
        
        [alertController setTitle:SNOOZEF];
        //UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIDatePicker *picker = [[UIDatePicker alloc] initWithFrame:CGRectMake(10 + alertController.view.bounds.origin.x, 80, alertController.view.frame.size.width - margin * 4.0F - 20, 50)];
        //[picker setDatePickerMode:UIDatePickerModeDateAndTime];
        //[picker setMinuteInterval:15];
        //[picker setMinimumDate:[NSDate dateWithTimeInterval:900 sinceDate:[NSDate date]]];
        //[picker setMaximumDate:[NSDate dateWithTimeInterval:604800 sinceDate:requestToProcess.timeStamp]];
        picker.hidden = YES;
        [alertController.view addSubview:picker];

        SButton *button = [SButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(10 + alertController.view.bounds.origin.x, alertController.view.bounds.origin.y + ((picker.frame.size.height+40) - 2) + 50, alertController.view.frame.size.width - margin * 4.0F - 20, 50);
        [button setBackgroundColor:[UIColor systemBlueColor]];
        [button setTitle:SNOOZE forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:19];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.request = requestToProcess;
        button.controllerToDismiss = alertController;
        button.cell = cellToCapture;
        button.grouped = grouped;
        [button addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(buttonUpCancel:) forControlEvents:UIControlEventTouchDragExit];
        [button addTarget:self action:@selector(stepperButtonUp:) forControlEvents:UIControlEventTouchUpInside];
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
        UIHoursStepper *stepper = [[UIHoursStepper alloc] init];
        stepper.minimumValue = 1; //15, 30, 45, 1, 2, 3, 4, 6, 8, 12
        stepper.maximumValue = 10;
        [stepper addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
        [alertController.view addSubview:stepperFrame];
        //[alertController.view addSubview:stepper];
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
        //[alertController.view addSubview:stepperLabel];
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"lastStepperLabelText"]) {
            stepperLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastStepperLabelText"];
            stepper.value = [(NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:@"lastStepperValue"] doubleValue];
        } else {
            stepperLabel.text = @"15 Minutes";
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

        button.stepperDate = [self performSelector:@selector(getStepperValue:) withObject:[NSNumber numberWithFloat:stepper.value]];
        button.stepper = stepper;
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
        [alertController.view addSubview:stackView];

        button.frame = CGRectMake(10 + alertController.view.bounds.origin.x, alertController.view.bounds.origin.y + (picker.frame.size.height+20) + stepperFrame.frame.size.height + button2.frame.size.height, alertController.view.frame.size.width - margin * 4.0F - 20, 50);
        UIPopoverPresentationController *popoverController = alertController.popoverPresentationController;
        popoverController.sourceView = alertController.view;
        popoverController.sourceRect = [alertController.view bounds];

        [alertController.view addConstraint:[NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:alertController.view attribute:NSLayoutAttributeBottomMargin multiplier:1.0 constant:-76.0f]];

        [alertController addAction:[UIAlertAction actionWithTitle:CANCEL style:UIAlertActionStyleCancel handler:nil]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:sTIME style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NCNotificationManagementAlertController *alertController = [[%c(NCNotificationManagementAlertController) alloc] initWithRequest:requestToProcess withPresentingView:nil settingsDelegate:nil];
        [alertController setTitle:SNOOZEF];
        //UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        NSLocale *locale = [NSLocale currentLocale];
        UIDatePicker *picker = [[UIDatePicker alloc] init];
        picker.locale = locale; 
        [picker setDatePickerMode:UIDatePickerModeDateAndTime];
        [picker setMinuteInterval:segmentInterval];
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
        for (char i=0; i<((60/segmentInterval)+1); i++) {
            if ([[NSDate date] timeIntervalSinceDate:minimumDate] < 0) {
                break;
            } else {
                minimumDate = [NSDate dateWithTimeInterval:(segmentInterval*60) sinceDate:minimumDate];
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

        UIViewController *test = [[UIViewController alloc] init];
        [[test view] setBackgroundColor:[UIColor whiteColor]];
        [test setModalPresentationStyle:UIModalPresentationPopover];

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

        button.pillView = view;
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
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
	static UIImage *imageRender;/* = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    }];*/

    if (view.alpha == 0) {
	    renderer = nil;
        return imageRender;
    } else {
        imageRender = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
            [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
        }];
	    renderer = nil;
        return imageRender;
    }

	renderer = nil;
    /*if (view.alpha != 1.0f) {
        NSCoder *imageBoundsData = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastCellImageBounds"];
        CGRect imageBounds = [imageBoundsData decodeCGRectForKey:@"cellRect"];
        static UIImage *imageFromDefaults = [UIImage imageWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"lastCellImageData"]];
        imageRender = [UIImage imageWithCGImage:CGImageCreateWithImageInRect([UIImage imageWithData:imageFromDefaults.CGImage, imageBounds) scale:imageFromDefaults.CGImage.scale orientation:imageFromDefaults.CGImage.imageOrientation];
        //imageRender = [UIImage imageWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"lastCellImageData"]];
    } else {
        NSData *imageData = UIImagePNGRepresentation(imageRender);
        [[NSUserDefaults standardUserDefaults] setObject:imageData forKey:@"lastCellImageData"];
        NSCoder *imageBoundsData;
        [imageBoundsData encodeCGRect:view.bounds forKey:@"cellRect"];
        [[NSUserDefaults standardUserDefaults] setObject:imageBoundsData forKey:@"lastCellImageBounds"];
    }*/
    return imageRender;
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
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = @"15 Minutes";
            break;
        case 2:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = @"30 Minutes";
            break;
        case 3:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = @"45 Minutes";
            break;
        case 4:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = @"1 Hour";
            break;
        case 5:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = @"2 Hours";
            break;
        case 6:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = @"3 Hours";
            break;
        case 7:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = @"4 Hours";
            break;
        case 8:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = @"6 Hours";
            break;
        case 9:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = @"8 Hours";
            break;
        case 10:
            [(NSArray<UILabel*>*)stepper.stepperLabel.arrangedSubviews firstObject].text = @"12 Hours";
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.miwix.selenium.menu" object:nil userInfo:notifInfo];
}

%new
-(void)buttonDonate:(UIButton *)sender {
    SButton *senderFix = sender;
    [senderFix.controllerToDismiss dismissViewControllerAnimated:YES completion:nil];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=DSAQ8SXMGFUNU&source=url"]];
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
        NSMutableArray *parts = [SNOOZEF componentsSeparatedByString:@" "];
        [parts removeObject:parts[0]];
        NSString *UNTIL = [parts componentsJoinedByString:@" "];
        NSMutableAttributedString *attributedSnoozedForUntilLabel = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@",UNTIL,[(NSArray<UILabel*>*)senderFix.stepper.stepperLabel.arrangedSubviews firstObject].text] attributes:attribsSnoozedLabel];
        pillSnoozedForUntilLabel.attributedText = attributedSnoozedForUntilLabel;
        pillSnoozedForUntilLabel.textAlignment = NSTextAlignmentCenter;
        pillSnoozedForUntilLabel.textColor = [UIColor systemBlueColor];
        CGSize expectedSnoozedForUntilLabelSize = [[NSString stringWithFormat:@"%@%@",UNTIL,[(NSArray<UILabel*>*)senderFix.stepper.stepperLabel.arrangedSubviews firstObject].text] sizeWithAttributes:@{NSFontAttributeName:boldFont}];
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
            if (![request.content.header containsString:SNOOZED]) {
                NSString *newTitle = [NSString stringWithFormat:@"%@ · %@", request.content.header, SNOOZED];
                [request.content setValue:newTitle forKey:@"_header"];
            }
            processEntry(request, -1, value);
        }
        NSDictionary* userInfo = @{@"requests" : reqsArray, @"grouped" : [NSNumber numberWithBool:senderFix.grouped]};
        PCSimpleTimer *timerShow = [[PCSimpleTimer alloc] initWithFireDate:value
                            serviceIdentifier:@"com.miwix.selenium.service"
                            target:self
                            selector:@selector(timerOperations:)
                            userInfo:userInfo];
        [timerShow scheduleInRunLoop:[NSRunLoop mainRunLoop]];
    } else {
        [[AXNManager sharedInstance] hideNotificationRequest:senderFix.request];
        if (![senderFix.request.content.header containsString:SNOOZED]) {
            NSString *newTitle = [NSString stringWithFormat:@"%@ · %@", senderFix.request.content.header, SNOOZED];
            [senderFix.request.content setValue:newTitle forKey:@"_header"];
        }
        #pragma mark PCPersistentTimer setup
        NSDictionary* userInfo = @{@"request" : senderFix.request, @"grouped" : [NSNumber numberWithBool:senderFix.grouped]};
        PCSimpleTimer *timerShow = [[PCSimpleTimer alloc] initWithFireDate:value
                            serviceIdentifier:@"com.miwix.selenium.service"
                            target:self
                            selector:@selector(timerOperations:)
                            userInfo:userInfo];
        [timerShow scheduleInRunLoop:[NSRunLoop mainRunLoop]];

        processEntry(senderFix.request, -1, value);
    }
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
                NSString *newTitle = [NSString stringWithFormat:@"%@ · %@", request.content.header, SNOOZED];
                [request.content setValue:newTitle forKey:@"_header"];
            }
            processEntry(request, -1, senderFix.pickerDate);
        }
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
            NSString *newTitle = [NSString stringWithFormat:@"%@ · %@", senderFix.request.content.header, SNOOZED];
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

        processEntry(senderFix.request, -1, senderFix.pickerDate);
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
            NSString *timeStampString = [NSString stringWithFormat:@"%@", entry[@"timeStamp"]];
            if ([timeStampString isEqualToString:@"-2"]) {
                [[AXNManager sharedInstance] showNotificationRequest:(NCNotificationRequest *)entry[@"id"]];
                processEntry((NCNotificationRequest *)entry[@"id"], 0, nil);
            }
        }
    }
    return %orig;
}
%end*/ //DND START

%hook CSNotificationDispatcher
- (void)postNotificationRequest:(NCNotificationRequest *)arg1 {
    /*if (isEnabledForDND && isDNDEnabled && [arg1.timestamp compare:config[@"DNDStartTime"]] == NSOrderedDescending && ![[arg1.content.header lowercaseString] isEqualToString:@"do not disturb"]) {
        NCNotificationRequest *argFix = arg1;
        NSString *newTitle = [NSString stringWithFormat:@"%@ · %@", argFix.content.header, @"DND"];
        [argFix.content setValue:newTitle forKey:@"_header"];
        %orig(argFix);
        [[AXNManager sharedInstance] hideNotificationRequest:argFix];
        processEntry(argFix, -2, nil);
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
                NSString *newTitle = [NSString stringWithFormat:@"%@ · %@", arg1.content.header, @"DND"];
                [argFix.content setValue:newTitle forKey:@"_header"];
                %orig(argFix);
                [[AXNManager sharedInstance] hideNotificationRequest:argFix];
            } else {
                NCNotificationRequest *argFix = arg1;
                NSString *newTitle = [NSString stringWithFormat:@"%@ · %@", argFix.content.header, SNOOZED];
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
                    NSString *newTitle = [NSString stringWithFormat:@"%@ · %@", argFix.content.header, @"DND"];
                    [argFix.content setValue:newTitle forKey:@"_header"];
                }
            } else {*/
                if (![argFix.content.header containsString:SNOOZED]) {
                    NSString *newTitle = [NSString stringWithFormat:@"%@ · %@", argFix.content.header, SNOOZED];
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
    processEntry(request, 0, nil);
    [[AXNManager sharedInstance] showNotificationRequest:request];
}
%end

// Controls whether the screen should wake up for a notification when it is arriving. Doesn't have much use now, but will be useful for DND.
/*%hook SBNCScreenController
-(void)turnOnScreenForNotificationRequest:(NCNotificationRequest *)arg1 {
    //NSMutableDictionary *config = [[[NSUserDefaults standardUserDefaults] objectForKey:@"dictionaryKey"] mutableCopy];
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

// Controls whether a sound will be played (and what sound) for a notification when it is arriving. Doesn't have much use now, but will be useful for DND.
%hook SBNCSoundController
-(void)playSoundForNotificationRequest:(id)arg1 presentingDestination:(id)arg2 {
    //NSMutableDictionary *config = [[[NSUserDefaults standardUserDefaults] objectForKey:@"dictionaryKey"] mutableCopy];
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

// Displays a banner for a notification when it is arriving. Doesn't have much use now.
%hook SBNotificationBannerDestination
-(void)_postNotificationRequest:(id)arg1 modal:(BOOL)arg2 completion:(id)arg3 {
    //NSMutableDictionary *config = [[[NSUserDefaults standardUserDefaults] objectForKey:@"dictionaryKey"] mutableCopy];
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
%end*/
%end

%group AxonFix // Trying to fix Axon compatibility issues
%hook AXNManager
-(NSInteger)countForBundleIdentifier:(NSString *)bundleIdentifier {
    NSMutableArray *allNotifs = [config[@"entries"] mutableCopy];
    unsigned int count = 0;
    for (id entry in allNotifs) {
        NSArray *sectionId = [entry[@"id"] componentsSeparatedByString:@"sectionId: "];
        NSMutableArray *parts = [[sectionId[1] componentsSeparatedByString:@"; "] mutableCopy];
        NSString *snoozedBundleID = (NSString*)parts[0];
        NSLog(@"[AXNCOUNT] bundleIdentifier: %@ snoozedBundleID: %@",bundleIdentifier,snoozedBundleID);
        if ([bundleIdentifier isEqualToString:snoozedBundleID]) count++;
    }

    NSLog(@"[AXNCOUNT] bundleID: %@", bundleIdentifier);
    if (%orig(bundleIdentifier)-count < 0)
    return 0;
    else
    return %orig(bundleIdentifier)-count;
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
}

-(void)hideNotificationRequest:(id)req {
    %orig;
    [self updateCountForBundleIdentifier:[(NCNotificationRequest*)req sectionIdentifier]];
    [self.view refresh];
}
%end
%end

static void loadPrefs() {
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.miwix.seleniumprefs.plist"];
    if ( [prefs objectForKey:@"TweakisEnabled"] ? [[prefs objectForKey:@"TweakisEnabled"] boolValue] : YES ) {
		enabled = YES;
		segmentInterval = [[prefs objectForKey:@"segmentInterval"] intValue];
	}
}

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
    fourHOURS = [tweakBundle localizedStringForKey:@"fourHOURS" value:@"" table:nil];
    eightHOURS = [tweakBundle localizedStringForKey:@"eightHOURS" value:@"" table:nil];
    sTIME = [tweakBundle localizedStringForKey:@"sTIME" value:@"" table:nil];
    SNOOZEU = [tweakBundle localizedStringForKey:@"SNOOZEU" value:@"" table:nil];
    SNOOZEF = [tweakBundle localizedStringForKey:@"SNOOZEF" value:@"" table:nil];
    CANCEL = [tweakBundle localizedStringForKey:@"CANCEL" value:@"" table:nil];
    TAPCHANGE = [tweakBundle localizedStringForKey:@"TAPCHANGE" value:@"" table:nil];
    STEPPER = [tweakBundle localizedStringForKey:@"STEPPER" value:@"" table:nil];

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
        %init(Selenium);
        %init(AxonFix);
        return;
    }

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.miwix.seleniumprefs/settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}
