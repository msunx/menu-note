#import "MNNoteController.h"
#import <WebKit/WebKit.h>

static NSString * const MNBlocksDefaultsKey = @"MenuNoteBlocks";
static NSString * const MNMarkdownDefaultsKey = @"MenuNoteMarkdown";
static NSString * const MNRichTextDefaultsKey = @"MenuNoteRichTextHTML";
static NSString * const MNThemeDefaultsKey = @"MenuNoteTheme";

static NSString *MNEscapeHTML(NSString *value) {
    NSString *escaped = [value stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
    return [escaped stringByReplacingOccurrencesOfString:@"'" withString:@"&#039;"];
}

static NSString *MNReplacePattern(NSString *value, NSString *pattern, NSString *templateValue) {
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    if (!expression) return value;
    return [expression stringByReplacingMatchesInString:value options:0 range:NSMakeRange(0, value.length) withTemplate:templateValue];
}

static NSString *MNInlineRichHTML(NSString *value) {
    NSString *html = MNEscapeHTML(value);
    html = MNReplacePattern(html, @"`([^`]+)`", @"<code>$1</code>");
    html = MNReplacePattern(html, @"\\*\\*([^*]+)\\*\\*", @"<strong>$1</strong>");
    html = MNReplacePattern(html, @"__([^_]+)__", @"<strong>$1</strong>");
    html = MNReplacePattern(html, @"(?<!\\*)\\*([^*]+)\\*(?!\\*)", @"<em>$1</em>");
    html = MNReplacePattern(html, @"\\[([^]]+)\\]\\((https?://[^ )]+)\\)", @"<a href=\"$2\">$1</a>");
    return html;
}

@interface MNNoteController () <WKScriptMessageHandler, WKNavigationDelegate>
@property(nonatomic, strong) WKWebView *webView;
@property(nonatomic, copy, readwrite) NSString *currentTheme;
@property(nonatomic) BOOL previewContent;
@property(nonatomic) BOOL awakeState;
@property(nonatomic) BOOL finderExtensionState;
@end

@implementation MNNoteController

- (instancetype)initWithPreviewContent:(BOOL)previewContent {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _previewContent = previewContent;
        NSString *savedTheme = [NSUserDefaults.standardUserDefaults stringForKey:MNThemeDefaultsKey];
        if ([savedTheme isEqualToString:@"light"] || [savedTheme isEqualToString:@"dark"]) {
            _currentTheme = savedTheme;
        } else {
            _currentTheme = @"dark";
        }
    }
    return self;
}

- (void)loadView {
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    configuration.websiteDataStore = WKWebsiteDataStore.nonPersistentDataStore;
    configuration.preferences.javaScriptCanOpenWindowsAutomatically = NO;

    WKUserContentController *contentController = [WKUserContentController new];
    [contentController addScriptMessageHandler:self name:@"menuNoteSave"];
    [contentController addScriptMessageHandler:self name:@"menuNoteTheme"];
    [contentController addScriptMessageHandler:self name:@"menuNoteAwake"];
    [contentController addScriptMessageHandler:self name:@"menuNoteFinder"];
    [contentController addScriptMessageHandler:self name:@"menuNoteQuit"];

    NSDictionary *initialState = @{ @"html": [self initialRichTextHTML] };
    NSString *stateJSON = [self JSONStringForObject:initialState fallback:@"{\"html\":\"\"}"];
    NSString *themeJSON = [self JSONStringForObject:self.currentTheme fallback:@"\"light\""];
    NSString *bootstrap = [NSString stringWithFormat:@"window.__MENU_NOTE_INITIAL__ = %@; window.__MENU_NOTE_THEME__ = %@; window.__MENU_NOTE_AWAKE__ = %@; window.__MENU_NOTE_FINDER_ENABLED__ = %@;",
        stateJSON,
        themeJSON,
        self.awakeState ? @"true" : @"false",
        self.finderExtensionState ? @"true" : @"false"];
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:bootstrap injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    [contentController addUserScript:userScript];
    configuration.userContentController = contentController;

    self.webView = [[WKWebView alloc] initWithFrame:NSMakeRect(0, 0, 380, 480) configuration:configuration];
    self.webView.navigationDelegate = self;
    self.webView.allowsMagnification = NO;
    self.webView.underPageBackgroundColor = NSColor.clearColor;
    self.webView.wantsLayer = YES;
    self.webView.layer.backgroundColor = NSColor.clearColor.CGColor;
    self.webView.layer.opaque = NO;
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;

    NSVisualEffectView *glassView = [[NSVisualEffectView alloc] initWithFrame:NSMakeRect(0, 0, 380, 480)];
    glassView.material = NSVisualEffectMaterialUnderWindowBackground;
    glassView.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    glassView.state = NSVisualEffectStateActive;
    glassView.wantsLayer = YES;
    glassView.layer.backgroundColor = NSColor.clearColor.CGColor;
    [glassView addSubview:self.webView];
    [NSLayoutConstraint activateConstraints:@[
        [self.webView.leadingAnchor constraintEqualToAnchor:glassView.leadingAnchor],
        [self.webView.trailingAnchor constraintEqualToAnchor:glassView.trailingAnchor],
        [self.webView.topAnchor constraintEqualToAnchor:glassView.topAnchor],
        [self.webView.bottomAnchor constraintEqualToAnchor:glassView.bottomAnchor]
    ]];

    self.view = glassView;
    self.preferredContentSize = NSMakeSize(380, 480);

    NSURL *webDirectory = [NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"Web" isDirectory:YES];
    NSURL *indexURL = [webDirectory URLByAppendingPathComponent:@"index.html"];
    [self.webView loadFileURL:indexURL allowingReadAccessToURL:webDirectory];
}

- (NSString *)initialRichTextHTML {
    if (self.previewContent) {
        return @"<div><strong class=\"text-color-blue\">今天</strong> · <span class=\"text-color-mauve\">把重要的事写下来</span></div><div><br></div>"
            "<div class=\"todo-row\" data-checked=\"true\"><button class=\"todo-check\" type=\"button\" contenteditable=\"false\"></button><span class=\"todo-text\">完成菜单栏编辑器</span></div>"
            "<div class=\"todo-row\" data-checked=\"true\"><button class=\"todo-check\" type=\"button\" contenteditable=\"false\"></button><span class=\"todo-text\">打磨交互细节</span></div>"
            "<div class=\"todo-row\" data-checked=\"false\"><button class=\"todo-check\" type=\"button\" contenteditable=\"false\"></button>"
            "<span class=\"todo-text text-color-green\">录制演示</span></div>"
            "<div class=\"todo-row\" data-checked=\"false\"><button class=\"todo-check\" type=\"button\" contenteditable=\"false\"></button>"
            "<span class=\"todo-text text-color-peach\">发布 ✨</span></div>";
    }

    NSString *savedRichText = [NSUserDefaults.standardUserDefaults stringForKey:MNRichTextDefaultsKey];
    if (savedRichText) return savedRichText;

    NSString *savedMarkdown = [NSUserDefaults.standardUserDefaults stringForKey:MNMarkdownDefaultsKey];
    if (!savedMarkdown) savedMarkdown = [self markdownFromLegacyBlocks];
    if (!savedMarkdown) return @"";

    NSString *richText = [self richTextHTMLFromMarkdown:savedMarkdown];
    [NSUserDefaults.standardUserDefaults setObject:richText forKey:MNRichTextDefaultsKey];
    return richText;
}

- (nullable NSString *)markdownFromLegacyBlocks {
    NSArray *savedBlocks = [NSUserDefaults.standardUserDefaults arrayForKey:MNBlocksDefaultsKey];
    if (!savedBlocks) return nil;
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    for (NSDictionary *block in savedBlocks) {
        if (![block isKindOfClass:NSDictionary.class]) continue;
        NSString *type = [block[@"type"] isKindOfClass:NSString.class] ? block[@"type"] : @"";
        NSString *text = [block[@"text"] isKindOfClass:NSString.class] ? block[@"text"] : @"";
        if ([type isEqualToString:@"todo"]) [parts addObject:[NSString stringWithFormat:@"- [%@] %@", [block[@"checked"] boolValue] ? @"x" : @" ", text]];
        else if ([type isEqualToString:@"list"]) [parts addObject:[NSString stringWithFormat:@"- %@", text]];
        else if ([type isEqualToString:@"text"]) [parts addObject:text];
    }
    return [parts componentsJoinedByString:@"\n\n"];
}

- (NSString *)richTextHTMLFromMarkdown:(NSString *)markdown {
    NSArray<NSString *> *lines = [markdown componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet];
    NSMutableArray<NSString *> *html = [NSMutableArray array];
    __block NSString *openList = nil;
    NSRegularExpression *taskExpression = [NSRegularExpression regularExpressionWithPattern:@"^\\s*[-*+]\\s+\\[([ xX])\\]\\s+(.*)$"
                                                                                       options:0
                                                                                         error:nil];
    NSRegularExpression *bulletExpression = [NSRegularExpression regularExpressionWithPattern:@"^\\s*[-*+]\\s+(.*)$"
                                                                                         options:0
                                                                                           error:nil];
    NSRegularExpression *orderedExpression = [NSRegularExpression regularExpressionWithPattern:@"^\\s*\\d+\\.\\s+(.*)$"
                                                                                          options:0
                                                                                            error:nil];

    void (^closeList)(void) = ^{
        if (openList) {
            [html addObject:[NSString stringWithFormat:@"</%@>", openList]];
            openList = nil;
        }
    };

    for (NSString *line in lines) {
        NSTextCheckingResult *task = [taskExpression firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
        NSTextCheckingResult *bullet = [bulletExpression firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
        NSTextCheckingResult *ordered = [orderedExpression firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];

        if (task) {
            closeList();
            NSString *checkedValue = [line substringWithRange:[task rangeAtIndex:1]];
            NSString *text = MNInlineRichHTML([line substringWithRange:[task rangeAtIndex:2]]);
            BOOL checked = [checkedValue.lowercaseString isEqualToString:@"x"];
            NSString *todoHTML = [NSString stringWithFormat:
                @"<div class=\"todo-row\" data-checked=\"%@\"><button class=\"todo-check\" type=\"button\" contenteditable=\"false\"></button><span class=\"todo-text\">%@</span></div>",
                checked ? @"true" : @"false",
                text];
            [html addObject:todoHTML];
        } else if (bullet || ordered) {
            NSString *listName = bullet ? @"ul" : @"ol";
            if (![openList isEqualToString:listName]) {
                closeList();
                openList = listName;
                [html addObject:[NSString stringWithFormat:@"<%@>", listName]];
            }
            NSTextCheckingResult *match = bullet ?: ordered;
            [html addObject:[NSString stringWithFormat:@"<li>%@</li>", MNInlineRichHTML([line substringWithRange:[match rangeAtIndex:1]])]];
        } else {
            closeList();
            if (line.length == 0) [html addObject:@"<div><br></div>"];
            else if ([line hasPrefix:@"### "]) [html addObject:[NSString stringWithFormat:@"<div><strong>%@</strong></div>", MNInlineRichHTML([line substringFromIndex:4])]];
            else if ([line hasPrefix:@"## "]) [html addObject:[NSString stringWithFormat:@"<div><strong>%@</strong></div>", MNInlineRichHTML([line substringFromIndex:3])]];
            else if ([line hasPrefix:@"# "]) [html addObject:[NSString stringWithFormat:@"<div><strong>%@</strong></div>", MNInlineRichHTML([line substringFromIndex:2])]];
            else if ([line hasPrefix:@"> "]) [html addObject:[NSString stringWithFormat:@"<blockquote>%@</blockquote>", MNInlineRichHTML([line substringFromIndex:2])]];
            else [html addObject:[NSString stringWithFormat:@"<div>%@</div>", MNInlineRichHTML(line)]];
        }
    }
    closeList();
    return [html componentsJoinedByString:@""];
}

- (NSString *)JSONStringForObject:(id)object fallback:(NSString *)fallback {
    if (![NSJSONSerialization isValidJSONObject:object]) return fallback;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
    if (!data) return fallback;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: fallback;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    (void)userContentController;
    if ([message.name isEqualToString:@"menuNoteSave"]) {
        [self saveMessageBody:message.body];
        return;
    }
    if ([message.name isEqualToString:@"menuNoteTheme"] && [message.body isKindOfClass:NSString.class]) {
        NSString *theme = message.body;
        if (![theme isEqualToString:@"light"] && ![theme isEqualToString:@"dark"]) return;
        self.currentTheme = theme;
        [NSUserDefaults.standardUserDefaults setObject:theme forKey:MNThemeDefaultsKey];
        if (self.themeHandler) self.themeHandler(theme);
        return;
    }
    if ([message.name isEqualToString:@"menuNoteAwake"] && [message.body respondsToSelector:@selector(boolValue)]) {
        if (self.awakeHandler) self.awakeHandler([message.body boolValue]);
        return;
    }
    if ([message.name isEqualToString:@"menuNoteFinder"] && self.finderExtensionHandler) {
        self.finderExtensionHandler();
        return;
    }
    if ([message.name isEqualToString:@"menuNoteQuit"] && self.quitHandler) self.quitHandler();
}

- (void)setAwakeEnabled:(BOOL)enabled {
    self.awakeState = enabled;
    if (!self.webView) return;
    NSString *script = [NSString stringWithFormat:@"window.__MENU_NOTE_SET_AWAKE__ && window.__MENU_NOTE_SET_AWAKE__(%@);", enabled ? @"true" : @"false"];
    [self.webView evaluateJavaScript:script completionHandler:nil];
}

- (void)setFinderExtensionEnabled:(BOOL)enabled {
    self.finderExtensionState = enabled;
    if (!self.webView) return;
    NSString *script = [NSString stringWithFormat:@"window.__MENU_NOTE_SET_FINDER_ENABLED__ && window.__MENU_NOTE_SET_FINDER_ENABLED__(%@);", enabled ? @"true" : @"false"];
    [self.webView evaluateJavaScript:script completionHandler:nil];
}

- (void)saveMessageBody:(id)body {
    if (self.previewContent || ![body isKindOfClass:NSDictionary.class]) return;
    NSString *html = [body[@"html"] isKindOfClass:NSString.class] ? body[@"html"] : nil;
    if (html) [NSUserDefaults.standardUserDefaults setObject:html forKey:MNRichTextDefaultsKey];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    (void)webView;
    (void)navigation;
    NSLog(@"Menu Note 页面加载失败：%@", error.localizedDescription);
}

@end
