typedef enum {
    CustomPresentationAnimationBottomToTop,
    CustomPresentationAnimationFadeIn
} CustomPresentationAnimation;


@interface CustomPresentationController : NSObject

- (void)presentViewController:(UIViewController *)presentedViewController
           fromViewController:(UIViewController *)presentingViewController
        presentationAnimation:(CustomPresentationAnimation)animation;

- (void)presentViewController:(UIViewController *)presentedViewController
           fromViewController:(UIViewController *)presentingViewController
        presentationAnimation:(CustomPresentationAnimation)animation
                     duration:(CGFloat)duration;

@end
