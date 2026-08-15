#import <Cocoa/Cocoa.h>
#import "MNNoteController.h"

static CGFloat const MNPopoverWidth = 350.0;
static CGFloat const MNPopoverHeight = 440.0;

static NSImage *MNMenuBarIcon(void) {
    NSImage *image = [NSImage imageWithSize:NSMakeSize(18, 18) flipped:NO drawingHandler:^BOOL(NSRect destinationRect) {
        (void)destinationRect;
        [NSColor.blackColor setStroke];

        NSBezierPath *leftCard = [NSBezierPath bezierPath];
        [leftCard moveToPoint:NSMakePoint(4.7, 10.7)];
        [leftCard lineToPoint:NSMakePoint(5.2, 15.7)];
        [leftCard lineToPoint:NSMakePoint(9.0, 15.3)];
        [leftCard lineToPoint:NSMakePoint(8.8, 11.0)];
        leftCard.lineWidth = 1.15;
        leftCard.lineJoinStyle = NSLineJoinStyleRound;
        [leftCard stroke];

        NSBezierPath *rightCard = [NSBezierPath bezierPath];
        [rightCard moveToPoint:NSMakePoint(9.1, 11.0)];
        [rightCard lineToPoint:NSMakePoint(9.5, 15.0)];
        [rightCard lineToPoint:NSMakePoint(13.2, 14.7)];
        [rightCard lineToPoint:NSMakePoint(13.0, 10.8)];
        rightCard.lineWidth = 1.15;
        rightCard.lineJoinStyle = NSLineJoinStyleRound;
        [rightCard stroke];

        NSBezierPath *pocket = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(2.1, 2.0, 13.8, 10.2) xRadius:3.0 yRadius:3.0];
        pocket.lineWidth = 1.35;
        [pocket stroke];

        NSBezierPath *lip = [NSBezierPath bezierPath];
        [lip moveToPoint:NSMakePoint(3.3, 10.8)];
        [lip curveToPoint:NSMakePoint(14.7, 10.8) controlPoint1:NSMakePoint(6.2, 11.4) controlPoint2:NSMakePoint(11.8, 11.4)];
        lip.lineWidth = 1.05;
        lip.lineCapStyle = NSLineCapStyleRound;
        [lip stroke];

        NSBezierPath *writing = [NSBezierPath bezierPath];
        [writing moveToPoint:NSMakePoint(5.0, 7.4)];
        [writing lineToPoint:NSMakePoint(11.9, 7.4)];
        [writing moveToPoint:NSMakePoint(5.0, 4.9)];
        [writing lineToPoint:NSMakePoint(9.8, 4.9)];
        writing.lineWidth = 1.25;
        writing.lineCapStyle = NSLineCapStyleRound;
        [writing stroke];
        return YES;
    }];
    image.template = YES;
    return image;
}

@interface MNAppDelegate : NSObject <NSApplicationDelegate, NSPopoverDelegate>
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSPopover *popover;
@property(nonatomic, strong) MNNoteController *noteController;
@property(nonatomic, strong, nullable) NSWindow *previewWindow;
@property(nonatomic) BOOL previewMode;
@end

@implementation MNAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    self.previewMode = [NSProcessInfo.processInfo.arguments containsObject:@"--preview"];
    [self configureApplicationMenu];

    self.noteController = [[MNNoteController alloc] initWithPreviewContent:self.previewMode];
    __weak typeof(self) weakSelf = self;
    self.noteController.quitHandler = ^{ [NSApp terminate:nil]; };
    self.noteController.themeHandler = ^(NSString *theme) { [weakSelf applyTheme:theme]; };
    [self applyTheme:self.noteController.currentTheme];

    if (self.previewMode) {
        [self showPreviewWindow];
        return;
    }

    [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    [self configureMenuBar];
    [self configurePopover];
}

- (void)configureApplicationMenu {
    NSMenu *mainMenu = [NSMenu new];

    NSMenuItem *appRoot = [[NSMenuItem alloc] initWithTitle:@"Menu Note" action:nil keyEquivalent:@""];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"Menu Note"];
    NSMenuItem *quit = [[NSMenuItem alloc] initWithTitle:@"退出 Menu Note" action:@selector(terminate:) keyEquivalent:@"q"];
    quit.target = NSApp;
    [appMenu addItem:quit];
    appRoot.submenu = appMenu;
    [mainMenu addItem:appRoot];

    NSMenuItem *editRoot = [[NSMenuItem alloc] initWithTitle:@"编辑" action:nil keyEquivalent:@""];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"编辑"];
    NSArray<NSArray<NSString *> *> *definitions = @[
        @[@"撤销", NSStringFromSelector(@selector(undo:)), @"z"],
        @[@"重做", NSStringFromSelector(@selector(redo:)), @"Z"],
        @[@"剪切", NSStringFromSelector(@selector(cut:)), @"x"],
        @[@"复制", NSStringFromSelector(@selector(copy:)), @"c"],
        @[@"粘贴", NSStringFromSelector(@selector(paste:)), @"v"],
        @[@"全选", NSStringFromSelector(@selector(selectAll:)), @"a"]
    ];
    for (NSArray<NSString *> *definition in definitions) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:definition[0] action:NSSelectorFromString(definition[1]) keyEquivalent:definition[2].lowercaseString];
        item.target = nil;
        if ([definition[0] isEqualToString:@"重做"]) item.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagShift;
        [editMenu addItem:item];
    }
    editRoot.submenu = editMenu;
    [mainMenu addItem:editRoot];
    NSApp.mainMenu = mainMenu;
}

- (void)configureMenuBar {
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSSquareStatusItemLength];
    NSStatusBarButton *button = self.statusItem.button;
    button.target = self;
    button.action = @selector(togglePopover:);
    button.toolTip = @"Menu Note · 临时记事";
    button.accessibilityLabel = @"打开 Menu Note";
    button.image = MNMenuBarIcon();
}

- (void)configurePopover {
    self.popover = [NSPopover new];
    self.popover.behavior = NSPopoverBehaviorTransient;
    self.popover.animates = !NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion;
    self.popover.contentViewController = self.noteController;
    self.popover.contentSize = NSMakeSize(MNPopoverWidth, MNPopoverHeight);
    self.popover.delegate = self;
}

- (void)togglePopover:(id)sender {
    (void)sender;
    if (self.popover.shown) {
        [self.popover performClose:nil];
        return;
    }
    NSStatusBarButton *button = self.statusItem.button;
    [self.popover showRelativeToRect:button.bounds ofView:button preferredEdge:NSRectEdgeMinY];
}

- (void)popoverDidShow:(NSNotification *)notification {
    (void)notification;
    NSWindow *popoverWindow = self.popover.contentViewController.view.window;
    popoverWindow.opaque = NO;
    popoverWindow.backgroundColor = NSColor.clearColor;
    [popoverWindow makeKeyWindow];
}

- (void)showPreviewWindow {
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    self.previewWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, MNPopoverWidth, MNPopoverHeight)
                                                      styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable
                                                        backing:NSBackingStoreBuffered
                                                          defer:NO];
    self.previewWindow.title = @"Menu Note · 界面预览";
    self.previewWindow.contentViewController = self.noteController;
    self.previewWindow.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;
    [self.previewWindow center];
    [self.previewWindow orderFrontRegardless];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)applyTheme:(NSString *)theme {
    NSAppearanceName name = [theme isEqualToString:@"dark"] ? NSAppearanceNameDarkAqua : NSAppearanceNameAqua;
    NSApp.appearance = [NSAppearance appearanceNamed:name];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    (void)sender;
    return self.previewMode;
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        (void)argc;
        (void)argv;
        NSApplication *application = NSApplication.sharedApplication;
        MNAppDelegate *delegate = [MNAppDelegate new];
        application.delegate = delegate;
        [application run];
    }
    return 0;
}
