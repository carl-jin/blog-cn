---
title: 如何修复 WebStorm 不提示 antd-vue 3 的组件问题
date: 2022-03-26 13:31:07
tags:
  - Front End
  - WebStorm
categories:
  - Front End
description: WebStorm 2021.3.2 版本下使用 antd-vue 3.1.0-rc.4 时，不提示组件的 props 的问题修复
---

# 环境

```text
WebStorm 2021.3.2
ant-design-vue 3.1.0-rc.4
```

# 问题描述

`ant-design-vue` 官方已经提供了 [web-type.json])(https://unpkg.com/browse/ant-design-vue@3.1.0-rc.4/vetur/web-types.json) 并且 `WebStorm 2021.3.2` 版本也支持 `web-type.json`, 但是这仅仅适用于全局引用的情况。也就是说我们的 `antd` 包，必须说完全引入，如下面这样使用

```ts
//  main.ts
import { createApp } from "vue";
import Antd from "ant-design-vue";
import App from "./App";
import "ant-design-vue/dist/antd.css";

const app = createApp(App);

app.use(Antd).mount("#app");
```

这样调用

```vue
<template>
  <a-button size="large">按钮</a-button>
</template>
```

这肯定不是我们想要的结果，我们想要的是按需引用，像下面这样调用

```vue
<template>
  <Button size="large">按钮</Button>
</template>
<script lang="ts" setup>
import { Button } from "ant-design-vue";
</script>
```

但是如果我们按照上面这种方法书写的话，会导致 `<Button>` 组件，没有 `props` 提示，并且使用其他组件时，即使在 `script` 中进行引用，但是由于 `setup` 语法糖的问题

还是没有办法提示组件名和 `porps`.

我们来看下 `antd` 提供的 `web-types.json` 里面定义的 tag 名称是这样的

```json
{
  "tags": [
    {
      "name": "a-alert",
      "attributes": []
    }
  ]
}
```

聪明的同学可能想到了，那么我们自己定一个 web-types.json 文件，将 name 改成 `Alert` 这样的不就行了吗？

答案是不行的，即使我们修改或者引用了我们自己的 `web-types.json` 文件，当我们在 `setup` 里面引用 `Button` 时，

`WebStorm` 还是会优先分析 `import` 的类型导出。也就是说如果我们使用 `import { Button } from "ant-design-vue";` 来导入

`<Button>` 组件，它会覆盖 i 刚刚我们自己的 `web-types.json` 文件。

> 奇怪 🤔 你不是说 WebStorm 处理不了 setup 语法糖吗。
> 其实它并不是处理不了，而是没办法理解 antd 的组件导出方式

那么有没有一种办法，既让它有提示，还是按需引用呢？

还真有，就是用 vscode 就行了， vscode 的 vetur 插件对这块支持很好。

# ？？

说了半天让换编辑器？

其实除此之外还真有一种不换编辑器，不换框架的解决方法，就是使用

[`unplugin-vue-components`](https://github.com/antfu/unplugin-vue-components) vite 插件，这样既能实现按需引用，同时也能支持代码提示。

`unplugin-vue-components` 插件是用于自动引入组件的，也就是说我们可以直接使用组件，而不需要引用

首先我们来安装下

```shell
$ yarn add unplugin-vue-components -D
```

然后我们来编辑下 vite.config.ts

```ts
// vite.config.ts
import Components from "unplugin-vue-components/vite";
import { AntDesignVueResolver } from "unplugin-vue-components/resolvers";

export default defineConfig({
  plugins: [
    Components({
      dts: true,
      resolvers: [AntDesignVueResolver()],
    }),
  ],
});
```

这样的话，我们清理下编辑器缓存并重启，我们依次点击 `File->Invalidate Caches->Invalidate And Restart`。

重启之后我们就可以直接在有组件提示的情况下，开心的开发了。比如我们要使用 `<Button>` 组件可以这样写

```vue
<template>
  <AButton size="large">按钮</AButton>
  <AFormItem :has-feedback="false"></AFormItem>
</template>
<script lang="ts" setup>
//  这里不需要引用 AButton 因为 unplugin-vue-components 插件会自动引用
//  此时我们去修改 AButton 上的 props 已经有代码提示了
</script>
```
