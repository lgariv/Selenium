#line 1 "Tweak.xm"
#import "Tweak.h"
#import "AXNManager.h"
#import "CustomUIStepper.h"

BOOL dpkgInvalid = NO;
BOOL initialized = NO;
BOOL enabled;
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


#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

@class CSCombinedListViewController; @class NCNotificationListCellActionButtonsView; @class CSNotificationDispatcher; @class SBFStaticWallpaperView; @class NCNotificationCombinedListViewController; @class SBNotificationBannerDestination; @class SBNCSoundController; @class NCNotificationManagementAlertController; @class SBFLockScreenDateView; @class SBDashBoardCombinedListViewController; @class SBNCNotificationDispatcher; @class NCNotificationStructuredListViewController; @class SBNCScreenController; @class SpringBoard; @class PCPersistentTimer; 

static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$NCNotificationManagementAlertController(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("NCNotificationManagementAlertController"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$PCPersistentTimer(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("PCPersistentTimer"); } return _klass; }
#line 39 "Tweak.xm"
static SBFLockScreenDateView* (*_logos_orig$Axon$SBFLockScreenDateView$initWithFrame$)(_LOGOS_SELF_TYPE_INIT SBFLockScreenDateView*, SEL, CGRect) _LOGOS_RETURN_RETAINED; static SBFLockScreenDateView* _logos_method$Axon$SBFLockScreenDateView$initWithFrame$(_LOGOS_SELF_TYPE_INIT SBFLockScreenDateView*, SEL, CGRect) _LOGOS_RETURN_RETAINED; static void (*_logos_orig$Axon$SBFLockScreenDateView$setLegibilitySettings$)(_LOGOS_SELF_TYPE_NORMAL SBFLockScreenDateView* _LOGOS_SELF_CONST, SEL, _UILegibilitySettings *); static void _logos_method$Axon$SBFLockScreenDateView$setLegibilitySettings$(_LOGOS_SELF_TYPE_NORMAL SBFLockScreenDateView* _LOGOS_SELF_CONST, SEL, _UILegibilitySettings *); static SBNCNotificationDispatcher* (*_logos_orig$Axon$SBNCNotificationDispatcher$init)(_LOGOS_SELF_TYPE_INIT SBNCNotificationDispatcher*, SEL) _LOGOS_RETURN_RETAINED; static SBNCNotificationDispatcher* _logos_method$Axon$SBNCNotificationDispatcher$init(_LOGOS_SELF_TYPE_INIT SBNCNotificationDispatcher*, SEL) _LOGOS_RETURN_RETAINED; static void (*_logos_orig$Axon$SBNCNotificationDispatcher$setDispatcher$)(_LOGOS_SELF_TYPE_NORMAL SBNCNotificationDispatcher* _LOGOS_SELF_CONST, SEL, NCNotificationDispatcher *); static void _logos_method$Axon$SBNCNotificationDispatcher$setDispatcher$(_LOGOS_SELF_TYPE_NORMAL SBNCNotificationDispatcher* _LOGOS_SELF_CONST, SEL, NCNotificationDispatcher *); static NCNotificationCombinedListViewController* (*_logos_orig$Axon$NCNotificationCombinedListViewController$init)(_LOGOS_SELF_TYPE_INIT NCNotificationCombinedListViewController*, SEL) _LOGOS_RETURN_RETAINED; static NCNotificationCombinedListViewController* _logos_method$Axon$NCNotificationCombinedListViewController$init(_LOGOS_SELF_TYPE_INIT NCNotificationCombinedListViewController*, SEL) _LOGOS_RETURN_RETAINED; static bool (*_logos_orig$Axon$NCNotificationCombinedListViewController$insertNotificationRequest$forCoalescedNotification$)(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL, NCNotificationRequest *, id); static bool _logos_method$Axon$NCNotificationCombinedListViewController$insertNotificationRequest$forCoalescedNotification$(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL, NCNotificationRequest *, id); static bool (*_logos_orig$Axon$NCNotificationCombinedListViewController$removeNotificationRequest$forCoalescedNotification$)(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL, NCNotificationRequest *, id); static bool _logos_method$Axon$NCNotificationCombinedListViewController$removeNotificationRequest$forCoalescedNotification$(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL, NCNotificationRequest *, id); static bool (*_logos_orig$Axon$NCNotificationCombinedListViewController$modifyNotificationRequest$forCoalescedNotification$)(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL, NCNotificationRequest *, id); static bool _logos_method$Axon$NCNotificationCombinedListViewController$modifyNotificationRequest$forCoalescedNotification$(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL, NCNotificationRequest *, id); static bool (*_logos_orig$Axon$NCNotificationCombinedListViewController$hasContent)(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL); static bool _logos_method$Axon$NCNotificationCombinedListViewController$hasContent(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$Axon$NCNotificationCombinedListViewController$viewDidAppear$)(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$Axon$NCNotificationCombinedListViewController$viewDidAppear$(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$Axon$NCNotificationCombinedListViewController$_clearAllPriorityListNotificationRequests)(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$Axon$NCNotificationCombinedListViewController$_clearAllPriorityListNotificationRequests(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$Axon$NCNotificationCombinedListViewController$_clearAllNotificationRequests)(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$Axon$NCNotificationCombinedListViewController$_clearAllNotificationRequests(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$Axon$NCNotificationCombinedListViewController$clearAll)(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$Axon$NCNotificationCombinedListViewController$clearAll(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL); static id _logos_method$Axon$NCNotificationCombinedListViewController$axnNotificationRequests(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$Axon$NCNotificationCombinedListViewController$revealNotificationHistory$(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL, BOOL); static NCNotificationStructuredListViewController* (*_logos_orig$Axon$NCNotificationStructuredListViewController$init)(_LOGOS_SELF_TYPE_INIT NCNotificationStructuredListViewController*, SEL) _LOGOS_RETURN_RETAINED; static NCNotificationStructuredListViewController* _logos_method$Axon$NCNotificationStructuredListViewController$init(_LOGOS_SELF_TYPE_INIT NCNotificationStructuredListViewController*, SEL) _LOGOS_RETURN_RETAINED; static bool (*_logos_orig$Axon$NCNotificationStructuredListViewController$insertNotificationRequest$)(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST, SEL, NCNotificationRequest *); static bool _logos_method$Axon$NCNotificationStructuredListViewController$insertNotificationRequest$(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST, SEL, NCNotificationRequest *); static bool (*_logos_orig$Axon$NCNotificationStructuredListViewController$removeNotificationRequest$)(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST, SEL, NCNotificationRequest *); static bool _logos_method$Axon$NCNotificationStructuredListViewController$removeNotificationRequest$(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST, SEL, NCNotificationRequest *); static bool (*_logos_orig$Axon$NCNotificationStructuredListViewController$modifyNotificationRequest$)(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST, SEL, NCNotificationRequest *); static bool _logos_method$Axon$NCNotificationStructuredListViewController$modifyNotificationRequest$(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST, SEL, NCNotificationRequest *); static void (*_logos_orig$Axon$NCNotificationStructuredListViewController$viewDidAppear$)(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void _logos_method$Axon$NCNotificationStructuredListViewController$viewDidAppear$(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST, SEL, BOOL); static id _logos_method$Axon$NCNotificationStructuredListViewController$axnNotificationRequests(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST, SEL); static NSSet * _logos_method$Axon$NCNotificationStructuredListViewController$allNotificationRequests(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$Axon$NCNotificationStructuredListViewController$revealNotificationHistory$(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST, SEL, BOOL); static void (*_logos_orig$Axon$SBFStaticWallpaperView$_setDisplayedImage$)(_LOGOS_SELF_TYPE_NORMAL SBFStaticWallpaperView* _LOGOS_SELF_CONST, SEL, UIImage *); static void _logos_method$Axon$SBFStaticWallpaperView$_setDisplayedImage$(_LOGOS_SELF_TYPE_NORMAL SBFStaticWallpaperView* _LOGOS_SELF_CONST, SEL, UIImage *); static void (*_logos_orig$Axon$NCNotificationListCellActionButtonsView$layoutSubviews)(_LOGOS_SELF_TYPE_NORMAL NCNotificationListCellActionButtonsView* _LOGOS_SELF_CONST, SEL); static void _logos_method$Axon$NCNotificationListCellActionButtonsView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL NCNotificationListCellActionButtonsView* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$Axon$NCNotificationListCellActionButtonsView$configureCellActionButtonsForNotificationRequest$sectionSettings$cell$)(_LOGOS_SELF_TYPE_NORMAL NCNotificationListCellActionButtonsView* _LOGOS_SELF_CONST, SEL, id, id, id); static void _logos_method$Axon$NCNotificationListCellActionButtonsView$configureCellActionButtonsForNotificationRequest$sectionSettings$cell$(_LOGOS_SELF_TYPE_NORMAL NCNotificationListCellActionButtonsView* _LOGOS_SELF_CONST, SEL, id, id, id); static void _logos_method$Axon$NCNotificationListCellActionButtonsView$swipedUp$(_LOGOS_SELF_TYPE_NORMAL NCNotificationListCellActionButtonsView* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$Axon$SpringBoard$applicationDidFinishLaunching$)(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$Axon$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$Axon$SpringBoard$showMuteMenu$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, NSNotification *); static UIImage * _logos_method$Axon$SpringBoard$imageWithView$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, UIView *); static void _logos_method$Axon$SpringBoard$buttonDown$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, UIButton *); static void _logos_method$Axon$SpringBoard$buttonUpCancel$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, UIButton *); static void _logos_method$Axon$SpringBoard$buttonUp$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$Axon$SpringBoard$timerOperations$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, PCPersistentTimer *); static void (*_logos_orig$Axon$CSNotificationDispatcher$postNotificationRequest$)(_LOGOS_SELF_TYPE_NORMAL CSNotificationDispatcher* _LOGOS_SELF_CONST, SEL, NCNotificationRequest *); static void _logos_method$Axon$CSNotificationDispatcher$postNotificationRequest$(_LOGOS_SELF_TYPE_NORMAL CSNotificationDispatcher* _LOGOS_SELF_CONST, SEL, NCNotificationRequest *); static void (*_logos_orig$Axon$SBNCScreenController$turnOnScreenForNotificationRequest$)(_LOGOS_SELF_TYPE_NORMAL SBNCScreenController* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$Axon$SBNCScreenController$turnOnScreenForNotificationRequest$(_LOGOS_SELF_TYPE_NORMAL SBNCScreenController* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$Axon$SBNCSoundController$playSoundForNotificationRequest$presentingDestination$)(_LOGOS_SELF_TYPE_NORMAL SBNCSoundController* _LOGOS_SELF_CONST, SEL, id, id); static void _logos_method$Axon$SBNCSoundController$playSoundForNotificationRequest$presentingDestination$(_LOGOS_SELF_TYPE_NORMAL SBNCSoundController* _LOGOS_SELF_CONST, SEL, id, id); static void (*_logos_orig$Axon$SBNotificationBannerDestination$_postNotificationRequest$modal$completion$)(_LOGOS_SELF_TYPE_NORMAL SBNotificationBannerDestination* _LOGOS_SELF_CONST, SEL, id, BOOL, id); static void _logos_method$Axon$SBNotificationBannerDestination$_postNotificationRequest$modal$completion$(_LOGOS_SELF_TYPE_NORMAL SBNotificationBannerDestination* _LOGOS_SELF_CONST, SEL, id, BOOL, id); 

#pragma mark Legibility color



static SBFLockScreenDateView* _logos_method$Axon$SBFLockScreenDateView$initWithFrame$(_LOGOS_SELF_TYPE_INIT SBFLockScreenDateView* __unused self, SEL __unused _cmd, CGRect arg1) _LOGOS_RETURN_RETAINED {
    _logos_orig$Axon$SBFLockScreenDateView$initWithFrame$(self, _cmd, arg1);
    if (self.legibilitySettings && self.legibilitySettings.primaryColor) {
        [AXNManager sharedInstance].fallbackColor = [self.legibilitySettings.primaryColor copy];
    }
    return self;
}

static void _logos_method$Axon$SBFLockScreenDateView$setLegibilitySettings$(_LOGOS_SELF_TYPE_NORMAL SBFLockScreenDateView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, _UILegibilitySettings * arg1) {
    _logos_orig$Axon$SBFLockScreenDateView$setLegibilitySettings$(self, _cmd, arg1);
    if (self.legibilitySettings && self.legibilitySettings.primaryColor) {
        [AXNManager sharedInstance].fallbackColor = [self.legibilitySettings.primaryColor copy];
    }
}



#pragma mark Store dispatcher for future use



static SBNCNotificationDispatcher* _logos_method$Axon$SBNCNotificationDispatcher$init(_LOGOS_SELF_TYPE_INIT SBNCNotificationDispatcher* __unused self, SEL __unused _cmd) _LOGOS_RETURN_RETAINED {
    _logos_orig$Axon$SBNCNotificationDispatcher$init(self, _cmd);
    [AXNManager sharedInstance].dispatcher = self.dispatcher;
    return self;
}

static void _logos_method$Axon$SBNCNotificationDispatcher$setDispatcher$(_LOGOS_SELF_TYPE_NORMAL SBNCNotificationDispatcher* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NCNotificationDispatcher * arg1) {
    _logos_orig$Axon$SBNCNotificationDispatcher$setDispatcher$(self, _cmd, arg1);
    [AXNManager sharedInstance].dispatcher = arg1;
}



#pragma mark Inject the Axon view into NC

#pragma mark disabled












#pragma mark disabled






#pragma mark Notification management



__attribute__((used)) static BOOL _logos_method$Axon$NCNotificationCombinedListViewController$axnAllowChanges(NCNotificationCombinedListViewController * __unused self, SEL __unused _cmd) { NSValue * value = objc_getAssociatedObject(self, (void *)_logos_method$Axon$NCNotificationCombinedListViewController$axnAllowChanges); BOOL rawValue; [value getValue:&rawValue]; return rawValue; }; __attribute__((used)) static void _logos_method$Axon$NCNotificationCombinedListViewController$setAxnAllowChanges(NCNotificationCombinedListViewController * __unused self, SEL __unused _cmd, BOOL rawValue) { NSValue * value = [NSValue valueWithBytes:&rawValue objCType:@encode(BOOL)]; objc_setAssociatedObject(self, (void *)_logos_method$Axon$NCNotificationCombinedListViewController$axnAllowChanges, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }



static NCNotificationCombinedListViewController* _logos_method$Axon$NCNotificationCombinedListViewController$init(_LOGOS_SELF_TYPE_INIT NCNotificationCombinedListViewController* __unused self, SEL __unused _cmd) _LOGOS_RETURN_RETAINED {
    _logos_orig$Axon$NCNotificationCombinedListViewController$init(self, _cmd);
    [AXNManager sharedInstance].clvc = self;
    self.axnAllowChanges = NO;
    return self;
}



static bool _logos_method$Axon$NCNotificationCombinedListViewController$insertNotificationRequest$forCoalescedNotification$(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NCNotificationRequest * req, id arg2) {
    if (self.axnAllowChanges) return _logos_orig$Axon$NCNotificationCombinedListViewController$insertNotificationRequest$forCoalescedNotification$(self, _cmd, req, arg2);     
    [[AXNManager sharedInstance] insertNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) _logos_orig$Axon$NCNotificationCombinedListViewController$insertNotificationRequest$forCoalescedNotification$(self, _cmd, req, arg2);
    }

    if (![AXNManager sharedInstance].view.selectedBundleIdentifier && showByDefault == 1) {
        [[AXNManager sharedInstance].view reset];
    }

    return YES;
}

static bool _logos_method$Axon$NCNotificationCombinedListViewController$removeNotificationRequest$forCoalescedNotification$(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NCNotificationRequest * req, id arg2) {
    if (self.axnAllowChanges) return _logos_orig$Axon$NCNotificationCombinedListViewController$removeNotificationRequest$forCoalescedNotification$(self, _cmd, req, arg2);     

    NSString *identifier = [[req notificationIdentifier] copy];

    [[AXNManager sharedInstance] removeNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) _logos_orig$Axon$NCNotificationCombinedListViewController$removeNotificationRequest$forCoalescedNotification$(self, _cmd, req, arg2);
    }

    if ([AXNManager sharedInstance].view.showingLatestRequest && identifier &&
    [[[AXNManager sharedInstance].latestRequest notificationIdentifier] isEqualToString:identifier]) {
        _logos_orig$Axon$NCNotificationCombinedListViewController$removeNotificationRequest$forCoalescedNotification$(self, _cmd, req, arg2);
    }

    return YES;
}

static bool _logos_method$Axon$NCNotificationCombinedListViewController$modifyNotificationRequest$forCoalescedNotification$(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NCNotificationRequest * req, id arg2) {
    if (self.axnAllowChanges) return _logos_orig$Axon$NCNotificationCombinedListViewController$modifyNotificationRequest$forCoalescedNotification$(self, _cmd, req, arg2);     

    NSString *identifier = [[req notificationIdentifier] copy];

    [[AXNManager sharedInstance] modifyNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) _logos_orig$Axon$NCNotificationCombinedListViewController$modifyNotificationRequest$forCoalescedNotification$(self, _cmd, req, arg2);
    }

    if ([AXNManager sharedInstance].view.showingLatestRequest && identifier &&
    [[[AXNManager sharedInstance].latestRequest notificationIdentifier] isEqualToString:identifier]) {
        _logos_orig$Axon$NCNotificationCombinedListViewController$modifyNotificationRequest$forCoalescedNotification$(self, _cmd, req, arg2);
    }

    return YES;
}

static bool _logos_method$Axon$NCNotificationCombinedListViewController$hasContent(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if ([AXNManager sharedInstance].view.list && [[AXNManager sharedInstance].view.list count] > 0) return YES;
    return _logos_orig$Axon$NCNotificationCombinedListViewController$hasContent(self, _cmd);
}

static void _logos_method$Axon$NCNotificationCombinedListViewController$viewDidAppear$(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL animated) {
    _logos_orig$Axon$NCNotificationCombinedListViewController$viewDidAppear$(self, _cmd, animated);
    [[AXNManager sharedInstance].view reset];
    [[AXNManager sharedInstance].view refresh];
}



static void _logos_method$Axon$NCNotificationCombinedListViewController$_clearAllPriorityListNotificationRequests(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    [[AXNManager sharedInstance].dispatcher destination:nil requestsClearingNotificationRequests:[self allNotificationRequests]];
}

static void _logos_method$Axon$NCNotificationCombinedListViewController$_clearAllNotificationRequests(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    [[AXNManager sharedInstance].dispatcher destination:nil requestsClearingNotificationRequests:[self allNotificationRequests]];
}

static void _logos_method$Axon$NCNotificationCombinedListViewController$clearAll(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    [[AXNManager sharedInstance].dispatcher destination:nil requestsClearingNotificationRequests:[self axnNotificationRequests]];
}




static id _logos_method$Axon$NCNotificationCombinedListViewController$axnNotificationRequests(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    NSMutableOrderedSet *allRequests = [NSMutableOrderedSet new];
    for (NSString *key in [[AXNManager sharedInstance].notificationRequests allKeys]) {
        [allRequests addObjectsFromArray:[[AXNManager sharedInstance] requestsForBundleIdentifier:key]];
    }
    return allRequests;
}


static void _logos_method$Axon$NCNotificationCombinedListViewController$revealNotificationHistory$(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL revealed) {
  [self setDidPlayRevealHaptic:YES];
  [self forceNotificationHistoryRevealed:revealed animated:NO];
  [self setNotificationHistorySectionNeedsReload:YES];
  [self _reloadNotificationHistorySectionIfNecessary];
  if (!revealed && [self respondsToSelector:@selector(clearAllCoalescingControlsCells)]) [self clearAllCoalescingControlsCells];
}




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

__attribute__((used)) static BOOL _logos_method$Axon$NCNotificationStructuredListViewController$axnAllowChanges(NCNotificationStructuredListViewController * __unused self, SEL __unused _cmd) { NSValue * value = objc_getAssociatedObject(self, (void *)_logos_method$Axon$NCNotificationStructuredListViewController$axnAllowChanges); BOOL rawValue; [value getValue:&rawValue]; return rawValue; }; __attribute__((used)) static void _logos_method$Axon$NCNotificationStructuredListViewController$setAxnAllowChanges(NCNotificationStructuredListViewController * __unused self, SEL __unused _cmd, BOOL rawValue) { NSValue * value = [NSValue valueWithBytes:&rawValue objCType:@encode(BOOL)]; objc_setAssociatedObject(self, (void *)_logos_method$Axon$NCNotificationStructuredListViewController$axnAllowChanges, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
static NCNotificationStructuredListViewController* _logos_method$Axon$NCNotificationStructuredListViewController$init(_LOGOS_SELF_TYPE_INIT NCNotificationStructuredListViewController* __unused self, SEL __unused _cmd) _LOGOS_RETURN_RETAINED {
    _logos_orig$Axon$NCNotificationStructuredListViewController$init(self, _cmd);
    [AXNManager sharedInstance].clvc = self;
    self.axnAllowChanges = NO;
    return self;
}

static bool _logos_method$Axon$NCNotificationStructuredListViewController$insertNotificationRequest$(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NCNotificationRequest * req) {
    if (self.axnAllowChanges) return _logos_orig$Axon$NCNotificationStructuredListViewController$insertNotificationRequest$(self, _cmd, req);     
    [[AXNManager sharedInstance] insertNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    



    _logos_orig$Axon$NCNotificationStructuredListViewController$insertNotificationRequest$(self, _cmd, req);

    if (![AXNManager sharedInstance].view.selectedBundleIdentifier && showByDefault == 1) {
        [[AXNManager sharedInstance].view reset];
    }

    return YES;
}

static bool _logos_method$Axon$NCNotificationStructuredListViewController$removeNotificationRequest$(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NCNotificationRequest * req) {
    if (self.axnAllowChanges) return _logos_orig$Axon$NCNotificationStructuredListViewController$removeNotificationRequest$(self, _cmd, req);     

    

    [[AXNManager sharedInstance] removeNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) _logos_orig$Axon$NCNotificationStructuredListViewController$removeNotificationRequest$(self, _cmd, req);
    }

    
    
        _logos_orig$Axon$NCNotificationStructuredListViewController$removeNotificationRequest$(self, _cmd, req);
    

    return YES;
}

static bool _logos_method$Axon$NCNotificationStructuredListViewController$modifyNotificationRequest$(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NCNotificationRequest * req) {
    if (self.axnAllowChanges) return _logos_orig$Axon$NCNotificationStructuredListViewController$modifyNotificationRequest$(self, _cmd, req);     

    

    [[AXNManager sharedInstance] modifyNotificationRequest:req];
    [[AXNManager sharedInstance].view refresh];

    if (req.bulletin.sectionID) {
        NSString *bundleIdentifier = req.bulletin.sectionID;
        if ([bundleIdentifier isEqualToString:[AXNManager sharedInstance].view.selectedBundleIdentifier]) _logos_orig$Axon$NCNotificationStructuredListViewController$modifyNotificationRequest$(self, _cmd, req);
    }

    
    
        _logos_orig$Axon$NCNotificationStructuredListViewController$modifyNotificationRequest$(self, _cmd, req);
    

    return YES;
}

static void _logos_method$Axon$NCNotificationStructuredListViewController$viewDidAppear$(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL animated) {
    _logos_orig$Axon$NCNotificationStructuredListViewController$viewDidAppear$(self, _cmd, animated);
    [[AXNManager sharedInstance].view reset];
    [[AXNManager sharedInstance].view refresh];
}


static id _logos_method$Axon$NCNotificationStructuredListViewController$axnNotificationRequests(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    NSMutableOrderedSet *allRequests = [NSMutableOrderedSet new];
    for (NSString *key in [[AXNManager sharedInstance].notificationRequests allKeys]) {
        [allRequests addObjectsFromArray:[[AXNManager sharedInstance] requestsForBundleIdentifier:key]];
    }
    return allRequests;
}


static NSSet * _logos_method$Axon$NCNotificationStructuredListViewController$allNotificationRequests(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
  NSArray *array = [NSMutableArray new];
  NCNotificationMasterList *masterList = [self masterList];
  for(NCNotificationStructuredSectionList *item in [masterList notificationSections]) {
    array = [array arrayByAddingObjectsFromArray:[item allNotificationRequests]];
  }
  return [[NSSet alloc] initWithArray:array];
}


static void _logos_method$Axon$NCNotificationStructuredListViewController$revealNotificationHistory$(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, BOOL revealed) {
  [self revealNotificationHistory:revealed animated:true];
}


@interface SBFStaticWallpaperView : UIView 
@property (nonatomic, retain) NSString *displayedImageHashString;
@end



static void _logos_method$Axon$SBFStaticWallpaperView$_setDisplayedImage$(_LOGOS_SELF_TYPE_NORMAL SBFStaticWallpaperView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIImage * image) {
    _logos_orig$Axon$SBFStaticWallpaperView$_setDisplayedImage$(self, _cmd, image);
        [[AXNManager sharedInstance] updateWallpaperColors:image];
}



#pragma mark my additions

@interface NCNotificationViewController : UIViewController {
    NCNotificationRequest* _notificationRequest;
}
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
@end

@interface NCNotificationListCell : UIView {
	NCNotificationViewController* _contentViewController;
}
@property (nonatomic,retain) NCNotificationViewController * contentViewController;                          
- (void)dateIsNow:(NSTimer *)timer ;
@end

@interface NCNotificationListCellActionButtonsView : UIView
@property (nonatomic,retain) UIStackView * buttonsStackView;
@property (nonatomic) BOOL shouldPerformDefaultAction;
- (void)swipedUp:(id)arg1;
@end

@interface UIView (FUCK)
@property (nonatomic,copy) NSString * title;                                                                             
@end

NSString *bundleID;
NCNotificationListCell *snoozedCell;
NCNotificationRequest *argToDismiss;

NCNotificationRequest *reqToBeSnoozed;

UIView *newView;
UIButton *newButton;


static void _logos_method$Axon$NCNotificationListCellActionButtonsView$layoutSubviews(_LOGOS_SELF_TYPE_NORMAL NCNotificationListCellActionButtonsView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    _logos_orig$Axon$NCNotificationListCellActionButtonsView$layoutSubviews(self, _cmd);

    
    

    
    
    if (self.buttonsStackView.arrangedSubviews.count == 3) {
        
        self.buttonsStackView.arrangedSubviews[1].title = @"Snooze";
        [self.buttonsStackView.arrangedSubviews[1] removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents]; 
        [self.buttonsStackView.arrangedSubviews[1] addTarget:self action:@selector(swipedUp:) forControlEvents:UIControlEventTouchUpInside];
    }
}

static void _logos_method$Axon$NCNotificationListCellActionButtonsView$configureCellActionButtonsForNotificationRequest$sectionSettings$cell$(_LOGOS_SELF_TYPE_NORMAL NCNotificationListCellActionButtonsView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1, id arg2, id arg3) {
    argToDismiss = arg1;
    bundleID = argToDismiss.sectionIdentifier;
    snoozedCell = arg3;
    reqToBeSnoozed = snoozedCell.contentViewController.notificationRequest;
    NSLog(@"snoozedCell: %@", snoozedCell);
    












    _logos_orig$Axon$NCNotificationListCellActionButtonsView$configureCellActionButtonsForNotificationRequest$sectionSettings$cell$(self, _cmd, arg1, arg2, arg3);
}


static void _logos_method$Axon$NCNotificationListCellActionButtonsView$swipedUp$(_LOGOS_SELF_TYPE_NORMAL NCNotificationListCellActionButtonsView* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    NSDictionary *info = @{@"id": reqToBeSnoozed, @"cell": snoozedCell};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"xyz.skitty.quietdown.menu" object:nil userInfo:info];
}



static double secondsLeft;

static NSString *configPath = @"/var/mobile/Library/QuietDown/config.plist";
static NSMutableDictionary *config;

static void storeSnoozed(NCNotificationRequest *request) {
  NSString *req = [NSString stringWithFormat:@"%@", request];
  NSMutableArray *entries = [config[@"storeSnoozed"] mutableCopy];
  bool add = YES;
  NSDictionary *remove = nil;
  for (NSMutableDictionary *entry in entries) {
    NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@";"] mutableCopy];
    [parts removeObject:parts[0]];
    NSString *combinedparts = [parts componentsJoinedByString:@";"];
    if ([req containsString:combinedparts]) {
        NSDate *removeDate = [[NSDate alloc] initWithTimeInterval:604800 sinceDate:request.timestamp];
        entry[@"timeToRemove"] = removeDate;
        add = NO;
    }
  }
  if (remove) {
    [entries removeObject:remove];
  }
  if (add) {
    NSDictionary *info;
    NSDate *removeDate = [[NSDate alloc] initWithTimeInterval:604800 sinceDate:request.timestamp];
    info = @{@"id": req, @"timeToRemove": removeDate};
    [entries addObject:info];
  }
  [config setValue:entries forKey:@"storeSnoozed"];
  [config writeToFile:configPath atomically:YES];
}

static void processEntry(NCNotificationRequest *request, double interval, NSDate *inputDate) {
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
            if (interval == -1)
            entry[@"timeStamp"] = @([inputDate timeIntervalSince1970]);
            else if (interval == -2)
            entry[@"timeStamp"] = @(-2);
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
  if (add) {
    storeSnoozed(request);
    NSDictionary *info;
    if (interval < 0) {
        if (interval == -1)
        info = @{@"id": req, @"timeStamp": @([inputDate timeIntervalSince1970])};
        if (interval == -2)
        info = @{@"id": req, @"timeStamp": @(-2)};
    } else if (interval != 0) {
        info = @{@"id": req, @"timeStamp": @([[NSDate date] timeIntervalSince1970] + interval)};
    }
    if (info) {
      [entries addObject:info];
    }
  }
  [config setValue:entries forKey:@"entries"];
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
@property (assign,nonatomic) id<NCNotificationManagementControllerSettingsDelegate> settingsDelegate;              
+(id)notificationManagementAlertControllerForNotificationRequest:(id)arg1 withPresentingView:(id)arg2 settingsDelegate:(id)arg3 ;
@end

@interface NCNotificationManagementViewPresenter : NSObject <NCNotificationManagementControllerSettingsDelegate>
-(void)setNotificationManagementAlertViewController:(UIAlertController *)arg1 ;
@end

@interface NCNotificationManagementView : UIView  {
    NCNotificationManagementBlueButton* _onOffToggleButton;
	NCNotificationManagementBlueButton* _deliveryButton;
}
@property (nonatomic,readonly) NCNotificationManagementBlueButton * deliveryButton;                 
@property (nonatomic,readonly) NCNotificationManagementBlueButton * onOffToggleButton;              
-(id)initWithIcon:(id)arg1 title:(id)arg2 subtitle:(id)arg3 sectionSettings:(id)arg4 criticalAlert:(BOOL)arg5 ;
@end

@interface SButton : UIButton
@property (nonatomic,retain) NCNotificationRequest *request;    
@property (nonatomic,retain) NCNotificationListCell *cell;    
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

@interface PCSimpleTimer : NSObject {
	NSRunLoop* _timerRunLoop;
}
@end

@interface PCPersistentTimer : NSObject {
    PCSimpleTimer* _simpleTimer;
	id _userInfo;
}



-(id)initWithFireDate:(id)arg1 serviceIdentifier:(id)arg2 target:(id)arg3 selector:(SEL)arg4 userInfo:(id)arg5 ;
-(void)scheduleInRunLoop:(id)arg1 ;

-(id)userInfo;
@end


static void _logos_method$Axon$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id application) {
  _logos_orig$Axon$SpringBoard$applicationDidFinishLaunching$(self, _cmd, application);
  config = [NSMutableDictionary dictionaryWithContentsOfFile:configPath];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMuteMenu:) name:@"xyz.skitty.quietdown.menu" object:nil];
}


static void _logos_method$Axon$SpringBoard$showMuteMenu$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NSNotification * notification) {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Snooze notifications" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    NCNotificationRequest *requestToProcess = notification.userInfo[@"id"];
    NCNotificationListCell *cellToCapture = notification.userInfo[@"cell"];
    NCNotificationListView *cellListView = (NCNotificationListView *)cellToCapture.superview;
    NCNotificationGroupList *groupList = cellListView.dataSource;
    NSMutableArray *reqsArray = [groupList.orderedRequests copy];

    BOOL grouped;
    if (cellListView.grouped) {
        grouped = YES;
    } else {
        grouped = NO;
    }

  [alert addAction:[UIAlertAction actionWithTitle:@"For 15 minutes" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    if(grouped){
        [[AXNManager sharedInstance] hideNotificationRequests:reqsArray];
        for (NCNotificationRequest *request in reqsArray) {
            if (![request.content.header containsString:@"Snoozed"]) {
                NSString *newTitle = [NSString stringWithFormat:@"%@ • Snoozed", request.content.header];
                [request.content setValue:newTitle forKey:@"_header"];
            }
            processEntry(request, 900, nil);
        }
        NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:900]
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             for (NCNotificationRequest *request in reqsArray) {
                                                                processEntry(request, 0, nil);
                                                             }
                                                             [[AXNManager sharedInstance] showNotificationRequests:reqsArray];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];
    } else {
        [[AXNManager sharedInstance] hideNotificationRequest:requestToProcess];
        if (![requestToProcess.content.header containsString:@"Snoozed"]) {
            NSString *newTitle = [NSString stringWithFormat:@"%@ • Snoozed", requestToProcess.content.header];
            [requestToProcess.content setValue:newTitle forKey:@"_header"];
        }
        NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:900]
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             processEntry(requestToProcess, 0, nil);
                                                             [[AXNManager sharedInstance] showNotificationRequest:requestToProcess];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];
        processEntry(requestToProcess, 900, nil);
    }
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"For 1 Hour" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    if(grouped){
        [[AXNManager sharedInstance] hideNotificationRequests:reqsArray];
        for (NCNotificationRequest *request in reqsArray) {
            if (![request.content.header containsString:@"Snoozed"]) {
                NSString *newTitle = [NSString stringWithFormat:@"%@ • Snoozed", request.content.header];
                [request.content setValue:newTitle forKey:@"_header"];
            }
            processEntry(request, 3600, nil);
        }
        NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:3600]
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             for (NCNotificationRequest *request in reqsArray) {
                                                                processEntry(request, 0, nil);
                                                             }
                                                             [[AXNManager sharedInstance] showNotificationRequests:reqsArray];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];
    } else {
        [[AXNManager sharedInstance] hideNotificationRequest:requestToProcess];
        if (![requestToProcess.content.header containsString:@"Snoozed"]) {
            NSString *newTitle = [NSString stringWithFormat:@"%@ • Snoozed", requestToProcess.content.header];
            [requestToProcess.content setValue:newTitle forKey:@"_header"];
        }
        NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:3600]
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             processEntry(requestToProcess, 0, nil);
                                                             [[AXNManager sharedInstance] showNotificationRequest:requestToProcess];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];
        processEntry(requestToProcess, 3600, nil);
    }
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"For 4 Hour" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    if(grouped){
        [[AXNManager sharedInstance] hideNotificationRequests:reqsArray];
        for (NCNotificationRequest *request in reqsArray) {
            if (![request.content.header containsString:@"Snoozed"]) {
                NSString *newTitle = [NSString stringWithFormat:@"%@ • Snoozed", request.content.header];
                [request.content setValue:newTitle forKey:@"_header"];
            }
            processEntry(request, 14400, nil);
        }
        NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:14400]
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             for (NCNotificationRequest *request in reqsArray) {
                                                                processEntry(request, 0, nil);
                                                             }
                                                             [[AXNManager sharedInstance] showNotificationRequests:reqsArray];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];
    } else {
        [[AXNManager sharedInstance] hideNotificationRequest:requestToProcess];
        if (![requestToProcess.content.header containsString:@"Snoozed"]) {
            NSString *newTitle = [NSString stringWithFormat:@"%@ • Snoozed", requestToProcess.content.header];
            [requestToProcess.content setValue:newTitle forKey:@"_header"];
        }
        NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:14400]
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             processEntry(requestToProcess, 0, nil);
                                                             [[AXNManager sharedInstance] showNotificationRequest:requestToProcess];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];
        processEntry(requestToProcess, 14400, nil);
    }
  }]];
  [alert addAction:[UIAlertAction actionWithTitle:@"For 8 Hours" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    if(grouped){
        [[AXNManager sharedInstance] hideNotificationRequests:reqsArray];
        for (NCNotificationRequest *request in reqsArray) {
            if (![request.content.header containsString:@"Snoozed"]) {
                NSString *newTitle = [NSString stringWithFormat:@"%@ • Snoozed", request.content.header];
                [request.content setValue:newTitle forKey:@"_header"];
            }
            processEntry(request, 28800, nil);
        }
        NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:28800]
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             for (NCNotificationRequest *request in reqsArray) {
                                                                processEntry(request, 0, nil);
                                                             }
                                                             [[AXNManager sharedInstance] showNotificationRequests:reqsArray];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];
    } else {
        [[AXNManager sharedInstance] hideNotificationRequest:requestToProcess];
        if (![requestToProcess.content.header containsString:@"Snoozed"]) {
            NSString *newTitle = [NSString stringWithFormat:@"%@ • Snoozed", requestToProcess.content.header];
            [requestToProcess.content setValue:newTitle forKey:@"_header"];
        }
        NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:28800]
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             processEntry(requestToProcess, 0, nil);
                                                             [[AXNManager sharedInstance] showNotificationRequest:requestToProcess];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];
        processEntry(requestToProcess, 28800, nil);
    }
  }]];
  

























    [alert addAction:[UIAlertAction actionWithTitle:@"Specific time" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NCNotificationManagementAlertController *alertController = [[_logos_static_class_lookup$NCNotificationManagementAlertController() alloc] initWithRequest:requestToProcess withPresentingView:nil settingsDelegate:nil];
        [alertController setTitle:@"Snooze until:"]; 
        
        UIDatePicker *picker = [[UIDatePicker alloc] init];
        [picker setDatePickerMode:UIDatePickerModeDateAndTime];
        [picker setMinuteInterval:15];
        [picker setMinimumDate:[NSDate dateWithTimeInterval:900 sinceDate:[NSDate date]]];
        [picker setMaximumDate:[NSDate dateWithTimeInterval:604800 sinceDate:requestToProcess.timestamp]];
        [alertController.view addSubview:picker];

        SButton *button = [SButton buttonWithType:UIButtonTypeSystem];
        CGFloat margin = 4.0F;
        button.frame = CGRectMake(10 + alertController.view.bounds.origin.x, alertController.view.bounds.origin.y + ((picker.frame.size.height+40) - 2) + 50, alertController.view.frame.size.width - margin * 4.0F - 20, 50);
        [button setBackgroundColor:[UIColor systemBlueColor]];
        [button setTitle:@"Snooze" forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:19];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.request = requestToProcess;
        button.controllerToDismiss = alertController;
        button.pickerDate = picker.date;
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

        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window.isKeyWindow) {
                [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
                [window.rootViewController presentViewController:alertController animated:YES completion:nil];
                break;
            }
        }
    }]];

    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow) {
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
            [window.rootViewController presentViewController:alert animated:YES completion:nil];
            break;
        }
    }
}


static UIImage * _logos_method$Axon$SpringBoard$imageWithView$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIView * viewB) {
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


static void _logos_method$Axon$SpringBoard$buttonDown$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIButton * sender) {
    [UIView animateWithDuration:0.2 delay:0 options:nil animations:^{
        sender.alpha = 0.5f;
    } completion:nil];
}


static void _logos_method$Axon$SpringBoard$buttonUpCancel$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UIButton * sender) {
    [UIView animateWithDuration:0.2 delay:0 options:nil animations:^{
        sender.alpha = 1.0f;
    } completion:nil];
}


static void _logos_method$Axon$SpringBoard$buttonUp$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id sender) {
    SButton *senderFix = sender;
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
            if (![request.content.header containsString:@"Snoozed"]) {
                NSString *newTitle = [NSString stringWithFormat:@"%@ • Snoozed", request.content.header];
                [request.content setValue:newTitle forKey:@"_header"];
            }
            processEntry(request, -1, senderFix.pickerDate);
        }
        NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:senderFix.pickerDate
                                                      interval:nil
                                                       repeats:NO
                                                         block:(void (^)(NSTimer *timer))^{
                                                             for (NCNotificationRequest *request in reqsArray) {
                                                                processEntry(request, 0, nil);
                                                             }
                                                             [[AXNManager sharedInstance] showNotificationRequests:reqsArray];
                                                         }];
        [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];
    } else {
        [[AXNManager sharedInstance] hideNotificationRequest:senderFix.request];
        if (![senderFix.request.content.header containsString:@"Snoozed"]) {
            NSString *newTitle = [NSString stringWithFormat:@"%@ • Snoozed", senderFix.request.content.header];
            [senderFix.request.content setValue:newTitle forKey:@"_header"];
        }
        PCPersistentTimer *PersistentTimer = [_logos_static_class_lookup$PCPersistentTimer() alloc];
        PCSimpleTimer *simpleTimer = MSHookIvar<PCSimpleTimer *>(PersistentTimer, "_simpleTimer");
        NSRunLoop *timerRunLoop = MSHookIvar<NSRunLoop *>(simpleTimer, "_timerRunLoop");
        NSDictionary* userInfo = @{@"request" : senderFix.request};
        PCPersistentTimer *timerShow = [[PCPersistentTimer alloc] initWithFireDate:senderFix.pickerDate
                            serviceIdentifier:nil
                            target:self
                            selector:@selector(timerOperations:)
                            userInfo:userInfo];
        [timerShow scheduleInRunLoop:timerRunLoop];
        








        processEntry(senderFix.request, -1, senderFix.pickerDate);
    }
}


static void _logos_method$Axon$SpringBoard$timerOperations$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, PCPersistentTimer * timer) {
    NSDictionary* userInfo = timer.userInfo;
    NCNotificationRequest *request = (NCNotificationRequest *)userInfo[@"request"];
    processEntry(request, 0, nil);
    [[AXNManager sharedInstance] showNotificationRequest:request];
}










































static void _logos_method$Axon$CSNotificationDispatcher$postNotificationRequest$(_LOGOS_SELF_TYPE_NORMAL CSNotificationDispatcher* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, NCNotificationRequest * arg1) {
    NSString *req = [NSString stringWithFormat:@"%@", arg1];
    NSMutableArray *entries = [config[@"entries"] mutableCopy];
    for (NSMutableDictionary *entry in entries) {
        NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@";"] mutableCopy];
        [parts removeObject:parts[0]];
        NSString *combinedparts = [parts componentsJoinedByString:@";"];
        if ([req containsString:combinedparts]) {
            NCNotificationRequest *argFix = arg1;
            NSString *newTitle = [NSString stringWithFormat:@"%@ • Snoozed", argFix.content.header];
            [argFix.content setValue:newTitle forKey:@"_header"];
            _logos_orig$Axon$CSNotificationDispatcher$postNotificationRequest$(self, _cmd, argFix);
            [[AXNManager sharedInstance] hideNotificationRequest:argFix];
                secondsLeft = [entry[@"timeStamp"] doubleValue] - [[NSDate date] timeIntervalSince1970] + 1;
            NSTimer *timerShow = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:secondsLeft]
                                                          interval:nil
                                                           repeats:NO
                                                             block:(void (^)(NSTimer *timer))^{
                                                                 processEntry(argFix, 0, nil);
                                                                 [[AXNManager sharedInstance] showNotificationRequest:argFix];
                                                             }];
            [[NSRunLoop mainRunLoop] addTimer:timerShow forMode:NSDefaultRunLoopMode];
            return;
        }
    }
    _logos_orig$Axon$CSNotificationDispatcher$postNotificationRequest$(self, _cmd, arg1);
}



static void _logos_method$Axon$SBNCScreenController$turnOnScreenForNotificationRequest$(_LOGOS_SELF_TYPE_NORMAL SBNCScreenController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1) {
    NSString *req = [NSString stringWithFormat:@"%@", arg1];
    NSMutableArray *entries = [config[@"entries"] mutableCopy];
    for (NSMutableDictionary *entry in entries) {
        NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@";"] mutableCopy];
        [parts removeObject:parts[0]];
        NSString *combinedparts = [parts componentsJoinedByString:@";"];
        if ([req containsString:combinedparts]) {
                secondsLeft = [entry[@"timeStamp"] doubleValue] - [[NSDate date] timeIntervalSince1970] + 1;
            [NSTimer scheduledTimerWithTimeInterval:secondsLeft
                                        target:[NSBlockOperation blockOperationWithBlock:^{_logos_orig$Axon$SBNCScreenController$turnOnScreenForNotificationRequest$(self, _cmd, arg1);}]
                                        selector:@selector(main)
                                        userInfo:nil
                                        repeats:NO
                                    ];
            return;
        }
    }
    _logos_orig$Axon$SBNCScreenController$turnOnScreenForNotificationRequest$(self, _cmd, arg1);
}



static void _logos_method$Axon$SBNCSoundController$playSoundForNotificationRequest$presentingDestination$(_LOGOS_SELF_TYPE_NORMAL SBNCSoundController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1, id arg2) {
    NSString *req = [NSString stringWithFormat:@"%@", arg1];
    NSMutableArray *entries = [config[@"entries"] mutableCopy];
    for (NSMutableDictionary *entry in entries) {
        NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@";"] mutableCopy];
        [parts removeObject:parts[0]];
        NSString *combinedparts = [parts componentsJoinedByString:@";"];
        if ([req containsString:combinedparts]) {
                secondsLeft = [entry[@"timeStamp"] doubleValue] - [[NSDate date] timeIntervalSince1970] + 1;
            [NSTimer scheduledTimerWithTimeInterval:secondsLeft
                                        target:[NSBlockOperation blockOperationWithBlock:^{_logos_orig$Axon$SBNCSoundController$playSoundForNotificationRequest$presentingDestination$(self, _cmd, arg1, arg2);}]
                                        selector:@selector(main)
                                        userInfo:nil
                                        repeats:NO
                                    ];
            return;
        }
    }
    _logos_orig$Axon$SBNCSoundController$playSoundForNotificationRequest$presentingDestination$(self, _cmd, arg1, arg2);
}



static void _logos_method$Axon$SBNotificationBannerDestination$_postNotificationRequest$modal$completion$(_LOGOS_SELF_TYPE_NORMAL SBNotificationBannerDestination* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id arg1, BOOL arg2, id arg3) {
    NSString *req = [NSString stringWithFormat:@"%@", arg1];
    NSMutableArray *entries = [config[@"entries"] mutableCopy];
    for (NSMutableDictionary *entry in entries) {
        NSMutableArray *parts = [[entry[@"id"] componentsSeparatedByString:@";"] mutableCopy];
        [parts removeObject:parts[0]];
        NSString *combinedparts = [parts componentsJoinedByString:@";"];
        if ([req containsString:combinedparts]) {
                secondsLeft = [entry[@"timeStamp"] doubleValue] - [[NSDate date] timeIntervalSince1970] + 1;
            [NSTimer scheduledTimerWithTimeInterval:secondsLeft
                                        target:[NSBlockOperation blockOperationWithBlock:^{_logos_orig$Axon$SBNotificationBannerDestination$_postNotificationRequest$modal$completion$(self, _cmd, arg1, arg2, arg3);}]
                                        selector:@selector(main)
                                        userInfo:nil
                                        repeats:NO
                                    ];
            return;
        }
    }
    _logos_orig$Axon$SBNotificationBannerDestination$_postNotificationRequest$modal$completion$(self, _cmd, arg1, arg2, arg3);
}



@interface NCNotificationContentView : NSObject
@end

@interface UIView (Private)
-(NSArray *)allSubviews;
@end

static UIEdgeInsets (*_logos_orig$AxonVertical$NCNotificationCombinedListViewController$insetMargins)(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL); static UIEdgeInsets _logos_method$AxonVertical$NCNotificationCombinedListViewController$insetMargins(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL); static CGSize (*_logos_orig$AxonVertical$NCNotificationCombinedListViewController$collectionView$layout$sizeForItemAtIndexPath$)(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL, UICollectionView *, UICollectionViewLayout*, id); static CGSize _logos_method$AxonVertical$NCNotificationCombinedListViewController$collectionView$layout$sizeForItemAtIndexPath$(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST, SEL, UICollectionView *, UICollectionViewLayout*, id); static UIEdgeInsets (*_logos_orig$AxonVertical$NCNotificationStructuredListViewController$insetMargins)(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST, SEL); static UIEdgeInsets _logos_method$AxonVertical$NCNotificationStructuredListViewController$insetMargins(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST, SEL); 

__attribute__((used)) static BOOL _logos_method$AxonVertical$NCNotificationCombinedListViewController$axnAllowChanges(NCNotificationCombinedListViewController * __unused self, SEL __unused _cmd) { NSValue * value = objc_getAssociatedObject(self, (void *)_logos_method$AxonVertical$NCNotificationCombinedListViewController$axnAllowChanges); BOOL rawValue; [value getValue:&rawValue]; return rawValue; }; __attribute__((used)) static void _logos_method$AxonVertical$NCNotificationCombinedListViewController$setAxnAllowChanges(NCNotificationCombinedListViewController * __unused self, SEL __unused _cmd, BOOL rawValue) { NSValue * value = [NSValue valueWithBytes:&rawValue objCType:@encode(BOOL)]; objc_setAssociatedObject(self, (void *)_logos_method$AxonVertical$NCNotificationCombinedListViewController$axnAllowChanges, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }

static UIEdgeInsets _logos_method$AxonVertical$NCNotificationCombinedListViewController$insetMargins(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if (verticalPosition == 0) return UIEdgeInsetsMake(0, -96, 0, 0);
    else return UIEdgeInsetsMake(0, 0, 0, -96);
}

static CGSize _logos_method$AxonVertical$NCNotificationCombinedListViewController$collectionView$layout$sizeForItemAtIndexPath$(_LOGOS_SELF_TYPE_NORMAL NCNotificationCombinedListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, UICollectionView * arg1, UICollectionViewLayout* arg2, id arg3) {
    CGSize orig = _logos_orig$AxonVertical$NCNotificationCombinedListViewController$collectionView$layout$sizeForItemAtIndexPath$(self, _cmd, arg1, arg2, arg3);
    UIView *view = [arg1 cellForItemAtIndexPath:arg3].contentView;
    for(id item in view.allSubviews) {
      if([item isKindOfClass:[objc_getClass("NCNotificationContentView") class]]) {
        return CGSizeMake(orig.width - 96, ((UIView *)item).frame.size.height+30);
      }
    }
    return CGSizeMake(orig.width - 96, orig.height);
}




__attribute__((used)) static BOOL _logos_method$AxonVertical$NCNotificationStructuredListViewController$axnAllowChanges(NCNotificationStructuredListViewController * __unused self, SEL __unused _cmd) { NSValue * value = objc_getAssociatedObject(self, (void *)_logos_method$AxonVertical$NCNotificationStructuredListViewController$axnAllowChanges); BOOL rawValue; [value getValue:&rawValue]; return rawValue; }; __attribute__((used)) static void _logos_method$AxonVertical$NCNotificationStructuredListViewController$setAxnAllowChanges(NCNotificationStructuredListViewController * __unused self, SEL __unused _cmd, BOOL rawValue) { NSValue * value = [NSValue valueWithBytes:&rawValue objCType:@encode(BOOL)]; objc_setAssociatedObject(self, (void *)_logos_method$AxonVertical$NCNotificationStructuredListViewController$axnAllowChanges, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
static UIEdgeInsets _logos_method$AxonVertical$NCNotificationStructuredListViewController$insetMargins(_LOGOS_SELF_TYPE_NORMAL NCNotificationStructuredListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd) {
    if (verticalPosition == 0) return UIEdgeInsetsMake(0, -96, 0, 0);
    else return UIEdgeInsetsMake(0, 0, 0, -96);
}



static void (*_logos_orig$AxonHorizontal$SBDashBoardCombinedListViewController$viewDidLoad)(_LOGOS_SELF_TYPE_NORMAL SBDashBoardCombinedListViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$AxonHorizontal$SBDashBoardCombinedListViewController$viewDidLoad(_LOGOS_SELF_TYPE_NORMAL SBDashBoardCombinedListViewController* _LOGOS_SELF_CONST, SEL); static void (*_logos_orig$AxonHorizontal$CSCombinedListViewController$viewDidLoad)(_LOGOS_SELF_TYPE_NORMAL CSCombinedListViewController* _LOGOS_SELF_CONST, SEL); static void _logos_method$AxonHorizontal$CSCombinedListViewController$viewDidLoad(_LOGOS_SELF_TYPE_NORMAL CSCombinedListViewController* _LOGOS_SELF_CONST, SEL); 

static void _logos_method$AxonHorizontal$SBDashBoardCombinedListViewController$viewDidLoad(_LOGOS_SELF_TYPE_NORMAL SBDashBoardCombinedListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd){
    _logos_orig$AxonHorizontal$SBDashBoardCombinedListViewController$viewDidLoad(self, _cmd);
    [AXNManager sharedInstance].sbclvc = self;
}





static void _logos_method$AxonHorizontal$CSCombinedListViewController$viewDidLoad(_LOGOS_SELF_TYPE_NORMAL CSCombinedListViewController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd){
    _logos_orig$AxonHorizontal$CSCombinedListViewController$viewDidLoad(self, _cmd);
    [AXNManager sharedInstance].sbclvc = self;
}





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
    BOOL dynamicBadges = boolValueForKey(@"dynamicBadges", YES);

    [AXNManager sharedInstance].style = style;
    [AXNManager sharedInstance].fadeEntireCell = fadeEntireCell;
    [AXNManager sharedInstance].dynamicBadges = dynamicBadges;


    updateViewConfiguration();
}

static __attribute__((constructor)) void _logosLocalCtor_2fe82bf2(int __unused argc, char __unused **argv, char __unused **envp){
    preferencesChanged();
    
    NSLog(@"[Axon] init");

    dpkgInvalid = ![[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/me.nepeta.axon.list"];
    


    if (!dpkgInvalid) dpkgInvalid = ![[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/me.nepeta.axon.md5sums"];

    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        &observer,
        (CFNotificationCallback)preferencesChanged,
        (CFStringRef)@"me.nepeta.axon/ReloadPrefs",
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );

    if (!dpkgInvalid && enabled) {
        {Class _logos_class$Axon$SBFLockScreenDateView = objc_getClass("SBFLockScreenDateView"); MSHookMessageEx(_logos_class$Axon$SBFLockScreenDateView, @selector(initWithFrame:), (IMP)&_logos_method$Axon$SBFLockScreenDateView$initWithFrame$, (IMP*)&_logos_orig$Axon$SBFLockScreenDateView$initWithFrame$);MSHookMessageEx(_logos_class$Axon$SBFLockScreenDateView, @selector(setLegibilitySettings:), (IMP)&_logos_method$Axon$SBFLockScreenDateView$setLegibilitySettings$, (IMP*)&_logos_orig$Axon$SBFLockScreenDateView$setLegibilitySettings$);Class _logos_class$Axon$SBNCNotificationDispatcher = objc_getClass("SBNCNotificationDispatcher"); MSHookMessageEx(_logos_class$Axon$SBNCNotificationDispatcher, @selector(init), (IMP)&_logos_method$Axon$SBNCNotificationDispatcher$init, (IMP*)&_logos_orig$Axon$SBNCNotificationDispatcher$init);MSHookMessageEx(_logos_class$Axon$SBNCNotificationDispatcher, @selector(setDispatcher:), (IMP)&_logos_method$Axon$SBNCNotificationDispatcher$setDispatcher$, (IMP*)&_logos_orig$Axon$SBNCNotificationDispatcher$setDispatcher$);Class _logos_class$Axon$NCNotificationCombinedListViewController = objc_getClass("NCNotificationCombinedListViewController"); MSHookMessageEx(_logos_class$Axon$NCNotificationCombinedListViewController, @selector(init), (IMP)&_logos_method$Axon$NCNotificationCombinedListViewController$init, (IMP*)&_logos_orig$Axon$NCNotificationCombinedListViewController$init);MSHookMessageEx(_logos_class$Axon$NCNotificationCombinedListViewController, @selector(insertNotificationRequest:forCoalescedNotification:), (IMP)&_logos_method$Axon$NCNotificationCombinedListViewController$insertNotificationRequest$forCoalescedNotification$, (IMP*)&_logos_orig$Axon$NCNotificationCombinedListViewController$insertNotificationRequest$forCoalescedNotification$);MSHookMessageEx(_logos_class$Axon$NCNotificationCombinedListViewController, @selector(removeNotificationRequest:forCoalescedNotification:), (IMP)&_logos_method$Axon$NCNotificationCombinedListViewController$removeNotificationRequest$forCoalescedNotification$, (IMP*)&_logos_orig$Axon$NCNotificationCombinedListViewController$removeNotificationRequest$forCoalescedNotification$);MSHookMessageEx(_logos_class$Axon$NCNotificationCombinedListViewController, @selector(modifyNotificationRequest:forCoalescedNotification:), (IMP)&_logos_method$Axon$NCNotificationCombinedListViewController$modifyNotificationRequest$forCoalescedNotification$, (IMP*)&_logos_orig$Axon$NCNotificationCombinedListViewController$modifyNotificationRequest$forCoalescedNotification$);MSHookMessageEx(_logos_class$Axon$NCNotificationCombinedListViewController, @selector(hasContent), (IMP)&_logos_method$Axon$NCNotificationCombinedListViewController$hasContent, (IMP*)&_logos_orig$Axon$NCNotificationCombinedListViewController$hasContent);MSHookMessageEx(_logos_class$Axon$NCNotificationCombinedListViewController, @selector(viewDidAppear:), (IMP)&_logos_method$Axon$NCNotificationCombinedListViewController$viewDidAppear$, (IMP*)&_logos_orig$Axon$NCNotificationCombinedListViewController$viewDidAppear$);MSHookMessageEx(_logos_class$Axon$NCNotificationCombinedListViewController, @selector(_clearAllPriorityListNotificationRequests), (IMP)&_logos_method$Axon$NCNotificationCombinedListViewController$_clearAllPriorityListNotificationRequests, (IMP*)&_logos_orig$Axon$NCNotificationCombinedListViewController$_clearAllPriorityListNotificationRequests);MSHookMessageEx(_logos_class$Axon$NCNotificationCombinedListViewController, @selector(_clearAllNotificationRequests), (IMP)&_logos_method$Axon$NCNotificationCombinedListViewController$_clearAllNotificationRequests, (IMP*)&_logos_orig$Axon$NCNotificationCombinedListViewController$_clearAllNotificationRequests);MSHookMessageEx(_logos_class$Axon$NCNotificationCombinedListViewController, @selector(clearAll), (IMP)&_logos_method$Axon$NCNotificationCombinedListViewController$clearAll, (IMP*)&_logos_orig$Axon$NCNotificationCombinedListViewController$clearAll);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$Axon$NCNotificationCombinedListViewController, @selector(axnNotificationRequests), (IMP)&_logos_method$Axon$NCNotificationCombinedListViewController$axnNotificationRequests, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(BOOL), strlen(@encode(BOOL))); i += strlen(@encode(BOOL)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$Axon$NCNotificationCombinedListViewController, @selector(revealNotificationHistory:), (IMP)&_logos_method$Axon$NCNotificationCombinedListViewController$revealNotificationHistory$, _typeEncoding); }{ char _typeEncoding[1024]; sprintf(_typeEncoding, "%s@:", @encode(BOOL)); class_addMethod(_logos_class$Axon$NCNotificationCombinedListViewController, @selector(axnAllowChanges), (IMP)&_logos_method$Axon$NCNotificationCombinedListViewController$axnAllowChanges, _typeEncoding); sprintf(_typeEncoding, "v@:%s", @encode(BOOL)); class_addMethod(_logos_class$Axon$NCNotificationCombinedListViewController, @selector(setAxnAllowChanges:), (IMP)&_logos_method$Axon$NCNotificationCombinedListViewController$setAxnAllowChanges, _typeEncoding); } Class _logos_class$Axon$NCNotificationStructuredListViewController = objc_getClass("NCNotificationStructuredListViewController"); MSHookMessageEx(_logos_class$Axon$NCNotificationStructuredListViewController, @selector(init), (IMP)&_logos_method$Axon$NCNotificationStructuredListViewController$init, (IMP*)&_logos_orig$Axon$NCNotificationStructuredListViewController$init);MSHookMessageEx(_logos_class$Axon$NCNotificationStructuredListViewController, @selector(insertNotificationRequest:), (IMP)&_logos_method$Axon$NCNotificationStructuredListViewController$insertNotificationRequest$, (IMP*)&_logos_orig$Axon$NCNotificationStructuredListViewController$insertNotificationRequest$);MSHookMessageEx(_logos_class$Axon$NCNotificationStructuredListViewController, @selector(removeNotificationRequest:), (IMP)&_logos_method$Axon$NCNotificationStructuredListViewController$removeNotificationRequest$, (IMP*)&_logos_orig$Axon$NCNotificationStructuredListViewController$removeNotificationRequest$);MSHookMessageEx(_logos_class$Axon$NCNotificationStructuredListViewController, @selector(modifyNotificationRequest:), (IMP)&_logos_method$Axon$NCNotificationStructuredListViewController$modifyNotificationRequest$, (IMP*)&_logos_orig$Axon$NCNotificationStructuredListViewController$modifyNotificationRequest$);MSHookMessageEx(_logos_class$Axon$NCNotificationStructuredListViewController, @selector(viewDidAppear:), (IMP)&_logos_method$Axon$NCNotificationStructuredListViewController$viewDidAppear$, (IMP*)&_logos_orig$Axon$NCNotificationStructuredListViewController$viewDidAppear$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$Axon$NCNotificationStructuredListViewController, @selector(axnNotificationRequests), (IMP)&_logos_method$Axon$NCNotificationStructuredListViewController$axnNotificationRequests, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(NSSet *), strlen(@encode(NSSet *))); i += strlen(@encode(NSSet *)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$Axon$NCNotificationStructuredListViewController, @selector(allNotificationRequests), (IMP)&_logos_method$Axon$NCNotificationStructuredListViewController$allNotificationRequests, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(BOOL), strlen(@encode(BOOL))); i += strlen(@encode(BOOL)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$Axon$NCNotificationStructuredListViewController, @selector(revealNotificationHistory:), (IMP)&_logos_method$Axon$NCNotificationStructuredListViewController$revealNotificationHistory$, _typeEncoding); }{ char _typeEncoding[1024]; sprintf(_typeEncoding, "%s@:", @encode(BOOL)); class_addMethod(_logos_class$Axon$NCNotificationStructuredListViewController, @selector(axnAllowChanges), (IMP)&_logos_method$Axon$NCNotificationStructuredListViewController$axnAllowChanges, _typeEncoding); sprintf(_typeEncoding, "v@:%s", @encode(BOOL)); class_addMethod(_logos_class$Axon$NCNotificationStructuredListViewController, @selector(setAxnAllowChanges:), (IMP)&_logos_method$Axon$NCNotificationStructuredListViewController$setAxnAllowChanges, _typeEncoding); } Class _logos_class$Axon$SBFStaticWallpaperView = objc_getClass("SBFStaticWallpaperView"); MSHookMessageEx(_logos_class$Axon$SBFStaticWallpaperView, @selector(_setDisplayedImage:), (IMP)&_logos_method$Axon$SBFStaticWallpaperView$_setDisplayedImage$, (IMP*)&_logos_orig$Axon$SBFStaticWallpaperView$_setDisplayedImage$);Class _logos_class$Axon$NCNotificationListCellActionButtonsView = objc_getClass("NCNotificationListCellActionButtonsView"); MSHookMessageEx(_logos_class$Axon$NCNotificationListCellActionButtonsView, @selector(layoutSubviews), (IMP)&_logos_method$Axon$NCNotificationListCellActionButtonsView$layoutSubviews, (IMP*)&_logos_orig$Axon$NCNotificationListCellActionButtonsView$layoutSubviews);MSHookMessageEx(_logos_class$Axon$NCNotificationListCellActionButtonsView, @selector(configureCellActionButtonsForNotificationRequest:sectionSettings:cell:), (IMP)&_logos_method$Axon$NCNotificationListCellActionButtonsView$configureCellActionButtonsForNotificationRequest$sectionSettings$cell$, (IMP*)&_logos_orig$Axon$NCNotificationListCellActionButtonsView$configureCellActionButtonsForNotificationRequest$sectionSettings$cell$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$Axon$NCNotificationListCellActionButtonsView, @selector(swipedUp:), (IMP)&_logos_method$Axon$NCNotificationListCellActionButtonsView$swipedUp$, _typeEncoding); }Class _logos_class$Axon$SpringBoard = objc_getClass("SpringBoard"); MSHookMessageEx(_logos_class$Axon$SpringBoard, @selector(applicationDidFinishLaunching:), (IMP)&_logos_method$Axon$SpringBoard$applicationDidFinishLaunching$, (IMP*)&_logos_orig$Axon$SpringBoard$applicationDidFinishLaunching$);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(NSNotification *), strlen(@encode(NSNotification *))); i += strlen(@encode(NSNotification *)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$Axon$SpringBoard, @selector(showMuteMenu:), (IMP)&_logos_method$Axon$SpringBoard$showMuteMenu$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; memcpy(_typeEncoding + i, @encode(UIImage *), strlen(@encode(UIImage *))); i += strlen(@encode(UIImage *)); _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(UIView *), strlen(@encode(UIView *))); i += strlen(@encode(UIView *)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$Axon$SpringBoard, @selector(imageWithView:), (IMP)&_logos_method$Axon$SpringBoard$imageWithView$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(UIButton *), strlen(@encode(UIButton *))); i += strlen(@encode(UIButton *)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$Axon$SpringBoard, @selector(buttonDown:), (IMP)&_logos_method$Axon$SpringBoard$buttonDown$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(UIButton *), strlen(@encode(UIButton *))); i += strlen(@encode(UIButton *)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$Axon$SpringBoard, @selector(buttonUpCancel:), (IMP)&_logos_method$Axon$SpringBoard$buttonUpCancel$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$Axon$SpringBoard, @selector(buttonUp:), (IMP)&_logos_method$Axon$SpringBoard$buttonUp$, _typeEncoding); }{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; memcpy(_typeEncoding + i, @encode(PCPersistentTimer *), strlen(@encode(PCPersistentTimer *))); i += strlen(@encode(PCPersistentTimer *)); _typeEncoding[i] = '\0'; class_addMethod(_logos_class$Axon$SpringBoard, @selector(timerOperations:), (IMP)&_logos_method$Axon$SpringBoard$timerOperations$, _typeEncoding); }Class _logos_class$Axon$CSNotificationDispatcher = objc_getClass("CSNotificationDispatcher"); MSHookMessageEx(_logos_class$Axon$CSNotificationDispatcher, @selector(postNotificationRequest:), (IMP)&_logos_method$Axon$CSNotificationDispatcher$postNotificationRequest$, (IMP*)&_logos_orig$Axon$CSNotificationDispatcher$postNotificationRequest$);Class _logos_class$Axon$SBNCScreenController = objc_getClass("SBNCScreenController"); MSHookMessageEx(_logos_class$Axon$SBNCScreenController, @selector(turnOnScreenForNotificationRequest:), (IMP)&_logos_method$Axon$SBNCScreenController$turnOnScreenForNotificationRequest$, (IMP*)&_logos_orig$Axon$SBNCScreenController$turnOnScreenForNotificationRequest$);Class _logos_class$Axon$SBNCSoundController = objc_getClass("SBNCSoundController"); MSHookMessageEx(_logos_class$Axon$SBNCSoundController, @selector(playSoundForNotificationRequest:presentingDestination:), (IMP)&_logos_method$Axon$SBNCSoundController$playSoundForNotificationRequest$presentingDestination$, (IMP*)&_logos_orig$Axon$SBNCSoundController$playSoundForNotificationRequest$presentingDestination$);Class _logos_class$Axon$SBNotificationBannerDestination = objc_getClass("SBNotificationBannerDestination"); MSHookMessageEx(_logos_class$Axon$SBNotificationBannerDestination, @selector(_postNotificationRequest:modal:completion:), (IMP)&_logos_method$Axon$SBNotificationBannerDestination$_postNotificationRequest$modal$completion$, (IMP*)&_logos_orig$Axon$SBNotificationBannerDestination$_postNotificationRequest$modal$completion$);}
        if (!vertical) {
            {Class _logos_class$AxonHorizontal$SBDashBoardCombinedListViewController = objc_getClass("SBDashBoardCombinedListViewController"); MSHookMessageEx(_logos_class$AxonHorizontal$SBDashBoardCombinedListViewController, @selector(viewDidLoad), (IMP)&_logos_method$AxonHorizontal$SBDashBoardCombinedListViewController$viewDidLoad, (IMP*)&_logos_orig$AxonHorizontal$SBDashBoardCombinedListViewController$viewDidLoad);Class _logos_class$AxonHorizontal$CSCombinedListViewController = objc_getClass("CSCombinedListViewController"); MSHookMessageEx(_logos_class$AxonHorizontal$CSCombinedListViewController, @selector(viewDidLoad), (IMP)&_logos_method$AxonHorizontal$CSCombinedListViewController$viewDidLoad, (IMP*)&_logos_orig$AxonHorizontal$CSCombinedListViewController$viewDidLoad);}
        } else {
            {Class _logos_class$AxonVertical$NCNotificationCombinedListViewController = objc_getClass("NCNotificationCombinedListViewController"); MSHookMessageEx(_logos_class$AxonVertical$NCNotificationCombinedListViewController, @selector(insetMargins), (IMP)&_logos_method$AxonVertical$NCNotificationCombinedListViewController$insetMargins, (IMP*)&_logos_orig$AxonVertical$NCNotificationCombinedListViewController$insetMargins);MSHookMessageEx(_logos_class$AxonVertical$NCNotificationCombinedListViewController, @selector(collectionView:layout:sizeForItemAtIndexPath:), (IMP)&_logos_method$AxonVertical$NCNotificationCombinedListViewController$collectionView$layout$sizeForItemAtIndexPath$, (IMP*)&_logos_orig$AxonVertical$NCNotificationCombinedListViewController$collectionView$layout$sizeForItemAtIndexPath$);{ char _typeEncoding[1024]; sprintf(_typeEncoding, "%s@:", @encode(BOOL)); class_addMethod(_logos_class$AxonVertical$NCNotificationCombinedListViewController, @selector(axnAllowChanges), (IMP)&_logos_method$AxonVertical$NCNotificationCombinedListViewController$axnAllowChanges, _typeEncoding); sprintf(_typeEncoding, "v@:%s", @encode(BOOL)); class_addMethod(_logos_class$AxonVertical$NCNotificationCombinedListViewController, @selector(setAxnAllowChanges:), (IMP)&_logos_method$AxonVertical$NCNotificationCombinedListViewController$setAxnAllowChanges, _typeEncoding); } Class _logos_class$AxonVertical$NCNotificationStructuredListViewController = objc_getClass("NCNotificationStructuredListViewController"); MSHookMessageEx(_logos_class$AxonVertical$NCNotificationStructuredListViewController, @selector(insetMargins), (IMP)&_logos_method$AxonVertical$NCNotificationStructuredListViewController$insetMargins, (IMP*)&_logos_orig$AxonVertical$NCNotificationStructuredListViewController$insetMargins);{ char _typeEncoding[1024]; sprintf(_typeEncoding, "%s@:", @encode(BOOL)); class_addMethod(_logos_class$AxonVertical$NCNotificationStructuredListViewController, @selector(axnAllowChanges), (IMP)&_logos_method$AxonVertical$NCNotificationStructuredListViewController$axnAllowChanges, _typeEncoding); sprintf(_typeEncoding, "v@:%s", @encode(BOOL)); class_addMethod(_logos_class$AxonVertical$NCNotificationStructuredListViewController, @selector(setAxnAllowChanges:), (IMP)&_logos_method$AxonVertical$NCNotificationStructuredListViewController$setAxnAllowChanges, _typeEncoding); } }
        }
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, displayStatusChanged, CFSTR("com.apple.iokit.hid.displayStatus"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        return;
    }
    
    #pragma mark my addition

    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setObject:[NSNumber numberWithInt:501] forKey:NSFileOwnerAccountID];
    [attributes setObject:[NSNumber numberWithInt:501] forKey:NSFileGroupOwnerAccountID];

    NSFileManager *manager = [NSFileManager defaultManager];

    if (![manager fileExistsAtPath:configPath]) {
        if(![manager fileExistsAtPath:configPath.stringByDeletingLastPathComponent isDirectory:nil]) {
            [manager createDirectoryAtPath:configPath.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:attributes error:NULL];
        }
        [manager createFileAtPath:configPath contents:nil attributes:attributes];
        [@{@"entries":@[]} writeToFile:configPath atomically:YES];
    }
    config = [NSMutableDictionary dictionaryWithContentsOfFile:configPath];
}
