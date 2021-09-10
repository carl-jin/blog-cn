---
title: 如果项目不想公开源代码，如何在npm上隐藏源代码文件？
date: 2021-09-09 22:18:45
tags:
description: 本文将简单介绍, 如何避免源代码暴露在npm上
---

## 解决方法

只需要添加`.npmignore`文件到根目录即可，该文件与`.gitignore`文件类似，可以配置哪些文件不发不到 npm 上，
假如我们想隐藏源代码`src`文件夹，只需要在该文件中配置即可, 也可以添加更多的配置

```text
src
build
mock
node_modules
public
index.html
ts.config
vite.config.ts
.npmignore
```
