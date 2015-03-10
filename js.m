//
//  js.m
//  CopyHook
//
//  Created by Satoh on 2015/03/10.
//  Copyright (c) 2015年 Satoh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "js.h"

@implementation JSContext (Closure)

- (void)setFunction: (aFunction) func forKeyedSubscript: (NSString*) key
{
    [self setObject: func forKeyedSubscript: key];
}

@end
