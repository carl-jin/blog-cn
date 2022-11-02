---
title: 如何将代码部署到 Netlify 上（私人项目）
date: 2022-11-02 17:34:06
description: 公开的 github 项目大家都知道怎么部署了，但是很多时候我们不想在 github 上公开项目，并且还不想为此掏钱，那么今天来看看怎么将私人项目部署到 Netlify 上
---

# 准备工作
1. 我们需要一个通过 **Deploy manually** 部署的项目的 Site ID![https://imgur.com/a/WJqD92t](https://i.imgur.com/xSefnkS.png)
2. 需要一个 Netlify 上的  Personal access tokens
> 关于如何获取这俩东西，不是本文所关心的，你可以自己上网查，很简单，点击下就 ok

# Github action 自动部署
```yaml
# .github/workflows/netlify.yml
name: Build and Deploy to Netlify
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
    
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
        with:
          node-version: 16
          registry-url: 'https://registry.npmjs.org'
      # 安装依赖
      - run: npm install
      # 打包
      - run: npm run build

      # 部署
      - name: Deploy to netlify
        uses: netlify/actions/cli@master
        with:
          # 这里指定下需要部署的目录
          args: deploy --dir=dist --prod
        env:
          # 在 secrets/actions 中配置的 Site ID
          NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
          # 在 secrets/actions 中配置的 Personal access tokens
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
```

# 手动部署
手动部署，我们需要使用 `netlify-cli` 这个包

```shell
$ yarn add netlify-cli -D
```

创建一个文件，用于处理手动部署
```typescript
# deploy.ts
/**
 * 处理部署 Hook_injection.js
 */
import { spawn } from "child_process";

// prettier-ignore
const output = spawn("npx", [
  "netlify",
  "deploy",
  "--dir", "需要部署的 folder 路径",
  "--site", "你的 Site ID",
  "--auth", "你的 Personal access tokens",
  "--prod"
]);

output.stdout.on("data", function (data) {
  console.log("stdout: " + data.toString());
});

output.stderr.on("data", function (data) {
  console.log("stderr: " + data.toString());
});

output.on("exit", function (code) {
  //  @ts-ignore
  console.log("child process exited with code " + code.toString());
});
```

手动执行下即可 `esno deploy.ts`
