#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

static UIViewController *CreateSideloadedTab(void) {
    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = [UIColor systemBackgroundColor];

    UIImage *icon = [UIImage systemImageNamed:@"globe"];
    UIImage *iconSelected = [UIImage systemImageNamed:@"globe"];
    vc.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Sideloaded"
                                                  image:icon
                                          selectedImage:iconSelected];

    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [vc.view addSubview:webView];

    [NSLayoutConstraint activateConstraints:@[
        [webView.topAnchor constraintEqualToAnchor:vc.view.safeAreaLayoutGuide.topAnchor],
        [webView.bottomAnchor constraintEqualToAnchor:vc.view.bottomAnchor],
        [webView.leadingAnchor constraintEqualToAnchor:vc.view.leadingAnchor],
        [webView.trailingAnchor constraintEqualToAnchor:vc.view.trailingAnchor]
    ]];

    NSURL *url = [NSURL URLWithString:@"https://www.reddit.com/r/sideloaded/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView loadRequest:request];

    return vc;
}

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

static BOOL HasCustomTab(NSArray<UIViewController *> *controllers) {
    for (UIViewController *vc in controllers) {
        if ([vc.tabBarItem.title isEqualToString:@"Sideloaded"]) {
            return YES;
        }
    }
    return NO;
}

static void AddCustomTab(UITabBarController *tab) {
    NSArray<UIViewController *> *orig = tab.viewControllers;
    if (!orig || orig.count == 0) return;
    if (HasCustomTab(orig)) return;

    NSMutableArray<UIViewController *> *tabs = [orig mutableCopy];
    UIViewController *customVC = CreateSideloadedTab();

    NSInteger createIndex = NSNotFound;
    for (NSInteger i = 0; i < (NSInteger)orig.count; i++) {
        if (IsCreateTab(orig[i])) {
            createIndex = i;
            break;
        }
    }

    // se troviamo Create, inseriamo la nuova tab dopo Create
    if (createIndex != NSNotFound && createIndex + 1 <= (NSInteger)tabs.count) {
        [tabs insertObject:customVC atIndex:createIndex + 1];
    } else {
        [tabs addObject:customVC];
    }

    UIViewController *selected = tab.selectedViewController;
    [tab setViewControllers:tabs animated:NO];

    if (selected && [tabs containsObject:selected]) {
        tab.selectedViewController = selected;
    }
}

%hook UITabBarController

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    static BOOL addedOnce = NO;
    if (addedOnce) return;
    addedOnce = YES;

    dispatch_async(dispatch_get_main_queue(), ^{
        AddCustomTab((UITabBarController *)self);
    });
}

%end
