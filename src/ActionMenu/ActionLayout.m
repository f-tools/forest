//
//  ActionLayout.m
//  Forest
//

#import "ActionLayout.h"
#import "ThemeManager.h"

@implementation ActionButtonInfo

- (id)init
{
    if (self = [super init]) {
    }

    return self;
}

- (id)initWithTitle:(NSString *)title withImageName:(NSString *)name
{
    if (self = [super init]) {
        _buttonImageName = name;
        _title = title;
    }
    return self;
}

@end

// ActionLayoutBuilder
@implementation ActionLayout

- (void)verticalLayout:(NSArray *)infoArray withWidth:(NSUInteger)containerWidth
{
    self.buttonWidth = 60;
    self.buttonHeight = 90;

    self.spaceWidth = 10;
    self.spaceHeight = 0.5;

    self.topMargin = 20;
    self.bottomMargin = 0.5;
    self.leftMargin = 10;
    self.rightMargin = 10;

    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor clearColor];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    self.view = view;

    UIView *bottomRefView = self.view;

    for (NSInteger i = [infoArray count] - 1; i >= 0; i--) {
        ActionButtonInfo *info = [infoArray objectAtIndex:i];
        //下から積み上げていく
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        info.view = button;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        info.button = button;

        [self.view addSubview:info.button];

        NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:button
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1.0
                                                                             constant:38];
        [button addConstraints:@[ heightConstraint ]];

        NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:button
                                                                          attribute:NSLayoutAttributeLeft
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.view
                                                                          attribute:NSLayoutAttributeLeft
                                                                         multiplier:1.0
                                                                           constant:0];
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:button
                                                                           attribute:NSLayoutAttributeRight
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.view
                                                                           attribute:NSLayoutAttributeRight
                                                                          multiplier:1.0
                                                                            constant:0];
        [self.view addConstraints:@[ leftConstraint, rightConstraint ]];
        [self setBottomPositionConstraint:bottomRefView button:button];

        bottomRefView = button;
    }

    //self.viewのtop制約
    if (bottomRefView) {
        if (self.aboveViews) {
            for (UIView *view in self.aboveViews) {
                [self.view addSubview:view];

                [self.view addConstraints:@[
                    [NSLayoutConstraint constraintWithItem:bottomRefView
                                                 attribute:NSLayoutAttributeTop
                                                 relatedBy:NSLayoutRelationEqual
                                                    toItem:view
                                                 attribute:NSLayoutAttributeBottom
                                                multiplier:1.0
                                                  constant:17]
                ]];
                [self.view addConstraints:@[
                    [NSLayoutConstraint constraintWithItem:view
                                                 attribute:NSLayoutAttributeCenterX
                                                 relatedBy:NSLayoutRelationEqual
                                                    toItem:self.view
                                                 attribute:NSLayoutAttributeCenterX
                                                multiplier:1.0
                                                  constant:0]
                ]];

                bottomRefView = view;
            }
        }

        [self.view addConstraints:@[
            [NSLayoutConstraint constraintWithItem:bottomRefView
                                         attribute:NSLayoutAttributeTop
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self.view
                                         attribute:NSLayoutAttributeTop
                                        multiplier:1.0
                                          constant:self.topMargin]
        ]];
    }
}

- (void)layout:(NSArray *)infoArray withWidth:(NSUInteger)containerWidth
{

    self.buttonWidth = 60;
    self.buttonHeight = 90;

    self.spaceWidth = 15;
    self.spaceHeight = 4;

    self.topMargin = 20;
    self.bottomMargin = 5;
    self.leftMargin = 10;
    self.rightMargin = 10;

    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor clearColor];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    self.view = view;

    NSUInteger count = [infoArray count];

    NSInteger nextButtonIndex = 0;
    UIView *bottomRefView = self.view;
    BOOL firstBottom = YES;

    while (YES) {
        UIView *leftRefButton = nil;
        UIView *rightRefButton = nil;

        NSInteger remain = count - nextButtonIndex;
        NSUInteger buttonCountInLine = 0;

        for (NSUInteger tempButtonCount = 1; tempButtonCount <= remain; tempButtonCount++) {
            NSUInteger totalWidth = self.buttonWidth * tempButtonCount;
            totalWidth += self.leftMargin + self.rightMargin;
            totalWidth += (tempButtonCount - 1) * self.spaceWidth;
            if (totalWidth > containerWidth)
                break;

            buttonCountInLine = tempButtonCount;
        }

        if (buttonCountInLine == 0) break;

        //最後が少なすぎるときの数合わせ
        if (remain - buttonCountInLine > 0 && remain - buttonCountInLine <= buttonCountInLine - 2) {
            buttonCountInLine -= (buttonCountInLine - (remain - buttonCountInLine)) / 2;
        }

        BOOL odd = buttonCountInLine % 2 == 1;

        int horizontalIndex = 0;

        if (odd) {
            ActionButtonInfo *info = [infoArray objectAtIndex:nextButtonIndex++];
            [self setupButton:info];
            UIView *centerButton = info.view;

            rightRefButton = leftRefButton = centerButton;

            [self setWidthAndHeightConstraint:centerButton];
            [self setBottomPositionConstraint:bottomRefView button:centerButton];

            [self.view addConstraints:@[
                [NSLayoutConstraint constraintWithItem:centerButton
                                             attribute:NSLayoutAttributeCenterX
                                             relatedBy:NSLayoutRelationEqual
                                                toItem:self.view
                                             attribute:NSLayoutAttributeCenterX
                                            multiplier:1.0
                                              constant:0]
            ]];

            horizontalIndex++;
        } else {

            ActionButtonInfo *rightInfo = [infoArray objectAtIndex:nextButtonIndex++];
            [self setupButton:rightInfo];
            rightRefButton = rightInfo.view;

            [self setWidthAndHeightConstraint:rightRefButton];
            [self.view addConstraints:@[
                [NSLayoutConstraint constraintWithItem:rightRefButton
                                             attribute:NSLayoutAttributeLeft
                                             relatedBy:NSLayoutRelationEqual
                                                toItem:self.view
                                             attribute:NSLayoutAttributeCenterX
                                            multiplier:1.0
                                              constant:self.spaceWidth / 2]
            ]];
            [self setBottomPositionConstraint:bottomRefView button:rightRefButton];

            ActionButtonInfo *leftInfo = [infoArray objectAtIndex:nextButtonIndex++];
            [self setupButton:leftInfo];
            leftRefButton = leftInfo.view;

            [self setWidthAndHeightConstraint:leftRefButton];
            [self.view addConstraints:@[
                [NSLayoutConstraint constraintWithItem:self.view
                                             attribute:NSLayoutAttributeCenterX
                                             relatedBy:NSLayoutRelationEqual
                                                toItem:leftRefButton
                                             attribute:NSLayoutAttributeRight
                                            multiplier:1.0
                                              constant:self.spaceWidth / 2]
            ]];
            [self setBottomPositionConstraint:bottomRefView button:leftRefButton];
            horizontalIndex += 2;
        }

        UIView *nextBottomRefView = leftRefButton; //次の上のボタンのbottomの指標となる

        for (; nextButtonIndex < count && horizontalIndex < buttonCountInLine; horizontalIndex += 2) {
            //right
            ActionButtonInfo *rightInfo = (ActionButtonInfo *)[infoArray objectAtIndex:nextButtonIndex++];
            [self setupButton:rightInfo];
            UIView *rightButton = rightInfo.view;

            [self setWidthAndHeightConstraint:rightButton];
            [self.view addConstraints:@[
                [NSLayoutConstraint constraintWithItem:rightButton
                                             attribute:NSLayoutAttributeLeft
                                             relatedBy:NSLayoutRelationEqual
                                                toItem:rightRefButton
                                             attribute:NSLayoutAttributeRight
                                            multiplier:1.0
                                              constant:self.spaceWidth]

            ]];
            [self setBottomPositionConstraint:bottomRefView button:rightInfo.view];
            rightRefButton = rightInfo.view;

            //left
            ActionButtonInfo *leftInfo = [infoArray objectAtIndex:nextButtonIndex++];
            [self setupButton:leftInfo];
            UIView *leftButton = leftInfo.view;

            [self setWidthAndHeightConstraint:leftButton];
            [self.view addConstraints:@[
                [NSLayoutConstraint constraintWithItem:leftRefButton
                                             attribute:NSLayoutAttributeLeft
                                             relatedBy:NSLayoutRelationEqual
                                                toItem:leftButton
                                             attribute:NSLayoutAttributeRight
                                            multiplier:1.0
                                              constant:self.spaceWidth]
            ]];
            [self setBottomPositionConstraint:bottomRefView button:leftButton];
            leftRefButton = leftButton;
        }

        bottomRefView = nextBottomRefView;
        firstBottom = NO;
    }

    //self.viewのtop制約
    if (bottomRefView) {
        if (self.aboveViews) {
            for (UIView *view in self.aboveViews) {
                [self.view addSubview:view];

                [self.view addConstraints:@[
                    [NSLayoutConstraint constraintWithItem:bottomRefView
                                                 attribute:NSLayoutAttributeTop
                                                 relatedBy:NSLayoutRelationEqual
                                                    toItem:view
                                                 attribute:NSLayoutAttributeBottom
                                                multiplier:1.0
                                                  constant:17]
                ]];
                [self.view addConstraints:@[
                    [NSLayoutConstraint constraintWithItem:view
                                                 attribute:NSLayoutAttributeCenterX
                                                 relatedBy:NSLayoutRelationEqual
                                                    toItem:self.view
                                                 attribute:NSLayoutAttributeCenterX
                                                multiplier:1.0
                                                  constant:0]
                ]];

                bottomRefView = view;
            }
        }
        [self.view addConstraints:@[
            [NSLayoutConstraint constraintWithItem:bottomRefView
                                         attribute:NSLayoutAttributeTop
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self.view
                                         attribute:NSLayoutAttributeTop
                                        multiplier:1.0
                                          constant:self.topMargin]
        ]];
    }
}

- (void)setupButton:(ActionButtonInfo *)info
{
    UIView *view = [[UIView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 60, 60);
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 64, 60, 26)];
    label.font = [UIFont systemFontOfSize:12];

    info.label = label;
    [info.label setText:info.title];
    [label setNumberOfLines:0];
    [label sizeToFit];

    label.frame = CGRectMake(0, 64, 60, label.frame.size.height);

    label.textAlignment = NSTextAlignmentCenter;

    [view addSubview:label];
    info.view = view;
    info.button = button;
    [view addSubview:button];
    [self.view addSubview:view];
}

- (void)setBottomPositionConstraint:(UIView *)bottomRefView button:(UIView *)centerButton
{
    BOOL firstBottom = bottomRefView == self.view;
    NSLayoutConstraint *constraint = nil;
    if (firstBottom) {
        constraint = [NSLayoutConstraint constraintWithItem:bottomRefView
                                                  attribute:NSLayoutAttributeBottom
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:centerButton
                                                  attribute:NSLayoutAttributeBottom
                                                 multiplier:1.0
                                                   constant:self.bottomMargin];
    } else {
        constraint = [NSLayoutConstraint constraintWithItem:bottomRefView
                                                  attribute:NSLayoutAttributeTop
                                                  relatedBy:NSLayoutRelationEqual
                                                     toItem:centerButton
                                                  attribute:NSLayoutAttributeBottom
                                                 multiplier:1.0
                                                   constant:self.spaceHeight];
    }

    [self.view addConstraints:@[
        constraint

    ]];
}

- (void)setWidthAndHeightConstraint:(UIView *)button
{
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:button
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0
                                                                         constant:self.buttonHeight];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:button
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1.0
                                                                        constant:self.buttonWidth];
    [button addConstraints:@[ heightConstraint, widthConstraint ]];
}

@end
