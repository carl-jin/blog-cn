---
title: vue cli 4， 关闭代码拆分
date: 2021-06-04 11:33:31
tags:
- front-end
- vue
- vue-cli
- webpack
description: vue-cli^4.0.0 版本以后，将会自动启用代码拆分功能，而且通过vue-cli 3的版本配置方式无法关闭 SplitChunksPlugin。 本文将介绍如何在vue cli 4版本中关闭SplitChunksPlugin
---

### 直接关闭代码拆分
```javascript
//  vue.config.js
//  在 chainWebpack 中添加以下配置
module.exports = {
  // ...
  chainWebpack: config =>{

    //  需要判断下只在生产环境中运用
    //  如果在开发环境中也这样配置， 会导致devtool的map功能失效
    if (process.env.NODE_ENV !== "development") {
      const webpack = require("webpack");
      
      //  使用 limitChunkCountPlugin 插件关闭代码拆分
      config
        .plugin("limitChunkCountPlugin")
        .use(webpack.optimize.LimitChunkCountPlugin, [
          {
            maxChunks: 1,
          },
        ]);
    }
    
  }
  // ...
}
```