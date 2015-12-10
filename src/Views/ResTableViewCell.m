//
//  ResTableViewCell.m
//  Forest
//

#import "ResTableViewCell.h"

@implementation ResTableViewCell

- (void)prepareForReuse
{
    [self.resView prepareForReuse];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.resView = [[ResView alloc] init];
        [self.contentView addSubview:self.resView];
        self.containerView = self.contentView;
    }
    return self;
}

- (void)awakeFromNib
{
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
}

@end
