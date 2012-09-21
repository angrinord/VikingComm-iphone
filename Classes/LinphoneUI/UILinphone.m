/* UILinphone.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "UILinphone.h"
#import "ColorSpaceUtilities.h"
#import "Utils.h"

#import <UIKit/UIView.h>

@implementation UIColor (LightAndDark)

- (UIColor *)lumColor:(float)mult {
    float hsbH, hsbS, hsbB;
    float rgbaR, rgbaG, rgbaB, rgbaA;
    
    // Get RGB
    CGColorRef cgColor = [self CGColor];
    CGColorSpaceRef cgColorSpace = CGColorGetColorSpace(cgColor);
    if(CGColorSpaceGetModel(cgColorSpace) != kCGColorSpaceModelRGB) {
        [LinphoneLogger log:LinphoneLoggerWarning format:@"Can't convert not RGB color"];
        return self;
    } else {
        const float *colors = CGColorGetComponents(cgColor);
        rgbaR = colors[0];
        rgbaG = colors[1];
        rgbaB = colors[2];
        rgbaA = CGColorGetAlpha(cgColor);
    }
    
    RGB2HSL(rgbaR, rgbaG, rgbaB, &hsbH, &hsbS, &hsbB);
    
    hsbB = MIN(MAX(hsbB * mult, 0.0), 1.0);
    
    HSL2RGB(hsbH, hsbS, hsbB, &rgbaR, &rgbaG, &rgbaB);
    
    return [UIColor colorWithRed:rgbaR green:rgbaG blue:rgbaB alpha:rgbaA];
}

- (UIColor *)adjustHue:(float)hm saturation:(float)sm brightness:(float)bm alpha:(float)am {
    float hsbH, hsbS, hsbB;
    float rgbaR, rgbaG, rgbaB, rgbaA;
    
    
    // Get RGB
    CGColorRef cgColor = [self CGColor];
    CGColorSpaceRef cgColorSpace = CGColorGetColorSpace(cgColor);
    if(CGColorSpaceGetModel(cgColorSpace) != kCGColorSpaceModelRGB) {
        [LinphoneLogger log:LinphoneLoggerWarning format:@"Can't convert not RGB color"];
        return self;
    } else {
        const float *colors = CGColorGetComponents(cgColor);
        rgbaR = colors[0];
        rgbaG = colors[1];
        rgbaB = colors[2];
        rgbaA = CGColorGetAlpha(cgColor);
    }
    
    RGB2HSL(rgbaR, rgbaG, rgbaB, &hsbH, &hsbS, &hsbB);
    
    hsbH = MIN(MAX(hsbH + hm, 0.0), 1.0);
    hsbS = MIN(MAX(hsbS + sm, 0.0), 1.0);
    hsbB = MIN(MAX(hsbB + bm, 0.0), 1.0);
    rgbaA = MIN(MAX(rgbaA + am, 0.0), 1.0);
    
    HSL2RGB(hsbH, hsbS, hsbB, &rgbaR, &rgbaG, &rgbaB);
    
    return [UIColor colorWithRed:rgbaR green:rgbaG blue:rgbaB alpha:rgbaA];
}

- (UIColor *)lighterColor {
    return [self lumColor:1.3];
}

- (UIColor *)darkerColor {
    return [self lumColor:0.75];
}

@end
