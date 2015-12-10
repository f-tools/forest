//
//  ThTableViewCell.m
//  Forest
//

#import "ThTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation ThTableViewCell

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

// 一番上のセクション分の高さだけ透明する
- (void)maskCellFromTop:(CGFloat)margin
{
    self.layer.mask = [self visibilityMaskFromLocation:margin];

    self.layer.masksToBounds = YES;
}

- (CAGradientLayer *)visibilityMaskFromLocation:(CGFloat)location
{
    CAGradientLayer *mask = [CAGradientLayer layer];
    mask.frame = CGRectMake(
        self.bounds.origin.x,
        location + self.bounds.origin.y,
        self.bounds.size.width,
        self.bounds.size.height - location);
    mask.colors = @[
        (id)[[UIColor colorWithWhite:1 alpha:1] CGColor],
        (id)[[UIColor colorWithWhite:1 alpha:1] CGColor]
    ];
    return mask;
}

@end
