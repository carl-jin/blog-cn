---
title: 如何在已经存在的 Vue 项目中添加 PWA 功能
date: 2020-11-25 06:29:36
tags:
  - PWA
  - VUE
categories:
  - blog
description: 如何在已经存在的 Vue 项目中添加 PWA 功能
---

# 如何在已经存在的 Vue 项目中添加 PWA 功能

使用 vue-cli 创建的项目, 可以在生成的时候, 够选 PWA 功能, 但是如果已经创建好的 Vue 项目该如何添加 PWA 呢?

# 步骤

1. 首先在项目根目录下安装 `@vue/cli-plugin-pwa`和`register-service-worker`

```shell
npm i -D @vue/cli-plugin-pwa register-service-worker
```

2. 在`@`(src)目录下创建`registerServiceWorker.js`文件, 内容如下

```js
import { register } from "register-service-worker";

register(`${process.env.BASE_URL}service-worker.js`, {
  enabled: true,
  registrationStrategy: "registerImmediately",
  ready() {
    console.log(
      "App is being served from cache by a service worker.\n" +
        "For more details, visit https://goo.gl/AFskqB"
    );
  },
  registered() {
    console.log("Service worker has been registered.");
  },
  cached() {
    console.log("Content has been cached for offline use.");
  },
  updatefound() {
    console.log("New content is downloading.");
  },
  updated() {
    console.log("New content is available; please refresh.");
  },
  offline() {
    console.log(
      "No internet connection found. App is running in offline mode."
    );
  },
  error(error) {
    console.error("Error during service worker registration:", error);
  }
});
```

3. 配置`vue.config.js`文件, 添加`pwa`属性, 内容如下

```js
module.exports = {
  pwa: {
    name: "项目名称",
    themeColor: "#2F54EB",
    msTileColor: "#fff",
    appleMobileWebAppCapable: "yes",
    appleMobileWebAppStatusBarStyle: "black",
    manifestOptions: {
      short_name: "system",
      // https://github.com/jcalixte/vue-pwa-asset-generator
      // 可以通过上面这个项目生成icons包, 很方便
      icons: {
        "src": "/icons/android-chrome-192x192.png",
        "sizes": "192x192",
        "type": "image/png"
        },
        {
            "src": "/icons/android-chrome-512x512.png",
            "sizes": "512x512",
            "type": "image/png"
        },
      description: "一个测试的项目",
      // 这个值是生存在manifest文件中, 如果需要网页显示添加到主屏功能的话, 这个地方一定得设置对
      // 这个start_url因该和你得manifest文件存放得相对路径一致, 比如此项目的manifest文件存放在/admin/目录下
      // 结尾的 / 务必写上
      start_url:"/admin/",
      background_color: "#fff",
      display: "standalone"
    },
    //  此处使用的是 InjectManifest 这意味着我们可以通过serviceworker实现更多的功能
    workboxPluginMode: "InjectManifest",
    workboxOptions: {
      // swSrc is required in InjectManifest mode.
      swSrc: "src/service-worker.js",
      swDest: "service-worker.js"   //  此处输出的service-worker.js文件位置, 会相对于 outputDir 目录进行存放
    }
  }
 }
```

4. 在`@`(src)目录下, 创建`service-worker.js`

```js
self.__precacheManifest = [].concat(self.__precacheManifest || []);
workbox.precaching.precacheAndRoute(self.__precacheManifest, {});

self.addEventListener("message", event => {
  if (event.data.action == "SKIP_WAITING") self.skipWaiting();
});

//  再此文件中可以添加更多的功能, 如Notification
```
