//
//  GMGridViewCustom.m
//  GMGridView
//
//  Created by Chathurka on 10/4/13.
//
//
//  Latest code can be found on GitHub: https://github.com/gmoledina/GMGridView
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "GMGridViewCustom.h"
#import "GMGridView.h"
#import "GMGridViewLayoutStrategies.h"
#import "GMGridViewCell+Extended.h"

static const NSInteger kTagOffset = 50;
static const CGFloat kDefaultAnimationDuration = 0.3;

@implementation GMGridViewCustom

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL valid = [super gestureRecognizerShouldBegin:gestureRecognizer];
    BOOL isScrolling = self.isDragging || self.isDecelerating;
    
    if (gestureRecognizer == self.longPressGesture)
    {
        valid = (self.sortingDelegate || self.enableEditOnLongPress) && !isScrolling ;//removed editing
    }
    
    return valid;
}

- (void)longPressGestureUpdated:(UILongPressGestureRecognizer *)longPressGesture
{
    if (longPressGesture.state == UIGestureRecognizerStateBegan)
    {
        if (!self.sortMovingItem)
        {
            CGPoint location = [longPressGesture locationInView:self];
            NSInteger position = [self.layoutStrategy itemPositionFromLocation:location];
            
            if (position != GMGV_INVALID_POSITION)
            {
                [self sortingMoveDidStartAtPoint:location];
                
                if (!self.editing)
                { 
                    self.editing = YES; // added editing yes.
                }
            }
        }
    }
    
    [super longPressGestureUpdated:longPressGesture];
}

- (void)sortingMoveDidStartAtPoint:(CGPoint)point
{
    self.editing = NO;// changed
    [super sortingMoveDidStartAtPoint:point];
}

- (void)sortingMoveDidStopAtPoint:(CGPoint)point
{
    self.editing = YES;//changed
    [self.sortMovingItem shake:NO];
    
    self.sortMovingItem.tag = self.sortFuturePosition + kTagOffset;
    CGRect frameInScroll = [self.mainSuperView convertRect:self.sortMovingItem.frame toView:self];
    
    [self.sortMovingItem removeFromSuperview];
    self.sortMovingItem.frame = frameInScroll;
    [self addSubview:self.sortMovingItem];
    
    CGPoint newOrigin = [self.layoutStrategy originForItemAtPosition:self.sortFuturePosition];
    CGRect newFrame = CGRectMake(newOrigin.x, newOrigin.y, self.itemSize.width, self.itemSize.height);
    
    [UIView animateWithDuration:kDefaultAnimationDuration
                          delay:0
                        options:0
                     animations:^{
                         self.sortMovingItem.transform = CGAffineTransformIdentity;
                         self.sortMovingItem.frame = newFrame;
                     }
                     completion:^(BOOL finished){
                         if ([self.sortingDelegate respondsToSelector:@selector(GMGridView:didEndMovingCell:)])
                         {
                             [self.sortingDelegate GMGridView:self didEndMovingCell:self.sortMovingItem];
                         }
                         
						 if (self.editing)
                         {
							 self.sortMovingItem.editing = YES;//changed
                         }
                         
                         self.sortMovingItem = nil;
                         self.sortFuturePosition = GMGV_INVALID_POSITION;
                         
                         [self setSubviewsCacheAsInvalid];
                     }
     ];
}

- (void)sortingMoveDidContinueToPoint:(CGPoint)point
{
    self.editing = NO;//changed
    [super sortingMoveDidContinueToPoint:point];
}

@end
