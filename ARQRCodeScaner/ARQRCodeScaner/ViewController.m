//
//  ViewController.m
//  ARQRCodeScaner
//
//  Created by zhoudl on 15/11/10.
//  Copyright © 2015年 zhoudl. All rights reserved.
//

#import "ViewController.h"
#import "ARQRCodeScanerViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)click:(id)sender {
    
    ARQRCodeScanerViewController * sqVC = [[ARQRCodeScanerViewController alloc]init];
    UINavigationController * nVC = [[UINavigationController alloc]initWithRootViewController:sqVC];
    [self presentViewController:nVC animated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
