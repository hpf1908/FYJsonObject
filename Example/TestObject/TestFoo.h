//
//  TestFoo.h
//  FYFramework
//
//  Created by pengfeihuang on 15-6-12.
//  Copyright (c) 2015年 pengfeihuang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FYJsonObject.h"

@interface TestBar : NSObject

@property(nonatomic) NSString* city;

@end

@interface TestFoo : NSObject<FYJsonObjectClassInfo>

@property(nonatomic,strong) NSString* name;
@property(nonatomic,assign) NSInteger age;
@property(nonatomic,strong) TestBar*  bar;
@property(nonatomic,strong) NSArray*  items;
@property(nonatomic,strong) NSArray*  basicItems;
@property(nonatomic,strong) NSDictionary*  itemsDict;
@property(nonatomic,strong) NSDictionary*  basicItemsDict;
@property(nonatomic,strong) NSString* nickName;

@end
