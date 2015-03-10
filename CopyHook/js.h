//
//  js.h
//  CopyHook
//
//  Created by Satoh on 2015/03/10.
//  Copyright (c) 2015年 Satoh. All rights reserved.
//

#ifndef CopyHook_js_h
#define CopyHook_js_h

#import <JavaScriptCore/JavaScriptCore.h>

@interface JSContext (Closure)

typedef id (^aFunction)(id);

- (void) setFunction: (aFunction) func forKeyedSubscript: (NSString*) key;

@end


#endif
