---
title: fancybox3 左右切换动画卡顿问题修复
date: 2019-11-18 22:14:42
tags:
  - fancybox3
categories:
  - Front End
  - Fix Bug
description: 本文记录在使用fancybox3 左右切换动画在手机实体机机上卡顿问题, 其根本原因是图片太大, 导致其渲染与动画同时进行使得动画不流畅卡顿.
---

#### 问题描述

fancybox3 在移动端实体机中因图片质量太大(>1M), 导致在左右切换图片时, 动画时常卡顿, 影响用户体验.

#### 问题重现步骤

1. 使用 fancyBox3 初始化超过 1M 的图片
2. 使用移动端实体机进行访问
3. 左右滑动切换图片

#### 预期结果

左右切换动画在移动端实体机上流畅执行.

#### 实际结果

左右切换动画在移动端实体机上卡顿

#### 环境

- fancyBox v3.5.7
- 手机 iPhone 6 Plug, 系统版本 10.3.2
- 在下图处卡顿
  ![https://i.imgur.com/gtkRutX.jpg](https://i.imgur.com/gtkRutX.jpg)

#### 解决过程

打开[fancybox3 源代码](https://cdnjs.cloudflare.com/ajax/libs/fancybox/3.5.7/jquery.fancybox.js)
修改`1221`行代码

```javascript
//  修改前
self.preload("image");

//  修改后, 修改原因为防止preload生成Img太快导致卡顿问题
window.setTimeout(() => self.preload("image"), 200);
```

修改`3181`行代码

```javascript
//  修改前
if (this.use3d) {

//  修改后, 修改原因为启动GUP渲染, 这个判断未提供外部接口, 只能进行源代码修改
if (true) {
```

添加以下样式, 使用`will-change`关键字, 提前渲染动画

```scss
.fancybox-content,
.fancybox-slide {
  will-change: transform;
}
```
