//
//  FYJsonObject.m
//  FYFramework
//
//  Created by pengfeihuang on 15-6-12.
//  Copyright (c) 2015年 pengfeihuang. All rights reserved.
//

#import "FYJsonObject.h"
#import <objc/runtime.h>

@interface FYJsonPropertyInfo : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *attributesStr;
@property (nonatomic, assign) BOOL readOnly;

@end

@implementation FYJsonPropertyInfo

@end

@implementation FYJsonObject

/*
 * 获取类型信息
 * 参考：https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
 */
+ (FYJsonPropertyInfo*)createPropertyInfo:(objc_property_t)prop
{
    FYJsonPropertyInfo* propertyInfo = [FYJsonPropertyInfo new];
    propertyInfo.name = [NSString stringWithUTF8String:property_getName(prop)];
    
    NSString *attributeStr = [NSString stringWithUTF8String:property_getAttributes(prop)];
    NSArray* attrArray = [attributeStr componentsSeparatedByString:@","];
    
    if (attrArray.count) {
        NSString* typeStr = [attrArray objectAtIndex:0];
        if (typeStr && typeStr.length > 0) {
            if ([typeStr characterAtIndex:0] == 'T') {
                propertyInfo.type = [typeStr substringFromIndex:1];
            }
        }
    }
    
    for (NSInteger i = 1; i < attrArray.count; i++) {
        NSString* attrStr = [attrArray objectAtIndex:0];
        
        //暂时只需要关心是否只读
        if ([attrStr isEqualToString:@"R"]) {
            propertyInfo.readOnly = YES;
            break;
        }
    }
    
    propertyInfo.attributesStr = attributeStr;
    return propertyInfo;
}

+ (NSDictionary*)filterDefaultProperty
{
    return [self propertyDictWithClass:[NSObject class] filterDictionary:nil];
}

+ (NSDictionary *)propertyDictWithClass:(Class)class filterDictionary:(NSDictionary*)filterDicts
{
    static NSMutableDictionary *_propsDescriptionDicts;
    
    @synchronized(self) {
        if (_propsDescriptionDicts == nil) {
            _propsDescriptionDicts = [[NSMutableDictionary alloc] initWithCapacity:5];
        }
        
        NSMutableDictionary *propsDescription = nil;
        NSString* className = NSStringFromClass(class);
        
        if ((propsDescription = [_propsDescriptionDicts objectForKey:className]) == nil) {
            
            unsigned count;
            objc_property_t *properties = class_copyPropertyList(class, &count);
            
            propsDescription = [[NSMutableDictionary alloc] initWithCapacity:count];
            [_propsDescriptionDicts setObject:propsDescription forKey:className];
            
            unsigned i;
            
            for (i = 0; i < count; i++)
            {
                objc_property_t property = properties[i];
                NSString* properName = [NSString stringWithUTF8String:property_getName(property)];
                FYJsonPropertyInfo* propertyInfo = [self createPropertyInfo:property];
                
                if ([filterDicts objectForKey:properName] == nil) {
                    [propsDescription setObject:propertyInfo forKey:propertyInfo.name];
                }
            }
            
            free(properties);
        }
        
        return propsDescription;
    }
}

#pragma mark - dictionary to object
/*
 * 动态设值
 * 参考：https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
 */
+ (id)objectWithClass:(Class)cls jsonDictionary:(NSDictionary*)jsonDict
{
    NSDictionary* propDicts = [self propertyDictWithClass:cls filterDictionary:[self filterDefaultProperty]];
    id newObject = [cls new];
    
    for (NSString* jsonKey in jsonDict) {
        id jsonValue = [jsonDict objectForKey:jsonKey];
        
        NSString* propertyName = nil;
        
        if ([newObject respondsToSelector:@selector(propertyNameMapJsonKey:)]) {
            propertyName = [newObject propertyNameMapJsonKey:jsonKey];
        }
        
        if (propertyName == nil) {
            propertyName = jsonKey;
        }
        
        FYJsonPropertyInfo* propertyInfo = [propDicts objectForKey:propertyName];
        
        if (propertyInfo == nil || jsonValue == nil) {
            continue;
        }
        
        //如果是只读的话就忽略掉
        if (propertyInfo.readOnly) {
            continue;
        }
        
        switch ([propertyInfo.type characterAtIndex:0])
        {
            case 'c':   // A char
            case 'i':   // An int
            case 's':   // A short
            case 'l':   // A long
            case 'q':   // long long
            case 'C':   // An unsigned char
            case 'I':   // An unsigned int
            case 'S':   // An unsigned short
            case 'L':   // An unsigned long
            case 'Q':   // An unsigned long long
            case 'f':   // A float
            case 'd':   // A double
            case 'B':   // A C++ bool or a C99 _Bool
            {
                if ([jsonValue isKindOfClass:[NSNumber class]]) {
                    [newObject setValue:jsonValue forKey:propertyInfo.name];
                }
                break;
            }
            case '@':
            {
                id newValue = [self objectWithJsonValue:jsonValue propertyInfo:propertyInfo parentCls:cls];
                if (newValue) {
                    [newObject setValue:newValue forKey:propertyInfo.name];
                }
                break;
            }
            default:
                break;
        }
    }
    
    return newObject;
}

/*
 * 注意array和dictinary的解析因为没有类型信息，不是类型安全的
 */
+ (id)objectWithJsonValue:(id)jsonValue propertyInfo:(FYJsonPropertyInfo*)propertyInfo parentCls:(Class)parentCls
{
    NSString* clsName = nil;
    Class cls = nil;
    
    if (propertyInfo.type.length > 3) {
        clsName = [propertyInfo.type substringWithRange:NSMakeRange(2, [propertyInfo.type length] - 3)];
    }
    
    if (clsName != nil) {
        cls = NSClassFromString(clsName);
    }
    
    if (cls == nil) {
        return nil;
    }
    
    id clsObject = [parentCls new];
    
    if ([jsonValue isKindOfClass:[NSString class]] && cls == [NSString class]) {
        
        //如果是基本类型，直接返回即可
        return jsonValue;
        
    } else if ([jsonValue isKindOfClass:[NSArray class]] && cls == [NSArray class]) {
        
        //如果是数组，那么尝试获取类型信息
        NSArray* jsonArr = (NSArray*)jsonValue;
        NSMutableArray* newArr = [[NSMutableArray alloc] initWithCapacity:jsonArr.count];
        Class subClass = nil;
        
        if ([clsObject respondsToSelector:@selector(clsWithCollectionProperyName:)]) {
            subClass = [clsObject clsWithCollectionProperyName:propertyInfo.name];
        }
        
        //没有类型信息就不初始化了
        if (subClass == nil) {
            return nil;
        }
        
        for (id jsonObj in jsonArr) {
            if ([jsonObj isKindOfClass:[NSDictionary class]]) {
                [newArr addObject:[self objectWithClass:subClass jsonDictionary:jsonObj]];
            } else if(![jsonObj isKindOfClass:[NSArray class]]) {
                [newArr addObject:jsonObj];
            }
        }
        return newArr;
        
    } else if ([jsonValue isKindOfClass:[NSDictionary class]] && cls == [NSDictionary class]) {
        
        //如果是字典，那么尝试获取类型信息
        NSDictionary* jsonDict = (NSDictionary*)jsonValue;
        NSMutableDictionary* newDict = [[NSMutableDictionary alloc] initWithCapacity:jsonDict.count];
        Class subClass = nil;
        
        if ([clsObject respondsToSelector:@selector(clsWithCollectionProperyName:)]) {
            subClass = [clsObject clsWithCollectionProperyName:propertyInfo.name];
        }
        
        //没有类型信息就不初始化了
        if (subClass == nil) {
            return nil;
        }
        
        for (id jsonkey in jsonDict) {
            id value = [jsonDict objectForKey:jsonkey];
            if ([value isKindOfClass:[NSDictionary class]]) {
                [newDict setObject:[self objectWithClass:subClass jsonDictionary:value] forKey:jsonkey];
            } else if(![value isKindOfClass:[NSArray class]]) {
                [newDict setObject:value forKey:jsonkey];
            }
        }
        return newDict;
        
    } else if ([jsonValue isKindOfClass:[NSDictionary class]]){
        
        //如果本身是字典，那么已经包含类型信息，可以直接解析了
        id newValue = [self objectWithClass:cls jsonDictionary:jsonValue];
        return newValue;
    }
    
    return nil;
}

+ (NSArray*)objectArrayWithClass:(Class)cls jsonArray:(NSArray*)jsonArray
{
    NSMutableArray* result = [[NSMutableArray alloc] initWithCapacity:jsonArray.count];
    
    for (NSDictionary* item in jsonArray) {
        if ([item isKindOfClass:[NSDictionary class]]) {
            id newItem = [self objectWithClass:cls jsonDictionary:item];
            [result addObject:newItem];
        }
    }
    return result;
}

#pragma mark - object to dictionary

+ (BOOL)notAllowAdapterToDict:(id)obj
{
    if ([obj isKindOfClass:[NSNumber class]] ||
        [obj isKindOfClass:[NSString class]] ||
        [obj isKindOfClass:[NSDictionary class]] ||
        [obj isKindOfClass:[NSArray class]] ||
        [obj isKindOfClass:[NSData class]] ) {
        return YES;
    } else {
        return NO;
    }
}

+ (NSDictionary*)jsonDictWithObject:(id)object
{
    if (object == nil) {
        return nil;
    }
    
    if ([self notAllowAdapterToDict:object]) {
        return nil;
    }
    
    NSMutableDictionary* resultDict = [NSMutableDictionary new];
    
    NSDictionary* propertyDicts = [self propertyDictWithClass:[object class] filterDictionary:[self filterDefaultProperty]];
    
    for (NSString* properName in propertyDicts) {
        
        FYJsonPropertyInfo* propertyInfo = [propertyDicts objectForKey:properName];
        
        switch ([propertyInfo.type characterAtIndex:0])
        {
            case 'c':   // A char
            case 'i':   // An int
            case 's':   // A short
            case 'l':   // A long
            case 'q':   // long long
            case 'C':   // An unsigned char
            case 'I':   // An unsigned int
            case 'S':   // An unsigned short
            case 'L':   // An unsigned long
            case 'Q':   // An unsigned long long
            case 'f':   // A float
            case 'd':   // A double
            case 'B':   // A C++ bool or a C99 _Bool
            {
                id objValue = [object valueForKey:properName];
                if (objValue != nil) {
                    [resultDict setObject:objValue forKey:properName];
                }
                break;
            }
            case '@':
            {
                id objValue = [object valueForKey:properName];
                
                if (objValue) {
                    
                    if ([objValue isKindOfClass:[NSString class]] || [objValue isKindOfClass:[NSNumber class]]) {
                        
                        [resultDict setObject:objValue forKey:properName];
                        
                    } else if([objValue isKindOfClass:[NSArray class]]){
                        
                        NSArray* objArray = (NSArray*)objValue;
                        NSMutableArray* newArr = [NSMutableArray new];
                        
                        for (id obj in objArray) {
                            NSDictionary* objDict = [self jsonDictWithObject:obj];
                            if (objDict != nil) {
                                [newArr addObject:objDict];
                            }
                        }
                        
                        [resultDict setObject:newArr forKey:properName];
                        
                    } else if([objValue isKindOfClass:[NSDictionary class]]){
                        
                        NSDictionary* objDict = (NSDictionary*)objValue;
                        NSMutableDictionary* newDict = [NSMutableDictionary new];
                        
                        for (NSString* key in objDict) {
                            NSDictionary* newObjDict = [self jsonDictWithObject:[objDict objectForKey:key]];
                            if (newObjDict != nil) {
                                [newDict setObject:newObjDict forKey:key];
                            }
                        }
                        
                        [resultDict setObject:newDict forKey:properName];
                        
                    } else {
                        NSDictionary* objDict = [self jsonDictWithObject:objValue];
                        if (objDict != nil) {
                            [resultDict setObject:objDict forKey:properName];
                        }
                    }
                }
                break;
            }
            default:
                break;
        }
    }
    
    return resultDict;
}

+ (NSArray*)jsonDictArrayWithObjectArray:(NSArray*)objectArray
{
    NSMutableArray* result = [[NSMutableArray alloc] initWithCapacity:objectArray.count];
    
    for (id item in objectArray) {
        NSDictionary* dict = [self jsonDictWithObject:item];
        if (dict) {
            [result addObject:dict];
        }
    }
    return result;
}

#pragma mark - encoder & decoder

+ (void)encodeWithCoder:(NSCoder *)coder object:(id)object
{
    NSDictionary* propertyDicts = [self propertyDictWithClass:[object class] filterDictionary:[self filterDefaultProperty]];
    
    for (NSString* properName in propertyDicts) {
        id value = [object valueForKey:properName];
        if (value) {
            [coder encodeObject:value forKey:properName];
        }
    }
}

+ (id)initWithCoder:(NSCoder *)coder object:(id)object
{
    if (object) {
        NSDictionary* propertyDicts = [self propertyDictWithClass:[object class] filterDictionary:[self filterDefaultProperty]];
        for (NSString* properName in propertyDicts) {
            id value = [coder decodeObjectForKey:properName];
            if (value) {
                [object setValue:value forKey:properName];
            }
        }
    }
    return object;
}

#pragma mark - for ovverrider object convinient

- (void)encodeWithCoder:(NSCoder *)coder
{
    [FYJsonObject encodeWithCoder:coder object:self];
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init]) {
        [FYJsonObject initWithCoder:coder object:self];
    }
    return self;
}

@end
