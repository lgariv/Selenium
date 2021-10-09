#import "AXNView.h"
#import "RandomHeaders.h"
#import "Protocol.h"

@interface AXNManager : NSObject

@property (nonatomic, retain) NSMutableDictionary *notificationRequests;
@property (nonatomic, retain) NSMutableDictionary *names;
@property (nonatomic, retain) NSMutableDictionary *timestamps;
@property (nonatomic, retain) NSMutableDictionary *iconStore;
@property (nonatomic, retain) NSMutableDictionary *backgroundColorCache;
@property (nonatomic, retain) NSMutableDictionary *textColorCache;
@property (nonatomic, retain) NSMutableDictionary *countCache;
@property (nonatomic, retain) UIColor *fallbackColor;
@property (nonatomic, weak) NCNotificationRequest *latestRequest;
@property (nonatomic, weak) AXNView *view;
@property (nonatomic, weak) id<clvc> clvc;
@property (nonatomic, weak) id sbclvc;
@property (nonatomic, weak) NCNotificationDispatcher *dispatcher;
+(instancetype)sharedInstance;
-(id)init;
-(void)getRidOfWaste;
-(void)insertNotificationRequest:(id)req;
-(void)removeNotificationRequest:(id)req;
-(void)modifyNotificationRequest:(id)req;
-(UIImage *)getIcon:(NSString *)bundleIdentifier;
-(UIImage *)getIcon:(NSString *)bundleIdentifier rounded:(BOOL)rounded;
-(void)clearAll:(NSString *)bundleIdentifier;
-(void)clearAll;

-(void)showNotificationRequest:(id)req;
-(void)hideNotificationRequest:(id)req;
-(void)showDNDNotificationRequests:(id)reqs;

-(void)showNotificationRequests:(id)reqs;
-(void)hideNotificationRequests:(id)reqs;

-(id)requestsForBundleIdentifier:(NSString *)bundleIdentifier;
-(NSArray *)allRequestsForBundleIdentifier:(NSString *)bundleIdentifier;
-(void)showNotificationRequestsForBundleIdentifier:(NSString *)bundleIdentifier;
-(void)showAllNotificationRequests;
-(void)hideAllNotificationRequests;
-(void)hideAllNotificationRequestsExcept:(id)notification;
-(void)revealNotificationHistory:(BOOL)revealed;
-(id)allNotificationRequests;

-(id)coalescedNotificationForRequest:(id)req ;

-(void)invalidateCountCache;
-(void)updateCountForBundleIdentifier:(NSString *)bundleIdentifier;
-(NSInteger)countForBundleIdentifier:(NSString *)bundleIdentifier;

@end
