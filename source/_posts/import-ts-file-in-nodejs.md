---
title: 如何在 node js 中引用 ts 文件
date: 2023-03-10 09:41:51
description: 如何在 node.js 中引用 ts 文件，并将其中的变量导出后生成对应的描述文件。文中以在使用 vite 开发项目中生成 CSS 描述文件为例，通过打包 ts 文件，获取 output.code，并通过 vm Script 运行代码来获取 colors 变量。最后，根据 colors 变量生成 CSS 代码，写入指定的文件中。
---

# 需求

我们在使用 vite 开发项目中，遇到一个需要在打包前，将 ts 文件中的变量导出后，生成对应的描述文件，比如以下场景

```typescript
// src/vars.ts
import redColor from './red

const colors = {
  red: redColor,
  white: "#fff",
};
export { colors };
```

我们希望在 vite 的 configServer 和 beforeBuild 这两个钩子之前，将 `src/vars.ts` 中的 colors 获取到，然后将其生成一个对应的 `src/colors.css` 文件，里面内容为

```css
.color-red {
  color: #f20;
}
.color-white {
  color: #fff;
}
```

如果仅仅通过添加一个 watch 脚本来通过正则处理，这不是太理想，因为 `vars.ts` 中还可能包含引入的 module，直接通过 `import('src/vars.ts'')` 的写法，会在 node 中报错，无法处理 `.ts` 文件

因此我们的思路是，首先以 `vars.ts` 作为入口文件，然后通过 vite 将其打包后，获取到 output.code，然后让 node 运行 output.code 得到最终的 colors

因为本身我们就是使用 vite 所以直接用 vite 提供的 build 来打包

```typescript
import { build } from "vite";
import path from "path";
import Ajv from "ajv";
import vm from "vm";
import fs from "fs-extra";

const entryFilePath = path.join("src", "vars.ts");
const outputFolderPath = path.join("src", "color.css");

function runBuild() {
  const filePath = `${process.cwd()}/${entryFilePath}`;
  const outputPath = `${process.cwd()}/${outputFolderPath}`;
  buildCsss(filePath, outputPath);
}

function buildCsss(filePath, outputPath) {
  console.time("Pre Complied CSS");
  build({
    mode: "development",
    root: `${process.cwd()}/src`,
    build: {
      write: false,
      commonjsOptions: {
        esmExternals: true,
      },
      emptyOutDir: false,
      sourcemap: false,
      cssCodeSplit: false,
      minify: false,
      lib: {
        entry: filePath,
        //  注意，由于我们需要将文件打包到一起，所以用的 iife 格式
        //  这里给一个全局名称，方便等等在上下文中获取
        name: "_",
        formats: ["iife"],
      },
    },
  }).then((data) => {
    const script = new vm.Script(data[0].output[0].code);
    const ctx: any = {};
    script.runInNewContext(ctx);

    //  获取到 vm 执行后上下文中的 colors
    const colors = ctx._.colors;

    //  todo 根据 colors 变量生成 css 代码
    const cssCode = "";

    fs.ensureDirSync(path.dirname(outputPath));
    fs.writeFileSync(outputPath, cssCode);

    console.timeEnd("Pre Complied CSS");
  });
}

runBuild();
```

# 总结

通过 vite 首先将 ts 文件打包成单个的 iffe 格式文件，
然后通过 vm Script 来执行它，这样就能从上下文中获取到 colors
后续如何生成文件，这个就比较简单了
