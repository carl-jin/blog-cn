---
title: 打包项目时如何一并输出d.ts文件？
date: 2021-09-09 21:45:13
tags:
  - typescript
description: 打包完项目后发现没有d.ts文件？本文将简单介绍如何在打包时一并输出d.ts文件
---

## 代码

不管你用 webpack 还是 vite 打包，或者其他的构建工具。下面代码是通用的

```bash
$ tsc -p ./tsconfig.dist.json -emitDeclarationOnly && tsc-alias -p ./tsconfig.dist.json
```

只需要将上述代码添加到 package.json 的 build 命令中即可

如

```json
{
  "script": {
    "build": "vite build && tsc -p ./tsconfig.dist.json -emitDeclarationOnly && tsc-alias -p ./tsconfig.dist.json"
  }
}
```

## 说明

`tsc` 这个是 typescript 的 cli 工具， 安装完 typescript 后就会有。

先说这行命令

```bash
tsc -p ./tsconfig.dist.json -emitDeclarationOnly
```

其中的 `-p` 参数的全写是`--project`该参数用于指定，使用哪个文件配置 typescript 的编译，默认是`tsconfig.json`，但是这里我们需要区分下生产和开发环境，所以单独建立了`typescript.dist.json`文件，其内容如下

```json
{
  "extends": "./tsconfig.json",
  "include": ["src"]
}
```

你可以简单理解为，该文件相当于`Object.assign()`方法，用于将该文件的`include`选项覆盖掉`./tsconfig.json`文件，从而形成一个新的配置文件.

`-emitDeclarationOnly` 参数意思是只输出 定义文件， 也就是 d.ts 文件。

现在我们来看第二条命令

```bash
tsc-alias -p ./tsconfig.dist.json
```

这条命令的 [tsc-alias](https://www.npmjs.com/package/tsc-alias) 用于处理 typescript 编译后的 alias 路径问题，比如在 vue 项目中，我们常使用`@`关键字来代替`src`目录，比如引用 type 时会这样写

```typescript
import type { TItem } from "@/index.ts";
```

通过`tsc-alias`命令可以将这个`@`关键字替换为相对路径，从而避免打包出来的插件，alias 丢失问题
