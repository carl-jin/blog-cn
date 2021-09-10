---
title: package.json 常用配置
date: 2021-09-09 22:09:34
tags:
description: 本文将简单介绍package.json中常用的配置
---

## 配置

```json
{
  //  指定入口文件
  "main": "./dist/visual-grid.umd.js",
  //  指定 esmodule 模式的入口文件
  "module": "./dist/visual-grid.es.js",
  //  自定types的入口文件
  "types": "./dist/index.d.ts",
  //  当这个包被安装为 dependency 的时候，哪些文件作为入口
  "files": ["dist/**/*.css", "dist/**/*.js", "dist/**/*.d.ts"],
  //  如果这个值设置为true，那么该项目不能通过 npm publish 发布
  "private": true,
  //  配置这个项目的运行最低要求，如果低于其他这个版本的项目则无法使用该项目
  "engines": {
    "node": "^16.7.0"
  }
}
```
