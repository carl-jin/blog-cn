---
title: gogocode AST 抽象语法树修改器使用例子 (四)
date: 2022-03-30 15:04:03
tags:
  - front-end
  - gogocode
categories:
  - Front End
description: 本文主要记录一些 gogocode 的使用例子和遇到的坑 (四)， 这次我们的场景是对 vue 文件中使用的 antd vue 的组件命名进行转换
---

接着上一篇 [gogocode AST 抽象语法树修改器使用例子 (三)](/gogocode-3.html)

# 背景

由于前段时间 webstorm 不提示 antd-vue3 的组件属性问题 见=》 [如何修复 WebStorm 不提示 antd-vue 3 的组件问题](https://carljin.com/webstorm-antd-vue-intelligent-code-completion.html)

迫于无奈，只能使用下面这种命名方式

```html
<AButton>按钮</AButton>
```

那么就需要将以往项目中所有的 `a-button` 这种命名的组件，转换为 `AButton`

我们来看下代码如何实现

```ts
//  转换 antd 插件
export function antdTransform($: AstType, source: string): string {
  source = transformTag(source);

  return source;
}

//  转换 tag
//  a-form => AForm
//  a-form-item => AFormItem
//  注意这里是用正则转换，gogocode 转换失败
function transformTag(source) {
  if (!~source.indexOf("<template>")) {
    return source;
  }

  let templateCode = $(source, {
    parseOptions: {
      language: "vue",
    },
  })
    .find("<template></template>")
    .eq(0)
    .generate();
  templateCode = templateCode.replace(/<(a\-[\w-]+)/g, (all, match) => {
    let newTagName = nameRulesLine2HugeHump(match);

    return `<${newTagName}`;
  });

  templateCode = templateCode.replace(/<\/(a\-[\w-]+)\s?>/g, (all, match) => {
    let newTagName = nameRulesLine2HugeHump(match);

    return `\n</${newTagName}>\n`;
  });

  templateCode = templateCode.trim();

  if (templateCode.length > 0) {
    source = source.replace(
      //  这里不用加 ？，因为可能模版中存在嵌套 teplate 的情况
      //  这里让它匹配到最后一个
      /<template>.*<\/template>/isu,
      `<template>\n${templateCode}\n</template>`
    );
  }

  return source;
}

/**
 * 将串烧命名法转换为大驼峰命名
 * a-form => AForm
 * @constructor
 */
export function nameRulesLine2HugeHump(name) {
  name = name.replace(/-(\w)/g, (all, letter) => {
    return letter.toUpperCase();
  });

  name = name.replace(/^\w/, (s) => s.toUpperCase());

  return name;
}
```
