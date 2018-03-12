//
//  SJVideoPlayerFilmEditingControlView.m
//  SJVideoPlayerProject
//
//  Created by BlueDancer on 2018/3/9.
//  Copyright © 2018年 SanJiang. All rights reserved.
//

#import "SJVideoPlayerFilmEditingControlView.h"
#import <Masonry/Masonry.h>
#import <SJUIFactory/SJUIFactory.h>
#import "UIView+SJVideoPlayerSetting.h"
#import "UIView+SJControlAdd.h"
#import "SJVideoPlayerFilmEditingResultView.h"
#import "SJFilmEditingResultShareItem.h"
#import "SJVideoPlayerFilmEditingRecordView.h"

NS_ASSUME_NONNULL_BEGIN
@interface SJVideoPlayerFilmEditingControlView ()

@property (nonatomic, strong, readonly) UIButton *screenshotBtn;
@property (nonatomic, strong, readonly) UIButton *exportBtn;
@property (nonatomic, strong, nullable) SJVideoPlayerFilmEditingResultView *s_resultView;
@property (nonatomic, strong, readonly) SJVideoPlayerFilmEditingRecordView *recordView;
@property (nonatomic, strong, readonly) UITapGestureRecognizer *tapGR;

@end
NS_ASSUME_NONNULL_END

@implementation SJVideoPlayerFilmEditingControlView

@synthesize screenshotBtn = _screenshotBtn;
@synthesize exportBtn = _exportBtn;
@synthesize s_resultView = _s_resultView;
@synthesize recordView = _recordView;
@synthesize tapGR = _tapGR;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if ( !self ) return nil;
    [self _setupViews];
    return self;
}

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"SJVideoPlayerLog: %zd - %s", __LINE__, __func__);
#endif
}

- (void)clickedBtn:(UIButton *)btn {
    switch ( btn.tag ) {
            // screenshot
        case SJVideoPlayerFilmEditingViewTag_Screenshot: {
            _isRecording = NO;
            [self _showResultWithType:SJVideoPlayerFilmEditingResultViewType_Screenshot];
        }
            break;
            // export
        case SJVideoPlayerFilmEditingViewTag_Export: {
            _isRecording = YES;
            self.recordView.tipsText = _recordTipsText;
            _recordView.waitingForRecordingTipsText = _waitingForRecordingTipsText;
            _recordView.cancelBtnTitle = _cancelBtnTitle;
            _recordView.recordEndBtnImage = _recordEndBtnImage;
            _recordView.alpha = 0.001;
            [self addSubview:_recordView];
            [UIView animateWithDuration:0.25 animations:^{
                _recordView.alpha = 1;
            } completion:^(BOOL finished) {
                [_recordView start];
            }];
        }
            break;
        default:
            break;
    }
    
    [_exportBtn disappear];
    [_screenshotBtn disappear];
}

- (void)completeRecording {
    [_recordView stop];
    [self _showResultWithType:SJVideoPlayerFilmEditingResultViewType_Video];
}

- (void)_showResultWithType:(SJVideoPlayerFilmEditingResultViewType)type{
    _s_resultView = [[SJVideoPlayerFilmEditingResultView alloc] initWithType:type];
    _s_resultView.frame = self.bounds;
    _s_resultView.cancelBtnTitle = _cancelBtnTitle;
    _s_resultView.resultShare = _resultShare;
    _s_resultView.alpha = 0.001;
    [self addSubview:_s_resultView];
    
    __weak typeof(self) _self = self;
    _s_resultView.clickedCancleBtn = ^(SJVideoPlayerFilmEditingResultView * _Nonnull view) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        if ( self.exit ) self.exit(self);
    };
    
    [UIView animateWithDuration:0.2 animations:^{
        self.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            self.backgroundColor = [UIColor clearColor];
            _s_resultView.alpha = 1;
        } completion:^(BOOL finished) {
            [_s_resultView showResultWithCompletion:^{
                if ( type == SJVideoPlayerFilmEditingResultViewType_Video ) {
                    if ( self.recordCompleteExeBlock ) self.recordCompleteExeBlock(self, _recordView.currentTime);
                }
            }];
        }];
    }];
    _s_resultView.image = self.getVideoScreenshot(self);
}

#pragma mark -
- (void)setExportBtnImage:(UIImage *)exportBtnImage {
    [self.exportBtn setImage:exportBtnImage forState:UIControlStateNormal];
}

- (void)setScreenshotBtnImage:(UIImage *)screenshotBtnImage {
    [self.screenshotBtn setImage:screenshotBtnImage forState:UIControlStateNormal];
}

- (void)setRecordedVideoExportProgress:(float)recordedVideoExportProgress {
    _s_resultView.recordedVideoExportProgress = recordedVideoExportProgress;
}

- (float)recordedVideoExportProgress {
    return _s_resultView.recordedVideoExportProgress;
}

- (void)setExportFailed:(BOOL)exportFailed {
    _s_resultView.exportFailed = exportFailed;
}

- (BOOL)exportFailed {
    return _s_resultView.exportFailed;
}

- (void)setExportedVideoURL:(NSURL *)exportedVideoURL {
    _s_resultView.exportedVideoURL = exportedVideoURL;
}

- (NSURL *)exportedVideoURL {
    return _s_resultView.exportedVideoURL;
}

- (UITapGestureRecognizer *)tapGR {
    if ( _tapGR ) return _tapGR;
    _tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGR)];
    return _tapGR;
}

- (void)handleTapGR {
    CGPoint location = [_tapGR locationInView:self];
    if ( !CGRectContainsPoint(_s_resultView.frame, location) &&
         !CGRectContainsPoint(_recordView.frame, location)) {
        if ( self.exit ) self.exit(self);
    }
}

#pragma mark -
- (void)_setupViews {
    [self addSubview:self.screenshotBtn];
    [self addSubview:self.exportBtn];
    [self addGestureRecognizer:self.tapGR]; // gesture
    
    [_screenshotBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.offset(0);
        make.size.offset(49);
        make.bottom.equalTo(self.mas_centerY);
    }];
    
    [_exportBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.offset(0);
        make.size.equalTo(_screenshotBtn);
        make.top.equalTo(self.mas_centerY);
    }];
    
    _screenshotBtn.disappearType = SJDisappearType_Transform;
    _screenshotBtn.disappearTransform = CGAffineTransformMakeTranslation(49, 0);
    _exportBtn.disappearType = SJDisappearType_Transform;
    _exportBtn.disappearTransform = CGAffineTransformMakeTranslation(49, 0);
    _s_resultView.disappearType = SJDisappearType_Alpha;
    
    [_screenshotBtn disappear];
    [_exportBtn disappear];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.25 animations:^{
            [_screenshotBtn appear];
            [_exportBtn appear];
        }];
    });
}

- (UIButton *)screenshotBtn {
    if ( _screenshotBtn ) return _screenshotBtn;
    _screenshotBtn = [SJUIButtonFactory buttonWithTarget:self sel:@selector(clickedBtn:) tag:SJVideoPlayerFilmEditingViewTag_Screenshot];
    return _screenshotBtn;
}

- (UIButton *)exportBtn {
    if ( _exportBtn ) return _exportBtn;
    _exportBtn = [SJUIButtonFactory buttonWithTarget:self sel:@selector(clickedBtn:) tag:SJVideoPlayerFilmEditingViewTag_Export];
    return _exportBtn;
}

- (SJVideoPlayerFilmEditingRecordView *)recordView {
    if ( _recordView ) return _recordView;
    _recordView = [[SJVideoPlayerFilmEditingRecordView alloc] initWithFrame:self.bounds];
    _recordView.backgroundColor = [UIColor clearColor];
    __weak typeof(self) _self = self;
    _recordView.clickedCancleBtnExeBlock = ^(SJVideoPlayerFilmEditingRecordView * _Nonnull view) {
        __strong typeof(_self) self = _self;
        if ( !self ) return ;
        if ( self.exit ) self.exit(self);
    };
    
    _recordView.clickedCompleteBtnExeBlock = ^(SJVideoPlayerFilmEditingRecordView * _Nonnull view) {
        __strong typeof(_self) self = _self;
        if ( !self ) return;
        [self completeRecording];
    };
    return _recordView;
}
@end