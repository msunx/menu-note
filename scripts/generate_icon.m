#import <Cocoa/Cocoa.h>

static NSColor *MNHex(NSUInteger rgb) {
    return [NSColor colorWithSRGBRed:((rgb >> 16) & 0xff) / 255.0 green:((rgb >> 8) & 0xff) / 255.0 blue:(rgb & 0xff) / 255.0 alpha:1.0];
}

static NSColor *MNHexAlpha(NSUInteger rgb, CGFloat alpha) {
    return [NSColor colorWithSRGBRed:((rgb >> 16) & 0xff) / 255.0 green:((rgb >> 8) & 0xff) / 255.0 blue:(rgb & 0xff) / 255.0 alpha:alpha];
}

static void DrawIcon(CGFloat size, NSString *path) {
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:NULL
                      pixelsWide:(NSInteger)size
                      pixelsHigh:(NSInteger)size
                   bitsPerSample:8
                 samplesPerPixel:4
                        hasAlpha:YES
                        isPlanar:NO
                  colorSpaceName:NSCalibratedRGBColorSpace
                     bytesPerRow:0
                    bitsPerPixel:0];
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = context;
    context.imageInterpolation = NSImageInterpolationHigh;

    NSRect tile = NSInsetRect(NSMakeRect(0, 0, size, size), size * 0.055, size * 0.055);
    NSBezierPath *background = [NSBezierPath bezierPathWithRoundedRect:tile xRadius:size * 0.22 yRadius:size * 0.22];
    [NSGraphicsContext saveGraphicsState];
    NSShadow *tileShadow = [NSShadow new];
    tileShadow.shadowColor = MNHexAlpha(0x5F7FC2, .24);
    tileShadow.shadowBlurRadius = size * .045;
    tileShadow.shadowOffset = NSMakeSize(0, -size * .018);
    [tileShadow set];
    NSGradient *backgroundGradient = [[NSGradient alloc] initWithStartingColor:MNHex(0xE9FBFF) endingColor:MNHex(0xCDD5FF)];
    [backgroundGradient drawInBezierPath:background angle:-45];
    [NSGraphicsContext restoreGraphicsState];

    NSBezierPath *aura = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(size * .55, size * .48, size * .38, size * .34)];
    [MNHexAlpha(0x72F1C0, .23) setFill];
    [aura fill];

    void (^drawCard)(NSRect, NSColor *, NSColor *) = ^(NSRect rect, NSColor *start, NSColor *end) {
        NSBezierPath *card = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:size * .04 yRadius:size * .04];
        [NSGraphicsContext saveGraphicsState];
        NSShadow *shadow = [NSShadow new];
        shadow.shadowColor = MNHexAlpha(0x27416E, .24);
        shadow.shadowBlurRadius = size * .026;
        shadow.shadowOffset = NSMakeSize(0, -size * .01);
        [shadow set];
        NSGradient *cardGradient = [[NSGradient alloc] initWithStartingColor:start endingColor:end];
        [cardGradient drawInBezierPath:card angle:75];
        [NSGraphicsContext restoreGraphicsState];
        card.lineWidth = MAX(1, size * .006);
        [MNHexAlpha(0xFFFFFF, .48) setStroke];
        [card stroke];
    };

    NSRect coralCard = NSMakeRect(size * .18, size * .47, size * .22, size * .34);
    NSRect violetCard = NSMakeRect(size * .39, size * .5, size * .24, size * .35);
    NSRect limeCard = NSMakeRect(size * .61, size * .48, size * .2, size * .31);
    drawCard(coralCard, MNHex(0xFF8EA1), MNHex(0xF05FAD));
    drawCard(violetCard, MNHex(0x757BFF), MNHex(0x4035B9));
    drawCard(limeCard, MNHex(0x9AF370), MNHex(0x35D3A1));

    if (size >= 64) {
        NSArray<NSValue *> *lineStarts = @[
            [NSValue valueWithPoint:NSMakePoint(size * .225, size * .735)],
            [NSValue valueWithPoint:NSMakePoint(size * .435, size * .777)],
            [NSValue valueWithPoint:NSMakePoint(size * .65, size * .72)]
        ];
        NSArray<NSNumber *> *lineWidths = @[@0.11, @0.14, @0.105];
        [MNHexAlpha(0xFFFFFF, .76) setStroke];
        for (NSUInteger index = 0; index < lineStarts.count; index++) {
            NSPoint start = lineStarts[index].pointValue;
            NSBezierPath *line = [NSBezierPath bezierPath];
            [line moveToPoint:start];
            [line lineToPoint:NSMakePoint(start.x + size * lineWidths[index].doubleValue, start.y)];
            line.lineWidth = MAX(1, size * .012);
            line.lineCapStyle = NSLineCapStyleRound;
            [line stroke];
        }
    }

    NSRect pocketRect = NSMakeRect(size * .105, size * .135, size * .79, size * .565);
    NSBezierPath *pocket = [NSBezierPath bezierPathWithRoundedRect:pocketRect xRadius:size * .135 yRadius:size * .135];
    [NSGraphicsContext saveGraphicsState];
    NSShadow *pocketShadow = [NSShadow new];
    pocketShadow.shadowColor = MNHexAlpha(0x177EA8, .36);
    pocketShadow.shadowBlurRadius = size * .065;
    pocketShadow.shadowOffset = NSMakeSize(0, -size * .028);
    [pocketShadow set];
    NSGradient *pocketGradient = [[NSGradient alloc] initWithStartingColor:MNHexAlpha(0x1FD0E9, .91) endingColor:MNHexAlpha(0x4C73EE, .92)];
    [pocketGradient drawInBezierPath:pocket angle:18];
    [NSGraphicsContext restoreGraphicsState];

    [NSGraphicsContext saveGraphicsState];
    [pocket addClip];
    NSBezierPath *cyanSheen = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(size * .05, size * .47, size * .56, size * .32)];
    [MNHexAlpha(0xFFFFFF, .17) setFill];
    [cyanSheen fill];
    NSBezierPath *greenGlow = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(size * .65, size * .37, size * .34, size * .35)];
    [MNHexAlpha(0x73F5B4, .18) setFill];
    [greenGlow fill];
    [NSGraphicsContext restoreGraphicsState];

    pocket.lineWidth = MAX(1, size * .009);
    [MNHexAlpha(0xFFFFFF, .58) setStroke];
    [pocket stroke];

    NSBezierPath *lip = [NSBezierPath bezierPath];
    [lip moveToPoint:NSMakePoint(size * .17, size * .658)];
    [lip curveToPoint:NSMakePoint(size * .83, size * .658) controlPoint1:NSMakePoint(size * .36, size * .683) controlPoint2:NSMakePoint(size * .66, size * .683)];
    lip.lineWidth = MAX(1, size * .009);
    lip.lineCapStyle = NSLineCapStyleRound;
    [MNHexAlpha(0xFFFFFF, .44) setStroke];
    [lip stroke];

    [MNHexAlpha(0xFFFFFF, .9) setStroke];
    NSBezierPath *todoBox = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(size * .22, size * .405, size * .068, size * .068) xRadius:size * .014 yRadius:size * .014];
    todoBox.lineWidth = MAX(1, size * .011);
    [todoBox stroke];
    NSBezierPath *firstLine = [NSBezierPath bezierPath];
    [firstLine moveToPoint:NSMakePoint(size * .34, size * .448)];
    [firstLine lineToPoint:NSMakePoint(size * .58, size * .448)];
    [firstLine moveToPoint:NSMakePoint(size * .22, size * .335)];
    [firstLine lineToPoint:NSMakePoint(size * .52, size * .335)];
    firstLine.lineWidth = MAX(1, size * .016);
    firstLine.lineCapStyle = NSLineCapStyleRound;
    [firstLine stroke];

    NSRect badgeRect = NSMakeRect(size * .66, size * .205, size * .16, size * .16);
    NSBezierPath *badge = [NSBezierPath bezierPathWithRoundedRect:badgeRect xRadius:size * .08 yRadius:size * .08];
    [NSGraphicsContext saveGraphicsState];
    NSShadow *badgeShadow = [NSShadow new];
    badgeShadow.shadowColor = MNHexAlpha(0x183B69, .28);
    badgeShadow.shadowBlurRadius = size * .025;
    badgeShadow.shadowOffset = NSMakeSize(0, -size * .01);
    [badgeShadow set];
    [MNHexAlpha(0xFFFFFF, .9) setFill];
    [badge fill];
    [NSGraphicsContext restoreGraphicsState];

    NSBezierPath *check = [NSBezierPath bezierPath];
    [check moveToPoint:NSMakePoint(size * .7, size * .282)];
    [check lineToPoint:NSMakePoint(size * .728, size * .252)];
    [check lineToPoint:NSMakePoint(size * .78, size * .316)];
    check.lineWidth = MAX(1, size * .012);
    check.lineCapStyle = NSLineCapStyleRound;
    check.lineJoinStyle = NSLineJoinStyleRound;
    [MNHex(0x248FAF) setStroke];
    [check stroke];

    [NSGraphicsContext restoreGraphicsState];
    NSData *png = [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    [png writeToFile:path atomically:YES];
}

static void AppendUInt32(NSMutableData *data, uint32_t value) {
    uint32_t bigEndian = CFSwapInt32HostToBig(value);
    [data appendBytes:&bigEndian length:sizeof(bigEndian)];
}

static void BuildICNS(NSString *directory, NSString *outputPath) {
    NSArray<NSArray<NSString *> *> *entries = @[
        @[@"icp4", @"icon_16x16.png"], @[@"ic11", @"icon_16x16@2x.png"], @[@"icp5", @"icon_32x32.png"],
        @[@"ic12", @"icon_32x32@2x.png"], @[@"ic07", @"icon_128x128.png"], @[@"ic13", @"icon_128x128@2x.png"],
        @[@"ic08", @"icon_256x256.png"], @[@"ic14", @"icon_256x256@2x.png"], @[@"ic09", @"icon_512x512.png"], @[@"ic10", @"icon_512x512@2x.png"]
    ];
    NSMutableData *body = [NSMutableData data];
    for (NSArray<NSString *> *entry in entries) {
        NSData *png = [NSData dataWithContentsOfFile:[directory stringByAppendingPathComponent:entry[1]]];
        if (!png) continue;
        [body appendData:[entry[0] dataUsingEncoding:NSASCIIStringEncoding]];
        AppendUInt32(body, (uint32_t)(8 + png.length));
        [body appendData:png];
    }
    NSMutableData *icns = [NSMutableData dataWithData:[@"icns" dataUsingEncoding:NSASCIIStringEncoding]];
    AppendUInt32(icns, (uint32_t)(8 + body.length));
    [icns appendData:body];
    [icns writeToFile:outputPath atomically:YES];
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc != 3) return 2;
        NSString *directory = [NSString stringWithUTF8String:argv[1]];
        NSString *outputPath = [NSString stringWithUTF8String:argv[2]];
        NSDictionary<NSString *, NSNumber *> *files = @{
            @"icon_16x16.png": @16, @"icon_16x16@2x.png": @32, @"icon_32x32.png": @32, @"icon_32x32@2x.png": @64,
            @"icon_128x128.png": @128, @"icon_128x128@2x.png": @256, @"icon_256x256.png": @256, @"icon_256x256@2x.png": @512,
            @"icon_512x512.png": @512, @"icon_512x512@2x.png": @1024
        };
        [files enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSNumber *size, BOOL *stop) {
            (void)stop;
            DrawIcon(size.doubleValue, [directory stringByAppendingPathComponent:name]);
        }];
        BuildICNS(directory, outputPath);
    }
    return 0;
}
