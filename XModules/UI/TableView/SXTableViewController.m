//
//  SXMainViewController.m
//  SXClient
//
//  Created by iBcker on 14-9-30.
//  Copyright (c) 2014年 SX. All rights reserved.
//

#import "SXTableViewController.h"
#import "SXUtilities.h"
#import "UIView+Sizes.h"

@implementation SXTableViewController

- (CGFloat)autoInsetsTop
{
    return self.navigationController.navigationBar.isTranslucent?64:0;
}

- (CGFloat)autoInsetsBottom
{
    return self.tabBarController&&!self.hidesBottomBarWhenPushed?48:0;
}

- (UITableViewStyle)tableViewStyle
{
    return UITableViewStylePlain;
}

- (void)loadView
{
    [super loadView];
    [self configTableView];
}

- (SXTableView *)tableView
{
    if (!_tableView) {
        _tableView = [[SXTableView alloc] initWithFrame:self.view.bounds style:self.tableViewStyle];
        [self.view addSubview:_tableView];
        [self configTableView];
    }
    return _tableView;
}

- (void)configTableView
{
    _tableView.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _tableView.contentInset=UIEdgeInsetsMake([self autoInsetsTop], 0, [self autoInsetsBottom], 0);
    _tableView.scrollIndicatorInsets=_tableView.contentInset;
    _tableView.delegate=self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.needPull2Refresh) {
        self.refreshView = [[SRRefreshView alloc] init];
        self.refreshView.delegate = self;
        self.refreshView.upInset = self.tableView.contentInset.top;
        self.refreshView.slimeMissWhenGoingBack = YES;
        self.refreshView.slime.bodyColor = [UIColor lightGrayColor];
        self.refreshView.slime.skinColor = [UIColor whiteColor];
        self.refreshView.slime.lineWith = 1;
        self.refreshView.slime.shadowBlur = 3;
        self.refreshView.slime.shadowColor = [UIColor lightGrayColor];
        [self.tableView addSubview:self.refreshView];
        self.refreshView.autoresizingMask=UIViewAutoresizingFlexibleWidth;
    }
    
    if (self.needLoadMore) {
        self.loadMoreControl=[[WLoadMore alloc] initWithScrollView:self.tableView];
        
        UIView *container = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.tableView.width, 40)];
        container.autoresizingMask=UIViewAutoresizingFlexibleWidth;
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [indicator startAnimating];
        indicator.frame=container.bounds;
        indicator.autoresizingMask=UIViewAutoresizingFlexibleWidth;
        [container addSubview:indicator];
        
        self.loadMoreControl.contentView = container;
        self.loadMoreControl.delegate = self;
        self.loadMoreControl.threshold=120;
    }
    
    [self loadData];
}

- (void)reloadData
{
}

- (void)loadData
{
}

- (void)reloadTableView
{
    self.dataSource.objs=[self buildCellObjes:self.viewModel.objs];
    [self.tableView reloadData];
}

- (BOOL)needRefresh
{
    return SXCacheIsExpire(self.viewModel.keyForDiskCache);
}

- (void)updateCacheTime
{
    updateCacheTime(self.viewModel.keyForDiskCache);
}

- (Class)dataSourceClass
{
    return SXTableViewDataSource.class;
}

- (Class)viewModelClass
{
    return SXViewModel.class;
}

-(SXTableViewDataSource *)dataSource
{
    if (!_dataSource) {
        _dataSource = [[self.dataSourceClass alloc] initWithTableView:self.tableView];
        _dataSource.delegate=self;
    }
    return _dataSource;
}

- (SXViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel=[[self.viewModelClass alloc] init];
    }
    return _viewModel;
}

- (NSArray *)buildCellObjes:(NSArray *)res
{
    return nil;
}

- (void)dealloc
{
    self.loadMoreControl.delegate=nil;
    self.loadMoreControl.contentView=nil;
    self.loadMoreControl=nil;
    
    self.refreshView.delegate=nil;
    [self.refreshView removeFromSuperview];
    self.refreshView=nil;
    
    _tableView.delegate=nil;
    _tableView.dataSource=nil;
    _tableView=nil;
    _viewModel=nil;
    _dataSource=nil;
    
    //    [(AppDelegate *)[[UIApplication sharedApplication] delegate] removeObserver:self forKeyPath:kIsLeftPathOpen];
}

- (void)slimeRefreshStartRefresh:(SRRefreshView *)refreshView
{
    [self.viewModel loadData:^(id res, NSError *error) {
        [_refreshView endRefresh];
        [self reloadTableView];
        if (!error) {
            [self updateCacheTime];
        }
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.refreshView scrollViewDidScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.refreshView scrollViewDidEndDraging];
}

#pragma mark --tableview--
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.dataSource heightForCellAtIndexPath:indexPath];
}

#pragma mark - loadMore delegate

// 返回YES则进入加载更多形态
- (BOOL)loadMoreShouldTrigger:(WLoadMore *)loadMore;
{
    return self.canLoadMore&&(self.tableView.contentSize.height>self.tableView.height);
}

- (BOOL)canLoadMore
{
    return self.viewModel.hasMore;
}

// 进入加载形态后被调用 当 设置loading = YES时触发，跟用KVO一样的效果
- (void)loadMoreDidTriggered:(WLoadMore *)loadMore
{
    [self.viewModel loadMore:^(id res, NSError *error) {
        [loadMore finishLoading];
        if (!error) {
            [self reloadTableView];
        }
    }];
}

- (BOOL)loadMoreShouldChangeContentInset:(WLoadMore *)loadMore enlarge:(BOOL)enlarge
{
    return YES;
}


@end