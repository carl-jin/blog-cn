---
title: socket 连接不上（前端）问题排查
date: 2022-03-01 10:16:52
tags:
  - socket
categories:
  - Front End
description: socket.io 一直调用 polling （5s 一次）但是死活也连接不上
---

# 问题描述

不知什么时候开始，socket.io 一直连接不上，接口未报错，请求也正确返回了，但是就是一直 polling

```text
XHR?EIO=4&transport=polling&t=Nz64TWU
XHR?EIO=4&transport=polling&t=Nz64Uxr
XHR?EIO=4&transport=polling&t=Nz64WSS
XHR?EIO=4&transport=polling&t=Nz64YD1
XHR?EIO=4&transport=polling&t=Nz64ZbS
XHR?EIO=4&transport=polling&t=Nz64b3e
XHR?EIO=4&transport=polling&t=Nz64cXX
XHR?EIO=4&transport=polling&t=Nz64eCf
XHR?EIO=4&transport=polling&t=Nz64fmH
XHR?EIO=4&transport=polling&t=Nz64hK7
XHR?EIO=4&transport=polling&t=Nz64iml
XHR?EIO=4&transport=polling&t=Nz64kMs
XHR?EIO=4&transport=polling&t=Nz64luP
XHR?EIO=4&transport=polling&t=Nz64nR4
XHR?EIO=4&transport=polling&t=Nz64pAJ
XHR?EIO=4&transport=polling&t=Nz64qyl
XHR?EIO=4&transport=polling&t=Nz64sSR
```

前端代码是这样写的

```typescript
import Echo from "laravel-echo";
import ioClient from "socket.io-client";

window.io = ioClient;
window.Echo = new Echo({
  broadcaster: "socket.io",
  host: "https://example.com",
});
```

对应的版本为

```text
"socket.io-client": "^4.4.0",
"laravel-echo": "^1.11.3",
```

# 解决方法

将从 npm 依赖的包，采用远程加载即可

在 html 引用 script 文件

```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/laravel-echo/1.10.0/echo.iife.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/socket.io-client@2/dist/socket.io.js"></script>
```

这里我们就直接调用 window 上的对象即可

```typescript
window.Echo = new window.Echo({
    broadcaster: 'socket.io',
    host: import.meta.env.VITE_APP_ECHO_SERVER,
    auth: { headers: { Authorization: 'Bearer ' + token } }
});
```

具体原因不清楚，但是如果通过 `import` 方式引用 `socket.io-client` 就一直 `polling` 。

但是通过 script 标签引用就没问题（🤔 奇怪了）
