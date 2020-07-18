

/**
 * Presents a view controller modally by superposing it's view on top of the
 * presenting's view, but retaining it's context.
 *
 * Useful for creating a modal presentation with a dimmed background.
 */

#import "cpc.h"

static const CGFloat CustomPresentationAnimationDuration = 1.5f;

__weak IBOutlet UIView *conViewers;

@interface CustomPresentationController () <UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate>

@property (assign, nonatomic) BOOL isPresenting;
@property (assign, nonatomic) CustomPresentationAnimation animation;
@property (assign, nonatomic) CGFloat duration;

@end

@implementation CustomPresentationController

- (instancetype)init
{
    if (self = [super init]) {
        self.duration = CustomPresentationAnimationDuration;
    }
    
    return self;
}

/*- (void)presentViewController:(UIViewController *)presentedViewController
           fromViewController:(UIViewController *)presentingViewController
        presentationAnimation:(CustomPresentationAnimation)animation
{
    self.animation = animation;
    presentedViewController.modalPresentationStyle = 7;
    presentedViewController.modalPresentationCapturesStatusBarAppearance = YES;
    presentedViewController.transitioningDelegate = self;

    [presentedViewController setNeedsStatusBarAppearanceUpdate];

    //this means the same controller is already pushed, lets skip this call then
    if ([presentingViewController.presentedViewController isKindOfClass:presentedViewController.class]) {
        return;
    }
    [presentingViewController presentViewController:presentedViewController
                                           animated:YES
                                         completion:nil];
}*/

- (void)presentViewController:(UIViewController *)presentedViewController
           fromViewController:(UIViewController *)presentingViewController
        presentationAnimation:(CustomPresentationAnimation)animation
                     duration:(CGFloat)duration
{
    self.duration = duration;
    
    [self presentViewController:presentedViewController
             fromViewController:presentingViewController
          presentationAnimation:animation];
}

#pragma mark - UIViewController transition delegate

- (id <UIViewControllerAnimatedTransitioning> )animationControllerForPresentedController:(UIViewController *)presented

                                                                    presentingController:(UIViewController *)presenting
                                                                        sourceController:(UIViewController *)source
{
    self.isPresenting = YES;
    
    return self;
}

- (id <UIViewControllerAnimatedTransitioning> )animationControllerForDismissedController:(UIViewController *)dismissed
{
    self.isPresenting = NO;
    
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning protocol

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning> )transitionContext
{
    return CustomPresentationAnimationDuration;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning> )transitionContext
{
    UIViewController *firstVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *secondVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = [transitionContext containerView];
    UIView *firstView = firstVC.view;
    UIView *secondView = secondVC.view;
    
    containerView.layer.cornerRadius = (100/3);
    firstView.layer.cornerRadius = (100/3);
    secondView.layer.cornerRadius = (100/3);

    BOOL isBottomToTopAnimation = self.animation == CustomPresentationAnimationBottomToTop;

    if (self.isPresenting) {
        [containerView addSubview:secondView];
        secondView.frame = (CGRect) {
            containerView.frame.origin.x,
            isBottomToTopAnimation ? containerView.frame.origin.y + (containerView.frame.size.height-300) : containerView.frame.origin.y,
            containerView.frame.size
        };
        
        secondView.alpha = isBottomToTopAnimation ? 1.f : 0.f;
        
        [UIView animateWithDuration:CustomPresentationAnimationDuration
                         animations: ^{
                             if (isBottomToTopAnimation) {
                                secondView.frame = (CGRect) {
                                    containerView.bounds.origin.x,
                                    containerView.bounds.origin.y + 300,
                                    containerView.bounds.size.width,
                                    containerView.bounds.size.height - 300
                                };
                                //containerView.bounds = secondView.frame;
                             }
                             else {
                                 secondView.alpha = 1.f;
                             }
                         } completion: ^(BOOL finished) {
                             [transitionContext completeTransition:YES];
                         }];
    }
    else {
        [UIView animateWithDuration:CustomPresentationAnimationDuration
                         animations: ^{
                             if (isBottomToTopAnimation) {
                                 firstView.frame = (CGRect) {
                                     containerView.frame.origin.x,
                                     containerView.frame.origin.y + containerView.frame.size.height,
                                     containerView.frame.size
                                 };
                             }
                             else {
                                 firstView.alpha = 0.f;
                             }
                         } completion: ^(BOOL finished) {
                             [transitionContext completeTransition:YES];
                         }];
    }
}

@end