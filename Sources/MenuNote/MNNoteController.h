#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MNNoteController : NSViewController

@property(nonatomic, copy, nullable) void (^quitHandler)(void);
@property(nonatomic, copy, nullable) void (^themeHandler)(NSString *theme);
@property(nonatomic, copy, nullable) void (^awakeHandler)(BOOL enabled);
@property(nonatomic, copy, readonly) NSString *currentTheme;

- (instancetype)initWithPreviewContent:(BOOL)previewContent;
- (void)setAwakeEnabled:(BOOL)enabled;

@end

NS_ASSUME_NONNULL_END
