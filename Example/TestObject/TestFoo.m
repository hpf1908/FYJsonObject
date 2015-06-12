//
//  TestFoo.m
//  FYFramework
//
//  Created by pengfeihuang on 15-6-12.
//  Copyright (c) 2015年 pengfeihuang. All rights reserved.
//

#import "TestFoo.h"

@implementation TestBar

@end

@implementation TestFoo

- (Class)clsWithCollectionProperyName:(NSString*)propertyName
{
    if ([propertyName isEqualToString:@"items"]) {
        return [TestBar class];
    } else if ([propertyName isEqualToString:@"itemsDict"]) {
        return [TestBar class];
    } else if ([propertyName isEqualToString:@"basicItems"]) {
        return [NSString class];
    } else if ([propertyName isEqualToString:@"basicItemsDict"]) {
        return [NSNumber class];
    } else {
        return nil;
    }
}

- (NSString*)propertyNameMapJsonKey:(NSString*)jsonKey
{
    if ([jsonKey isEqualToString:@"nick"]) {
        return @"nickName";
    } else {
        return nil;
    }
}

@end
