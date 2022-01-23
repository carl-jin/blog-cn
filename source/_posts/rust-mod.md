---
title: Rust 中 mod 的使用
date: 2022-01-23 07:24:26
tags:
  - Rust
categories:
  - Rust 
description: 如何以一个 js 开发者的角度去理解 rust 中的模块系统
---

## 注意事项
1. mod 如果要使用，需要加 pub 前缀
2. mod 中如果要引用标准库中的 mod 时， use 语法需要写到 mod 的内部，切记不要写到外部
3. 要使用一个 mod 时，首先需要 `mod worker;` 来将其引入到全局的 crate 中 (这里是 lib.rs) ,
4. 然后再引用 mod `use crate::worker`;
5. 如果你要使用 `worker` 文件夹下面的 `worker` 这个 mod， 那么就需要这样写了 `use crate::worker::worker`;


### 定义一个 mod
```rs
// src/worker.rs
pub mod worker {
    use std::thread;

    pub struct Worker {
        id: usize,
        thread: thread::JoinHandle<()>,
    }

    impl Worker {
        pub fn new(id: usize) -> Worker {
            let thread = thread::spawn(|| {});

            Worker { id, thread }
        }
    }
}
```

### 在其他文件中使用它

```rs
//  lib.rs
mod worker;
use std::thread;
use crate::worker::worker::*;

pub struct ThreadPool {
    workers: Vec<Worker>,
}
```

如果已经在 crate 中进行了 mod worker; 的引用 那么其他非 crate 的文件（必须也在 crate 中进行引用过），

只需要通过 下面代码即可以使用
```rs
// src/job.rs
use crate::worker::worker::*;
```

注意
这里的 job.rs 必须已经在 crate 也就是 lib.rs 中引用了
```rs
// src/lib.rs
mod job;
```

## 总结
其实正如官方文档描述的一样，mod 类似于一个 tree，我们必须要在 tree 的顶端引入每个需要使用的 mod，也就是 `mod job;`

这样才能让 `src/job.rs` 这个文件被编辑器识别，然后在其他文件中就可以通过 `use crate::job` 来访问了

如果仅仅是像 js 一样用于拆分文件，而不是在每个文件中实现多个 mod 的话， 其实 `worker.rs` 里面的内容可以这样写
```rs
use std::thread;

pub struct Worker {
    id: usize,
    thread: thread::JoinHandle<()>,
}

impl Worker {
    pub fn new(id: usize) -> Worker {
        let thread = thread::spawn(|| {});

        Worker { id, thread }
    }
}
```
然后这样引用
```rs
use std::thread;
use crate::worker::*;
```
