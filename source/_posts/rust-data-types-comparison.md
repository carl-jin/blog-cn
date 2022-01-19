---
title: Rust 中的数据类型汇总
date: 2022-01-19 23:42:26
tags:
  - Rust
categories:
  - Rust
description: Rust 中各种数据类型汇总与对比，主要用于记录每个类型之间的区别。
---

> 此文假设你已经了解基础知识，因此只讨论数据类型.

# 整数

整数存放在`栈`中，因此在声明字面量时，需要指定整数的类型（Rust 默认为 i32 类型）以确定栈堆中所占用的空间

## 类型

类型有以下

| 长度       | 有符号类型 | 无符号类型 |
| ---------- | ---------- | ---------- |
| 8 位       | i8         | u8         |
| 16 位      | i16        | u16        |
| 32 位      | i32        | u32        |
| 64 位      | i64        | u64        |
| 128 位     | i128       | u128       |
| 视架构而定 | isize      | usize      |

> isize 和 usize 类型取决于程序运行的计算机 cpu 类型： 若 cpu 是 32 位的，则这两个类型是 32 位的，同理，若 cpu 是 64 位，那么它们则是 64 位.

## 无符号整数最小值与最大值

让我们看看 无符号整数 和 有符号整数 的最小值和最大值。

| 类型 | 最小值 | 最大值                                  | 长度    |
| ---- | ------ | --------------------------------------- | ------- |
| u8   | 0      | 255                                     | 8-bit   |
| u16  | 0      | 65535                                   | 16-bit  |
| u32  | 0      | 4294967295                              | 32-bit  |
| u64  | 0      | 18446744073709551615                    | 64-bit  |
| u128 | 0      | 340282366920938463463374607431768211455 | 128-bit |

## 有符号整数最小值与最大值

| 类型 | 最小值                                   | 最大值                                  | 长度    |
| ---- | ---------------------------------------- | --------------------------------------- | ------- |
| i8   | -128                                     | 127                                     | 8-bit   |
| i16  | -32768                                   | 32767                                   | 16-bit  |
| i32  | -2147483648                              | 2147483647                              | 32-bit  |
| i64  | -9223372036854775808                     | 9223372036854775807                     | 64-bit  |
| i128 | -170141183460469231731687303715884105728 | 170141183460469231731687303715884105727 | 128-bit |

## 整数声明方式

一般来说，直接使用整形字面量表示即可；

```rs
let number:u32 = 200;
```

但是与此同时声明字面量还可以通过以下方式声明；

```rs
let number1 = 98_765; // 十进制声明方式， 等于 98765, 这个 _ 是用于提高可读性
let number2 = 0xff; // 十六进制声明方式
let number3 = 0o77; //  八进制声明方式
let number4 = 0b1111_0000;  //  二进制声明方式
let number6:u8 = b'A';  //  通过直接的 unicode 编码值声明（这里必须是 u8 类型）
```

## 使用场景

未指定整数类型时，默认会以 i32 进行储存，这些类型的区别也仅仅只是内存占用大小的区别，根据你的业务场景，选择合适的类型即可。

比如用户年龄你就可以使用 u8 类型，存时间戳就用 u32 类型。

# 浮点数

浮点数存放在`栈`中，因此在声明字面量时，需要指定浮点数的类型（Rust 默认为 f64 类型）以确定栈堆中所占用的空间

## 类型

类型有以下

| 类型 | 指数位 | 小数位 |
| ---- | ------ | ------ |
| f32  | 8      | 23     |
| f64  | 11     | 52     |

## 使用场景

虽然默认浮点类型是 f64，但是在现代的 CPU 中它的速度与 f32 几乎相同，所以采用默认 f64 就行，无需纠结


# 序列(Range)

Rust提供了一个非常简洁的方式，用来生成连续的数值，例如1..5，生成从1到4的连续数字，不包含5; 1..=5，生成从1到5的连续数字,包含5，它的用途很简单，常常用于循环中：

```rs
let range1 = 1..5;  //  生成一个 1-5 但是不包含 5 的 range
let range2 = 1..=5; //  生成一个 1-5 包含 5 的 range
let range3 = 'a'..='z' // 生成一个 a-z 的 range

for i in 1..=5 {
    //  遍历它
    println!("{}",i);
}
```


# 布尔值

过于简单不过多赘述；

```rs
    let t = true;
    let f: bool = false; // 显式指定类型注解
```

# 字符类型

```rs
let c = 'z';
let z = 'ℤ';
let g = '国';
let heart_eyed_cat = '😻';
```

字符类型只能存储一个 unicode 的字符，并且使用 单引号 来声明！

# 元类型

```rs
let a = ();

let name = get_name();  //  这类的 name 也是个 ()
fn get_name(){
}
```

一般 function 内部没有返回值时，会默认返回 ()，除非将函数标记为发散函数时才不会有返回值,

下面这个就是 发散函数
```rs
fn get_name() -> !{
}
```

你可以理解为 typescript 中的 void
```typescript
function get_name():void{
  
}
```

# 切片 (slice)
切片允许你引用集合中部分连续的元素序列，而不是引用整个集合。

声明方式如下

```rs
let my_name = "Pascal";

//  或者
let his_name = String::from("John");
let name = &his_name[0..]; //  这也是个切片
let name2 = &his_name[..]; //  这也是个切片
```

# 字符串
```rs
// 创建一个空String
let mut s = String::new();
// 将&str类型的"hello,world"添加到s中
s.push_str("hello,world");

//  或者
let name = String::from("名字")
```

# 元组 (tuple)
长度固定，元素中的顺序也是固定，元组里面的值可以为不同类型，且不可更改！

对元组不可以增加或者删除，可以简单理解为只读。

`元组因为内部的值类型不同，所以不能遍历！`

```rs
//  定义元组 
let tup: (i32, f64, u8) = (500, 6.4, 1);
//  元组中包含元组
let tuple_of_tuples = ((1u8, 2u16, 2u32), (4u64, -1i8), -2i16);

//  通过索引访问
println!("{}",tup.0);

//  解构元组
let (x, y, z) = tup;

//  打印
println!("tuple of tuples: {:?}", tup);
```

## 使用场景

比如返回值

```rs
fn main() {
    let s1 = String::from("hello");

    let (s2, len) = calculate_length(s1);

    println!("The length of '{}' is {}.", s2, len);
}

fn calculate_length(s: String) -> (String, usize) {
    let length = s.len(); // len() 返回字符串的长度

    (s, length)
}
```

# 结构体（struct）
类似 js 中的 Object，由多个类型组合而出，并且还可以为每个类型起一个名称（key）

```rs
//  与 js 中的 object 不同的地方，在于我们需要先初始化结构体后才能实现，类似于 ts 中 object 的 type
struct User {
    active: bool,
    username: String,
    email: String,
    sign_in_count: u64,
}

let user1 = User {
    email: String::from("someone@example.com"),
    username: String::from("someusername123"),
    active: true,
    sign_in_count: 1,
};

//  访问
user1.email;
```

## 元组结构体(Tuple Struct)
结构体必须要有名称，但是结构体的字段可以没有名称，这种结构体长得很像元组，因此被称为元组结构体，例如：

```rs
    struct Color(i32, i32, i32);
    struct Point(i32, i32, i32);

    let black = Color(0, 0, 0);
    let origin = Point(0, 0, 0);
```

## 元结构体(Unit-like Struct)
如果你定义一个类型，但是不关心该类型的内容, 只关心它的行为时，就可以使用元结构体:

```rs
struct AlwaysEqual;

let subject = AlwaysEqual;

// 我们不关心为AlwaysEqual的字段数据，只关心它的行为，因此将它声明为元结构体，然后再为它实现某个特征
impl SomeTrait for AlwaysEqual {
    
}
```

## 枚举（enum）
枚举与 ts 中的枚举类似，在一个枚举上可以定义所有可能的成员，包括枚举值的类型，

```rs
enum IpAddrKind {
    V4,
    V6,
}

IpAddrKind::V4; // V4
IpAddrKind::V6; // V6

//  也可以给枚举值定义类型
enum Message {
    Quit,
    Move { x: i32, y: i32 },
    Write(String),
    ChangeColor(i32, i32, i32),
}

let c1 = Message::Quit;
let c2 = Message::Move{10,10};
```

# 数组
存放在 栈 上，长度固定，大小固定，一旦定义不可以再修改。

```rs
let a = [1, 2, 3, 4, 5];

let months = ["January", "February", "March", "April", "May", "June", "July",
              "August", "September", "October", "November", "December"];
              
//  指明数组长度和类型
let a: [i32; 5] = [1, 2, 3, 4, 5];

let a = [3; 5]; //  let a = [3, 3, 3, 3, 3];
```

# vector 
存放在 堆 上，大小不固定，可以修改，但是值的类型必须是一致的
```rs
let v: Vec<i32> = Vec::new();

//  通过 宏 创建
let v = vec![1, 2, 3];


//  使用枚举来储存多种类型
enum SpreadsheetCell {
    Int(i32),
    Float(f64),
    Text(String),
}

let row = vec![
    SpreadsheetCell::Int(3),
    SpreadsheetCell::Text(String::from("blue")),
    SpreadsheetCell::Float(10.12),
];
```

# hashmap
存放在 堆 上，真正意义的 js 中的 object

```rs
use std::collections::HashMap;

let mut scores = HashMap::new();

scores.insert(String::from("Blue"), 10);
scores.insert(String::from("Yellow"), 50);
```
