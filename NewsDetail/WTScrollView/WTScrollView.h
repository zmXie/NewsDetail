//
//  WTScrollView.h
//  NewsDetail
//
//  Created by xzm on 2020/3/19.
//  Copyright © 2020 NewsDetail. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class WTScrollView;

@protocol WTScrollViewDataSource <NSObject>

@required
/// webview
/// @param wtScrollView self
- (WKWebView *_Nonnull)webViewInWtScrollView:(WTScrollView *_Nonnull)wtScrollView;
/// tableivew
/// @param wtScrollView self
- (UITableView *_Nonnull)tableViewInWtScrollView:(WTScrollView *_Nonnull)wtScrollView;

@optional
/// 头视图
/// @param wtScrollView self
- (UIView *_Nonnull)headerInWtScrollView:(WTScrollView *_Nonnull)wtScrollView;

@end


NS_ASSUME_NONNULL_BEGIN

@interface WTScrollView : UIScrollView

@property (nonatomic, weak) id <WTScrollViewDataSource> wtDataSource;
@property (nonatomic,strong,readonly) WKWebView *webView;
@property (nonatomic,strong,readonly) UITableView *tableView;
@property (nonatomic,strong,readonly) UIView *headView;

- (void)scrollToHeadAnimated:(BOOL)animated;
- (void)scrollToWebAnimated:(BOOL)animated;
- (void)scrollToTableAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
