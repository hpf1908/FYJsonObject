//
//  TestUnit.h
//  FYFramework
//
//  Created by pengfeihuang on 15-6-12.
//  Copyright (c) 2015年 pengfeihuang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TestUnit : NSObject

+ (TestUnit *)sharedInstance;

- (void)testAll;

@end
