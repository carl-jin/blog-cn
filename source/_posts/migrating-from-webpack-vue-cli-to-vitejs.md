---
title: 从 Vue-cli 迁移到 vite 的记录
date: 2021-12-26 20:21:37
tags:
  - vite
description: 基于 vue2 + antdv1 + vue-cli 的大项目, 迁移到 vite 的经历
---

# 起因

这个项目是两年前通过 vue cli 搭建基于 vue2 + ant-design-vue 1 和各种 UI 插件搭建的一套类似于 aPaaS 平台.

随着版本的不断迭代, 添加了各种各样的插件, 随着依赖慢慢增加从起初的一个 HMR 只需要几百毫秒, 到现在至少需要 4s.

Webpack 的短板慢慢暴露出来, 很不幸这期间前端团队还恰恰用 vite 写了几个大项目, 因此再也无法忍受 Webpack 了, 因此一致决定迁移到 Vite, 本文记录这个过程中遇到的各种各样的 bug

# 前提条件

因为项目目标群体主要是欧美国家, 而且用户群体可控, 所以就不用考虑低版本浏览器兼容问题, 功能开发均以最新 Chrome 浏览器为标准. 所以本文不会涉及到低版本浏览器兼容问题

# 对比

先看下迁移前后各方面的对比

### 测试电脑

```text
OS: Windows 10 x 64
CPU: (8) x64 Intel(R) Core(TM) i7-6700HQ CPU @ 2.60GHz
Memory: DDR4 x 16GB
Node: 16.7.0
Chrome: Version 96.0.4664.110
```

### 前后对比

| 构建工具 | 服务器启动耗时       | 页面首次加载速度 (无缓存) | 第二次加载速度 (有缓存) | 热更新 HMR | 打包      |
| -------- | -------------------- | ------------------------- | ----------------------- | ---------- | --------- |
| Webpack  | 83s                  | 4.78s                     | 3.35s                   | 4.78s      | 3mins 37s |
| Vite     | 4.72s (第二次 0.72s) | 1.71s                     | 1.33s                   | 瞬间       | 51.45s    |

> 因为 vite 的依赖预构建功能, 所以第二次服务器启动仅需 0.72s
>
> Vite 的热更新实在太快, 秒表都点不急 基本上一保存代码, 瞬间页面就更新了, 所以统计不到时间, 估计也在 300ms 以下

总体来看速度提升的不是一点半点.

### 注意

这里只记录了 HMR 的速度, 对于 Vite 依赖项修改后, 会知道 fully reload 的情况并未计算在内.

另外针对 Vite 刷新页面时候, 需要请求一大堆文件的问题, 测试时做了优化, 请参考这个文章 [Vite 解决项目刷新慢问题（请求量过大）
](https://carljin.com/vite-resolve-request-files-a-ton.html)

# 请不要一时兴起, 就开始迁移到 vite, vite 最头疼的地方就是社区内一些包还不支持 ESM, 而且导出的包并不是严格的 CMD 或者 UMD 规范, 这样会导致 vite 预构建和打包时出错, 如果你还没有心里准备去面对这些问题, 请不要轻易迁移

# 开始迁移

既然我们选择使用最新的技术, 那么我们可以顺便使用最新的 node 去开发, 比如这个项目两年前是用 node 12+ 的版本写的, 这次重构时就使用了 16.7.0 的最新版本, 这样对于 M1 的开发者也比较友好.

## 准备工作

我们先使用最新的 node 稳定版, 你可以安装 [NVM](https://github.com/nvm-sh/nvm) 来管理你的 node 版本, 还是很方便的

```shell
$ node -v
> v16.7.0
```

先建立个新分支, 给自己留个后路

```shell
git checkout -b chore_vite master
```

## 整理 package.json

我们可以先把 `node_modules` 这个文件夹删掉, 然后到 package.json 中删除一些 webpack 所依赖的包.

```json
{
  "devDependencies": {
    "@vue/cli-plugin-babel": "^4.3.0",
    "@vue/cli-plugin-unit-jest": "^4.0.5",
    "@vue/cli-service": "^4.3.0",
    "@vue/test-utils": "1.0.0-beta.29",
    "cache-loader": "^4.1.0",
    "babel-plugin-import": "^1.13.0",
    "babel-preset-env": "^1.7.0",
    "speed-measure-webpack-plugin": "^1.3.3"
  }
}
```

类似于以上的这些包都可以删掉了, 这些包的规则是

1. 跟 webpack 有关, 比如 `cache-loader` `ts-loader` 之类的
2. 跟 vue-cli 有关, 比如 `@vue/cli-service`
3. 跟 babel 有关, 比如 `babel-preset-env` `babel-runtime` 之类的

> 因为我们使用 vite 中集成的 typescript 功能, 所以 babel 就没有必要用了

## 删除配置文件

根目录下的 `babel.config.js` 这类文件可以删掉了.

**请不要删除 vue.config.js 我们还需要它作为依照去配置 vite**

## 安装依赖

现在开始安装 vite

安装 vite

```shell
yarn add vite -D
```

如果你项目使用了 sass 或者 less, 也需要安装下
因为这个项目同时使用了 less (antd) 和 sass , 所以俩都要安装下

```shell
yarn add sass -D
yarn add less -D
```

vite 只支持了 vue3 并没有支持 vue2 所以我们需要社区提供的插件来支持 vue2

[https://github.com/underfin/vite-plugin-vue2](https://github.com/underfin/vite-plugin-vue2)

```shell
yarn add vite-plugin-vue2 -D
```

## 调整文件结构

首先我们将 `/public/index.html` 移动到根目录下面 `/index.html`,

在 `<body />` 闭标签上面添加一行代码 (vite 基础知识不过多解释)

这里需要以相对路径引用之前的入口文件, 绝对路径是不起作用的

```html
<script src="./src/main.js" type="module"></script>
```

## 添加 vite.config.js

在根目录下创建 vite.config.js 内容如下

( vite 的配置项, 这里也不过多解释, 非本文主要内容)

```javascript
import { defineConfig } from "vite";
import { createVuePlugin } from "vue-plugin-vue2";

export default defineConfig(({ command }) => {
  return {
    publicDir: "public",
    base: "/",
    plugins: [createVuePlugin()],
  };
});
```

创建完后, 我们需要根据之前的 `vue.config.js` 文件里面的配置项, 进行配置的替换

但是在此之前, 我们需要先处理下 env 变量获取的问题, 以往是通过以下方式读取 env 变量

```javascript
process.env.APP_SERVE_HOST;
```

但是在 vite 中并不支持 [https://cn.vitejs.dev/guide/env-and-mode.html#env-files](https://cn.vitejs.dev/guide/env-and-mode.html#env-files)

我们需要通过以下方式来获取 env 变量

```javascript
import.meta.env.APP_SERVE_HOST;
```

但是由于 vite 官网中提到

> 为了防止意外地将一些环境变量泄漏到客户端，只有以 VITE\_ 为前缀的变量才会暴露给经过 vite 处理的代码。

我们无法直接使用之前 env 中的变量, 需要统一添加 `VITE_` 前缀,

这是我们不想要的情况 (如果你觉得无所谓, 可以按照 vite 的写法),

我们希望之前的 env 文件不做任何修改, 以避免再其他成员更新这个 chore 分支或者自动部署时出现的一些意外 i 情况.

因此我们需要做下兼容, 打开 `vite.config.js` 添加以下代码

```javascript
import { defineConfig, loadEnv } from "vite";

//  通过 vite 提供的 loadEnv 方法, 将环境变量重新赋值到 import.meta.env 上
import.meta.env = loadEnv("", process.cwd(), "");

export default defineConfig(({ command }) => {
  return {
    publicDir: "public",
    base: "/",
  };
});
```

通过上述的修改, 我们就能保证直接通过以下代码获取 env 变量, 而不需要添加 `VITE_` 前缀

```javascript
import.meta.env.APP_SERVE_HOST;
```

接下来我们根据 `vue.config.js` 中的配置项来配置 `vite.cofnig.js`

### 代理 Proxy

之前的 `vue.config.js`

```javascript
module.exports = {
  // ...

  devServer: {
    host: process.env.APP_SERVE_HOST,
    port: process.env.APP_SERVE_PORT,
    disableHostCheck: true,
    proxy:
      (process.env.APP_API_USE_HTTPS == "true" ? "https://" : "http://") +
      process.env.APP_API_BASE_URL,
  },

  // ...
};
```

修改为 `vite.config.js`

```javascript
export default defineConfig(({ command }) => {
  return {
    //  ...

    server: {
      host: import.meta.env.APP_SERVE_HOST,
      port: import.meta.env.APP_SERVE_PORT,
      proxy: {
        "/api": {
          target:
            (import.meta.env.APP_API_USE_HTTPS == "true"
              ? "https://"
              : "http://") + import.meta.env.APP_API_BASE_URL,
          changeOrigin: true,
        },
      },
    },

    // ...
  };
});
```

### 别名 Alias

之前的 `vue.config.js`

```javascript
module.exports = {
  // ...

  configureWebpack: {
    resolve: {
      alias: {
        "@": path.join(__dirname, "./src"),
      },
    },
  },

  // ...
};
```

有些项目可能没有直接在 `vue.config.js` 中配置 alias, 可能是再 `tsconfig.json` 中配置的, 如下面这个配置

```json
{
  "compilerOptions": {
    "paths": {
      "@/*": ["src/*"]
    }
  }
}
```

修改为 `vite.config.js`

```javascript
export default defineConfig(({ command }) => {
  return {
    //  ...

    resolve: {
      alias: [
        {
          find: "@",
          replacement: path.join(__dirname, "./src"),
        },
      ],
    },

    // ...
  };
});
```

### Scss 全局变量处理

之前的 `vue.config.js`

```javascript
module.exports = {
  // ...

  css: {
    loaderOptions: {
      sass: {
        //  这里全局引用了一些 scss 代码
        prependData: `
                @import "@/assets/scss/variables.scss";
                @import "@/assets/scss/mixins.scss";
                `,
      },
    },
  },

  // ...
};
```

修改为 `vite.config.js`

```javascript
export default defineConfig(({ command }) => {
  return {
    //  ...

    css: {
      preprocessorOptions: {
        scss: {
          additionalData: `
                        @import "@/assets/scss/variables.scss";
                        @import "@/assets/scss/mixins.scss";
                    `,
        },
      },
    },

    // ...
  };
});
```

到这里为止, 一些基本的配置已经迁移完

## 添加 启动脚本

打开 `package.json` 文件, 添加 `server` 和 `build` 命令

```json
{
  "scripts": {
    "serve": "vite",
    "build": "vite build"
  }
}
```

# 兼容处理

到目前为止, 基本的迁移已经结束, 接下来将介绍一些常见的令人头大的问题处理方式

## ant-design-vue moment 兼容

`ant-design-vue` 1.7.8 中因为未兼容 ESM 写法, 部分包的引用会有报错情况, 比如我们再使用 `<a-date-picker>` 组件时, 会包

```text
transforming (359) node_modules\.pnpm\ant-design-vue@1.7.3_vue@2.6.12\node_modules\ant-design-v
be resolved – treating it as an external dependency
transforming (1120) node_modules\.pnpm\lodash@4.17.21\node_modules\lodash\_coreJsData.js'isMome
'isMoment' is not exported by 'node_modules\.pnpm\moment@2.29.1\node_modules\moment\dist\moment
```

这样的错误, 原因是 antd 底层引用 moment 是这样写的.

```javascript
import * as moment from "moment";
```

但是作者没有意向再 antd v1 版本兼容这个问题, 原因是还有很多用户使用的是 vue-cli, 这会影响到他们, 具体情况见

[https://github.com/vueComponent/ant-design-vue/pull/4739](https://github.com/vueComponent/ant-design-vue/pull/4739)

类似的问题还有

[https://github.com/vueComponent/ant-design-vue/issues/2344](https://github.com/vueComponent/ant-design-vue/issues/2344)

[https://github.com/vueComponent/ant-design-vue/issues/3715](https://github.com/vueComponent/ant-design-vue/issues/3715)

解决方法是使用 vite 的插件 [vite-plugin-antdv1-momentjs-resolver](https://www.npmjs.com/package/vite-plugin-antdv1-momentjs-resolver)

```shell
yarn add vite-plugin-antdv1-momentjs-resolver -D
```

在 vite.config.js 中添加这个插件

```javascript
import AntdMomentResolver from "vite-plugin-antdv1-momentjs-resolver";

export default defineConfig(({ command }) => {
  return {
    //  ...

    plugins: [AntdMomentresolver()],

    // ...
  };
});
```

## ant-design-vue 自定义主题兼容

老项目兼容主题是通过引用 `antd.less` 后进行修改达到的, 实现方法是新建 `theme.less` (内容如下), 然后在 main.js 中引入达到的

```less
@import "~ant-design-vue/dist/antd.less"; // 引入官方提供的 less 样式入口文件

// Color
@primary-color: #e95c0a;
// Layout
@layout-header-background: #ffffff;
@body-background: #f3f3f3;
@progress-remaining-color: #e4e4e4;
```

但是在 vite 中, 我们需要在 `vite.config.js` 中进行配置主题

```javascript
export default defineConfig(({ command }) => {
  return {
    //  ...

    css: {
      preprocessorOptions: {
        less: {
          modifyVars: {
            "primary-color": "#e95c0a",
            "layout-header-background": "#ffffff",
            "body-background": "#f3f3f3",
            "progress-remaining-color": "#e4e4e4",
          },
          javascriptEnabled: true,
        },
      },
    },
    // ...
  };
});
```

## 打包时 chart-set 报错

这个原因是 postcss 在合并 css 中会自动添加 chart-set 导致的

```text
> <stdin>:1171:0: warning: "@charset" must be the first rule in the file
    1171 │ @charset "utf-8";
```

见问题

[https://github.com/vitejs/vite/discussions/5079](https://github.com/vitejs/vite/discussions/5079)

[https://github.com/vitejs/vite/issues/5519](https://github.com/vitejs/vite/issues/5519)

解决方法 添加 charset: false 即可

```javascript
export default defineConfig(({ command }) => {
  return {
    //  ...

    css: {
      preprocessorOptions: {
        scss: { charset: false },
      },
    },

    // ...
  };
});
```

但是这只是避免 Postcss 不自动生成 charset 如果你文件或者引用的文中默认已经有了 chart-set,

这样的话是不起作用的. 如果你遇到这种情况, 可以在 `vite.config.js` 中添加个 postcss 插件

```javascript
export default defineConfig(({ command }) => {
  return {
    //  ...

    css: {
      postcss: {
        plugins: [
          {
            postcssPlugin: "internal:charset-removal",
            AtRule: {
              charset: (atRule) => {
                if (atRule.name === "charset") {
                  atRule.remove();
                }
              },
            },
          },
        ],
      },
    },

    // ...
  };
});
```

## 打包后 require, exports 找不到

这个是因为一些依赖的包, 并不是完全按照 ESM 规范导出, 甚至没有按严格的 UMD 或者 CMD 导出, 在 rollup 进行打包时候, module, exports 等变量未能正确转化, 解决方法如下

在 `index.html` 中添加以下代码

```html
<script>
  window.exports = {};
  window.module = {};
</script>
```

## 打包后包 require 引用错误

这个问题还是由于前面提到的依赖包不是按照 ESM 规范导出, 因此在 rollup 编译时, 默认是不处理下面这样的语法的

```javascript
require("jquery");
```

解决方法, 我们需要到 `vite.config.js` 中添加个配置

```javascript
export default defineConfig(({ command }) => {
  return {
    //  ...

    build: {
      target: "modules",
      commonjsOptions: {
        //  改为 ture 后就会转化 require 语法
        transformMixedEsModules: true,
      },
    },

    // ...
  };
});
```

## 启动服务器时报语法错误

如

```text
Failed to parse source for import analysis because the content contains invalid JS syntax. Install @vitejs/plugin-vue to handle .vue files.
```

这是因为之前的老项目, 使用了 jsx 语法, 但是 `vite-plugin-vue2` 默认没有开始 jsx,

我们回到 vite.config.js 给 `vite-plugin-vue` 传递下参数

```javascript
import { defineConfig } from "vite";
import { createVuePlugin } from "vue-plugin-vue2";

export default defineConfig(({ command }) => {
  return {
    publicDir: "public",
    base: "/",
    plugins: [
      createVuePlugin({
        jsx: true,
        jsxOptions: {
          injectH: false,
        },
      }),
    ],
  };
});
```

配置好 `vite-plugin-vue` 我们需要将 .vue 文件中使用到 jsx 语法的 script 标签上添加一个 `lang="jsx"`

如之前的 `home.vue` 中代码为

```vue
<script>
export default {
  methods: {
    showMsg() {
      this.$notification.info({
        description: () => <div>我是通知</div>,
      });
    },
  },
};
</script>
```

在 `<script>` 标签加上 `lang="jsx"` 后变为

```vue
<script lang="jsx">
export default {
  methods: {
    showMsg() {
      this.$notification.info({
        description: () => <div>我是通知</div>,
      });
    },
  },
};
</script>
```

## 依赖包报错

由于依赖包为按照 ESM 编写, 导致启动或者打包时报错, 这种问题是最常见的, 以下列举了根据几个不同情况下对应的处理方式

### 最新包已支持 ESM

这个较为简单, 直接安装最新的包即可

### 作者不维护了

这是最头疼的事情, 有些包已经好几年没更新过了, 要是指望作者更新, 这几乎是不可能的, 因此对于这种情况有两种处理方法

#### Fork 项目自己重构成 ESM

这种方式不是太建议, 一方面比较耗时, 另外调试起来也麻烦, 而且还得打包发布 (用 git+ 下载也行), 这里不推荐

#### 使用本地包替代

这个方法比较推荐, 如果发现依赖的包, 不支持 ESM, 我们可以在本地新建个 `packages` 的文件夹, 将这些不支持 ESM 的包, 修改后放到这个 `packages` 中, 然后修改 `package.json` 中包的引用地址.

比如 `ve-charts` 这个包, 作者已经不维护了, 但是老项目中还是用到, 那么我们可以把这个包从 `node_modules` 中拿到 `packages` 文件夹中, 进行修改后在 `package.json` 中修改为

这样在执行 `yarn install` 时候, 就会使用本地的包. 可控性还比较高

```json
{
  "dependencies": {
    "ve-charts": "file:./packages/ve-charts"
  }
}
```

### iife 包引用报错

这种包可能是 gulp concat 打包的

这是很早之前的打包方式, 将几个 `js` 文件 merge 到一起, 不做任何的处理, 打包出来的文件是一个 `iife`,

这种包需要直接通过 `import` 引用. 或者通过 `<script>` 标签进行引入

因此我们首先需要在 `vite.config.js` 中的 `optimizeDeps` 过滤掉它, 避免 vite 的预构建时报错.

比如这个包文件 `@buff2017/rich-spreadsheet/dist/plugins/plugins.js`

```javascript
import { defineConfig } from "vite";

export default defineConfig(({ command }) => {
  return {
    // ...

    optimizeDeps: {
      exclude: ["@buff2017/rich-spreadsheet/dist/plugins/plugins.js"],
    },

    // ...
  };
});
```

# 优化
现在只是迁移到了 vite, 但是项目加载速度还是需要优化, 具体优化细节可以参考这篇文章

[Vite 解决项目刷新慢问题（请求量过大）](https://carljin.com/vite-resolve-request-files-a-ton.html)
