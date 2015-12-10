//
//  ActionLayout.h
//  Forest
//

#import <Foundation/Foundation.h>

@interface ActionButtonInfo : NSObject 

@property (nonatomic) BOOL isCheckedButton;
@property (nonatomic) BOOL isChecked;
@property (nonatomic) NSObject *tag;
@property (weak, nonatomic) UIButton *button;
@property (weak, nonatomic) UILabel *label;
@property (weak, nonatomic) UIView *view;
@property (nonatomic, copy) NSString *buttonImageName;
@property (nonatomic, copy) NSString *title;

- (id)initWithTitle:(NSString *)title withImageName:(NSString *)name;

@end

@interface ActionLayout : NSObject 

@property (nonatomic) UIView *view;
@property (nonatomic) NSUInteger buttonWidth;
@property (nonatomic) NSUInteger buttonHeight;
@property (nonatomic) NSUInteger buttonBorderWidth;
@property (nonatomic) NSUInteger buttonCornerRadius;

@property (nonatomic) NSUInteger leftMargin;
@property (nonatomic) NSUInteger rightMargin;
@property (nonatomic) NSUInteger topMargin;
@property (nonatomic) NSUInteger bottomMargin;

@property (nonatomic) NSUInteger spaceHeight;
@property (nonatomic) NSUInteger spaceWidth;
@property (nonatomic) NSArray *aboveViews;

@property (nonatomic) BOOL verticalMode;

- (void)layout:(NSArray *)infoArray withWidth:(NSUInteger)containerWidth;
- (void)verticalLayout:(NSArray *)infoArray withWidth:(NSUInteger)containerWidth;
@end
