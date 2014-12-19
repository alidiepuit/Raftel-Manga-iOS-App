//
//  CommentEntryViewController.m
//  Raftel
//
//  Created by  on 12/19/14.
//  Copyright (c) 2014 Raftel. All rights reserved.
//

#import "CommentEntryViewController.h"
#import "Manga+Parse.h"

@interface CommentEntryViewController ()

@end

@implementation CommentEntryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Comment", nil);
    // Do any additional setup after loading the view.
    UIBarButtonItem *sendButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send", nil) style:UIBarButtonItemStyleDone target:self action:@selector(didTapSendButton:)];
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleDone target:self action:@selector(didTapCancelButton:)];
    [self.navigationItem setRightBarButtonItem:sendButton];
    [self.navigationItem setLeftBarButtonItem:cancelButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidAppear:) name:UIKeyboardDidShowNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didTapSendButton:(id)sender {
    if (self.textView.text.length > 0) {
        __weak typeof (self) selfie = self;
        [self.manga addComment:self.textView.text completionBlock:^(NSError *error) {
            if (error) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *dismiss = [UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", nil) style:UIAlertActionStyleCancel handler:nil];
                [alert addAction:dismiss];
                [selfie presentViewController:alert animated:YES completion:nil];
            } else {
                if (selfie.delegate && [selfie.delegate respondsToSelector:@selector(commentEntry:didSendComment:)]) {
                    [selfie.delegate commentEntry:selfie didSendComment:selfie.textView.text];
                }
            }
        }];
    }
    
}

- (void)didTapCancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)keyboardDidAppear:(NSNotification *)keyboard {
    NSDictionary *userInfo = keyboard.userInfo;
    CGRect keyboardFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.textView.contentInset = ({
        UIEdgeInsets inset = self.textView.contentInset;
        inset.bottom = keyboardFrame.size.height;
        inset;
    });
}

@end