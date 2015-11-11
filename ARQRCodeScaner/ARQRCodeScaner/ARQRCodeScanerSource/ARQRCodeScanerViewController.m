//
//  ARQRCodeScanerViewController.m
//  ARQRCodeScaner
//
//  Created by zhoudl on 15/11/10.
//  Copyright © 2015年 zhoudl. All rights reserved.
//

#import "ARQRCodeScanerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define ARDeviceWidth  ([UIScreen mainScreen].bounds.size.width)
#define ARDeviceHeight ([UIScreen mainScreen].bounds.size.height)
#define ARWidthRate    (ARDeviceWidth/320)
#define AR_IS_IOS8     ([[UIDevice currentDevice].systemVersion intValue] >= 8 ? YES : NO)

#define ARScanAreaTop    (200*ARWidthRate)
#define ARScanAreaLeft   (60*ARWidthRate)
#define ARScanAreaWidth  (200*ARWidthRate)
#define ARScanAreaHeight (200*ARWidthRate)

#define ARMaskViewAlpha  0.6
#define ARMaskViewColor  [UIColor darkGrayColor]

@interface ARQRCodeScanerViewController ()<AVCaptureMetadataOutputObjectsDelegate>

/**
 *  视图动画
 */
@property (nonatomic, strong) UIView *qRCodeScanerView;
@property (nonatomic, strong) UIImageView *scanlineView;
@property (nonatomic, strong) UIImageView *scanBorderView;
@property (nonatomic, strong) UILabel *scanDescLabel;
@property (nonatomic, strong) UIButton *flashControlButton;

/**
 *  Capture
 */
@property (nonatomic, strong) AVCaptureSession *session;

/**
 *  状态
 */
@property (nonatomic, assign) BOOL isScanAnimated;

@end

@implementation ARQRCodeScanerViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.title = @"二维码扫描";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem * rbbItem = [[UIBarButtonItem alloc]initWithTitle:@"相册" style:UIBarButtonItemStyleDone target:self action:@selector(alumbBtnEvent)];
    self.navigationItem.rightBarButtonItem = rbbItem;
    
    UIBarButtonItem * lbbItem = [[UIBarButtonItem alloc]initWithTitle:@"返回" style:UIBarButtonItemStyleDone target:self action:@selector(backButtonEvent)];
    self.navigationItem.leftBarButtonItem = lbbItem;
    
    [self initUI];
    [self initDevice];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _qRCodeScanerView.alpha = 0;
    [UIView animateWithDuration:0.5 animations:^{
        _qRCodeScanerView.alpha = 1;
    }completion:^(BOOL finished) {
        
    }];
    
    [self startScan];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self stopScan];
    
}

- (void)dealloc
{
    
}

#pragma mark - delegate
#pragma mark AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects && metadataObjects.count>0) {
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex : 0 ];
        
        NSString *scanResult = metadataObject.stringValue;
        [self playSound];
        [self showMessage:scanResult];
    }

}

#pragma mark - event response
- (void)startScan
{
    [_session startRunning];
    
    _isScanAnimated = YES;
    [self loopScanLineAnimation];
}

- (void)stopScan
{
    [_session stopRunning];
    
    _isScanAnimated = NO;
}

- (void)alumbBtnEvent
{
    
}

- (void)backButtonEvent
{
    [self stopScan];
    
    if (self.navigationController) {
        
        if (self.navigationController.presentingViewController) {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        }else{
            [self.navigationController popViewControllerAnimated:YES];
        }
        
    }else{
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)flashControl:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    BOOL on = sender.selected;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if ([device hasTorch] && [device hasFlash]){
        
        [device lockForConfiguration:nil];
        if (on) {
            [device setTorchMode:AVCaptureTorchModeOn];
            [device setFlashMode:AVCaptureFlashModeOn];
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
            [device setFlashMode:AVCaptureFlashModeOff];
        }
        [device unlockForConfiguration];
    }

}

#pragma mark - getters and setters
- (UIView *)qRCodeScanerView
{
    if (!_qRCodeScanerView) {
        _qRCodeScanerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ARDeviceWidth, ARDeviceHeight)];
        _qRCodeScanerView.backgroundColor = [UIColor clearColor];
    }
    
    return _qRCodeScanerView;
}

- (UIImageView *)scanBorderView
{
    if (!_scanBorderView) {
        _scanBorderView = [[UIImageView alloc] initWithFrame:CGRectMake(ARScanAreaLeft, ARScanAreaTop, ARScanAreaWidth, ARScanAreaHeight)];
        [_scanBorderView setImage:[UIImage imageNamed:@"scanscanBg"]];
    }
    
    return _scanBorderView;
}

- (UIImageView *)scanlineView
{
    if (!_scanlineView) {
        _scanlineView = [[UIImageView alloc] initWithFrame:CGRectMake(ARScanAreaLeft, ARScanAreaTop, ARScanAreaWidth, 9)];
        [_scanlineView setImage:[UIImage imageNamed:@"scanLine"]];
    }
    
    return _scanlineView;
}

- (UILabel *)scanDescLabel
{
    if (!_scanDescLabel) {
        _scanDescLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 64.0 + (ARScanAreaTop - 64.0)/2.0, ARDeviceWidth, 21.0)];
        _scanDescLabel.textAlignment = NSTextAlignmentCenter;
        _scanDescLabel.textColor = [UIColor lightTextColor];
        _scanDescLabel.font = [UIFont systemFontOfSize:14.0];
        _scanDescLabel.text = @"请将二维码放置下框中";
    }
    
    return _scanDescLabel;
}

- (UIButton *)flashControlButton
{
    if (!_flashControlButton) {
        
        float bottomHeight = ARDeviceHeight - ARScanAreaTop - ARScanAreaHeight;
        _flashControlButton = [[UIButton alloc] initWithFrame:CGRectMake((ARDeviceWidth - 64.0)/2.0, ARScanAreaTop + ARScanAreaHeight + (bottomHeight - 64.0)/2.0, 64.0, 64.0)];
        [_flashControlButton addTarget:self action:@selector(flashControl:) forControlEvents:UIControlEventTouchUpInside];
        [_flashControlButton setImage:[UIImage imageNamed:@"lightNormal"] forState:UIControlStateNormal];
        [_flashControlButton setImage:[UIImage imageNamed:@"lightSelect"] forState:UIControlStateSelected];
    }
    
    return _flashControlButton;
}
#pragma mark - private

- (void)playSound
{
    SystemSoundID soundID;
    NSString *strSoundFile = [[NSBundle mainBundle] pathForResource:@"notice" ofType:@"wav"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:strSoundFile],&soundID);
    AudioServicesPlaySystemSound(soundID);

}

- (void)loopScanLineAnimation
{
    _scanlineView.frame = CGRectMake(ARScanAreaLeft, ARScanAreaTop, ARScanAreaWidth, 9);
    [UIView animateWithDuration:1.5 animations:^{
        _scanlineView.frame = CGRectMake(ARScanAreaLeft, ARScanAreaTop + ARScanAreaHeight - 9, ARScanAreaWidth, 9);
    } completion:^(BOOL finished) {
        if (_isScanAnimated) {
            [self loopScanLineAnimation];
        }
    }];
}

- (void)initUI
{
    //设置遮罩 上下左右
    UIView *leftMask = [[UIView alloc] initWithFrame:CGRectMake(0, ARScanAreaTop, ARScanAreaLeft, ARScanAreaHeight)];
    leftMask.alpha = ARMaskViewAlpha;
    leftMask.backgroundColor = ARMaskViewColor;
    [self.qRCodeScanerView addSubview:leftMask];
    
    UIView *topMask = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ARDeviceWidth, ARScanAreaTop)];
    topMask.alpha = ARMaskViewAlpha;
    topMask.backgroundColor = ARMaskViewColor;
    [self.qRCodeScanerView addSubview:topMask];
    
    UIView *bottomMask = [[UIView alloc] initWithFrame:CGRectMake(0, ARScanAreaTop + ARScanAreaHeight, ARDeviceWidth, ARDeviceHeight - ARScanAreaTop - ARScanAreaHeight)];
    bottomMask.alpha = ARMaskViewAlpha;
    bottomMask.backgroundColor = ARMaskViewColor;
    [self.qRCodeScanerView addSubview:bottomMask];
    
    UIView *rightMask = [[UIView alloc] initWithFrame:CGRectMake(ARScanAreaLeft + ARScanAreaWidth, ARScanAreaTop, ARDeviceWidth - ARScanAreaLeft - ARScanAreaWidth, ARScanAreaHeight)];
    rightMask.alpha = ARMaskViewAlpha;
    rightMask.backgroundColor = ARMaskViewColor;
    [self.qRCodeScanerView addSubview:rightMask];
    
    [self.qRCodeScanerView addSubview:self.scanBorderView];
    [self.qRCodeScanerView addSubview:self.scanlineView];
    [self.qRCodeScanerView addSubview:self.scanDescLabel];
    [self.qRCodeScanerView addSubview:self.flashControlButton];

    [self.view addSubview:self.qRCodeScanerView];
}

- (void)initDevice
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc]init];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    output.rectOfInterest = [self getScanArea];
    
    _session = [[AVCaptureSession alloc]init];
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    if ([_session canAddInput:input]) {
        [_session addInput:input];
    }
    if ([_session canAddOutput:output]) {
        [_session addOutput:output];
        NSMutableArray *metadataObjectTypes = [[NSMutableArray alloc] init];
        //二维码
        if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
            [metadataObjectTypes addObject:AVMetadataObjectTypeQRCode];
        }
        //以下是条形码
        if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN13Code]) {
            [metadataObjectTypes addObject:AVMetadataObjectTypeEAN13Code];
        }
        if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN8Code]) {
            [metadataObjectTypes addObject:AVMetadataObjectTypeEAN8Code];
        }
        if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeCode128Code]) {
            [metadataObjectTypes addObject:AVMetadataObjectTypeCode128Code];
        }
        output.metadataObjectTypes = metadataObjectTypes;
        
        AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
        layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        layer.frame = _qRCodeScanerView.layer.bounds;
        [_qRCodeScanerView.layer insertSublayer:layer atIndex:0];
    }

}

- (CGRect)getScanArea
{
    /**
     *  设置扫描区域 http://www.tuicool.com/articles/6jUjmur
     */
    CGFloat x,y,width,height;
    x = ARScanAreaTop / ARDeviceHeight;
    y = ARScanAreaLeft / ARDeviceWidth;
    width = ARScanAreaHeight / ARDeviceHeight;
    height = ARScanAreaWidth / ARDeviceWidth;
    
    return CGRectMake(x, y, width, height);
}

- (void)showMessage:(NSString *)result
{
    UIAlertView *alter = [[UIAlertView alloc] initWithTitle:@"扫描结果" message:result delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alter show];
    
    [self stopScan];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        
        [self startScan];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
