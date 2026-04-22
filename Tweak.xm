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

static BOOL IsCreateTab(UIViewController *vc) {
    NSString *title = SafeTabTitle(vc);
    if (!title) return NO;
    return [title caseInsensitiveCompare:@"Create"] == NSOrderedSame;
}

static NSInteger PreferredRankForTitle(NSString *title) {
    if (!title) return NSIntegerMax;

    if ([title caseInsensitiveCompare:@"Home"] == NSOrderedSame) return 0;
    if ([title caseInsensitiveCompare:@"Communities"] == NSOrderedSame) return 1;
    if ([title caseInsensitiveCompare:@"Inbox"] == NSOrderedSame) return 2;
    if ([title caseInsensitiveCompare:@"Profile"] == NSOrderedSame) return 3;

    return NSIntegerMax;
}

static NSArray<UIViewController *> *ReorderKeepingCreateCentered(NSArray<UIViewController *> *controllers) {
    if (!controllers || controllers.count < 2) return controllers;

    NSMutableArray<UIViewController *> *result = [controllers mutableCopy];

    NSInteger createIndex = NSNotFound;
    UIViewController *createVC = nil;

    NSMutableArray<UIViewController *> *others = [NSMutableArray array];
    NSMutableArray<NSNumber *> *otherIndexes = [NSMutableArray array];

    for (NSInteger i = 0; i < controllers.count; i++) {
        UIViewController *vc = controllers[i];
        if (IsCreateTab(vc) && createIndex == NSNotFound) {
            createIndex = i;
            createVC = vc;
        } else {
            [others addObject:vc];
            [otherIndexes addObject:@(i)];
        }
    }

    if (createIndex == NSNotFound || !createVC) {
        NSLog(@"[RedditTabOrder] Create tab not found, skipping hardcoded reorder");
        return controllers;
    }

    [others sortUsingComparator:^NSComparisonResult(UIViewController *a, UIViewController *b) {
        NSInteger ra = PreferredRankForTitle(SafeTabTitle(a));
        NSInteger rb = PreferredRankForTitle(SafeTabTitle(b));

        if (ra < rb) return NSOrderedAscending;
        if (ra > rb) return NSOrderedDescending;
        return NSOrderedSame;
    }];

    // rimetti Create al suo indice originale
    result[createIndex] = createVC;

    // riempi gli altri slot con l'ordine desiderato
    NSInteger cursor = 0;
    for (NSNumber *idxNum in otherIndexes) {
        NSInteger idx = idxNum.integerValue;
        if (cursor < others.count) {
            result[idx] = others[cursor];
            cursor++;
        }
    }

    return result.copy;
}

static void ApplyTabOrderIfNeeded(UITabBarController *tabController) {
    if (!tabController) return;

    NSArray<UIViewController *> *controllers = tabController.viewControllers;
    if (!controllers || controllers.count < 2) return;

    LogTabs(controllers, @"before reorder");

    UIViewController *selected = tabController.selectedViewController;
    NSArray<UIViewController *> *reordered = ReorderKeepingCreateCentered(controllers);

    if (![controllers isEqualToArray:reordered]) {
        [tabController setViewControllers:reordered animated:NO];

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
