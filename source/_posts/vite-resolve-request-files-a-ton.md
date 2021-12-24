---
title: Vite 解决项目刷新慢问题（请求量过大）
date: 2021-12-23 21:17:30
tags:
  - vite
description: Vite 搭建后的项目，在开发过程中，每次刷新都需要等待很久？本文将介绍具体原因以及解决方案
---

## Vite 上的 issues

如果你正在使用 Tailwindcss，那么可能是因为 less 编译问题， 具体解决方法请看 [https://github.com/vitejs/vite/issues/5145](https://github.com/vitejs/vite/issues/5145)

Vite 作者提到了这个加载慢的问题具体请看 [https://github.com/vitejs/vite/issues/1309](https://github.com/vitejs/vite/issues/1309), 这里面说的很清楚，这里就不啰嗦了

基于上面这个讨论，有开发者提交了一个 PR 但是一直没通过，所以他自己 Fork 了一个项目，有兴趣的可以看看 [https://github.com/ArnaudBarre/vite/commit/e7c54c8e5e8fb9968a49b6a835c7e375484082bf](https://github.com/ArnaudBarre/vite/commit/e7c54c8e5e8fb9968a49b6a835c7e375484082bf)

## 优化 1 预构建

如 [vite 官方文档](https://cn.vitejs.dev/guide/dep-pre-bundling.html#the-why) 中提到的，vite 会自动搜索需要预构建的包。但是它不会预构建下面这种写法的包

```typescript
import zhCn from "ant-design-vue/es/locale/zh_CN";
```

可以理解为 vite 只搜索了最外层的 `ant-design-vue` 的引用，如果我们引用的是这个 package 跟深级别的包，则无法自动加入预构建，这时候就需要手动配置下

```typescript
//  vite.config.js
{
  optimizeDeps: {
    include: ["ant-design-vue/es/locale/zh_CN"];
  }
}
```

如何找到这种未进行预构建的包，可以通过分析浏览器请求得到，下图是未被缓存的

![img1](https://imgur.com/SU4hjMI.png)

下图是被缓存的，你可以在 filter 中输入 `node_modules` 来过滤这些请求, 这里可以看到，被缓存过的文件能在请求路径中找到 `.vite`。这个具体原理就不细说了，非本文重点

![Imgur](https://i.imgur.com/xSkBmwV.png)

要想从预构建这块优化，可以通过这种方式分析到底是那个模块加载慢，可以把它放进预构建的配置中

## 优化 2 使用 https
vite 默认会对文件有个类似 304 的缓存效果，如果文件未修改，再次请求时会直接读取缓存，但是使用 Chrome 浏览器时，在某些情况下（具体原因未知）会导致 304 缓存失败，如下图

![Imgur](https://i.imgur.com/F5Ozlbg.png)

这里 Response Headers 中明明是 304 的状态码, 但是 chrome 处理时，还是重新请求了一遍 (200) , 这导致原本应该被 304 缓存的文件，却每次刷新时都需要重新读取一遍，非常消耗性能。这个原因是因为 Chrome 浏览器不缓存 非 https 请求的文件。

具体请看这个 Issue [https://github.com/vitejs/vite/issues/2725](https://github.com/vitejs/vite/issues/2725)

[https://bugs.chromium.org/p/chromium/issues/detail?id=110649#c8](https://bugs.chromium.org/p/chromium/issues/detail?id=110649#c8)  如这个 Issue 中说到的，Chrome 不会对无效的 SSL 证书下面的资源进行缓存。

那么要解决这个问题，我们需要使用这个插件

[https://github.com/liuweiGL/vite-plugin-mkcert](https://github.com/liuweiGL/vite-plugin-mkcert)

安装
```shell
$ npm i vite-plugin-mkcert -D
```

在 vite.config.js 中使用

```typescript
import {defineConfig} from'vite'
import mkcert from'vite-plugin-mkcert'

// https://vitejs.dev/config/
export default defineConfig({
  server: {
    https: true
  },
  plugins: [mkcert()]
})
```

当我们再次运行 vite 的开发浏览器时，就自动添加上证书，还是挺方便的。

# 注意

如果你的 Chrome 浏览器此时依然无法正确处理 304 响应时，那么这个原因是 Chrome 浏览器的政策问题，Chrome 不认自己授权的 SSL 证书

请看这个问题 [https://stackoverflow.com/questions/7580508/getting-chrome-to-accept-self-signed-localhost-certificate](https://stackoverflow.com/questions/7580508/getting-chrome-to-accept-self-signed-localhost-certificate)

对于这种情况，可以按照上文回答的步骤进行操作，把证书添加到本地当中（强烈不建议，因为特别麻烦）

这类建议直接换个浏览器就行了，如果你不想使用 firefox， 可以安装个 Chrome dev 版本 [https://www.google.com/chrome/dev/](https://www.google.com/chrome/dev/) Chrome dev 版本没有 SSL 限制。非常简单

## 优化 3 关掉没用的浏览器插件

浏览器插件特别是拦截广告插件如 ADBlock 和 ADGuard ， 再每次请求资源时候都会拦截请求进行分析，这非常消耗性能，你可以把插件全部关掉（或者在隐私窗口下访问） 能明显感觉到至少 1-2 倍速度的提升。

## 优化 4 使用 https 2

通过分析我们可以发现，刷新时请求量特别大，导致请求经常阻塞，这是因为 https1.1 导致的，chrome 只允许 6 个同时并发，这个是没有其他办法改变的。当我们在 vite 中配置了 `server.https` 为 ture 时，会自动使用 node 中的 http 2

```typescript
import {defineConfig} from'vite'

// https://vitejs.dev/config/
export default defineConfig({
  server: {
    https: true
  },
})
```

但是 vite 在源码中有限制 [https://github.com/vitejs/vite/blob/485e298e72599679e97f0ed1f4315ac5da55da2c/packages/vite/src/node/http.ts#L94](https://github.com/vitejs/vite/blob/485e298e72599679e97f0ed1f4315ac5da55da2c/packages/vite/src/node/http.ts#L94)
```typescript
  if (proxy) {
    // #484 fallback to http1 when proxy is needed.
    return require('https').createServer(httpsOptions, app)
  } else {
    return require('http2').createSecureServer(
      {
        ...httpsOptions,
        allowHTTP1: true
      },
      app
    )
  }
```

如果我们对 `server.proxy` 进行了配置，那么还会依然走 https, 这时候可以通过 [https://www.npmjs.com/package/vite-plugin-http2-proxy](https://www.npmjs.com/package/vite-plugin-http2-proxy) 处理

# 注意
如果你这样配置后， chrome 依然不支持 http2 的话，只能使用 Firefox 了，暂时没找到解决方法
