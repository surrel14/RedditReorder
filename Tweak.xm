#import <UIKit/UIKit.h>

static NSString *SafeTabTitle(UIViewController *vc) {
    if (!vc) return nil;

    if (vc.tabBarItem.title.length > 0) return vc.tabBarItem.title;
    if (vc.title.length > 0) return vc.title;

    return NSStringFromClass([vc class]);
}

static void LogTabs(NSArray<UIViewController *> *controllers, NSString *prefix) {
    NSLog(@"[RedditTabOrder] %@ count=%lu", prefix, (unsigned long)controllers.count);
    NSInteger idx = 0;
    for (UIViewController *vc in controllers) {
        NSLog(@"[RedditTabOrder] idx=%ld class=%@ title=%@",
              (long)idx,
              NSStringFromClass([vc class]),
              SafeTabTitle(vc));
        idx++;
    }
}

static BOOL IsProtectedTab(UIViewController *vc) {
    NSString *title = SafeTabTitle(vc);
    if (!title) return NO;

    // Lasciamo queste tab dove sono
    if ([title caseInsensitiveCompare:@"Create"] == NSOrderedSame) return YES;
    if ([title caseInsensitiveCompare:@"Inbox"] == NSOrderedSame) return YES;

    return NO;
}

static NSInteger PreferredRankForTitle(NSString *title) {
    if (!title) return NSIntegerMax;

    if ([title caseInsensitiveCompare:@"Home"] == NSOrderedSame) return 0;
    if ([title caseInsensitiveCompare:@"Communities"] == NSOrderedSame) return 1;
    if ([title caseInsensitiveCompare:@"Profile"] == NSOrderedSame) return 2;

    return NSIntegerMax;
}

static NSArray<UIViewController *> *SafelyReorderTabs(NSArray<UIViewController *> *controllers) {
    if (!controllers || controllers.count < 2) return controllers;

    NSMutableArray<UIViewController *> *result = [controllers mutableCopy];

    // raccogliamo solo le tab non protette
    NSMutableArray<UIViewController *> *movable = [NSMutableArray array];
    NSMutableArray<NSNumber *> *movableIndexes = [NSMutableArray array];

    for (NSInteger i = 0; i < controllers.count; i++) {
        UIViewController *vc = controllers[i];
        if (!IsProtectedTab(vc)) {
            [movable addObject:vc];
            [movableIndexes addObject:@(i)];
        }
    }

    // ordina solo le tab mobili
    [movable sortUsingComparator:^NSComparisonResult(UIViewController *a, UIViewController *b) {
        NSInteger ra = PreferredRankForTitle(SafeTabTitle(a));
        NSInteger rb = PreferredRankForTitle(SafeTabTitle(b));

        if (ra < rb) return NSOrderedAscending;
        if (ra > rb) return NSOrderedDescending;
        return NSOrderedSame;
    }];

    // rimetti le tab mobili negli slot originali delle mobili
    for (NSInteger i = 0; i < movableIndexes.count; i++) {
        NSInteger targetIndex = movableIndexes[i].integerValue;
        result[targetIndex] = movable[i];
    }

    return result.copy;
}

static void ApplyTabOrderIfNeeded(UITabBarController *tabController) {
    if (!tabController) return;

    NSArray<UIViewController *> *controllers = tabController.viewControllers;
    if (!controllers || controllers.count < 2) return;

    LogTabs(controllers, @"before reorder");

    UIViewController *selected = tabController.selectedViewController;
    NSArray<UIViewController *> *reordered = SafelyReorderTabs(controllers);

    if (![controllers isEqualToArray:reordered]) {
        [tabController setViewControllers:reordered animated:NO];

        // ripristina il selected controller se ancora presente
        if (selected && [reordered containsObject:selected]) {
            tabController.selectedViewController = selected;
        }

        LogTabs(reordered, @"after reorder");
    }
}

%hook UITabBarController

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        ApplyTabOrderIfNeeded((UITabBarController *)self);
    });
}

- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers {
    %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        ApplyTabOrderIfNeeded((UITabBarController *)self);
    });
}

%end
