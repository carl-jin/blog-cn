---
title: Rust 中 Condvar 条件变量的理解
date: 2022-01-23 07:34:26
tags:
  - Rust
categories:
  - Rust
description: 如何以一个 js 开发者的角度去理解 rust 中的条件变量
---

看了好几篇文章，都没有理解 Condvar 到底该怎么使用，为啥 wait 中要传入一个 mutex ， 而且文章中给的例子基本上都是官方文档的那个例子，对于我这种没接触过并发开发的来说非常的吃力。因此下面仅仅是个人理解。

我们先看下官方给的代码例子

```rs
use std::sync::{Arc, Condvar, Mutex};
use std::thread;

fn main() {
    let pair = Arc::new((Mutex::new(false), Condvar::new()));
    let pair2 = Arc::clone(&pair);

    thread::spawn(move || {
        let (lock, cvar) = &*pair2;
        // #2
        let mut started = lock.lock().unwrap();
        *started = true;
        // We notify the condvar that the value has changed.
        cvar.notify_one();
    });

    // Wait for the thread to start up.
    let (lock, cvar) = &*pair;
    //  #1 
    let mut started = lock.lock().unwrap();
    // As long as the value inside the `Mutex<bool>` is `false`, we wait.
    while !*started {
        // #3
        started = cvar.wait(started).unwrap();
    }
}
```

##  #3 下面的 wait 方法理解

首先来分析下官网对于 wait 方法的解释

> Blocks the current thread until this condition variable receives a notification.
> This function will atomically unlock the mutex specified (represented by guard) and block the current thread. This means that > any calls to notify_one or notify_all which happen logically after the mutex is unlocked are candidates to wake this thread up. When this function call returns, the lock specified will have been re-acquired.

这句话个人觉得关键点就在于
> This function will atomically unlock the mutex specified (represented by guard) and block the current thread.

意思是 wait 方法将会自动 unlock 传入的 mutex 并且阻塞当前进程， 如事例代码中的 #3 下方的 wait 方法，

我们在 #1 首先获取了 mutex 的锁，此时我们已经确定 `thread::spawn` 的执行肯定要比 #1 慢，不然 spawn 中都锁定了，#1 获取锁的请求就会等待，

所以自己理解这个 wait 方法的意思是

我们需要 wait 来监听一个 锁 上的事件，也就是 `notify_one` 方法触发的事件，当我们执行 wait 之后，如果某个时段，`notify_one` 被触发，`**且**` 这个锁被释放掉时， 将会返回 wait 的执行结果。

因此我们可以这样验证上面这个说法

```rs
use std::sync::{Arc, Condvar, Mutex};
use std::thread;
use std::time;

fn main() {
    let pair = Arc::new((Mutex::new(false), Condvar::new()));
    let pair2 = Arc::clone(&pair);

    thread::spawn(move || {
        let (lock, cvar) = &*pair2;
        println!("触发事件");
        cvar.notify_one();

        thread::sleep(time::Duration::from_secs(4));

        println!("线程内获取锁");
        let mut started = lock.lock().unwrap();
        *started = true;

        println!("线程内锁被释放");
    });

    // Wait for the thread to start up.
    let (lock, cvar) = &*pair;
    let mut started = lock.lock().unwrap();
    // As long as the value inside the `Mutex<bool>` is `false`, we wait.
    while !*started {
        println!("调用 wait 之前");
        started = cvar.wait(started).unwrap();
        println!("接收到 wait 已触发");
    }
}
```

看下打印结果
```shell
调用 wait 之前
触发事件
接收到 wait 已触发
调用 wait 之前
// 这里等待的 4s
线程内获取锁
线程内锁被释放

// 程序不会自动关闭，因为 while 循环第二次执行 wait 后，并没有任何地方能触发 notify_one
```

通过这个打印结果，我们可以确定一件事， 如果想要触发 `notify_one`，这个锁当前的状态必须是自由的，也就是被释放的，也就是当前没有任何一个进程 lock 了这个锁。

那么如果我在 锁 还没有被释放期间，调用了 notify_one 会怎么样呢？ 我们来看个例子

```rs
use std::sync::{Arc, Condvar, Mutex};
use std::thread;
use std::time;

fn main() {
    let pair = Arc::new((Mutex::new(false), Condvar::new()));
    let pair2 = Arc::clone(&pair);

    thread::spawn(move || {
        let (lock, cvar) = &*pair2;
        println!("线程内获取锁");
        let mut started = lock.lock().unwrap();
        *started = true;

        println!("触发事件");
        cvar.notify_one();

        thread::sleep(time::Duration::from_secs(4));
        println!("线程内锁被释放");
    });

    // Wait for the thread to start up.
    let (lock, cvar) = &*pair;
    let mut started = lock.lock().unwrap();
    // As long as the value inside the `Mutex<bool>` is `false`, we wait.
    while !*started {
        println!("调用 wait 之前");
        started = cvar.wait(started).unwrap();
        println!("接收到 wait 已触发");
    }
}
```
看下打印结果

```shell
调用 wait 之前
线程内获取锁
触发事件
// 等待 4s
线程内锁被释放
接收到 wait 已触发
// 程序自动关闭
```

这里我个人理解， 在锁还未被释放期间，执行 notify_one ， 会类似放入一个队列的情况，一旦这个锁被释放了，wait 才会收到通知

现在在回过来看官方给的解释
>  Condition variables are typically associated with a boolean predicate (a condition) and a mutex.

这里就明白了，为什么这个 Condvar 经常与一个 bool 的 mutex 一起使用，因为这个 mutex<bool> 的实际意义只是用来控制 wait 什么时候接受通知的。

实际上这个 条件变量 和 mutex 一起使用时， mutex 也可以携带数据，但是一般不会这样弄，现在个人理解，这个 条件变量 唯一能用到的地方就是

# 什么时候线程任务全部执行完毕
