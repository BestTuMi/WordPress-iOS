//
//  LoginCompletedWalkthroughViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/1/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "LoginCompletedWalkthroughViewController.h"
#import "UIView+FormSheetHelpers.h"
#import "AboutViewController.h"
#import "WPWalkthroughGrayOverlayView.h"
#import "WordPressAppDelegate.h"
#import "WPNUXUtility.h"

@interface LoginCompletedWalkthroughViewController ()<UIScrollViewDelegate> {
    UIScrollView *_scrollView;
    UILabel *_skipToApp;
    
    // Page 1
    UIImageView *_page1Icon;
    UILabel *_page1Title;
    UILabel *_page1Description;
    UILabel *_page1SwipeToContinue;
    UIImageView *_page1TopSeparator;
    UIImageView *_page1BottomSeparator;
    UIView *_bottomPanelLine;
    UIView *_bottomPanel;
    UIPageControl *_pageControl;
    
    // Page 2
    UIImageView *_page2Icon;
    UILabel *_page2Title;
    UILabel *_page2Description;
    UIImageView *_page2TopSeparator;
    UIImageView *_page2BottomSeparator;
    
    // Page 3
    UIImageView *_page3Icon;
    UILabel *_page3Title;
    UILabel *_page3Description;
    UIImageView *_page3TopSeparator;
    UIImageView *_page3BottomSeparator;
    
    // Page 4
    UIImageView *_page4Icon;
    UILabel *_page4Title;
    
    CGFloat _viewWidth;
    CGFloat _viewHeight;
    
    CGFloat _currentPage;
    CGFloat _bottomPanelOriginalX;
    CGFloat _skipToAppOriginalX;
    CGFloat _pageControlOriginalX;
    CGFloat _heightFromSwipeToContinueToBottom;

    BOOL _savedOriginalPositionsOfStickyControls;
    BOOL _isDismissing;
    
    UIColor *_textShadowColor;
}

@end

@implementation LoginCompletedWalkthroughViewController

NSUInteger const LoginCompletedWalkthroughStandardOffset = 16;
CGFloat const LoginCompletedWalkthroughIconVerticalOffset = 85;
CGFloat const LoginCompletedWalkthroughMaxTextWidth = 289.0;
CGFloat const LoginCompletedWalkthroughBottomBackgroundHeight = 64.0;
CGFloat const LoginCompeltedWalkthroughSwipeToContinueTopOffset = 14.0;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self getInitialWidthAndHeight];
    self.view.backgroundColor = [UIColor colorWithRed:30.0/255.0 green:140.0/255.0 blue:190.0/255.0 alpha:1.0];
    [self addScrollview];
    [self initializePage1];
    [self initializePage2];
    [self initializePage3];
    [self initializePage4];
    [self showLoginSuccess];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self layoutScrollview];
    [self layoutPage1Controls];
    [self layoutPage2Controls];
    [self layoutPage3Controls];
    [self layoutPage4Controls];
    [self savePositionsOfStickyControls];
}

#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // TODO: Clean up this method as it's confusing
    if (scrollView.contentOffset.x < 0) {
        CGRect bottomPanelFrame = _bottomPanel.frame;
        bottomPanelFrame.origin.x = _bottomPanelOriginalX + scrollView.contentOffset.x;
        _bottomPanel.frame = bottomPanelFrame;
        
        CGRect skipToAppFrame = _skipToApp.frame;
        skipToAppFrame.origin.x = _skipToAppOriginalX + scrollView.contentOffset.x;
        _skipToApp.frame = skipToAppFrame;
        
        return;
    }
    
    NSUInteger pageViewed = ceil(scrollView.contentOffset.x/_viewWidth) + 1;
    
    CGRect bottomPanelFrame = _bottomPanel.frame;
    bottomPanelFrame.origin.x = _bottomPanelOriginalX + scrollView.contentOffset.x;
    _bottomPanel.frame = bottomPanelFrame;
    
    CGRect pageControlFrame = _pageControl.frame;
    pageControlFrame.origin.x = _pageControlOriginalX + scrollView.contentOffset.x;
    _pageControl.frame = pageControlFrame;

    CGRect skipToAppFrame = _skipToApp.frame;
    skipToAppFrame.origin.x = _skipToAppOriginalX + scrollView.contentOffset.x;
    _skipToApp.frame = skipToAppFrame;
    
    [self flagPageViewed:pageViewed];
}


#pragma mark - Private Methods

- (void)getInitialWidthAndHeight
{
    _viewWidth = [self.view formSheetViewWidth];
    _viewHeight = [self.view formSheetViewHeight];
}

- (void)savePositionsOfStickyControls
{
    if (!_savedOriginalPositionsOfStickyControls) {
        _savedOriginalPositionsOfStickyControls = true;
        _skipToAppOriginalX = CGRectGetMinX(_skipToApp.frame);
        _bottomPanelOriginalX = CGRectGetMinX(_bottomPanel.frame);
        _pageControlOriginalX = CGRectGetMinX(_pageControl.frame);
    }
}

- (void)showLoginSuccess
{
    WPWalkthroughGrayOverlayView *grayOverlay = [[WPWalkthroughGrayOverlayView alloc] initWithFrame:CGRectMake(0, 0, _viewWidth, _viewHeight)];
    grayOverlay.overlayTitle = NSLocalizedString(@"NUX_Second_Walkthrough_Success_Overlay_Title", nil);
    grayOverlay.overlayDescription = NSLocalizedString(@"NUX_Second_Walkthrough_Success_Overlay_Description", nil);
    grayOverlay.overlayMode = WPWalkthroughGrayOverlayViewOverlayModeTapToDismiss;
    grayOverlay.footerDescription = NSLocalizedString(@"TAP TO CONTINUE", nil);
    grayOverlay.icon = WPWalkthroughGrayOverlayViewBlueCheckmarkIcon;
    grayOverlay.hideBackgroundView = YES;
    grayOverlay.singleTapCompletionBlock = ^(WPWalkthroughGrayOverlayView * overlayView){
        if (!self.showsExtraWalkthroughPages) {
            [self dismiss];
        } else {
            [overlayView dismiss];
        }
    };
    [self.view addSubview:grayOverlay];
}

- (void)addScrollview
{
    _scrollView = [[UIScrollView alloc] init];
    CGSize scrollViewSize = _scrollView.contentSize;
    scrollViewSize.width = _viewWidth * 4;
    _scrollView.frame = self.view.bounds;
    _scrollView.contentSize = scrollViewSize;
    _scrollView.pagingEnabled = true;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.pagingEnabled = YES;
    [self.view addSubview:_scrollView];
    _scrollView.delegate = self;
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedScrollView:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.numberOfTapsRequired = 1;
    [_scrollView addGestureRecognizer:gestureRecognizer];
}

- (void)layoutScrollview
{
    _scrollView.frame = self.view.bounds;
}

- (void)initializePage1
{
    [self addPage1Controls];
    [self layoutPage1Controls];
}

- (void)addPage1Controls
{
    
    // Add Icon
    if (_page1Icon == nil) {
        _page1Icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-stats"]];
        [_scrollView addSubview:_page1Icon];
    }

    // Add Title
    if (_page1Title == nil) {
        _page1Title = [[UILabel alloc] init];
        _page1Title.backgroundColor = [UIColor clearColor];
        _page1Title.textAlignment = UITextAlignmentCenter;
        _page1Title.numberOfLines = 0;
        _page1Title.lineBreakMode = UILineBreakModeWordWrap;
        _page1Title.font = [WPNUXUtility titleFont];
        _page1Title.text = NSLocalizedString(@"NUX_Second_Walkthrough_Page1_Title", nil);
        _page1Title.shadowColor = [WPNUXUtility textShadowColor];
        _page1Title.shadowOffset = CGSizeMake(0.0, 1.0);
        _page1Title.layer.shadowRadius = 2.0;
        _page1Title.textColor = [UIColor whiteColor];
        [_scrollView addSubview:_page1Title];
    }
    
    // Add Top Separator
    if (_page1TopSeparator == nil) {
        _page1TopSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line"]];
        [_scrollView addSubview:_page1TopSeparator];
    }
    
    // Add Description
    if (_page1Description == nil) {
        _page1Description = [[UILabel alloc] init];
        _page1Description.backgroundColor = [UIColor clearColor];
        _page1Description.textAlignment = UITextAlignmentCenter;
        _page1Description.numberOfLines = 0;
        _page1Description.lineBreakMode = UILineBreakModeWordWrap;
        _page1Description.font = [WPNUXUtility descriptionTextFont];
        _page1Description.text = NSLocalizedString(@"NUX_Second_Walkthrough_Page1_Description", nil);
        _page1Description.shadowOffset = CGSizeMake(0.0, 1.0);
        _page1Description.shadowColor = [WPNUXUtility textShadowColor];
        _page1Title.layer.shadowRadius = 2.0;
        _page1Description.textColor = [WPNUXUtility descriptionTextColor];
        [_scrollView addSubview:_page1Description];
    }
    
    // Add Bottom Separator
    if (_page1BottomSeparator == nil) {
        _page1BottomSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line"]];
        [_scrollView addSubview:_page1BottomSeparator];
    }
    
    // Bottom Portion
    if (_bottomPanel == nil) {
        _bottomPanel = [[UIView alloc] init];
        _bottomPanel.backgroundColor = [WPNUXUtility bottomPanelBackgroundColor];
        [_scrollView addSubview:_bottomPanel];
        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedBottomPanel:)];
        gestureRecognizer.numberOfTapsRequired = 1;
        [_bottomPanel addGestureRecognizer:gestureRecognizer];
    }
    
    // Bottom Panel "Black" Line
    if (_bottomPanelLine == nil) {
        _bottomPanelLine = [[UIView alloc] init];
        _bottomPanelLine.backgroundColor = [WPNUXUtility bottomPanelLineColor];
        [_scrollView addSubview:_bottomPanelLine];
    }
    
    // Add Page Control
    if (_pageControl == nil) {
        // The page control adds a bunch of extra space for padding that messes with our calculations.
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.numberOfPages = 4;
        [_pageControl sizeToFit];
        [WPNUXUtility configurePageControlTintColors:_pageControl];
        [_scrollView addSubview:_pageControl];
    }
    
    // Add "SWIPE TO CONTINUE"
    if (_page1SwipeToContinue == nil) {
        _page1SwipeToContinue = [[UILabel alloc] init];
        [_page1SwipeToContinue setTextColor:[WPNUXUtility swipeToContinueTextColor]];
        [_page1SwipeToContinue setShadowColor:[WPNUXUtility textShadowColor]];
        _page1SwipeToContinue.backgroundColor = [UIColor clearColor];
        _page1SwipeToContinue.textAlignment = UITextAlignmentCenter;
        _page1SwipeToContinue.numberOfLines = 1;
        _page1SwipeToContinue.font = [WPNUXUtility swipeToContinueFont];
        _page1SwipeToContinue.text = NSLocalizedString(@"SWIPE TO CONTINUE", nil);
        [_page1SwipeToContinue sizeToFit];
        [_scrollView addSubview:_page1SwipeToContinue];
    }
    
    // Add Skip to App Button
    if (_skipToApp == nil) {
        _skipToApp = [[UILabel alloc] init];
        _skipToApp.backgroundColor = [UIColor clearColor];
        _skipToApp.textColor = [UIColor whiteColor];
        _skipToApp.font = [UIFont fontWithName:@"OpenSans" size:15.0];
        _skipToApp.text = NSLocalizedString(@"NUX_Second_Walkthrough_Bottom_Skip_Label", nil;);
        _skipToApp.shadowColor = [UIColor blackColor];
        [_skipToApp sizeToFit];
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickedSkipToApp:)];
        tapGestureRecognizer.numberOfTapsRequired = 1;
        _skipToApp.userInteractionEnabled = YES;
        [_skipToApp addGestureRecognizer:tapGestureRecognizer];
        [_scrollView addSubview:_skipToApp];
    }
}

- (void)layoutPage1Controls
{
    CGFloat x,y;
    
    // Layout Stats Icon
    x = (_viewWidth - CGRectGetWidth(_page1Icon.frame))/2.0;
    y = LoginCompletedWalkthroughIconVerticalOffset;
    _page1Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page1Icon.frame), CGRectGetHeight(_page1Icon.frame)));
 
    // Layout Title
    CGSize titleSize = [_page1Title.text sizeWithFont:_page1Title.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - titleSize.width)/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(_page1Icon.frame) + 0.5*LoginCompletedWalkthroughStandardOffset;
    _page1Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    // Layout Top Separator
    x = LoginCompletedWalkthroughStandardOffset;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(_page1Title.frame) + LoginCompletedWalkthroughStandardOffset;
    _page1TopSeparator.frame = CGRectMake(x, y, _viewWidth - 2*LoginCompletedWalkthroughStandardOffset, 2);
    
    // Layout Description
    CGSize labelSize = [_page1Description.text sizeWithFont:_page1Description.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - labelSize.width)/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(_page1TopSeparator.frame) + 0.5*LoginCompletedWalkthroughStandardOffset;
    _page1Description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));

    // Layout Bottom Separator
    x = LoginCompletedWalkthroughStandardOffset;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMaxY(_page1Description.frame) + 0.5*LoginCompletedWalkthroughStandardOffset;
    _page1BottomSeparator.frame = CGRectMake(x, y, _viewWidth - 2*LoginCompletedWalkthroughStandardOffset, 2);
    
    // Layout Bottom Panel
    x = 0;
    x = [self adjustX:x forPage:1];
    y = _viewHeight - LoginCompletedWalkthroughBottomBackgroundHeight;
    _bottomPanel.frame = CGRectMake(x, y, _viewWidth, LoginCompletedWalkthroughBottomBackgroundHeight);
    
    // Layout Bottom Panel Line
    x = 0;
    y = CGRectGetMinY(_bottomPanel.frame);
    _bottomPanelLine.frame = CGRectMake(x, y, _viewWidth, 1);
    
    // Layout Page Control
    CGFloat verticalSpaceForPageControl = 15;
    x = (_viewWidth - CGRectGetWidth(_pageControl.frame))/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMinY(_bottomPanel.frame) - LoginCompletedWalkthroughStandardOffset - CGRectGetHeight(_pageControl.frame) + verticalSpaceForPageControl;
    _pageControl.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_pageControl.frame), CGRectGetHeight(_pageControl.frame)));

    // Layout Swipe to Continue Label
    x = (_viewWidth - CGRectGetWidth(_page1SwipeToContinue.frame))/2.0;
    x = [self adjustX:x forPage:1];
    y = CGRectGetMinY(_pageControl.frame) - LoginCompeltedWalkthroughSwipeToContinueTopOffset - CGRectGetHeight(_page1SwipeToContinue.frame) + verticalSpaceForPageControl;
    _page1SwipeToContinue.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page1SwipeToContinue.frame), CGRectGetHeight(_page1SwipeToContinue.frame)));

    // Layout Skip and Start Using App
    x = (_viewWidth - CGRectGetWidth(_skipToApp.frame))/2.0;
    y = CGRectGetMinY(_bottomPanel.frame) + (CGRectGetHeight(_bottomPanel.frame)-CGRectGetHeight(_skipToApp.frame))/2.0;
    _skipToApp.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_skipToApp.frame), CGRectGetHeight(_skipToApp.frame)));
    
    _heightFromSwipeToContinueToBottom = _viewHeight - CGRectGetMinY(_page1SwipeToContinue.frame) - CGRectGetHeight(_page1SwipeToContinue.frame);
    NSArray *viewsToCenter = @[_page1Icon, _page1Title, _page1TopSeparator, _page1Description, _page1BottomSeparator];
    [WPNUXUtility centerViews:viewsToCenter withStartingView:_page1Icon andEndingView:_page1BottomSeparator forHeight:(_viewHeight-_heightFromSwipeToContinueToBottom)];
}

- (void)initializePage2
{
    [self addPage2Controls];
    [self layoutPage2Controls];
}

- (void)addPage2Controls
{
    // Add Icon
    if (_page2Icon == nil) {
        _page2Icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-reader"]];
        [_scrollView addSubview:_page2Icon];
    }
    
    // Add Title
    if (_page2Title == nil) {
        _page2Title = [[UILabel alloc] init];
        _page2Title.backgroundColor = [UIColor clearColor];
        _page2Title.textAlignment = UITextAlignmentCenter;
        _page2Title.numberOfLines = 0;
        _page2Title.lineBreakMode = UILineBreakModeWordWrap;
        _page2Title.font = [WPNUXUtility titleFont];
        _page2Title.text = NSLocalizedString(@"NUX_Second_Walkthrough_Page2_Title", nil);
        _page2Title.shadowColor = [WPNUXUtility textShadowColor];
        _page2Title.shadowOffset = CGSizeMake(0.0, 1.0);
        _page2Title.layer.shadowRadius = 2.0;
        _page2Title.textColor = [UIColor whiteColor];
        [_scrollView addSubview:_page2Title];
    }
    
    // Add Top Separator
    if (_page2TopSeparator == nil) {
        _page2TopSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line"]];
        [_scrollView addSubview:_page2TopSeparator];
    }
    
    // Add Description
    if (_page2Description == nil) {
        _page2Description = [[UILabel alloc] init];
        _page2Description.backgroundColor = [UIColor clearColor];
        _page2Description.textAlignment = UITextAlignmentCenter;
        _page2Description.numberOfLines = 0;
        _page2Description.lineBreakMode = UILineBreakModeWordWrap;
        _page2Description.font = [WPNUXUtility descriptionTextFont];
        _page2Description.text = NSLocalizedString(@"NUX_Second_Walkthrough_Page2_Description", nil);
        _page2Description.shadowOffset = CGSizeMake(0.0, 1.0);
        _page2Description.shadowColor = [WPNUXUtility textShadowColor];
        _page2Description.layer.shadowRadius = 2.0;
        _page2Description.textColor = [WPNUXUtility descriptionTextColor];
        [_scrollView addSubview:_page2Description];
    }
    
    // Add Bottom Separator
    if (_page2BottomSeparator == nil) {
        _page2BottomSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line"]];
        [_scrollView addSubview:_page2BottomSeparator];
    }
}

- (void)layoutPage2Controls
{
    CGFloat x,y;

    x = (_viewWidth - CGRectGetWidth(_page2Icon.frame))/2.0;
    x = [self adjustX:x forPage:2];
    y = LoginCompletedWalkthroughIconVerticalOffset;
    _page2Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page2Icon.frame), CGRectGetHeight(_page2Icon.frame)));

    // Layout Title
    CGSize titleSize = [_page2Title.text sizeWithFont:_page2Title.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - titleSize.width)/2.0;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(_page2Icon.frame) + 0.5*LoginCompletedWalkthroughStandardOffset;
    _page2Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    // Layout Top Separator
    x = LoginCompletedWalkthroughStandardOffset;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(_page2Title.frame) + LoginCompletedWalkthroughStandardOffset;
    _page2TopSeparator.frame = CGRectMake(x, y, _viewWidth - 2*LoginCompletedWalkthroughStandardOffset, 2);
    
    // Layout Description
    CGSize labelSize = [_page2Description.text sizeWithFont:_page2Description.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - labelSize.width)/2.0;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(_page2TopSeparator.frame) + 0.5*LoginCompletedWalkthroughStandardOffset;
    _page2Description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));
    
    // Layout Bottom Separator
    x = LoginCompletedWalkthroughStandardOffset;
    x = [self adjustX:x forPage:2];
    y = CGRectGetMaxY(_page2Description.frame) + 0.5*LoginCompletedWalkthroughStandardOffset;
    _page2BottomSeparator.frame = CGRectMake(x, y, _viewWidth - 2*LoginCompletedWalkthroughStandardOffset, 2);
    
    NSArray *viewsToCenter = @[_page2Icon, _page2Title, _page2TopSeparator, _page2Description, _page2BottomSeparator];
    [WPNUXUtility centerViews:viewsToCenter withStartingView:_page2Icon andEndingView:_page2BottomSeparator forHeight:(_viewHeight-_heightFromSwipeToContinueToBottom)];
}

- (void)initializePage3
{
    [self addPage3Controls];
    [self layoutPage3Controls];
}

- (void)addPage3Controls
{
    // Add Icon
    if (_page3Icon == nil) {
        _page3Icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-notifications"]];
        [_scrollView addSubview:_page3Icon];
    }
    
    // Add Title
    if (_page3Title == nil) {
        _page3Title = [[UILabel alloc] init];
        _page3Title.backgroundColor = [UIColor clearColor];
        _page3Title.textAlignment = UITextAlignmentCenter;
        _page3Title.numberOfLines = 0;
        _page3Title.lineBreakMode = UILineBreakModeWordWrap;
        _page3Title.font = [WPNUXUtility titleFont];
        _page3Title.text = NSLocalizedString(@"NUX_Second_Walkthrough_Page3_Title", nil);
        _page3Title.shadowColor = [WPNUXUtility textShadowColor];
        _page3Title.shadowOffset = CGSizeMake(0.0, 1.0);
        _page3Title.layer.shadowRadius = 2.0;
        _page3Title.textColor = [UIColor whiteColor];
        [_scrollView addSubview:_page3Title];
    }
    
    // Add Top Separator
    if (_page3TopSeparator == nil) {
        _page3TopSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line"]];
        [_scrollView addSubview:_page3TopSeparator];
    }
    
    // Add Description
    if (_page3Description == nil) {
        _page3Description = [[UILabel alloc] init];
        _page3Description.backgroundColor = [UIColor clearColor];
        _page3Description.textAlignment = UITextAlignmentCenter;
        _page3Description.numberOfLines = 0;
        _page3Description.lineBreakMode = UILineBreakModeWordWrap;
        _page3Description.font = [WPNUXUtility descriptionTextFont];
        _page3Description.text = NSLocalizedString(@"NUX_Second_Walkthrough_Page3_Description", nil);
        _page3Description.shadowOffset = CGSizeMake(0.0, 1.0);
        _page3Description.shadowColor = [WPNUXUtility textShadowColor];
        _page3Description.layer.shadowRadius = 2.0;
        _page3Description.textColor = [WPNUXUtility descriptionTextColor];
        [_scrollView addSubview:_page3Description];
    }
    
    // Add Bottom Separator
    if (_page3BottomSeparator == nil) {
        _page3BottomSeparator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui-line"]];
        [_scrollView addSubview:_page3BottomSeparator];
    }
}

- (void)layoutPage3Controls
{
    CGFloat x,y;
    
    x = (_viewWidth - CGRectGetWidth(_page3Icon.frame))/2.0;
    x = [self adjustX:x forPage:3];
    y = LoginCompletedWalkthroughIconVerticalOffset;
    _page3Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page3Icon.frame), CGRectGetHeight(_page3Icon.frame)));
    
    // Layout Title
    CGSize titleSize = [_page3Title.text sizeWithFont:_page3Title.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - titleSize.width)/2.0;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(_page3Icon.frame) + 0.5*LoginCompletedWalkthroughStandardOffset;
    _page3Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    // Layout Top Separator
    x = LoginCompletedWalkthroughStandardOffset;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(_page3Title.frame) + LoginCompletedWalkthroughStandardOffset;
    _page3TopSeparator.frame = CGRectMake(x, y, _viewWidth - 2*LoginCompletedWalkthroughStandardOffset, 2);
    
    // Layout Description
    CGSize labelSize = [_page3Description.text sizeWithFont:_page3Description.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - labelSize.width)/2.0;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(_page3TopSeparator.frame) + 0.5*LoginCompletedWalkthroughStandardOffset;
    _page3Description.frame = CGRectIntegral(CGRectMake(x, y, labelSize.width, labelSize.height));
    
    // Layout Bottom Separator
    x = LoginCompletedWalkthroughStandardOffset;
    x = [self adjustX:x forPage:3];
    y = CGRectGetMaxY(_page3Description.frame) + 0.5*LoginCompletedWalkthroughStandardOffset;
    _page3BottomSeparator.frame = CGRectMake(x, y, _viewWidth - 2*LoginCompletedWalkthroughStandardOffset, 2);
    
    NSArray *viewsToCenter = @[_page3Icon, _page3Title, _page3TopSeparator, _page3Description, _page3BottomSeparator];
    [WPNUXUtility centerViews:viewsToCenter withStartingView:_page3Icon andEndingView:_page3BottomSeparator forHeight:(_viewHeight-_heightFromSwipeToContinueToBottom)];
}

- (void)initializePage4
{
    [self addPage4Controls];
    [self layoutPage4Controls];
}

- (void)addPage4Controls
{
    // Add Icon
    if (_page4Icon == nil) {
        _page4Icon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon-check"]];
        [_scrollView addSubview:_page4Icon];
    }
    
    // Add Title
    if (_page4Title == nil) {
        _page4Title = [[UILabel alloc] init];
        _page4Title.backgroundColor = [UIColor clearColor];
        _page4Title.textAlignment = UITextAlignmentCenter;
        _page4Title.numberOfLines = 0;
        _page4Title.lineBreakMode = UILineBreakModeWordWrap;
        _page4Title.font = [WPNUXUtility titleFont];
        _page4Title.text = NSLocalizedString(@"NUX_Second_Walkthrough_Page4_Title", nil);
        _page4Title.shadowColor = [WPNUXUtility textShadowColor];
        _page4Title.shadowOffset = CGSizeMake(0.0, 1.0);
        _page4Title.layer.shadowRadius = 2.0;
        _page4Title.textColor = [UIColor whiteColor];
        [_scrollView addSubview:_page4Title];
    }    
}

- (void)layoutPage4Controls
{
    CGFloat x,y;
    CGFloat currentPage=4;
    
    x = (_viewWidth - CGRectGetWidth(_page4Icon.frame))/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = LoginCompletedWalkthroughIconVerticalOffset;
    _page4Icon.frame = CGRectIntegral(CGRectMake(x, y, CGRectGetWidth(_page4Icon.frame), CGRectGetHeight(_page4Icon.frame)));
    
    // Layout Title
    CGSize titleSize = [_page4Title.text sizeWithFont:_page4Title.font constrainedToSize:CGSizeMake(LoginCompletedWalkthroughMaxTextWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
    x = (_viewWidth - titleSize.width)/2.0;
    x = [self adjustX:x forPage:currentPage];
    y = CGRectGetMaxY(_page4Icon.frame) + 0.5*LoginCompletedWalkthroughStandardOffset;
    _page4Title.frame = CGRectIntegral(CGRectMake(x, y, titleSize.width, titleSize.height));
    
    NSArray *viewsToCenter = @[_page4Icon, _page4Title];
    [WPNUXUtility centerViews:viewsToCenter withStartingView:_page4Title andEndingView:_page4Title forHeight:(_viewHeight-_heightFromSwipeToContinueToBottom)];
}

- (CGFloat)adjustX:(CGFloat)x forPage:(NSUInteger)page
{
    return (x + _viewWidth*(page-1));
}

- (void)flagPageViewed:(NSUInteger)pageViewed
{
    _pageControl.currentPage = pageViewed - 1;
    _currentPage = pageViewed;
}

- (void)clickedSkipToApp:(UITapGestureRecognizer *)gestureRecognizer
{
    [self dismiss];
}

- (void)clickedBottomPanel:(UITapGestureRecognizer *)gestureRecognizer
{
    [self clickedSkipToApp:nil];
}

- (void)clickedScrollView:(UITapGestureRecognizer *)gestureRecognizer
{
    if (_currentPage == 4) {
        [self dismiss];
    }
}

- (void)dismiss
{
    if (!_isDismissing) {
        _isDismissing = true;
        self.parentViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self.parentViewController dismissModalViewControllerAnimated:YES];
        [[WordPressAppDelegate sharedWordPressApplicationDelegate].panelNavigationController teaseSidebar];
    }
}

@end
