#import "Esp/ImGuiDrawView.h"
#import "IMGUI/imgui.h"
#import "IMGUI/imgui_impl_metal.h"
#import "IMGUI/zzz.h"
#import "Macros.h"
#import "giovotinh/hook.h"
#import "resources/Resources.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <UIKit/UIKit.h>

#define NAME_BINARY "Frameworks/UnityFramework.framework/UnityFramework"
#define kWidth [UIScreen mainScreen].bounds.size.width
#define kHeight [UIScreen mainScreen].bounds.size.height
#define kScale [UIScreen mainScreen].scale
#define kFloatButtonWidth 50
#define kFloatButtonHeight 50
#define kPaddingVertical 30
#define kPaddingHorizontal 10

@interface ImGuiDrawView () <MTKViewDelegate>
@property(nonatomic, strong) id<MTLDevice> device;
@property(nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic, strong) UIWindow *floatButtonWindow;
@property(nonatomic, strong) UIImageView *floatButtonImageView;
@end

@implementation ImGuiDrawView

static bool isShowMenu = false;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    _device = MTLCreateSystemDefaultDevice();
    _commandQueue = [_device newCommandQueue];
    
    if (!self.device)
        abort();
    
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO &io = ImGui::GetIO();
    (void)io;
    
    ImGui::StyleColorsClassic();
    
    ImFont *font = io.Fonts->AddFontFromMemoryCompressedTTF(
                                                            (void *)zzz_compressed_data, zzz_compressed_size, 60.0f, NULL,
                                                            io.Fonts->GetGlyphRangesVietnamese());
    
    ImGui_ImplMetal_Init(_device);
    
    return self;
}

- (void)loadView {
    self.view = [[MTKView alloc] initWithFrame:CGRectMake(0, 0, kWidth, kHeight)];
    [self setup];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mtkView.device = self.device;
    self.mtkView.delegate = self;
    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);
    self.mtkView.backgroundColor = [UIColor colorWithRed:0
                                                   green:0
                                                    blue:0
                                                   alpha:0];
    self.mtkView.clipsToBounds = YES;
    [self setupFloatButton];
    timer(1) { [self snapFloatButtonToEdge]; });
}

- (void)setup {
    [common setFrameworkName:NAME_BINARY];
    Il2CppAttach();
    [self loadState];
    [self hook];
}

- (void)loadState {
}

- (void)setupFloatButton {
    NSString *pureBase64 = kFloatButtonBase64;
    if ([pureBase64 hasPrefix:@"data:"]) {
        NSArray *components = [pureBase64 componentsSeparatedByString:@","];
        if (components.count > 1)
            pureBase64 = components[1];
    }
    NSData *data = [[NSData alloc]
                    initWithBase64EncodedString:pureBase64
                    options:NSDataBase64DecodingIgnoreUnknownCharacters];
    UIImage *image = [UIImage imageWithData:data];
    if (!image)
        return;
    
    CGFloat x = (kWidth - kFloatButtonWidth) / 2;
    CGFloat y = (kHeight - kFloatButtonHeight) / 2;
    
    self.floatButtonWindow = [[UIWindow alloc]
                              initWithFrame:CGRectMake(x, y, kFloatButtonWidth, kFloatButtonHeight)];
    self.floatButtonWindow.backgroundColor = [UIColor clearColor];
    self.floatButtonWindow.windowLevel = UIWindowLevelAlert + 1;
    
    UIViewController *rootVC = [[UIViewController alloc] init];
    rootVC.view.backgroundColor = [UIColor clearColor];
    rootVC.view.userInteractionEnabled = YES;
    self.floatButtonWindow.rootViewController = rootVC;
    
    self.floatButtonImageView =
    [[UIImageView alloc] initWithFrame:self.floatButtonWindow.bounds];
    self.floatButtonImageView.image = image;
    self.floatButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.floatButtonImageView.layer.cornerRadius = kFloatButtonWidth / 2;
    self.floatButtonImageView.clipsToBounds = YES;
    self.floatButtonImageView.userInteractionEnabled = YES;
    
    [self.floatButtonWindow.rootViewController.view
     addSubview:self.floatButtonImageView];
    self.floatButtonWindow.hidden = NO;
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(handlePanFloatButton:)];
    [self.floatButtonImageView addGestureRecognizer:panGesture];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(handleTapFloatButton)];
    [self.floatButtonImageView addGestureRecognizer:tapGesture];
}

- (void)handlePanFloatButton:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.floatButtonWindow];
    
    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint newCenter =
        CGPointMake(self.floatButtonWindow.center.x + translation.x,
                    self.floatButtonWindow.center.y + translation.y);
        CGFloat minY = (kFloatButtonHeight / 2) + kPaddingVertical;
        CGFloat maxY = kHeight - (kFloatButtonHeight / 2) - kPaddingVertical;
        newCenter.y = fmax(minY, fmin(newCenter.y, maxY));
        self.floatButtonWindow.center = newCenter;
        
        [gesture setTranslation:CGPointZero inView:self.floatButtonWindow];
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
               gesture.state == UIGestureRecognizerStateCancelled) {
        [self snapFloatButtonToEdge];
    }
}

- (void)snapFloatButtonToEdge {
    CGRect frame = self.floatButtonWindow.frame;
    CGFloat targetX = (self.floatButtonWindow.center.x < kWidth / 2)
    ? kPaddingHorizontal
    : kWidth - frame.size.width - kPaddingHorizontal;
    
    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        CGRect finalFrame = self.floatButtonWindow.frame;
        finalFrame.origin.x = targetX;
        self.floatButtonWindow.frame = finalFrame;
    }
                     completion:nil];
}

- (void)handleTapFloatButton {
    if (self.onCallChange) {
        isShowMenu = !isShowMenu;
        self.onCallChange(isShowMenu);
    }
    
    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc]
                                            initWithStyle:UIImpactFeedbackStyleLight];
    [generator impactOccurred];
}

- (void)hook {
    LOG(NSSENCRYPT("========= Start hooking ========="));
    
    HOOK_V2(ENCRYPTOFFSET("0x028A4AE0"), SYBO_Subway_GameplayCameraConfig___ctor, _SYBO_Subway_GameplayCameraConfig___ctor);
    HOOK_V2(ENCRYPTOFFSET("0x029A0B08"), SYBO_RunnerCore_Character_CharacterMotorConfig___ctor, _SYBO_RunnerCore_Character_CharacterMotorConfig___ctor);
    
    LOG(NSSENCRYPT("========= Hooking done ========="));
}

- (void)patch {
    // patchOffset(0x00123456, "1F 20 03 D5"); // NOP
}

+ (void)showChange:(BOOL)open {
    isShowMenu = open;
}

- (MTKView *)mtkView {
    return (MTKView *)self.view;
}

#pragma mark - Interaction

- (void)updateIOWithTouchEvent:(UIEvent *)event {
    UITouch *anyTouch = event.allTouches.anyObject;
    CGPoint touchLocation = [anyTouch locationInView:self.view];
    ImGuiIO &io = ImGui::GetIO();
    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);
    
    BOOL hasActiveTouch = NO;
    for (UITouch *touch in event.allTouches) {
        if (touch.phase != UITouchPhaseEnded &&
            touch.phase != UITouchPhaseCancelled) {
            hasActiveTouch = YES;
            break;
        }
    }
    io.MouseDown[0] = hasActiveTouch;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateIOWithTouchEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateIOWithTouchEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches
               withEvent:(UIEvent *)event {
    [self updateIOWithTouchEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self updateIOWithTouchEvent:event];
}

#pragma mark - MTKViewDelegate

- (void)drawInMTKView:(MTKView *)view {
    // Resize view rotate the screen
    self.view.frame = CGRectMake(0, 0, kWidth, kHeight);
    
    ImGuiIO &io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;
    
    CGFloat framebufferScale =
    view.window.screen.scale ?: UIScreen.mainScreen.scale;
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    io.DeltaTime = 1 / float(view.preferredFramesPerSecond ?: 120);
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    if (isShowMenu == true) {
        [self.view setUserInteractionEnabled:YES];
    } else if (isShowMenu == false) {
        [self.view setUserInteractionEnabled:NO];
    }
    
    MTLRenderPassDescriptor *renderPassDescriptor =
    view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil) {
        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder pushDebugGroup:@"ImGui"];
        
        ImGui_ImplMetal_NewFrame(renderPassDescriptor);
        ImGui::NewFrame();
        
        ImFont *font = ImGui::GetFont();
        font->Scale = 15.f / font->FontSize;
        
        bool isIpad = ([[UIDevice currentDevice] userInterfaceIdiom] ==
                       UIUserInterfaceIdiomPad);
        
        CGFloat width = fmin(kWidth * (isIpad ? 0.5 : 0.8), 600);
        CGFloat height = fmin(kHeight * (isIpad ? 0.6 : 0.6), 600);
        CGFloat x = (kWidth - width) / 2;
        CGFloat y = (kHeight - height) / 2;
        
        static float lastKnownWidth = 0;
        static float lastKnownHeight = 0;
        
        if (lastKnownWidth != kWidth || lastKnownHeight != kHeight) {
            ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_Always);
            ImGui::SetNextWindowSize(ImVec2(width, height), ImGuiCond_Always);
            
            lastKnownWidth = kWidth;
            lastKnownHeight = kHeight;
        } else {
            ImGui::SetNextWindowPos(ImVec2(x, y), ImGuiCond_Appearing);
            ImGui::SetNextWindowSize(ImVec2(width, height), ImGuiCond_Appearing);
        }
        
        if (isShowMenu) {
            applyMod();
            
            ImGui::Begin("Subway Surfers Mod", &isShowMenu);
            ImGui::TextWrapped(
                               "Click the floating icon on the screen to open or close the menu.\n"
                               "Alternatively, use three fingers to double-tap to open the menu, or "
                               "two fingers to double-tap to hide the menu.");
            ImGui::TextWrapped(
                               "Bấm vào icon nổi trên màn hình để mở hoặc đóng menu.\n"
                               "Hoặc dùng 3 ngón chạm 2 lần để mở menu, 2 ngón chạm "
                               "2 lần để ẩn menu\n\n");
            
            ImGui::TextWrapped("Click on the type you want to mod + adjust the quantity you want to mod.\n\n");
            ImGui::TextWrapped("Chọn thể loại muốn mod + kéo thanh điều chỉnh số lượng muốn mod.\n\n");
            
            if (ImGui::SliderFloat("Cam xa gần", &fieldOfViewScale, 1.0, 2.5)) {
                isChangeFieldOfViewScale = true;
            }
            if (ImGui::SliderFloat("Nhảy cao", &jumpHeightScale, 1.0, 10.0)) {
                isChangeJumpHeightScale = true;
            }
            if (ImGui::SliderFloat("Chạy nhanh", &initialTargetSpeedScale, 0.1, 5.0)) {
                isChangeInitialTargetSpeedScale = true;
            }
            
            ImGui::TextWrapped("\nFPS: %.2f", ImGui::GetIO().Framerate);
            
            ImGui::End();
        }
        
        [self patch];
        
        ImDrawList *draw_list = ImGui::GetBackgroundDrawList();
        
        ImGui::Render();
        ImDrawData *draw_data = ImGui::GetDrawData();
        ImGui_ImplMetal_RenderDrawData(draw_data, commandBuffer, renderEncoder);
        
        [renderEncoder popDebugGroup];
        [renderEncoder endEncoding];
        
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    [commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
}

@end
