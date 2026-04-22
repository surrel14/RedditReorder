#import <UIKit/UIKit.h>

static NSString *SafeString(NSString *value) {
    return value.length ? value : @"<nil>";
}

static NSString *BuildTabsReport(UITabBarController *tabController) {
    NSMutableString *report = [NSMutableString string];
    NSArray<UIViewController *> *controllers = tabController.viewControllers;

    [report appendFormat:@"Tab controller class: %@\n", NSStringFromClass([tabController class])];
    [report appendFormat:@"Tab count: %lu\n\n", (unsigned long)controllers.count];

    NSInteger idx = 0;
    for (UIViewController *vc in controllers) {
        UITabBarItem *item = vc.tabBarItem;

        [report appendFormat:@"[%ld]\n", (long)idx];
        [report appendFormat:@"Class: %@\n", NSStringFromClass([vc class])];
        [report appendFormat:@"vc.title: %@\n", SafeString(vc.title)];
        [report appendFormat:@"tabBarItem.title: %@\n", SafeString(item.title)];
        [report appendFormat:@"tag: %ld\n", (long)item.tag];

        if ([vc respondsToSelector:@selector(childViewControllers)]) {
            NSArray<UIViewController *> *children = vc.childViewControllers;
            [report appendFormat:@"child count: %lu\n", (unsigned long)children.count];
            for (UIViewController *child in children) {
                [report appendFormat:@"  child: %@\n", NSStringFromClass([child class])];
            }
        }

        [report appendString:@"\n"];
        idx++;
    }

    return report.copy;
}

static void ShowTabsReport(UITabBarController *tabController) {
    if (!tabController) return;

    NSString *report = BuildTabsReport(tabController);

    dispatch_async(dispatch_get_main_queue(), ^{
        UIPasteboard.generalPasteboard.string = report;

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"RedditTabOrder Debug"
                                                                       message:report
                                                                preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction actionWithTitle:@"Close"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];

        UIViewController *presenter = tabController.presentedViewController ?: tabController;
        [presenter presentViewController:alert animated:YES completion:nil];
    });
}

%hook UITabBarController

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    static BOOL shownOnce = NO;
    if (shownOnce) return;
    shownOnce = YES;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        ShowTabsReport((UITabBarController *)self);
    });
}

%end
