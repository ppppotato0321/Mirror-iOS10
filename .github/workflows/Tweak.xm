#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>

static NSString *kPrefsDomain = @"com.ial2wi.mirror";

static BOOL MirrorPrefsEnabled(void) {
    CFPreferencesAppSynchronize((__bridge CFStringRef)kPrefsDomain);
    return CFPreferencesGetAppBooleanValue(CFSTR("MirrorEnabled"), (__bridge CFStringRef)kPrefsDomain, NULL);
}

static UIImage *MirrorFlipHorizontal(UIImage *image) {
    if (!image) return nil;
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(ctx, image.size.width, 0);
    CGContextScaleCTM(ctx, -1.0, 1.0);
    CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
    UIImage *flipped = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return flipped ?: image;
}

static BOOL MirrorIsFrontCamera(id obj) {
    if (!obj) return NO;
    NSArray *keyPaths = @[@"position", @"camera", @"captureDevice.position", @"device.position"];
    for (NSString *kp in keyPaths) {
        @try {
            id v = [obj valueForKeyPath:kp];
            if ([v isKindOfClass:[NSNumber class]]) {
                NSInteger n = [v integerValue];
                if (n == 2 || n == 1) return YES;
            }
        } @catch (NSException *e) {}
    }
    return NO;
}

%hook PLCamera

- (UIImage *)prepareImageForRelease:(UIImage *)image {
    UIImage *result = %orig;
    if (!MirrorPrefsEnabled() || !result) return result;
    if (MirrorIsFrontCamera(self)) {
        NSLog(@"[Mirror] Flipping front camera photo");
        result = MirrorFlipHorizontal(result);
    }
    return result;
}

%end

%hook PLCameraView

- (void)captureCompleteWithPreparedPhoto:(id)photo options:(id)options {
    %orig;
    NSLog(@"[Mirror] captureComplete called");
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[Mirror] iOS 10 Tweak loaded");
        %init();
    }
}
