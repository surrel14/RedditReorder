#import <UIKit/UIKit.h>

static NSArray<NSString *> *PreferredTabOrder(void) {
    // Cambia questo ordine come vuoi
    // Usa i titoli reali che Reddit mostra nella tab bar
    return @[
        @"Home",
        @"Inbox",
        @"Communities",
        @"Profile",
        @"Create"
    ];
}

static NSString *SafeTabTitle(UIViewController *vc) {
    if (!vc) return nil;

    NSString *title = vc.tabBarItem.title;
    if (title.length > 0) return title;

    if (vc.title.length > 0) return vc.title;

    return NSStringFromClass([vc class]);
}

static void LogTabs(NSArray<UIViewController *> *controllers, NSString *prefix) {
    NSLog(@"[RedditTabOrder] %@ count=%lu", prefix, (unsigned long)controllers.count);
    for (UIViewController *vc in controllers) {
        NSLog(@"[RedditTabOrder] tab class=%@ title=%@",
              NSStringFromClass([vc class]),
              SafeTabTitle(vc));
    }
}

static NSArray<UIViewController *> *ReorderedTabs(NSArray<UIViewController *> *controllers) {
    if (!controllers || controllers.count == 0) return controllers;

    NSArray<NSString *> *preferred = PreferredTabOrder();
    NSMutableArray<UIViewController *> *result = [NSMutableArray array];
    NSMutableSet<UIViewController *> *used = [NSMutableSet set];

    // Prima aggiunge le tab nel nostro ordine desiderato
    for (NSString *wantedTitle in preferred) {
        for (UIViewController *vc in controllers) {
            if ([used containsObject:vc]) continue;

            NSString *title = SafeTabTitle(vc);
            if ([title caseInsensitiveCompare:wantedTitle] == NSOrderedSame) {
                [result addObject:vc];
                [used addObject:vc];
                break;
            }
        }
    }

    // Poi aggiunge eventuali tab non matchate
    for (UIViewController *vc in controllers) {
        if (![used containsObject:vc]) {
            [result addObject:vc];
            [used addObject:vc];
        }
    }

    return result.copy;
}

static void ApplyTabOrderIfNeeded(UITabBarController *tabController) {
    if (!tabController) return;

    NSArray<UIViewController *> *controllers = tabController.viewControllers;
    if (!controllers || controllers.count < 2) return;

    LogTabs(controllers, @"before reorder");

    NSArray<UIViewController *> *reordered = ReorderedTabs(controllers);
    if (![controllers isEqualToArray:reordered]) {
        [tabController setViewControllers:reordered animated:NO];
        LogTabs(reordered, @"after reorder");
    }
}

%hook UITabBarController

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    // Dispatch async così aspettiamo eventuali update interni di Reddit
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
