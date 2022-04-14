---
title: Vue3 技巧
date: 2022-04-05 10:03:01
tags:
  - front-end
  - vue
categories:
  - Front End
description: 记录一些 vue3 的使用技巧
---

## 1. 渲染一个类似于 AntD 类似于 Message 的组件

> 该组件是在 vue 程序外调用的，也就是说我们需要重新执行 app.mount 来绑定到新的 dom
> 该组件的模版文件，最好是通过 vue 文件生成，而不应该直接在 tsx 中编写

```tsx
//  edit tsx
import EditorCmp from "./components/editorRender.vue";
const app = createApp({
  components: {
    EditorCmp,
  },
  setup() {
    const columnsOptions = reactive({});
    const value = ref(EditParams.value);
    return () => (
      //  @ts-ignore
      <EditorCmp columnsOptions={unref(columnsOptions)} value={unref(value)} />
    );
  },
});

app.mount(Dom);
```

## 2. watch 无法监听 props

> A watch source can only be a getter/effect function, a ref, a reactive object, or an array of these types.

需要改成这样写

```ts
watch(
  () => props.value,
  (val) => {
    formState.value[id] = val;
  },
  {
    deep: true,
  }
);
```

## 3. Vue3 使用 setup 语法糖后父组件$refs 无法使用调用子组件函数、属性的解决方法

使用 (defineExpose)[https://v3.cn.vuejs.org/api/sfc-script-setup.html#defineexpose]

```vue
<script setup>
import { ref } from "vue";

const a = 1;
const b = ref(2);

defineExpose({
  a,
  b,
});
</script>
```

## 4. Injection "Symbol(pinia)" not found

原因是未初始化 pinia 导致的，有些组件是脱离 main.js 运行的，需要手动初始化下 pinia

```ts
setupStore(this.CMP);
```
