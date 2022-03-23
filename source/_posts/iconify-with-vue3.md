---
title: iconify + vue3 结合使用
date: 2022-03-23 17:36:33
tags:
  - iconify
categories:
  - Front End
description: iconify 将大部分开源图标统一在了一起，提供便捷的 api 调用。并且通过使用 vite 的插件，还能做到按需打包，这样比以往使用 icomoon 将 svg 生成字体来说，方便太多了，本文介绍如何在 vue3 中使用 iconify
---

# 搭建项目

首先我们使用 vite 建立一个新的项目

```shell
$ yarn create vite
```

安装下依赖

```shell
$ yarn add @iconify/vue
```

# 使用

```vue
<template>
  <Icon icon="mdi:home" width="24px" height="24px" />
</template>

<script lang="ts" setup>
import { Icon } from "@iconify/vue";
</script>
```

这样就可以使用 iconify 了。

# 添加自定义图标

如果要想添加自定义图标，我们只需要在 main.js 中注册一下就行了

```ts
import { disableCache, addIcon } from "@iconify/vue";

//  添加自定义图标
disableCache("all");

const iconData = {
  body: '<path d="M10 20v-6h4v6h5v-8h3L12 3L2 12h3v8h5z" fill="currentColor"/>',
  width: 24,
  height: 24,
};

let res = addIcon("custom:home", iconData);
//  如果注册成功 res 为 true， 如果数据有问题则返回 false
console.log(res);
```

# 进阶

官方提供的 `<Icon>` 组件接受以下参数 [Icon component properties](https://github.com/iconify/iconify/tree/master/packages/vue#icon-component-properties).
