---
title: 如何在 Vite 中使用 UMD 的包
date: 2021-11-07 22:53:36
tags:
  - vite
description: 如何配置才能解决 UMD 在 Dev 和 Prod 环境中不同的引用行为？
---
  
## 小道
如果使用 vite 打包后，运行 js 时遇到，诸如`require is not defined` `exports is not defined` 问题的话，请尝试一下配置

```typescript
build: {
    commonjsOptions: {
        transformMixedEsModules: true,
    },
}
```

> 如果以上配置未能解决你的问题的话，那么往往是因为你所引用的这些包，没有严格按照 UMD 或者 CMD 方式道出

** 如果你 Vite 打包后 UMD 引用报错的问题，请跳过介绍 **

## 认识 UMD

大部分可以在浏览器中运行的插件库一般都会提供 UMD 的包，UMD (Universal Module Definition),

希望提供一个前后端跨平台的解决方案(支持 AMD 与 CommonJS 模块方式),

其实也就是一个 UMD 的包，可以在 AMD，CommonJS 和浏览器中运行

核心代码也就是下面这几行

```javascript
!(function (t, n) {
  "object" == typeof exports && "undefined" != typeof module
    ? (module.exports = n())
    : "function" == typeof define && define.amd
    ? define(n)
    : ((t = t || self).PackageName = n());
})(window, function () {
  //  逻辑代码
});
```

## Vite 对 UMD 包的支持

正如 Vite 官方说到的

> 开发阶段中，Vite 的开发服务器将所有代码视为原生 ES 模块。
> 因此，Vite 必须先将作为 CommonJS 或 UMD 发布的依赖项转换为 ESM。

如果插件作者导出的是一个`正规`的 UMD 包，在开发阶段是无需担心 UMD 包引用后无法调用问题，

比如说我们使用到了 [Headroom](https://wicky.nillia.ms/headroom.js/) 这个插件，

我们只需要这样引用后调用即可

```typescript
import * as Headroom from 'headroomjs'
new Headroom(document.body)
```

上述代码在 Dev 开发环境中是没有问题的，但是当我们执行 Build 命令后，运行 `vite preview` 可以看到控制台报了一个错

```text
index.4678aea5.js:formatted:34 Uncaught TypeError: s is not a constructor
```

我们来看下源代码

```javascript
import {H as s} from "./vendor.c84e7be5.js";
//  ...
//  下面这行报错了
const l = new s(document.body);
```

s 不是一个 constructor，奇怪了 Dev 环境明明是可以 new 的为什么到这里就不行了，

我们来打印下这个 s 看看在 Dev 和 Prod 环境中它到底是什么

```text
//  Dev
ƒ Headroom(elem, options) {

//  Prod
Module {
  default: function,
  Symbol(Symbol.toStringTag): "Module"
}
```

可以看到这个 headroom 提供的 UMD 文件，在 Dev 中引用时是个 Fn， 但是到了 Prod 环境中却变成了一个 Module 的对象，

这就导致了直接引用后使用是行不通的。

也许你已经想到了做个兼容不就行了吗

```javascript
import * as Headroom from 'headroomjs'
new (Headroom.default ?? Headroom)()
```

确实这样兼容后，代码可以在浏览器中运行了。

**⚠️ 这里代码仅仅只是在 ESM 的环境中运行**

## UMD 的包如何兼容 IE 11？

其实我也是搞不懂，你既然想兼容低版本浏览器，为何还要在 Vite 上折腾，Webpack 它不香吗？

虽然官方提供了 [@vitejs/plugin-legacy](https://www.npmjs.com/package/@vitejs/plugin-legacy) 可以很简单的兼容 IE 11，

但是当我们配置好了这个插件，再次执行 Build 命令后，可以发现 Legacy 处理后的代码变成这样了

```javascript
//  headroom 库的逻辑代码在下面这行代码的上面
var Hs = Object.freeze({
    __proto__: null,
    [Symbol(Symbol.toStringTag)]: "Module",
  })
//  下面这行报错
new (Hs)(document.body)
```

这里我们需要 new 的 `headroom` 已经被转换成 `Hs` 了，

原因也就是因为经过 legacy 处理后的代码，headroom 直接被打包到一起了，

当把这个 UMD 打包到一起时，vite 会自动给 headroom 生成一个 Object.freeze 对象，

这样保证了我们在 new Headroom 时能找到该对象，但是恰巧我们上面做了兼容

```javascript
new (Headroom.default ?? Headroom)()
```

因为这个 `Headroom` 下的 `default` 确实找不到，所以 ?? 运算符执行完后就只剩下 `Headroom` 也就是打包后的 `Hs`

这个原因也很简单，因为 vite 是需要在 ESM 环境下执行，但是 IE 11 不支持 ESM，那么 legacy 只能把他们转换成在浏览器中直接运行的 iife 格式，

这就导致我们按照 ESM 写的兼容方式是行不通的

## 解决方法

既然 iife 模式下 Headroom 并不在 `Object.freeze` 生成的对象上，那么它究竟跑哪去了呢？

我们回过头来看下 UMD 的兼容方式

```javascript
!(function (t, n) {
  "object" == typeof exports && "undefined" != typeof module
    ? (module.exports = n())
    : "function" == typeof define && define.amd
    ? define(n)
    //  可以看到在因为 iife 是直接运行的不存在模块的问题，
    //  所以这里直接把 Headroom 导出到了 window 下面
    //  这也就是为什么你在页面中引用了 cdnjs 上面的 headroomjs
    //  直接就可以在 js 中 new Headroom ， 
    //  其实也就是在 new window.Headroom
    : ((t = t || self).Headroom = n());
})(window, function () {
  //  逻辑代码
});
```

那么你可能会想，既然这样我直接使用 window 下面的 Headroom 不就行了吗？

```html
//  index.html
<script src="https://cdnjs.cloudflare.com/ajax/libs/headroom/0.12.0/headroom.min.js"></script>
```

```typescript
//  index.ts
new winodw.Headroom(document.body)
```

这样确实可以达到 IE 11 和 ESM 浏览器的兼容

这也是比较稳妥的方案

但是如果你不想引用 cdnjs 上的文件，就想让这个包打包在 output 的 js 中怎么办，也就是我们说的单文件。

那么这样的话，只能写个兼容的方法去调用了

```typescript
/**
 * 该方法用于处理 vite 编译 umd 包时, 在 es format 和 umd format 引入的格式不一致问题
 * @param module  - import * as PackageName 中的 PackageName 对象
 * @param moduleName - UMD 包的 library 名称， 也就是导出到 Window 对象上的名称
 */
export const importHack = (module: any, moduleName: string) => {
  if (typeof module === "function") {
    return module;
  }

  if (module.default) {
    return module.default;
  }

  const wModule = window[moduleName];
  if (wModule) {
    return wModule.default ? wModule.default : wModule;
  }

  if (module) {
    return module;
  }

  throw new Error(`无法处理模块 : ${moduleName}`);
};

```

调用方式改成这样

```typescript
import {importHack} from 'helper'
import * as HeadroomFn from 'headroom.js'
new (importHack(HeadroomFn,'Headroom'))(document.body)
```

这样就解决了 UMD 包在开发环境和 IE 11 上运行的问题

这里需要注意下引用的名称

```typescript
import * as HeadroomFn from 'headroom.js'
```

在通过 glob 方式引用后赋值的变量名不能与 UMD 导出包的名称一致

```javascript
!(function (t, n) {
  "object" == typeof exports && "undefined" != typeof module
    ? (module.exports = n())
    : "function" == typeof define && define.amd
    ? define(n)
    //  不能与下面这个 Headroom 一致，
    : ((t = t || self).Headroom = n());
})(window, function () {
  //  逻辑代码
});
```

如果一致的话，会导致 window 上的变量被覆盖的问题，

原因也很简单因为 Vite 会创建一个 Object.freeze 对象， 

此时这个对象的名称恰好是和 Headroom 导出在 Window 上的名称是一致的

这样 Headroom 的导出就被覆盖掉了

## 总结

如果你不考虑 IE 11 兼容的话， 只需要添加个 default 判断即可

也就是

```javascript
import * as Headroom from 'headroom.js'
new (Headroom.default ?? Headroom)()
```

但是如果你要打包的是 iife 且引用的 UMD 库也需要参与打包时， 

定一个 `importHack` 方法是个不错的选择
