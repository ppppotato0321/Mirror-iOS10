//
//  Mirror for iOS 10
//  前置摄像头自拍镜像插件
//
//  移植自 BigBoss: Mirror by 0ldGold (com.ial2wi.mirror)
//  原版本: iOS 11-13
//  本版本: iOS 10.x 适配
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>
#import <objc/message.h>

#pragma mark - 偏好设置

static NSString *kPrefsDomain = @"com.ial2wi.mirror";
static NSString *kPrefEnabled = @"MirrorEnabled";

static BOOL MirrorPrefsEnabled(void) {
    CFPreferencesAppSynchronize((__bridge CFStringRef)kPrefsDomain);
    Boolean keyExists = false;
    BOOL value = CFPreferencesGetAppBooleanValue(
        (__bridge CFStringRef)kPrefEnabled,
        (__bridge CFStringRef)kPrefsDomain,
        &keyExists
    );
    return keyExists ? value : YES; // 默认开启
}

#pragma mark - 工具方法

// 水平翻转图片
static UIImage *MirrorFlipHorizontal(UIImage *image) {
    if (!image) return nil;
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) {
        UIGraphicsEndImageContext();
        return image;
    }
    
    CGContextTranslateCTM(ctx, image.size.width, 0);
    CGContextScaleCTM(ctx, -1.0, 1.0);
    CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
    
    UIImage *flipped = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return flipped ?: image;
}

// 判断对象是否代表前置摄像头
static BOOL MirrorIsFrontCamera(id obj) {
    if (!obj) return NO;
    
    // 尝试各种可能的属性
    NSArray *keyPaths = @[
        @"position",           // AVCaptureDevice
        @"camera",             // PLCamera
        @"captureDevice.position",
        @"device.position",
        @"frontCamera",
        @"isFront"
    ];
    
    for (NSString *keyPath in keyPaths) {
        @try {
            id value = [obj valueForKeyPath:keyPath];
            if ([value isKindOfClass:[NSNumber class]]) {
                NSInteger num = [value integerValue];
                // AVCaptureDevicePositionFront = 2
                // 旧版 camera == 1 代表前置
                if (num == 2 || num == 1) return YES;
            }
            if ([value isKindOfClass:[NSString class]]) {
                if ([value isEqualToString:@"front"]) return YES;
            }
        } @catch (NSException *e) {}
    }
    
    return NO;
}

#pragma mark - Hook: PLCameraView (iOS 10 相机主视图)

%hook PLCameraView

// 拍照完成 - 旧版方法
- (void)captureCompleteWithPreparedPhoto:(id)photo options:(id)options {
    %orig;
    
    if (!MirrorPrefsEnabled()) return;
    
    NSLog(@"[Mirror] PLCameraView.captureComplete called");
    
    if (MirrorIsFrontCamera(self)) {
        NSLog(@"[Mirror] Front camera detected in captureComplete");
    }
}

// 自动保存准备好的照片
- (void)handleAutosaverPreparedPhoto:(id)photo {
    %orig;
    
    if (!MirrorPrefsEnabled()) return;
    
    NSLog(@"[Mirror] PLCameraView.handleAutosaverPreparedPhoto called");
    
    if (MirrorIsFrontCamera(self)) {
        NSLog(@"[Mirror] Front camera detected in autosaver");
    }
}

// 准备保存照片
- (void)prepareToSavePhoto:(id)photo {
    %orig;
    
    if (!MirrorPrefsEnabled()) return;
    NSLog(@"[Mirror] prepareToSavePhoto called");
}

%end

#pragma mark - Hook: PLCamera (相机核心控制器)

%hook PLCamera

// 准备图像释放 - 这是处理方向和镜像的关键位置
- (UIImage *)prepareImageForRelease:(UIImage *)image {
    UIImage *result = %orig;
    
    if (!MirrorPrefsEnabled()) return result;
    if (!result) return result;
    
    NSLog(@"[Mirror] PLCamera.prepareImageForRelease: %@", NSStringFromCGSize(result.size));
    
    if (MirrorIsFrontCamera(self)) {
        NSLog(@"[Mirror] -> Flipping front camera photo");
        result = MirrorFlipHorizontal(result);
    }
    
    return result;
}

// 旧版: 准备图像输出
- (UIImage *)prepareImageForOutput:(UIImage *)image {
    UIImage *result = %orig;
    
    if (!MirrorPrefsEnabled()) return result;
    
    if (MirrorIsFrontCamera(self)) {
        NSLog(@"[Mirror] prepareImageForOutput: flipping");
        result = MirrorFlipHorizontal(result);
    }
    
    return result;
}

%end

#pragma mark - Hook: PLCameraPhoto (照片对象)

%hook PLCameraPhoto

// 旋转后的图像
- (UIImage *)rotatedImage {
    UIImage *image = %orig;
    
    if (!MirrorPrefsEnabled()) return image;
    
    NSLog(@"[Mirror] PLCameraPhoto.rotatedImage called");
    
    // 尝试判断是不是前置摄像头拍的
    @try {
        id camera = [self valueForKey:@"camera"];
        if (MirrorIsFrontCamera(camera)) {
            NSLog(@"[Mirror] -> Flipping rotatedImage");
            image = MirrorFlipHorizontal(image);
        }
    } @catch (NSException *e) {}
    
    return image;
}

// 原始图像
- (UIImage *)originalImage {
    UIImage *image = %orig;
    
    if (!MirrorPrefsEnabled()) return image;
    
    return image;
}

%end

#pragma mark - Hook: 备用类 (不同版本可能不同)

%hook CAMManager

- (void)captureStillImage {
    %orig;
    NSLog(@"[Mirror] CAMManager.captureStillImage called");
}

%end

#pragma mark - 初始化

%ctor {
    @autoreleasepool {
        NSLog(@"[Mirror] ====================================");
        NSLog(@"[Mirror] Mirror iOS 10 Tweak loaded");
        NSLog(@"[Mirror] Enabled: %d", MirrorPrefsEnabled());
        NSLog(@"[Mirror] ====================================");
        %init();
    }
}
