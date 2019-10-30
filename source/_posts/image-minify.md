---
title: 图片批量压缩
date: 2019-10-30 12:30:51
tags:
  - 图片处理
  - 前端自动化
  - 压缩
categories:
  - Front End
description: 本文将介绍如何使用tinyjpg API 批量压缩图片.
---

# 前言

为何要使用[tinyjpg](https://tinyjpg.com)?
作为前端开发者中的一员,想必大家已经尝试过使用 Npm 上的图片压缩库,
比如[imagemin](https://www.npmjs.com/package/imagemin)或者其他的压缩库,
甚至你尝试过直接使用`canvas`进行图片压缩.不管你用什么库,区别在于压缩算法.
本人经过一系列的对比(在线压缩网站与 Npm 库)最终产生的佼佼者是[tinyjpg](https://tinyjpg.com)俗称`熊猫压缩`.
熊猫压缩算法是迄今为止能找到的最好的(没有之一)

# 准备工作

1. nodejs 环境搭建, 作为前端开发者这里就略过了
2. [在这里](https://tinyjpg.com/developers)获取熊猫压缩免费 API
   > 熊猫压缩是一个在线压缩网站.
   > 但是有部分限制,图片大小必须要小于 5M,批量处理不能超过 20 张.
   > 但其开发者 API 并没有这些限制
3. 安装 npm 包 `tinify`
   ```bash
   npm install tinify
   ```

# 直接上代码
```javascript
//  引用glob的库的目的是为了快速获取images目录下的所有图片
const glob = require("glob");
const path = require("path");
const tinify = require("tinify");
//  这里设置的是从熊猫压缩获取的API key 当然下面这个是不能使用的, 你需要替换成自己的
tinify.key = "cn4da8yB9pfjhewGlZ5wq3G0xHqh5spY";
//  获取需要压缩image的图片目录路径
imgs = path.join(path.dirname(__filename), "images");
let i = 0;
let total = 0;

//  写个递归 遍历压缩图片
const process = async list => {
  let fileName = list.shift();
  //    核心代码 通过tinify 压缩图片
  const source = tinify.fromFile(fileName);
  await source.toFile(fileName);
  
  //    打印进度
  console.log(i++, total, fileName);

  if (list.length > 0) {
    await process(list);
  }
};

//  获取目标路径下的所有 .jpg 和 .png图片
glob(`${imgs}/**/*.{jpg,png}`, {}, async (err, res) => {
  total = res.length;
  await process(res);
});
```

# 总结
代码还是较为简单的, 你可以把他扩展到gulp或者webpack上.
注意的是 免费的API调取每月只能压缩500张图, 但是对于一般的小公司完全够用了,
即使你不够用, 也可以使用多个免费API切换调用
另外还需要注意的就是 压缩图片时需要联网. 压缩过程是在 熊猫压缩服务器上进行. 
这样保证了压缩算法不泄漏的同时还能减少本地CPU资源的耗损
