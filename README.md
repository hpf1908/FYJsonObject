# FYJsonObject

将json字符串解析出来的dictionary自动解析为对应的NSObject对象，可用于通用json字符串到NSObject的解析

```objc

NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
NSString* name = @"mike";
NSString* nick = @"hello";
int age = 123;
[dict setObject:name forKey:@"name"];
[dict setObject:nick forKey:@"nick"];
[dict setObject:[NSNumber numberWithInt:age] forKey:@"age"];

//自动对dictionary的同名属性进行设值
TestFoo* foo = (TestFoo*)[FYJsonObject objectWithClass:[TestFoo class] jsonDictionary:dict];
assert([foo.name isEqualToString:name]);
assert(foo.age == age);
assert([foo.nickName isEqualToString:nick]);

```

将一个NSObject对象转为对应的dictionary

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