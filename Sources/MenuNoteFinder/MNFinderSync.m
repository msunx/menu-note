#import <Cocoa/Cocoa.h>
#import <FinderSync/FinderSync.h>
#import <pwd.h>
#import <unistd.h>

static NSPasteboardType const MNCutPasteboardType = @"com.muyang.menunote.finder-cut";
static NSString * const MNFinderErrorDomain = @"com.muyang.menunote.finder";

static NSString *MNUserHomeDirectory(void) {
    struct passwd *user = getpwuid(getuid());
    if (user && user->pw_dir) return [NSString stringWithUTF8String:user->pw_dir].stringByStandardizingPath;
    return NSHomeDirectoryForUser(NSUserName()).stringByStandardizingPath;
}

@interface MNFinderSync : FIFinderSync
@end

@implementation MNFinderSync

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURL *rootURL = [NSURL fileURLWithPath:@"/" isDirectory:YES];
        FIFinderSyncController.defaultController.directoryURLs = [NSSet setWithObject:rootURL];
    }
    return self;
}

- (NSMenu *)menuForMenuKind:(FIMenuKind)menuKind {
    FIFinderSyncController *controller = FIFinderSyncController.defaultController;
    NSArray<NSURL *> *selectedURLs = [self normalizedFileURLs:controller.selectedItemURLs ?: @[]];
    NSURL *targetedURL = [self normalizedFileURL:controller.targetedURL];
    NSMenu *menu = [NSMenu new];

    if (menuKind == FIMenuKindContextualMenuForItems) {
        NSArray<NSURL *> *itemURLs = selectedURLs.count > 0 ? selectedURLs : (targetedURL ? @[targetedURL] : @[]);
        if (itemURLs.count == 0) return menu;

        NSMenuItem *cutItem = [self menuItemWithTitle:@"剪切" systemSymbolName:@"scissors" action:@selector(cutItems:)];
        cutItem.enabled = [self mutableFileURLs:itemURLs].count > 0;
        [menu addItem:cutItem];
        [menu addItem:[self menuItemWithTitle:@"复制目录" systemSymbolName:@"doc.on.doc" action:@selector(copySelectedPaths:)]];

        NSMenuItem *deleteItem = [self menuItemWithTitle:@"彻底删除" systemSymbolName:@"trash" action:@selector(deleteItemsPermanently:)];
        deleteItem.enabled = [self mutableFileURLs:itemURLs].count > 0;
        [menu addItem:deleteItem];
        return menu;
    }

    if (menuKind == FIMenuKindContextualMenuForContainer && targetedURL) {
        [menu addItem:[self menuItemWithTitle:@"复制目录" systemSymbolName:@"doc.on.doc" action:@selector(copyContainerPath:)]];

        NSArray<NSURL *> *cutURLs = [self cutURLsFromPasteboard];
        if (cutURLs.count > 0 && [self isDirectoryURL:targetedURL]) {
            [menu addItem:[self menuItemWithTitle:@"粘贴并移动" systemSymbolName:@"doc.on.clipboard" action:@selector(moveCutItems:)]];
        }
    }

    return menu;
}

- (NSMenuItem *)menuItemWithTitle:(NSString *)title systemSymbolName:(NSString *)systemSymbolName action:(SEL)action {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:@""];
    NSImage *image = [NSImage imageWithSystemSymbolName:systemSymbolName accessibilityDescription:title];
    NSImageSymbolConfiguration *configuration = [NSImageSymbolConfiguration configurationWithPointSize:14.0 weight:NSFontWeightRegular];
    item.image = [image imageWithSymbolConfiguration:configuration] ?: image;
    return item;
}

- (void)copySelectedPaths:(id)sender {
    (void)sender;
    NSLog(@"Menu Note Finder：执行所选项目路径复制");
    [self copyPaths:[self selectedItemURLs]];
}

- (void)copyContainerPath:(id)sender {
    (void)sender;
    NSLog(@"Menu Note Finder：执行当前文件夹路径复制");
    NSURL *targetedURL = [self normalizedFileURL:FIFinderSyncController.defaultController.targetedURL];
    [self copyPaths:targetedURL ? @[targetedURL] : @[]];
}

- (void)copyPaths:(NSArray<NSURL *> *)urls {
    NSMutableArray<NSString *> *paths = [NSMutableArray arrayWithCapacity:urls.count];
    for (NSURL *url in urls) {
        if (url.path.length > 0) [paths addObject:url.path];
    }
    if (paths.count == 0) return;

    NSPasteboard *pasteboard = NSPasteboard.generalPasteboard;
    [pasteboard clearContents];
    [pasteboard setString:[paths componentsJoinedByString:@"\n"] forType:NSPasteboardTypeString];
}

- (void)cutItems:(id)sender {
    (void)sender;
    NSLog(@"Menu Note Finder：执行剪切");
    NSArray<NSURL *> *mutableURLs = [self mutableFileURLs:[self selectedItemURLs]];
    if (mutableURLs.count == 0) return;
    [self writeCutURLsToPasteboard:mutableURLs];
}

- (void)deleteItemsPermanently:(id)sender {
    (void)sender;
    NSLog(@"Menu Note Finder：执行彻底删除");
    NSArray<NSURL *> *mutableURLs = [self mutableFileURLs:[self selectedItemURLs]];
    if (mutableURLs.count == 0) return;

    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSMutableArray<NSString *> *failures = [NSMutableArray array];
    for (NSURL *url in mutableURLs) {
        BOOL accessed = [url startAccessingSecurityScopedResource];
        NSError *error = nil;
        if (![fileManager removeItemAtURL:url error:&error]) [failures addObject:[self failureDescriptionForURL:url error:error]];
        if (accessed) [url stopAccessingSecurityScopedResource];
    }
    [self showFailures:failures title:@"部分项目未能彻底删除"];
}

- (void)moveCutItems:(id)sender {
    (void)sender;
    NSLog(@"Menu Note Finder：执行粘贴并移动");
    NSArray<NSURL *> *sourceURLs = [self cutURLsFromPasteboard];
    NSURL *destinationURL = [self normalizedFileURL:FIFinderSyncController.defaultController.targetedURL];
    if (sourceURLs.count == 0 || !destinationURL || ![self isDirectoryURL:destinationURL]) return;

    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSMutableArray<NSURL *> *remainingURLs = [NSMutableArray array];
    NSMutableArray<NSString *> *failures = [NSMutableArray array];
    for (NSURL *sourceURL in sourceURLs) {
        NSURL *targetURL = [destinationURL URLByAppendingPathComponent:sourceURL.lastPathComponent isDirectory:[self isDirectoryURL:sourceURL]];
        NSError *validationError = [self moveValidationErrorForSourceURL:sourceURL targetURL:targetURL];
        if (validationError) {
            [remainingURLs addObject:sourceURL];
            [failures addObject:[self failureDescriptionForURL:sourceURL error:validationError]];
            continue;
        }

        BOOL sourceAccessed = [sourceURL startAccessingSecurityScopedResource];
        BOOL destinationAccessed = [destinationURL startAccessingSecurityScopedResource];
        NSError *moveError = nil;
        if (![fileManager moveItemAtURL:sourceURL toURL:targetURL error:&moveError]) {
            [remainingURLs addObject:sourceURL];
            [failures addObject:[self failureDescriptionForURL:sourceURL error:moveError]];
        }
        if (destinationAccessed) [destinationURL stopAccessingSecurityScopedResource];
        if (sourceAccessed) [sourceURL stopAccessingSecurityScopedResource];
    }

    if (remainingURLs.count > 0) [self writeCutURLsToPasteboard:remainingURLs];
    else [NSPasteboard.generalPasteboard clearContents];
    [self showFailures:failures title:@"部分项目未能移动"];
}

- (NSArray<NSURL *> *)selectedItemURLs {
    FIFinderSyncController *controller = FIFinderSyncController.defaultController;
    NSArray<NSURL *> *selectedURLs = [self normalizedFileURLs:controller.selectedItemURLs ?: @[]];
    if (selectedURLs.count > 0) return selectedURLs;
    NSURL *targetedURL = [self normalizedFileURL:controller.targetedURL];
    return targetedURL ? @[targetedURL] : @[];
}

- (NSError *)moveValidationErrorForSourceURL:(NSURL *)sourceURL targetURL:(NSURL *)targetURL {
    NSString *sourcePath = sourceURL.path.stringByStandardizingPath;
    NSString *targetPath = targetURL.path.stringByStandardizingPath;
    if (sourcePath.length == 0 || targetPath.length == 0) return [self errorWithDescription:@"路径无效"];
    if ([sourcePath isEqualToString:targetPath]) return [self errorWithDescription:@"源位置和目标位置相同"];
    if ([self isDirectoryURL:sourceURL] && [targetPath hasPrefix:[sourcePath stringByAppendingString:@"/"]]) return [self errorWithDescription:@"不能把文件夹移动到它自身内部"];
    if ([NSFileManager.defaultManager fileExistsAtPath:targetPath]) return [self errorWithDescription:@"目标位置已存在同名项目"];
    if (![NSFileManager.defaultManager fileExistsAtPath:sourcePath]) return [self errorWithDescription:@"源项目已不存在"];
    return nil;
}

- (NSError *)errorWithDescription:(NSString *)description {
    return [NSError errorWithDomain:MNFinderErrorDomain code:1 userInfo:@{ NSLocalizedDescriptionKey: description }];
}

- (NSString *)failureDescriptionForURL:(NSURL *)url error:(NSError *)error {
    NSString *name = url.lastPathComponent.length > 0 ? url.lastPathComponent : url.path;
    return [NSString stringWithFormat:@"%@：%@", name, error.localizedDescription ?: @"未知错误"];
}

- (void)showFailures:(NSArray<NSString *> *)failures title:(NSString *)title {
    if (failures.count == 0) return;
    NSUInteger displayedCount = MIN(failures.count, 6);
    NSMutableArray<NSString *> *displayedFailures = [[failures subarrayWithRange:NSMakeRange(0, displayedCount)] mutableCopy];
    if (failures.count > displayedCount) [displayedFailures addObject:[NSString stringWithFormat:@"另有 %lu 个错误", (unsigned long)(failures.count - displayedCount)]];

    NSLog(@"Menu Note Finder：%@：%@", title, [displayedFailures componentsJoinedByString:@"；"]);
    NSBeep();
}

- (void)writeCutURLsToPasteboard:(NSArray<NSURL *> *)urls {
    NSMutableArray<NSString *> *paths = [NSMutableArray arrayWithCapacity:urls.count];
    for (NSURL *url in [self normalizedFileURLs:urls]) {
        if (url.path.length > 0) [paths addObject:url.path];
    }
    if (paths.count == 0) return;

    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:paths options:0 error:&error];
    if (!data) {
        NSLog(@"Menu Note Finder：保存剪切路径失败：%@", error.localizedDescription);
        NSBeep();
        return;
    }

    NSPasteboard *pasteboard = NSPasteboard.generalPasteboard;
    [pasteboard clearContents];
    [pasteboard setData:data forType:MNCutPasteboardType];
    [pasteboard setString:[paths componentsJoinedByString:@"\n"] forType:NSPasteboardTypeString];
}

- (NSArray<NSURL *> *)cutURLsFromPasteboard {
    NSPasteboard *pasteboard = NSPasteboard.generalPasteboard;
    NSData *data = [pasteboard dataForType:MNCutPasteboardType];
    if (data.length == 0) return @[];

    NSError *error = nil;
    id value = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (![value isKindOfClass:NSArray.class]) {
        NSLog(@"Menu Note Finder：读取剪切路径失败：%@", error.localizedDescription ?: @"数据格式无效");
        return @[];
    }

    NSMutableArray<NSURL *> *existingURLs = [NSMutableArray array];
    for (id path in (NSArray *)value) {
        if (![path isKindOfClass:NSString.class] || [(NSString *)path length] == 0) continue;
        NSString *normalizedPath = [(NSString *)path stringByStandardizingPath];
        if (![NSFileManager.defaultManager fileExistsAtPath:normalizedPath]) continue;
        [existingURLs addObject:[NSURL fileURLWithPath:normalizedPath]];
    }
    return [self normalizedFileURLs:existingURLs];
}

- (NSArray<NSURL *> *)mutableFileURLs:(NSArray<NSURL *> *)urls {
    NSString *homePath = MNUserHomeDirectory();
    NSMutableArray<NSURL *> *mutableURLs = [NSMutableArray array];
    for (NSURL *url in [self normalizedFileURLs:urls]) {
        NSString *path = url.path.stringByStandardizingPath;
        if (path.length == 0 || [path isEqualToString:@"/"] || [path isEqualToString:homePath]) continue;
        [mutableURLs addObject:url];
    }
    return mutableURLs;
}

- (NSArray<NSURL *> *)normalizedFileURLs:(NSArray *)urls {
    NSMutableArray<NSURL *> *normalizedURLs = [NSMutableArray array];
    NSMutableSet<NSString *> *seenPaths = [NSMutableSet set];
    for (id value in urls) {
        NSURL *url = [value isKindOfClass:NSURL.class] ? [self normalizedFileURL:value] : nil;
        if (!url || [seenPaths containsObject:url.path]) continue;
        [seenPaths addObject:url.path];
        [normalizedURLs addObject:url];
    }
    return normalizedURLs;
}

- (NSURL *)normalizedFileURL:(NSURL *)url {
    if (![url isKindOfClass:NSURL.class] || !url.fileURL || url.path.length == 0) return nil;
    return [NSURL fileURLWithPath:url.path.stringByStandardizingPath isDirectory:[self isDirectoryURL:url]];
}

- (BOOL)isDirectoryURL:(NSURL *)url {
    NSNumber *isDirectory = nil;
    return [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil] && isDirectory.boolValue;
}

@end
