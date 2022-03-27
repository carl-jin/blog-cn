---
title: gogocode AST 抽象语法树修改器使用例子 (一)
date: 2022-03-26 22:04:03
tags:
  - front-end
  - gogocode
categories:
  - Front End
description: 本文主要记录一些 gogocode 的使用例子和遇到的坑，关于 googocode 的入门与教学，官网的文档已经写的很详细了
---

# 介绍

[gogocode](https://gogocode.io/zh/docs/specification/introduction),引用官网的介绍就是

> GoGoCode 是一个基于 AST 的 JavaScript/Typescript/HTML 代码转换工具，你可以用它来构建一个代码转换程序来帮你自动化完成如框架升级、代码重构、多平台转换等工作。

举个场景来说，就是如果我们需要进行大量的重构或者框架升级，这些繁琐还容易出错的过程，可以通过写 gogocode 的脚本来让程序自动帮我们完成。也就说之前你可能需要到每个文件里面 ctrl+r 替换的过程，现在完全可以使用脚本来实现

哪有人就好奇了，那用正则替换不一样吗？no no no ， gogocode 的操作是基于 AST 抽象语法树的，

这样代码的可控性就很高，另外鉴于 gogocode 极其便捷的 api 这开发成本要比用正则替换小太多了

> 本文并不介绍如何入门使用，只是记录一些代码替换的例子与坑
> 如果要看教程的话，官网的教程已经写的非常棒了 [官网教程](https://gogocode.io/zh/docs/specification/introduction)

# 例子 1

我们需要将下面的代码

```ts
export const ApiName1 = (user_uuid: string, op: PaginationParam) =>
  get(`/api/${user_uuid}/msg?include=owner&page=${op.page}&limit=${op.limit}`);

export const ApiName2 = (withs = "", include = "") =>
  get(`/api/ws?with=${withs},&include=${include}`);
```

替换为

```ts
export function ApiName1(user_uuid: string, op: PaginationParam) {
  return get(
    `/api/${user_uuid}/msg?include=owner&page=${op.page}&limit=${op.limit}`
  );
}

export function ApiName2(withs = "", include = "") {
  return get(`/api/ws?with=${withs},&include=${include}`);
}
```

### 坑 1

首先下面这个匹配方式是不生效的

```ts
$(source).replace(
  `const $_$1 = ($$$) => $$$2 `,
  `function $_$1($$$) { return $$$2 }`
);
```

原因是我们这里的箭头函数是直接返回的，没有 `{}` 来包裹，官方的例子里面也没有这样的案例。

这里如果我们需要正确的匹配 `const foo = (bar) => bar + bar` 这样的形势，需要按下面这样写

```ts
$(source).replace(
  `const $_$1 = ($$$) => "$_$2" `,
  `function $_$1($$$) { return $_$2 }`
);
```

这样就会将 `const foo = (bar) => bar + bar ` 转换为

```ts
function foo(bar) {
  return bar + bar;
}
```

### 坑 2

转换下面这个例子时报错

```ts
export const ApiName2 = (withs = "", include = "") =>
  get(`/api/ws?with=${withs},&include=${include}`);
```

报错信息为

```text
/**
Something goes wrong...
Error: replace failed: function ApiName2(withs = ""
include = "") { return get(`/api/ws?with=${withs},&include=${include}`) } cannot be parsed!
**/
```

从报错信息中，我们可以看到，代码将两个入参中间的 `,` 给删除了（或者替换为 `\n` 了？）。导致语法解析错误。

这迫使我们放弃使用 `replace` 方法，而使用 `replaceBy` 来进行细节的处理

```ts
$(source)
  .find(`export const $_$1 = ($$$) => "$_$2"`)
  .each((item) => {
    let args = item.match["$$$$"];
    //  我们将 ast 中读取到的 入参 合并成字符串
    let argsStr = args.map((arg) => $(arg).generate()).join(",");
    let fnName = item.match[1][0].value;
    let fnContent = item.match[2][0].value;

    item.replaceBy(
      $(`export function ${fnName}(${argsStr}) { return ${fnContent} }`)
    );
  });
```

问题可以跟踪 [#143](https://github.com/thx/gogocode/issues/143)

### 坑 3

这个严格意义上来说，应该不算坑，当我们的代码中同时存在下面的情况时

```ts
export const ApiToken = (params?: object) => {
  return post("/token", params);
};

export const ApiToken2 = (params?: object) => post("/token", params);
```

转换会报错，因为此时 `ApiToken` 会被转换为

```text
export function ApiToken(
  params?: object
) {{
  return return post(
    '/token',
    params
  )
}}
```

如果它 `ApiToken` 的箭头函数中是有 `{}` 包裹的，我们应该掠过它。

在原来的基础上加个判断即可

```ts
$(source)
  .find(`export const $_$1 = ($$$) => "$_$2"`)
  .each((item) => {
    let args = item.match["$$$$"];
    //  我们将 ast 中读取到的 入参 合并成字符串
    let argsStr = args.map((arg) => $(arg).generate()).join(",");
    let fnName = item.match[1][0].value;
    let fnContent = item.match[2][0].value;

    if (fnContent.trim()[0] === "{") {
      item.replaceBy($(`export function ${fnName}(${argsStr}) ${fnContent}`));
    } else {
      item.replaceBy(
        $(`export function ${fnName}(${argsStr}) { return ${fnContent} }`)
      );
    }
  });
```

### 坑 4

转换后的代码，所有注释都没有了，原因是

```ts
$(source).find(`export const $_$1 = ($$$) => "$_$2"`);
```

`find` 表达式中包含了 `export` ，导致我们使用 `replaceBy` 时注释信息也被删掉了

解决方法是删除 `export`

```ts
$(source)
  .find(`const $_$1 = ($$$) => "$_$2"`)
  .each((item) => {
    let args = item.match["$$$$"];
    //  我们将 ast 中读取到的 入参 合并成字符串
    let argsStr = args.map((arg) => $(arg).generate()).join(",");
    let fnName = item.match[1][0].value;
    let fnContent = item.match[2][0].value;

    if (fnContent.trim()[0] === "{") {
      item.replaceBy($(`function ${fnName}(${argsStr}) ${fnContent}`));
    } else {
      item.replaceBy(
        $(`function ${fnName}(${argsStr}) { return ${fnContent} }`)
      );
    }
  });
```

> 这里注意下，当我们这样处理后后续在使用 `item` 上面的 child 或者 find 方法时，需要调用下 `.parent()`

# 例子 2

我们需要将下面的代码

```ts
export function ApiToken(params?: object) {
  return post("/token", params);
}

export function ApiLogin(params?: LoginParam) {
  return post("/login", params);
}
```

替换为

```ts
export function ApiToken(params?: object, mode: ErrorMessageMode = "message") {
  return defHttp.post(
    {
      url: "/token",
      params,
    },
    {
      errorMessageMode: mode,
    }
  );
}

export function ApiLogin(
  params?: LoginParam,
  mode: ErrorMessageMode = "message"
) {
  return defHttp.post(
    {
      url: "/login",
      params,
    },
    {
      errorMessageMode: mode,
    }
  );
}
```

## 首先来转换 调用方法

```ts
$(source)
  .find(`function $_$1 ($$$) { $_$2 }`)
  .each((item) => {
    //  替换 post => defHttp.post
    //  为了解决前后命名不同的问题，这里用了个映射
    const methodsMap = {
      post: "post",
      get: "get",
      http_delete: "delete",
      put: "put",
      patch: "patch",
    };

    item
      .parent()
      .child("declaration.body")
      .find("$_$1($$$)")
      .each((_item) => {
        const method = _item.match[1][0].value;
        if (methodsMap[method]) {
          _item.attr("callee.name", `defHttp.${methodsMap[method]}`);
        }
      });
  });
```

## 转换参数

首先我们来给每个方法的入参最后添加个 `mode: ErrorMessageMode = "message"`

```ts
$(source)
  .find(`function $_$1 ($$$) { $_$2 }`)
  .each((item) => {
    item
      .parent()
      .child("declaration")
      .append("params", 'mode: ErrorMessageMode = "message"');
  });
```

## 修改方法的参数

```ts
$(source)
  .find(`function $_$1 ($$$) { $_$2 }`)
  .each((item) => {
    item
      .parent()
      .find(`$_$1($$$)`)
      .each((_item) => {
        const newMethodName = _item.attr("callee.name");
        //  这里无法保证用户传入的第一个参数是字符串还是模版标签，这里统一的转换为 文本代码
        const url = $(_item.match["$$$$"][0]).generate();
        const params = _item.match["$$$$"][1]
          ? $(_item.match["$$$$"][1]).generate()
          : null;

        _item.replaceBy(
          $(`${newMethodName}(
        {
          url: ${url},
          ${params ? `params: ${params}` : ""}
        },
        {
          errorMessageMode: mode,
        }
      )`)
        );
      });
  });
```

# 例子 3

将

```ts
import { post, get, put, patch, http_delete } from "../methods";
```

转换为

```ts
import { defHttp } from "/@/utils/http/axios";
```

其实你也可以理解为删除之前的，添加一个后面的

这个比较简单

```ts
$(source).replace(
  `import {$$$} from "../methods"`,
  `import { defHttp } from "/@/utils/http/axios";`
);
```
