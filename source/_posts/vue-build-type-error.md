---
title: typescript 生成 vue 的描述文件错误
date: 2022-08-19 17:19:15
description: 在使用 vue3 的 tsx 语法后，使用 typescript 编译 .d.ts 文件，出现 TS2604 JSX element type Comp does not have any construct or call signatures 错误
---

# 解决方案
src 目录下建立 `vue-shims.d.ts` 文件，内容如下

```typescript
declare module "*.vue" {
  import { defineComponent } from "vue";
  const component: ReturnType<typeof defineComponent>;
  export default component;
}
```

