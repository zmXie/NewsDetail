//
//  WTScrollView.m
//  NewsDetail
//
//  Created by xzm on 2020/3/19.
//  Copyright © 2020 NewsDetail. All rights reserved.
//

#import "WTScrollView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/NSObject+RACKVOWrapper.h>
#import <Masonry/Masonry.h>

@interface WTScrollView ()

@property (nonatomic,strong) UIView *contentView;
@property (weak,  nonatomic) NSLayoutConstraint *contentTopLayout;
@property (weak,  nonatomic) NSLayoutConstraint *webHeightLayout;
@property (weak,  nonatomic) NSLayoutConstraint *tabHeightLayout;

@end

@implementation WTScrollView

- (void)dealloc
{
    NSLog(@"WTScrollView dealloc");
}

#pragma mark - Setter
- (void)setWtDataSource:(id<WTScrollViewDataSource>)wtDataSource
{
    if (_wtDataSource != wtDataSource) {
        _wtDataSource = wtDataSource;
        _webView = [wtDataSource webViewInWtScrollView:self];
        _tableView = [wtDataSource tableViewInWtScrollView:self];
        if ([wtDataSource respondsToSelector:@selector(headerInWtScrollView:)]) {
            _headView = [wtDataSource headerInWtScrollView:self];
        }
        [self addSubViews];
        [self handleSignal];
    }
}

#pragma mark - Privates
- (void)addSubViews
{
    //容器视图
    if (!_contentView) {
        _contentView = [UIView new];
        [self addSubview:_contentView];
        __block MASConstraint *topLayout;
        [_contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            topLayout = make.top.mas_equalTo(0);
            make.left.right.mas_equalTo(0);
            make.width.mas_equalTo(self);
        }];
        _contentTopLayout = [topLayout valueForKey:@"layoutConstraint"];
    }
    
    //顶部头视图
    if (!_headView) {
        _headView = [UIView new];
        [_headView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0);
        }];
    }
    [_contentView addSubview:_headView];
    [_headView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(0);
        make.width.equalTo(self);
    }];
    
    //中间webView
    [_contentView addSubview:_webView];
    __block MASConstraint *webHeightLayout;
    [_webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_headView.mas_bottom);
        make.left.mas_equalTo(0);
        make.width.equalTo(self);
        webHeightLayout = make.height.mas_equalTo(0);
    }];
    _webHeightLayout = [webHeightLayout valueForKey:@"layoutConstraint"];
    
    //底部tableView
    [_contentView addSubview:_tableView];
    __block MASConstraint *tabHeightLayout;
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_webView.mas_bottom);
        make.left.mas_equalTo(0);
        make.width.equalTo(self);
        make.bottom.mas_equalTo(0).priorityMedium();
        tabHeightLayout = make.height.mas_equalTo(0);
    }];
    _tabHeightLayout = [tabHeightLayout valueForKey:@"layoutConstraint"];
    
    //配置
    _webView.scrollView.scrollEnabled = _tableView.scrollEnabled = NO;
    _webView.scrollView.delaysContentTouches = _tableView.delaysContentTouches = NO;
    self.decelerationRate = _webView.scrollView.decelerationRate = _tableView.decelerationRate = UIScrollViewDecelerationRateNormal;
}

- (void)handleSignal
{
    RACSignal *headerSignal = [[RACObserve(self.headView, bounds) distinctUntilChanged] map:^id(id value) {
        return @([value CGRectValue].size.height);
    }];
    RACSignal *tabSignal = [[[RACObserve(self.tableView,contentSize) skip:1] distinctUntilChanged] map:^id(id value) {
        return @([value CGSizeValue].height);
    }];
    @weakify(self)
    RACSignal *webSignal = [[[[[self.webView.scrollView rac_valuesAndChangesForKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld observer:nil] skip:1] distinctUntilChanged] doNext:^(id x) {
        //如果webview的内容高度缩小超过误差范围，则滑动到顶部，否则手动触发一下滑动KVO及时更新偏移量
        @strongify(self)
        RACTupleUnpack(NSValue *size,NSDictionary *change) = x;
        CGFloat n = [size CGSizeValue].height;
        CGFloat o = [change[NSKeyValueChangeOldKey] CGSizeValue].height;
        if (o - n > CGRectGetHeight(self.bounds)) {
            CGPoint webTopPoint = [self getOffsetWithY:CGRectGetHeight(self.headView.frame)];
            //只允许向上滑动
            if (self.contentOffset.y > webTopPoint.y) {
                [self setContentOffset:webTopPoint];
            }
        } else {
            [self didScrollWithOffsetY:self.contentOffset.y];
        }
    }] map:^id(id value) {
        RACTupleUnpack(NSValue *size) = value;
        return @([size CGSizeValue].height);
    }];
    
    //更新webview高度
    RAC(self.webHeightLayout,constant) = [webSignal map:^id(id value) {
        @strongify(self)
        return @(MIN(CGRectGetHeight(self.frame), [value floatValue]));
    }];
    //更新tabView高度
    RAC(self.tabHeightLayout,constant) = [tabSignal map:^id(id value) {
        @strongify(self)
        return @(MIN(CGRectGetHeight(self.frame), [value floatValue]));
    }];
    //更新self.contentSize
    RAC(self,contentSize) = [[RACSignal combineLatest:@[headerSignal,webSignal,tabSignal]] reduceEach:^id(NSNumber *h1,NSNumber *h2,NSNumber *h3){
        @strongify(self)
        CGSize size = CGSizeMake(self.contentSize.width, h1.doubleValue + h2.doubleValue + h3.doubleValue);
        return [NSValue valueWithCGSize:size];
    }];
    //监听self滑动
    [[RACObserve(self, contentOffset) distinctUntilChanged] subscribeNext:^(id x) {
        @strongify(self)
        [self didScrollWithOffsetY:[x CGPointValue].y];
    }];
}

- (void)didScrollWithOffsetY:(CGFloat)offsetY
{
    CGFloat scrollViewHeight = CGRectGetHeight(self.bounds);
    CGFloat headViewHeight = CGRectGetHeight(self.headView.frame);
    CGFloat webViewHeight = CGRectGetHeight(self.webView.frame);
    CGFloat tableViewHeight = CGRectGetHeight(self.tableView.frame);
    
    CGFloat webViewContentHeight = self.webView.scrollView.contentSize.height;
    CGFloat tableViewContentHeight = self.tableView.contentSize.height;
    BOOL atBottom = offsetY + scrollViewHeight >= self.contentSize.height;

    CGFloat netOffsetY = offsetY - headViewHeight;
    
    if (netOffsetY <= 0 && !atBottom) //webview的top滑动到顶部之前
    {
        //固定webview和tableView，滑动scrollView
        self.contentTopLayout.constant = 0;
        self.webView.scrollView.contentOffset = CGPointZero;
        self.tableView.contentOffset = CGPointZero;
    }
    else if(netOffsetY < webViewContentHeight - webViewHeight && !atBottom) //webview的bottom滑动到底部之前
    {
        //滑动webView，固定tableView
        self.contentTopLayout.constant = netOffsetY;
        self.webView.scrollView.contentOffset = CGPointMake(0, netOffsetY);
        self.tableView.contentOffset = CGPointZero;
    }
    else if(netOffsetY < webViewContentHeight && !atBottom) //webview的bottom滑动到顶部之前
    {
        //webView滑动到底部，固定webview和tableView，滑动contentView
        self.contentTopLayout.constant = webViewContentHeight - webViewHeight;
        self.webView.scrollView.contentOffset = CGPointMake(0, webViewContentHeight - webViewHeight);
        self.tableView.contentOffset = CGPointZero;
    }
    else if(netOffsetY < webViewContentHeight + tableViewContentHeight - tableViewHeight && !atBottom)
    { //tablview滑动到底之前
        //固定webview，滑动tableView
        self.contentTopLayout.constant = netOffsetY - webViewHeight;
        self.webView.scrollView.contentOffset = CGPointMake(0, webViewContentHeight - webViewHeight);
        self.tableView.contentOffset = CGPointMake(0, netOffsetY - webViewContentHeight);
    }
    else
    { //scrollview滑动到底部之后
        self.contentTopLayout.constant = self.contentSize.height - CGRectGetHeight(self.contentView.bounds);
        //beyond：scrollView滑动到底部回弹的距离，把contentView往下移动回弹的距离，只保留tableview的回弹效果
        CGFloat beyond = offsetY + CGRectGetHeight(self.bounds) - self.contentSize.height;
        if (beyond > 0 && tableViewHeight == scrollViewHeight) {
            self.contentTopLayout.constant += beyond;
        }
        //固定webview的contentoffset
        self.webView.scrollView.contentOffset = CGPointMake(0, webViewContentHeight - webViewHeight);
        CGFloat contentInsetBottom;
        if (@available (iOS 11.0, *)) {
            contentInsetBottom = self.tableView.adjustedContentInset.bottom;
        } else {
            contentInsetBottom = self.tableView.contentInset.bottom;
        }
        //tablview继续回弹，可以触发上拉刷新
        self.tableView.contentOffset = CGPointMake(0, MAX(0, netOffsetY - webViewContentHeight)+ contentInsetBottom);
    }
}

- (CGPoint)getOffsetWithY:(CGFloat)y
{
    CGPoint off = self.contentOffset;
    if (@available (iOS 11.0, *)) {
        off.y = y - self.adjustedContentInset.top;
    } else {
        off.y = y - self.contentInset.top;
    }
    return off;
}

#pragma mark - Publishs
- (void)scrollToHeadAnimated:(BOOL)animated
{
    [self setContentOffset:[self getOffsetWithY:0] animated:animated];
}

- (void)scrollToWebAnimated:(BOOL)animated
{
    [self setContentOffset:[self getOffsetWithY:CGRectGetHeight(self.headView.frame)] animated:animated];
}

- (void)scrollToTableAnimated:(BOOL)animated
{
    CGFloat insetY;
    if (@available (iOS 11.0, *)) {
        insetY = self.adjustedContentInset.top + self.adjustedContentInset.bottom;
    } else {
        insetY = self.contentInset.top + self.contentInset.bottom;
    }
    CGFloat maxOffsetY = MAX(0, insetY + self.contentSize.height - CGRectGetHeight(self.bounds));
    CGFloat offY = MIN(maxOffsetY, CGRectGetHeight(self.headView.frame) + self.webView.scrollView.contentSize.height);
    [self setContentOffset:[self getOffsetWithY:offY] animated:animated];
}

@end
