#import <UIKit/UIKit.h>

static BOOL IsCreateTab(UIViewController *vc) {
    if ([vc respondsToSelector:@selector(childViewControllers)]) {
        NSArray<UIViewController *> *children = vc.childViewControllers;
        if (children.count == 1) {
            NSString *childClass = NSStringFromClass([children[0] class]);
            return [childClass containsString:@"DeprecatedBaseViewController"];
        }
    }
    return NO;
}

static NSString *GetTitle(UIViewController *vc) {
    NSString *title = vc.tabBarItem.title;
    return title ? title : @"";
}

static NSInteger Rank(UIViewController *vc) {
    NSString *title = GetTitle(vc);

    if ([title isEqualToString:@"Home"]) return 0;
    if ([title isEqualToString:@"Inbox"]) return 2;

    // tutto il resto va dopo
    return 3;
}

static NSArray<UIViewController *> *ReorderTabs(NSArray<UIViewController *> *controllers) {
    if (!controllers || controllers.count < 2) return controllers;

    NSMutableArray<UIViewController *> *result = [controllers mutableCopy];

    NSInteger createIndex = NSNotFound;
    UIViewController *createVC = nil;

    NSMutableArray<UIViewController *> *others = [NSMutableArray array];
    NSMutableArray<NSNumber *> *indexes = [NSMutableArray array];

    for (NSInteger i = 0; i < (NSInteger)controllers.count; i++) {
        UIViewController *vc = controllers[i];

        if (IsCreateTab(vc) && createIndex == NSNotFound) {
            createIndex = i;
            createVC = vc;
        } else {
            [others addObject:vc];
            [indexes addObject:@(i)];
        }
    }

    if (createIndex == NSNotFound || !createVC) {
        return controllers;
    }

    [others sortUsingComparator:^NSComparisonResult(UIViewController *a, UIViewController *b) {
        NSInteger ra = Rank(a);
        NSInteger rb = Rank(b);

        if (ra < rb) return NSOrderedAscending;
        if (ra > rb) return NSOrderedDescending;
        return NSOrderedSame;
    }];

    result[createIndex] = createVC;

    NSInteger cursor = 0;
    for (NSNumber *n in indexes) {
        NSInteger idx = n.integerValue;
        if (cursor < (NSInteger)others.count) {
            result[idx] = others[cursor];
            cursor++;
        }
    }

    return result.copy;
}

static void Apply(UITabBarController *tab) {
    NSArray<UIViewController *> *orig = tab.viewControllers;
    if (!orig || orig.count < 2) return;

    UIViewController *selected = tab.selectedViewController;
    NSArray<UIViewController *> *reordered = ReorderTabs(orig);

    if (![orig isEqualToArray:reordered]) {
        [tab setViewControllers:reordered animated:NO];

        if (selected && [reordered containsObject:selected]) {
            tab.selectedViewController = selected;
        }
    }
}

%hook UITabBarController

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        Apply((UITabBarController *)self);
    });
}

- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers {
    %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        Apply((UITabBarController *)self);
    });
}

%end
