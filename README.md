# FYJsonObject

将json字符串解析出来的dictionary自动解析为对应的NSObject对象，可用于通用json字符串到NSObject的解析

1. 支持类型嵌套
1. 支持NSArray,NSDictionary
1. 方便的api实现encoder和decoder

## API

```objc

@protocol FYJsonObjectClassInfo <NSObject>

@optional

/*
 * 用于自定义映射json里的某个key对应当前类的某个属性
 */
- (NSString*)propertyNameMapJsonKey:(NSString*)jsonKey;

/*
 * object-c的collection比如说NSArray和NSDictionary没有类型信息，
   可通过实现这个函数指明类型信息
 */
- (Class)clsWithCollectionProperyName:(NSString*)propertyName;

@end

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
 * 遍历object进行encoder，这样就不用手写encode了，哈哈
 * @prama : object 
    需要保证实现了encodeWithCoder
    如果属性是自定义类型的object，需要保证也实现了encodeWithCoder
 */
+ (void)encodeWithCoder:(NSCoder *)coder object:(id)object;

/**
 * 遍历object进行decoder，上一步的逆操作
 */
+ (id)initWithCoder:(NSCoder *)coder object:(id)object;

```

## 使用示例

### foo,bar定义及实现

```objc

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

@implementation TestBar

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

@implementation TestFoo

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

```

### 将对应foo的dictionary解析为TestFoo

```objc

NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
NSString* name = @"mike";
int age = 123;
[dict setObject:name forKey:@"name"];
[dict setObject:nick forKey:@"nick"];
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

//TestFoo 实现了propertyNameMapJsonKey函数，自定义了nick到nickName的映射
assert([foo.nickName isEqualToString:nick]);

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


```

### 将一个NSObject对象转为对应的dictionary

```objc

TestFoo* foo = [TestFoo new];
NSString* name = @"hpf1908";
foo.name = name;
foo.age  = 15;

NSMutableArray* items = [NSMutableArray new];
NSMutableDictionary* itemsDict = [NSMutableDictionary new];
NSInteger itemsCount = 5;

for (NSInteger i = 0; i < itemsCount; i++) {
    TestBar* bar = [TestBar new];
    bar.city = [NSString stringWithFormat:@"%@_%ld",@"haha",i];
    [items addObject:bar];
    [itemsDict setObject:bar forKey:[NSString stringWithFormat:@"%ld",i]];
}
foo.items = items;
foo.itemsDict = itemsDict;

TestBar* bar = [TestBar new];
bar.city = @"haha";

foo.bar = bar;

//将foo转为对应的dictionary，支持嵌套类型
NSDictionary* dict = [FYJsonObject jsonDictWithObject:foo];

assert(dict != nil);
assert([[dict objectForKey:@"name"] isEqualToString:name]);
assert([[dict objectForKey:@"age"] integerValue] == foo.age);
assert([dict objectForKey:@"bar"]);
assert([[[dict objectForKey:@"bar"] objectForKey:@"city"] isEqualToString:bar.city]);
assert([[dict objectForKey:@"items"] count] == itemsCount);
assert([[dict objectForKey:@"itemsDict"] count] == itemsCount);


```