#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface MNNoteController : NSViewController

@property(nonatomic, copy, nullable) void (^quitHandler)(void);
@property(nonatomic, copy, nullable) void (^themeHandler)(NSString *theme);
@property(nonatomic, copy, readonly) NSString *currentTheme;

- (instancetype)initWithPreviewContent:(BOOL)previewContent;

@end

NS_ASSUME_NONNULL_END

