//
//  SecondViewController.m
//  NewsDetail
//
//  Created by xzm on 2020/3/17.
//  Copyright © 2020 NewsDetail. All rights reserved.
//

#import "SecondViewController.h"
#import <MJRefresh/MJRefresh.h>
#import <Masonry/Masonry.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import "WTScrollView.h"

@interface SecondViewController ()
<UITableViewDelegate,UITableViewDataSource,WTScrollViewDataSource,WKNavigationDelegate>
{
    NSMutableArray *_dataArray;
}

@property (strong, nonatomic) WTScrollView *wtScrollView;
@property (strong, nonatomic) WKWebView *webView;
@property (strong, nonatomic) UITableView *tableView;

@end

@implementation SecondViewController

- (void)dealloc
{
    NSLog(@"SecondViewController dealloc");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupNav];
    [self.view addSubview:self.wtScrollView];
    [self.wtScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    @weakify(self)
    self.wtScrollView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        @strongify(self)
        [self requestData];
    }];
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        @strongify(self);
        [self addTableData];
    }];
    [self.wtScrollView.mj_header beginRefreshing];
}

- (void)setupNav
{
    UIBarButtonItem *one = [[UIBarButtonItem alloc]initWithTitle:@"顶部" style:UIBarButtonItemStylePlain target:self action:@selector(rightAction:)];
    UIBarButtonItem *two = [[UIBarButtonItem alloc]initWithTitle:@"资讯" style:UIBarButtonItemStylePlain target:self action:@selector(rightAction:)];
    UIBarButtonItem *three = [[UIBarButtonItem alloc]initWithTitle:@"评论" style:UIBarButtonItemStylePlain target:self action:@selector(rightAction:)];
    self.navigationItem.rightBarButtonItems = @[three,two,one];
}

- (void)rightAction:(UIBarButtonItem *)item
{
    if ([item.title isEqualToString:@"顶部"]) {
        [self.wtScrollView scrollToHeadAnimated:YES];
    } else if ([item.title isEqualToString:@"资讯"]){
        [self.wtScrollView scrollToWebAnimated:YES];
    } else {
        [self.wtScrollView scrollToTableAnimated:YES];
    }
}

#pragma mark - Request
- (void)requestData
{
    [_dataArray removeAllObjects];
    [self addTableData];
    [self setWebUrl];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.wtScrollView.mj_header endRefreshing];
    });
}

- (void)addTableData
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self->_dataArray) self->_dataArray = @[].mutableCopy;
        for (int i = 0; i < 15; i ++) {
            [self->_dataArray addObject:@{}];
        };
        if (self->_dataArray.count > 100) {
            [self.tableView.mj_footer endRefreshingWithNoMoreData];
        } else {
            [self.tableView.mj_footer endRefreshing];
        }
        [self.tableView reloadData];
    });
}

- (void)setWebUrl
{
    NSArray *urlArray = @[@"http://www.medcircle.cn/osteoprosisonline/detail/254?type=2",
                          @"http://community.test.file.mediportal.com.cn/c6d12928a5b848d2972900a569c49389",
                          @"https://www.baidu.com",
                          @"https://weibo.com/2803301701/I1UyxmEqg?type=comme",
                          @"https://www.jianshu.com/app?utm_medium=app-download-bottom&utm_source=mobile",
                      @"http://test.mediportal.com.cn/doctororg/web/H5/wechatShare.html?title=xx&link=%2F%2Fcommunity.test.file.dachentech.com.cn%2Ff52eacd4cd2342678e5b9e90730db467&logo=http%3A%2F%2Fcommunity.test.file.dachentech.com.cn%2FFneocaG2U5OPgPoBTHRLfa9mY0cr%3FimageMogr2%2Fcrop%2F%21640x360a0a411.20000000000005&desc=xx",
                          @"https://mp.weixin.qq.com/s/wZCg-G-wVJfYZX_vR91h0A"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlArray[arc4random()%urlArray.count]]]];
}

#pragma mark - Lazzy
- (WKWebView *)webView
{
    if (!_webView) {
        _webView = [WKWebView new];
        _webView.navigationDelegate = self;
    }
    return _webView;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [UITableView new];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = 60;
    }
    return _tableView;
}

- (WTScrollView *)wtScrollView
{
    if (!_wtScrollView) {
        _wtScrollView = [WTScrollView new];
        _wtScrollView.wtDataSource = self;
    }
    return _wtScrollView;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.textLabel.text = @(indexPath.row).stringValue;
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SecondViewController *vc = [SecondViewController new];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - WKNavigationDelegate

#pragma mark - WTScrollViewDataSource
- (WKWebView *)webViewInWtScrollView:(WTScrollView *)wtScrollView
{
    return self.webView;
}

- (UITableView *)tableViewInWtScrollView:(WTScrollView *)wtScrollView
{
    return self.tableView;
}

- (UIView *)headerInWtScrollView:(WTScrollView *)wtScrollView
{
    UILabel *view = [UILabel new];
    view.textAlignment = 1;
    view.text = @"我是自定义header";
    view.backgroundColor = [UIColor grayColor];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(0);
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [view mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(200);
        }];
    });
    return view;
}

@end
