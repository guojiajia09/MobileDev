//
//  ViewController.m
//  二维码生成与读取
//
//  Created by HarrySun on 2016/12/29.
//  Copyright © 2016年 Mobby. All rights reserved.
//

#import "ViewController.h"
#import <CoreImage/CoreImage.h>     // 生成二维码用


#import <AVFoundation/AVFoundation.h>   // 读取二维码用


@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    UIButton *button1 = [UIButton buttonWithType:(UIButtonTypeCustom)];
    button1.frame = CGRectMake(100, 100, 100, 100);
    button1.backgroundColor = [UIColor redColor];
    [button1 setTitle:@"生成二维码" forState:(UIControlStateNormal)];
    
    [button1 addTarget:self action:@selector(createImageAction:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:button1];
    
    
    UIButton *button2 = [UIButton buttonWithType:(UIButtonTypeCustom)];
    button2.frame = CGRectMake(100, 250, 100, 100);
    button2.backgroundColor = [UIColor redColor];
    [button2 setTitle:@"扫描二维码" forState:(UIControlStateNormal)];
    [button2 addTarget:self action:@selector(readImageAction:) forControlEvents:(UIControlEventTouchUpInside)];
    [self.view addSubview:button2];
    
    
}

- (void)createImageAction:(UIButton *)sender{
    
    [sender removeFromSuperview];
    UIImage *image = [self createImageWithString:@"https://www.baidu.com"];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 150, 150)];
    imageView.center = self.view.center;
    
    imageView.image = image;
    [self.view addSubview:imageView];
}

- (void)readImageAction:(UIButton *)sender{
    
    [sender removeFromSuperview];
    [self readQRCode];
}


- (void)readQRCode{
    
    // 1.实例化拍摄设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // 2.设置输入设备
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    // 3.设置元数据输出
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];   // 设置代理
    
    // 4.添加拍摄会话
    self.session = [[AVCaptureSession alloc] init];
    [self.session addInput:input];       // 添加会话输入
    [self.session addOutput:output];     // 添加会话输出
    
    [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];      // 设置输出数据类型（需要将元数据输出添加到会话后才能制定元数据类型，否则会报错）
    
    // 5.视频预览图层
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session]; // 传递session是为了告诉图层将来显示什么内容
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;   // 显示方式
    // 设置videoGravity,顾名思义就是视频播放时的拉伸方式,默认是AVLayerVideoGravityResizeAspect
    // AVLayerVideoGravityResizeAspect 保持视频的宽高比并使播放内容自动适应播放窗口的大小。
    // AVLayerVideoGravityResizeAspectFill 和前者类似，但它是以播放内容填充而不是适应播放窗口的大小。最后一个值会拉伸播放内容以适应播放窗口.
    // 因为考虑到全屏显示以及设备自适应,这里我们采用fill填充
    
    self.previewLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:self.previewLayer atIndex:0]; // 将图层插入当前图层
    
    // 6.启动会话
    [self.session startRunning];
    
}

/**
 扫描结果处理
 
 @param captureOutput 输出数据源
 @param metadataObjects 扫描结果数组
 @param connection 用于协调输入与输出之间的数据流
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    // 1.判断扫描结果的数据是否存在
    if ([metadataObjects count] > 0) {
        // 2.如果存在数据，则停止会话
        [self.session stopRunning];
        // 3.删除预览图层
        [self.previewLayer removeFromSuperlayer];
        
        AVMetadataMachineReadableCodeObject *metadataObject = metadataObjects[0];
        
        // AVMetadataMachineReadableCodeObject 是AVMetadataObject的具体子类定义的特性检测一维或二维条形码。
        // AVMetadataMachineReadableCodeObject代表一个单一的照片中发现机器可读的代码。这是一个不可变对象描述条码的特性和载荷。
        // 在支持的平台上,AVCaptureMetadataOutput输出检测机器可读的代码对象的数组
        
        NSString *stringValue = metadataObject.stringValue;
        
        if ([stringValue containsString:@"http"]) {
            
            // 如果是字符串，则打开连接
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:stringValue] options:[NSDictionary dictionary] completionHandler:^(BOOL success) {
                
                if (success) {
                    NSLog(@"成功");
                }
            }];
        }else{
            NSLog(@"普通字符串：%@",stringValue);     // 可以将字符串放到需要用到的地方（比如label）
        }
    }
}







// 生成二维码
- (UIImage *)createImageWithString:(NSString *)string{
    
    // 1.实例化二维码滤镜
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 2.恢复滤镜的默认属性（因为滤镜可能保存上一次的属性）
    [filter setDefaults];
    
    // 3.讲字符串转换为NSData
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    // 4.通过KVO设置滤镜inputMessage数据
    [filter setValue:data forKey:@"inputMessage"];
    
    // 5.通过了滤镜输出的图像
    CIImage *outputImage = [filter outputImage];
    
    // 6.因为生成的二维码模糊，所以通过createNonInterpolatedUIImageFormCIImage:outputImage来获得高清的二维码图片
    
    UIImage *image = [self getErWeiMaImageFormCIImage:outputImage withSize:200];
    
    return image;
}

- (UIImage *)getErWeiMaImageFormCIImage:(CIImage *)image withSize:(CGFloat) size {
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
