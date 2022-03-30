---
title: gogocode AST 抽象语法树修改器使用例子 (三)
date: 2022-03-30 14:04:03
tags:
  - front-end
  - gogocode
categories:
  - Front End
description: 本文主要记录一些 gogocode 的使用例子和遇到的坑 (三)， 这次我们的场景 vue2 升级到 vue3
---

接着上一篇 [gogocode AST 抽象语法树修改器使用例子 (二)](/gogocode-2.html), 这次我们的场景是 vue2 升级到 vue3。

gogocode 官方已经提供了一个 [Vue2 到 Vue3 升级插件](https://github.com/thx/gogocode/tree/main/packages/gogocode-plugin-vue) 使用方法也比较简单，只需要

```shell
gogocode -s ./src -t gogocode-plugin-vue -o ./src-out
```

正如官方说的，这个插件可以帮你完成 80% 的转换任务，但是生下来的 20% 的任务还是得我们自己完成。

本文将记录在转换过程中遇到的各种各样的问题，以及如何完成该项目剩下的 20% 的转换

# 场景

这个项目是 2 年前基于 vue-cli 和 vue2 搭建的一个 Sass 系统，前段时间成功的从 [vue-cli 迁移到了 vite ](https://carljin.com/migrating-from-webpack-vue-cli-to-vitejs.html), 但是仅仅这样的优化还不够，我们希望能使用最新的 vue3 和 antd3，在此基础上来开发后续的功能。

使用 `ls -lR | grep '.vue' |wc -l` 统计了下 `src` 下面的 `vue` 文件，共有 `487` 个，这要是手动转换是不可能的。

# 第一次使用 gogocode

当第一次听到有 `gogocode` 这个东西时，我迫不及待的使用它将项目转换了下，结果在转换的过程中各种报错（注意，不是转换后运行报错，而是转换就没成功）。

总结了下原因，是因为这个项目经过几个开发者开发，有技术好的，也有技术差的，有按规范写的，也有不按规范写的，导致 `gogocode` 的 `vue` 插件不能按预期处理这些糟糕的代码，这是完全可以理解的。

# 思路

再经过直接转换失败后，萌生出了一个想法，为什么不提前将这些不规范的代码转换后再交与 gogocode 处理呢？

于是我们将 vue2 到 vue3 转换的过程拆封成了一下几步

```text
1. 预转换（处理一些不规范和 gogocode 无法识别的代码）
2. gogocode 转换
3. 再次转换 （处理一些 gogocode 转换后，我们并不满意的代码）
```

我们先按照思路简单写下大框

```ts
import glob from "glob";
import execSh from "exec-sh";
import fs from "fs";
import write from "write";

const files = glob.sync(`src/**/*.vue`);

for (let i = 0; i < files.length; i++) {
  const filePath = files[i];

  //  预处理每个文件
  preTransform(filePath, filePath.replace("/src/", "/src-pre/"));
}

// 执行 gogocode
await execSh.promise(
  `npx gogocode -s ./src-pre -t gogocode-plugin-vue -o ./src`,
  {
    cwd: path.resolve(__dirname, "../"),
    stdout: process.stdout,
  }
);

//  after handler
for (let i = 0; i < files.length; i++) {
  const filePath = files;

  //    再次处理每个文件
  afterTransform(filePath);
}

function preTransform(filePath, newPath) {
  let source = fs.readFileSync(filePath, "utf-8");
  write.sync(newPath, source, { overwrite: true });
}

function afterTransform() {
  let source = fs.readFileSync(filePath, "utf-8");
  write.sync(filePath, source, { overwrite: true });
}
```

# preTransform

预处理方法实现

```ts
function preTransform(filePath, newPath) {
  let source = fs.readFileSync(filePath, "utf-8");

  //  https://github.com/thx/gogocode/issues/145
  //  添加 { sourceType: 'module' } 就行了，但是这里就不处理了
  //  如果每个 $ 都添加 { sourceType: 'module' } 这就太麻烦了
  source = source.replace(/import\.meta\.env/g, "import_meta_env");

  //  替换 moment(record.data[col.id] | record.data[col.key])
  source = source.replace(
    `moment(record.data[col.id] | record.data[col.key])`,
    `moment(record.data[col.id] || record.data[col.key])`
  );

  //  替换  watch: { filters: {} }
  //  下面这个代码，把 watch 里面的 filters 也匹配到了
  //  https://github.com/thx/gogocode/blob/8a324770d307990276851c5c78dcfc4f7b4932dc/packages/gogocode-plugin-vue/src/filters.js#L40
  source = $(source, {
    parseOptions: {
      language: "vue",
    },
  })
    .find("<script></script>")
    .replace(
      `watch:{filters:$_$1 , $$$}`,
      `watch:{filters_temporary_preTransform:$_$1 , $$$}`
    )
    .root()
    .generate();

  //  替换
  //  export default mixins().extend({}) => export default {}
  source = $(source, {
    parseOptions: {
      language: "vue",
    },
  })
    .find("<script></script>")
    .replace(
      `export default mixins($$$1).extend({$$$2})`,
      `const MixinsPreFormat = {$$$1};export default {$$$2}`
    )
    .root()
    .generate();

  //  替换
  //  export default mixins().extend({}) => export default {}
  source = $(source, {
    parseOptions: {
      language: "vue",
    },
  })
    .find("<script></script>")
    .replace(`export default mixins().extend({$$$})`, `export default {$$$}`)
    .root()
    .generate();

  //    formatCodes 是 prettier 的 api，用来格式化代码
  write.sync(newPath, formatCodes(source, "vue"), { overwrite: true });
}

export function formatCodes(code, type = "typescript") {
  return prettier.format(code, { semi: false, parser: type });
}
```

# afterTransform

```ts
function afterTransform(filePath) {
  let source = fs.readFileSync(filePath, "utf-8");
  source = source.replace(/filters_temporary_preTransform/g, "filters");
  source = replaceMixinsPreFormat($, source);
  source = replaceVuex2Pinia($, source);

  //  这个一定要放到最后
  //  https://github.com/thx/gogocode/issues/145
  source = source.replace(/import_meta_env/g, "import.meta.env");
  write.sync(filePath, formatCodes(source, "vue"), { overwrite: true });
}

/**
 * 将 vuex 的调用方式替换为 pinia
 * @param $
 * @param source
 */
function replaceVuex2Pinia($, source) {
  let $source = $(source, {
    parseOptions: {
      language: "vue",
    },
  });
  $source = transformMutationsAndActionsInVueFile($, $source).root();
  $source = transformGettersAndStatesInVueFile($, $source).root();
  $source = autoImportStore($, $source).root();

  return $source.generate();
}

/**
 * 将 MixinsPreFormat 放置到 export default {} 中
 * @param $
 * @param source
 */
function replaceMixinsPreFormat($, source) {
  if (source.trim().length === 0) return source;
  let $source = $(source, {
    parseOptions: {
      language: "vue",
    },
  });

  let params = ``;
  $source
    .find("<script></script>")
    .find(`const MixinsPreFormat = {$$$}`)
    .each((item) => {
      params = item.match["$$$$"].map((param) => $(param).generate()).join(",");
    });

  $source
    .root()
    .find("<script></script>")
    .replace(`const MixinsPreFormat = {}`, "");

  if (params.length > 0) {
    return $source
      .find("<script></script>")
      .replace(
        `export default {$$$}`,
        `export default {$$$,mixins:[${params}]}`
      )
      .root()
      .generate();
  }

  return source;
}
```

# 总结

通过对 preTransform 和 afterTransform 方法的扩充，最终达到了 gogocode 转换过程不在报错，而且转换后的代码，也达到了我们预期的效果
