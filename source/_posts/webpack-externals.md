---
title: webpack externals 常用配置
date: 2020-03-25 15:50:43
tags:
  - webpack
categories:
  - front-end
description: 本文将在webpack-externals基础上, 举例一些项目开发中的常用externals配置
---

> 该文章默认以 webpack-chain 为基础进行配置

因本文章会默认跳过 webpack-externals 基础部分, 若不了解基础的朋友可以[查看此文章](https://github.com/weiqinl/vue-element-admin/issues/3)

### 场景 1

我们的项目在本地开发时分别引用了 gsap 与 jquery, 但是在线上环境中, 这些外部依赖的文件是统一使用 script 标签引用 cdnjs 上的, 所以在打包时我们不需要将这俩文件打包, 那么此时我们可以进行以下配置

```javascript
config.externals([
  {
    jquery: "root jQuery",
    gsap: "root gsap"
  }
]);
```

配置非常简单, 我们只需要将 jquery 使用 root 关键字指名, 在打包时我们代码中使用的 jquery 是从全局变量中来的. gsap 也是同理

### 场景 2

我们开发了一个插件 A, 并且该插件同时引用了插件 B, 且此时作为团队开发的一部分, 插件 B 可能在页面中被多次调用, 如果每个插件都把 B 插件打包, 那么将会照成代码的浪费, 因此我们会考虑只打包 A 插件的代码, 而 A 插件所依赖的 B 插件, 着通过 externals 声明其引用位置

```javascript
config.externals([
  (context, request, callback) => {
    //  我们可以判断如果import的文件来自于 vendor 目录, 那么在打包时候, 我们排除vendor下的这些文件
    //  同时告诉webpack我们代码中使用到的vendor目录下的插件, 将通过commonjs2 方式在其他页面中引用
    if (/\/vendor\//.test(request)) {
      return callback(null, `commonjs2 ${request.replace(/\.+\//, "@src/")}`);
    }
    callback();
  }
]);
```

这里注意下关键字`@src`, 这是 webpack 提供的 alias, 因引用的层级各不同, 我们需要按以下配置, 配置`@src/`对应的 alias

```javascript
config.resolve.alias.set("@src", path.resolve(path.dirname(__dirname), "src"));
```

### 场景 3

在场景 2 的基础上, 我们还想更进一步处理, 如我们只想过滤部分 vendor 下的插件, 而其他 vendor 下的插件, 我们还是想一并打包到项目中.

假设 vendor 目录下, 分别有插件 A,B,C 我们只需要过滤 C 不被打包

那么配置将会是如下

```javascript
config.externals([
  (context, request, callback) => {
    //  下面这行是用正则判断, import 的文件是来自于 插件C, 若是插件C, 我们将其声明为root(外部library引用)
    if (/\/vendor\/C/.test(request)) {
      //  注意这里的 window.C 一定要跟 C 插件导出时的output.library命名一样, 并且是使用umd方式导出的C插件, 下面会提到
      return callback(null, `root window.C`);
    }
    callback();
  }
]);
```

若我们这样写有个要求, 就是 C 插件必须是以 umd 方式导出, 这样不管是在开发环境还是线上环境, 通过 import 引用还是通过 script 引用, 都能正常运作

那么插件 C 的 output 配置因如下

```javascript
//  这行配置一共有两个关键点, 1.是通过umd方式导出, 2.是导出的library名字为C, 这样我们就可以在线上环境中的window.C中使用该插件
config.output.libraryTarget("umd").library("C");
```

### 场景 4

我们开发了一个插件 A, 该插件依赖于 jquery 插件, 但是不想让该插件打包时包含 jquery, 并且还同时想让该插件无论是通过 import 引用还是通过 script 引用都能正常使用. 那么我们需要在 A 插件进行以下配置

```javascript
config.externals({
  jquery: {
    commonjs2: "jquery",
    commonjs: "jquery",
    root: "jQuery"
  }
});
```

以上配置也比较好理解, 若是 commonjs2 和 commonjs 的环境, 则告诉 webpack 通过 import 引入 jquery, 如果是线上环境则告诉 webpack 使用 window.jQuery, 这样配置能保证我们写的插件 A 同时能在各种环境中运行
