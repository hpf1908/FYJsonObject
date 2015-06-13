//
//  FYJsonObject.h
//  FYFramework
//
//  Created by pengfeihuang on 15-6-12.
//  Copyright (c) 2015年 pengfeihuang. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FYJsonObjectClassInfo <NSObject>

@optional

/*
 * 自定义映射json里的某个key对应当前类的某个属性
 */
- (NSString*)propertyNameMapJsonKey:(NSString*)jsonKey;

/*
 * 定义类中列表的类型信息
 */
- (Class)clsWithCollectionProperyName:(NSString*)propertyName;

@end

@interface FYJsonObject : NSObject

/**
 * 给定Class类型信息和一个json解析后的dictionary，返回对应Class的一个实例
 */
+ (id)objectWithClass:(Class)cls jsonDictionary:(NSDictionary*)jsonDict;

/**
 * 给定Class类型信息和一个json解析后的NSArray，返回对应Class的一个NSArray
 */
+ (NSArray*)objectArrayWithClass:(Class)cls jsonArray:(NSArray*)jsonArray;

/**
 * 给定一个NSobject对象，返回该对象对应的一个dictinary
 */
+ (NSDictionary*)jsonDictWithObject:(id)object;

/**
 * 给定一个NSobject对象数组，返回该对象对应的一个dictinary的数组
 */
+ (NSArray*)jsonDictArrayWithObjectArray:(NSArray*)objectArray;

/**
 * 遍历object进行coder
 * @prama : object 
    需要保证实现了encodeWithCoder
    如果属性是自定义类型的object，需要保证也实现了encodeWithCoder
 */
+ (void)encodeWithCoder:(NSCoder *)coder object:(id)object;

/**
 * 遍历object进行decoder
 */
+ (id)initWithCoder:(NSCoder *)coder object:(id)object;

@end
