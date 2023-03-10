---
title: Cannot read properties of undefined (reading 'suggestedVariableName')
date: 2023-03-07 09:46:19
description: vite + vue 打包时报错 Cannot read properties of undefined (reading 'suggestedVariableName')
---

# 记录一次错误处理
`Cannot read properties of undefined (reading 'suggestedVariableName')`

在使用 `vite` 打包 `umd` 的时候报了一个这样的错误，查找了 github 问过 chatgpt 都没有解决，这个错误来自与 `rollup` 看了源代码才发现是 `dependencies` 引用了一个 undefined 导致的，也就是说我们写的代码中，引用了一个不存在的文件。

经过排查发现是 `unplugin-vue-components/vite` 插件在自动引用 antd 的组件 `AUpload` 时候出现了问题，
只需要将之前自动引用 `AUpload` 改为手动引用就行了

```vue
# 之前的
<template>
    <AUpload></AUpload> 
</template>
```

```vue
# 修改后的
<template>
    <Upload></AUpload> 
</template>

<script setup>
import {Upload} from 'ant-design-vue'
import 'ant-design-vue/lib/upload/style/index'
</script>
```
