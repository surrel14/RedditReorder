#import <UIKit/UIKit.h>

static NSString *SafeString(NSString *value) {
    return value.length ? value : @"<nil>";
}

static void DumpTabs(UITabBarController *tabController, NSString *prefix) {
    NSArray<UIViewController *> *controllers = tabController.viewControllers;
    NSLog(@"[RedditTabOrder] ===== %@ =====", prefix);
    NSLog(@"[RedditTabOrder] controller class = %@", NSStringFromClass([tabController class]));
    NSLog(@"[RedditTabOrder] tabs count = %lu", (unsigned long)controllers.count);

    NSInteger idx = 0;
    for (UIViewController *vc in controllers) {
        UITabBarItem *item = vc.tabBarItem;

        NSString *vcClass = NSStringFromClass([vc class]);
        NSString *title = SafeString(vc.title);
        NSString *tabTitle = SafeString(item.title);

        NSString *imageDesc = item.image ? [item.image description] : @"<nil>";
        NSString *selectedImageDesc = item.selectedImage ? [item.selectedImage description] : @"<nil>";

        NSLog(@"[RedditTabOrder] idx=%ld", (long)idx);
        NSLog(@"[RedditTabOrder]   vc class        = %@", vcClass);
        NSLog(@"[RedditTabOrder]   vc title        = %@", title);
        NSLog(@"[RedditTabOrder]   tab title       = %@", tabTitle);
        NSLog(@"[RedditTabOrder]   item tag        = %ld", (long)item.tag);
        NSLog(@"[RedditTabOrder]   image           = %@", imageDesc);
        NSLog(@"[RedditTabOrder]   selected image  = %@", selectedImageDesc);

        if ([vc respondsToSelector:@selector(childViewControllers)]) {
            NSArray<UIViewController *> *children = vc.childViewControllers;
            NSLog(@"[RedditTabOrder]   child count     = %lu", (unsigned long)children.count);
            for (UIViewController *child in children) {
                NSLog(@"[RedditTabOrder]     child class = %@", NSStringFromClass([child class]));
            }
        }

        idx++;
    }
}

%hook UITabBarController

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        DumpTabs((UITabBarController *)self, @"viewDidAppear");
    });
}

- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers {
    %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        DumpTabs((UITabBarController *)self, @"setViewControllers");
    });
}

%end
