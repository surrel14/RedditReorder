#import <UIKit/UIKit.h>

static BOOL IsCreateTab(UIViewController *vc) {
    if ([vc respondsToSelector:@selector(childViewControllers)]) {
        NSArray *children = vc.childViewControllers;
        if (children.count == 1) {
            NSString *childClass = NSStringFromClass([children[0] class]);
            return [childClass containsString:@"DeprecatedBaseViewController"];
        }
    }
    return NO;
}

static NSString *GetTitle(UIViewController *vc) {
    return vc.tabBarItem.title ?: @"";
}

static NSInteger Rank(UIViewController *vc) {
    NSString *title = GetTitle(vc);

    if ([title isEqualToString:@"Home"]) return 0;
    if ([title isEqualToString:@"Inbox"]) return 2;

    // tutto il resto (You)
    return 3;
}

static NSArray *ReorderTabs(NSArray *controllers) {
    if (controllers.count < 2) return controllers;

    NSMutableArray *result = [controllers mutableCopy];

    NSInteger createIndex = NSNotFound;
    UIViewController *createVC = nil;

    NSMutableArray *others = [NSMutableArray array];
    NSMutableArray *indexes = [NSMutableArray array];

    for (NSInteger i = 0; i < controllers.count; i++) {
        UIViewController *vc = controllers[i];

        if (IsCreateTab(vc)) {
            createIndex = i;
            createVC = vc;
        } else {
            [others addObject:vc];
            [indexes addObject:@(i)];
        }
    }

    if (createIndex == NSNotFound) return controllers;

    // ordina le altre
    [others sortUsingComparator:^NSComparisonResult(id a, id b) {
        NSInteger ra = Rank(a);
        NSInteger rb = Rank(b);
        return ra < rb ? NSOrderedAscending : NSOrderedDescending;
    }];

    // rimetti create dov'è
    result[createIndex] = createVC;

    // riempi gli altri slot
    NSInteger cursor = 0;
    for (NSNumber *n in indexes) {
        NSInteger i = n.integerValue;
        result[i] = others[cursor++];
    }

    return result;
}

static void Apply(UITabBarController *tab) {
    NSArray *orig = tab.viewControllers;
    if (!orig) return;

    UIViewController *selected = tab.selectedViewController;
    NSArray *new = ReorderTabs(orig);

    if (![orig isEqualToArray:new]) {
        [tab setViewControllers:new animated:NO];

        if ([new containsObject:selected]) {
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

- (void)setViewControllers:(NSArray *)viewControllers {
    %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        Apply((UITabBarController *)self);
    });
}

%end
