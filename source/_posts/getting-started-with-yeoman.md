---
title: Yeoman 快速入门
date: 2019-11-16 19:31:04
tags:
  - Yeoman
categories:
  - Front End
  - 前端自动化
description: 脚手架能够帮我们自动生成包含本地调试、编译、打包、发布等工具的项目目录，使我们能够减少大量重复劳动的同时，遵循一定的开发规范，大大提升我们的开发、协同效率。
---

# 什么是 Yeoman

[Yeoman 官网](https://yeoman.io/)横幅中说到

> THE WEB'S SCAFFOLDING TOOL FOR MODERN WEBAPPS

很容易理解, Yeoman 是现代化 Web 应用程序的脚手架工具.
那么什么是脚手架呢?
![https://i.imgur.com/YqrhXSb.jpg](https://i.imgur.com/YqrhXSb.jpg)

也就是说通过 Yeoman 官方的生成器,他们建立了一个 Yeoman 的工作流,这个流是由一个强大的,
固定的客户端组建,包含工具和框架帮助开发者快速建立稳健的 web 应用.
可能现在你还在自己配置前端开发环境与自动化.
Yeoman 就是提供这些东西, 你只需要专注于功能上的开发即可.
之前录制过一个视频, 有兴趣的可以查看下[https://www.youtube.com/watch?v=TGWe_TkwCDg](https://www.youtube.com/watch?v=TGWe_TkwCDg)

# 安装

> 前提本地要先安装 npm

直接打开命令行, 执行以下代码

```bash
npm install -g yo
```

# 安装 Generator

你可以在[Yeoman 官网](https://yeoman.io/generators/)搜索你想要的 Generator, 点击进去都有对应的安装方式,
本人开发环境中用的最多的就是, gulp + es6 + ejs + scss 的开发环境. 所以自己写了一个`gulp-with-es6`
这里以安装上述 Generator 为例. 打开命令行执行以下代码进行安装

```bash
npm install generator-gulp-with-es6 -g
```

# 使用 Yeoman

首先建立一个空文件夹

```bash
mkdir test
```

进入该文件夹

```bash
cd test
```

执行`yo`命令

```bash
yo
```

选择刚刚我们安装的`Gulp With Es6`Generator 即可.
![https://i.imgur.com/M1a023k.png](https://i.imgur.com/M1a023k.png)

回车后, 进入安装流程, Generator 一般都会与你进行交互, 比如问你项目名叫什么, 或者要不要什么功能之类的.
并且 Generator 会自动帮你执行`npm install`, 所以执行完后, 就可以直接使用了.
如下图所示,`Gulp With Es6`为我们生成了开发所需要的所有文件与配置, 且默认给我们打开`localhost:3000`作为开发服务器.
(注意: Generator 生成的文件因不同的 Generator 而异, 每个都有所不同)
![https://i.imgur.com/nKzBWjH.png](https://i.imgur.com/nKzBWjH.png)

# 总结

到此以后若要在建立新项目, 只需执行`yo`并且选择`Gulp With Es6`即可.
而且团队统一也只需要对应安装`yo`与对应`Generator`
这样将大大减少我们在前端开发与自动化中所耗费的时间.
