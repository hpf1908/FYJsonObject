//
//  TestUnit.m
//  FYFramework
//
//  Created by pengfeihuang on 15-6-12.
//  Copyright (c) 2015年 pengfeihuang. All rights reserved.
//

#import "TestUnit.h"
#import "TestFoo.h"
#import "FYJsonObject.h"

@implementation TestUnit

+ (TestUnit *)sharedInstance
{
    static dispatch_once_t once;
    static TestUnit * __singleton__;
    dispatch_once( &once, ^{ __singleton__ = [[TestUnit alloc] init]; } );
    return __singleton__;
}

- (void)testAll
{
    [self testDict2Plainbject];
    [self testDict2DeepObject];
    [self testDict2ObjectWithArray];
    [self testDict2ObjectWithDict];
}

- (void)testDict2Plainbject
{
    NSLog(@"testDict2Plainbject begin ....");
    
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    NSString* name = @"mike";
    NSString* nick = @"hello";
    int age = 123;
    [dict setObject:name forKey:@"name"];
    [dict setObject:nick forKey:@"nick"];
    [dict setObject:[NSNumber numberWithInt:age] forKey:@"age"];
    
    TestFoo* foo = (TestFoo*)[FYJsonObject objectWithClass:[TestFoo class] jsonDictionary:dict];
    assert([foo.name isEqualToString:name]);
    assert(foo.age == age);
    assert([foo.nickName isEqualToString:nick]);
    
    NSLog(@"testDict2Plainbject success ....");
}

- (void)testDict2DeepObject
{
    NSLog(@"testDict2DeepObject begin ....");
    
    NSMutableDictionary* fooDict = [[NSMutableDictionary alloc] init];
    NSString* name = @"mike";
    int age = 123;
    [fooDict setObject:name forKey:@"name"];
    [fooDict setObject:[NSNumber numberWithInt:age] forKey:@"age"];
    
    NSString* city = @"guangzhou";
    NSMutableDictionary* barDict = [[NSMutableDictionary alloc] init];
    [barDict setObject:city forKey:@"city"];
    
    [fooDict setObject:barDict forKey:@"bar"];
    
    TestFoo* foo = (TestFoo*)[FYJsonObject objectWithClass:[TestFoo class] jsonDictionary:fooDict];
    assert([foo.name isEqualToString:name]);
    assert(foo.age == age);
    assert(foo.bar != nil);
    assert([foo.bar.city isEqualToString:city]);
    
    NSLog(@"testDict2DeepObject success ....");
}

- (void)testDict2ObjectWithArray
{
    NSLog(@"testDict2ObjectWithArray begin ....");
    
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    NSString* name = @"mike";
    int age = 123;
    [dict setObject:name forKey:@"name"];
    [dict setObject:[NSNumber numberWithInt:age] forKey:@"age"];
    
    NSMutableArray* items = [NSMutableArray new];
    NSMutableArray* basicItems = [NSMutableArray new];
    NSInteger itemsCount = 4;
    
    NSString* city = @"guangzhou";
    
    for (NSInteger i = 0; i < itemsCount; i++) {
        NSMutableDictionary* barDict = [[NSMutableDictionary alloc] init];
        [barDict setObject:[NSString stringWithFormat:@"%@_%ld",city,(long)i] forKey:@"city"];
        [basicItems addObject:[NSString stringWithFormat:@"%@_%ld",city,(long)i]];
        [items addObject:barDict];
    }
    
    [dict setObject:items forKey:@"items"];
    [dict setObject:basicItems forKey:@"basicItems"];
    
    TestFoo* foo = (TestFoo*)[FYJsonObject objectWithClass:[TestFoo class] jsonDictionary:dict];
    assert([foo.name isEqualToString:name]);
    assert(foo.age == age);
    assert(foo.items != nil);
    assert(foo.items.count == itemsCount);
    
    for (NSInteger i = 0; i < itemsCount; i++) {
        TestBar* bar = [foo.items objectAtIndex:i];
        assert([bar class] == [TestBar class]);
        NSString* cityName = [NSString stringWithFormat:@"%@_%ld",city,i];
        assert([bar.city isEqualToString:cityName]);
    }
    
    assert(foo.basicItems != nil);
    assert(foo.basicItems.count == itemsCount);
    
    for (NSInteger i = 0; i < itemsCount; i++) {
        NSString* basicCityName = [foo.basicItems objectAtIndex:i];
        NSString* cityName = [NSString stringWithFormat:@"%@_%ld",city,i];
        assert([basicCityName isEqualToString:cityName]);
    }
    
    NSLog(@"testDict2ObjectWithArray success ....");
}

- (void)testDict2ObjectWithDict
{
    NSLog(@"testDict2ObjectWithDict begin ....");
    
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    NSString* name = @"mike";
    int age = 123;
    [dict setObject:name forKey:@"name"];
    [dict setObject:[NSNumber numberWithInt:age] forKey:@"age"];
    
    NSMutableDictionary* itemsDict = [NSMutableDictionary new];
    NSMutableDictionary* basicDicts = [NSMutableDictionary new];
    NSInteger itemsCount = 4;
    
    NSString* city = @"guangzhou";
    NSString* key  = @"item";
    
    for (NSInteger i = 0; i < itemsCount; i++) {
        NSMutableDictionary* barDict = [[NSMutableDictionary alloc] init];
        [barDict setObject:[NSString stringWithFormat:@"%@_%ld",city,(long)i] forKey:@"city"];
        [itemsDict setObject:barDict forKey:[NSString stringWithFormat:@"%@_%ld",key,i]];
        [basicDicts setObject:[NSNumber numberWithInteger:i] forKey:[NSString stringWithFormat:@"%@_%ld",key,i]];
    }
    
    [dict setObject:itemsDict forKey:@"itemsDict"];
    [dict setObject:basicDicts forKey:@"basicItemsDict"];
    
    TestFoo* foo = (TestFoo*)[FYJsonObject objectWithClass:[TestFoo class] jsonDictionary:dict];
    assert([foo.name isEqualToString:name]);
    assert(foo.age == age);
    assert(foo.itemsDict != nil);
    assert(foo.itemsDict.count == itemsCount);
    
    for (NSInteger i = 0; i < itemsCount; i++) {
        TestBar* bar = [foo.itemsDict objectForKey:[NSString stringWithFormat:@"%@_%ld",key,i]];
        assert(bar != nil);
        assert([bar class] == [TestBar class]);
        NSString* cityName = [NSString stringWithFormat:@"%@_%ld",city,i];
        assert([bar.city isEqualToString:cityName]);
    }
    
    assert(foo.basicItemsDict != nil);
    assert(foo.basicItemsDict.count == itemsCount);
    
    for (NSInteger i = 0; i < itemsCount; i++) {
        NSNumber* number = [foo.basicItemsDict objectForKey:[NSString stringWithFormat:@"%@_%ld",key,i]];
        assert(number != nil);
        assert([number integerValue] == i);
    }
    
    NSLog(@"testDict2ObjectWithDict success ....");
}

@end
