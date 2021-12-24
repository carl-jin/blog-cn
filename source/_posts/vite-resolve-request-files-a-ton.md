---
title: Vite 解决项目刷新慢问题（请求量过大）
date: 2021-12-23 21:17:30
tags:
  - vite
description: Vite 搭建后的项目，在开发过程中，每次刷新都需要等待很久？本文将介绍具体原因以及解决方案
---

## Vite 上的 issues

如果你正在使用 Tailwindcss，那么可能是因为 less 编译问题， 具体解决方法请看 [https://github.com/vitejs/vite/issues/5145](https://github.com/vitejs/vite/issues/5145)

Vite 作者提到了这个加载慢的问题具体请看 [https://github.com/vitejs/vite/issues/1309](https://github.com/vitejs/vite/issues/1309), 这里面说的很清楚，这里就不啰嗦了

基于上面这个讨论，有开发者提交了一个 PR 但是一直没通过，所以他自己 Fork 了一个项目，有兴趣的可以看看 [https://github.com/ArnaudBarre/vite/commit/e7c54c8e5e8fb9968a49b6a835c7e375484082bf](https://github.com/ArnaudBarre/vite/commit/e7c54c8e5e8fb9968a49b6a835c7e375484082bf)

## 优化 1 预构建

如 [vite 官方文档](https://cn.vitejs.dev/guide/dep-pre-bundling.html#the-why) 中提到的，vite 会自动搜索需要预构建的包。但是它不会预构建下面这种写法的包

```typescript
import zhCn from "ant-design-vue/es/locale/zh_CN";
```

可以理解为 vite 只搜索了最外层的 `ant-design-vue` 的引用，如果我们引用的是这个 package 跟深级别的包，则无法自动加入预构建，这时候就需要手动配置下

```typescript
//  vite.config.js
{
  optimizeDeps: {
    include: ["ant-design-vue/es/locale/zh_CN"];
  }
}
```

如何找到这种未进行预构建的包，可以通过分析浏览器请求得到，下图是未被缓存的

![img1](https://imgur.com/SU4hjMI.png)

下图是被缓存的，你可以在 filter 中输入 `node_modules` 来过滤这些请求

![Imgur](https://i.imgur.com/xSkBmwV.png)

