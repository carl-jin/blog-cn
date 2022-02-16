---
title: 使用 Chrome Extension Manifest 3 来处理 CORS 限制 
date: 2022-02-16 08:47:04
tags:
  - chrome
categories:
  - Front End
description: 对于前端开发者来说，在调用外部接口，或者通过 AJAX 请求资源时，时常会出现 CORS 报错。如果搭建个 CORS 的 proxy 每次都开着还要配置 proxy，有点麻烦，本文将介绍如何使用 Chrome Extension 来解决 CORS 限制
---

# 实现

首先我们来建立一个文件夹，里面包含 `manifest.json`

```json
{
  "name": "CORSAnyWhere",
  "version": "1.0",
  "manifest_version": 3,
  "declarative_net_request": {
    "rule_resources": [
      {
        "id": "ruleset_1",
        "enabled": true,
        "path": "rules_1.json"
      }
    ]
  },
  "action": {},
  "permissions": ["declarativeNetRequest", "declarativeNetRequestFeedback"],
  "host_permissions": ["*://*/*"]
}
```

首先来看 `host_permissions` 这是一个类似于通配符的数组，这个数组用于声明我们将插件的处理范围应用到哪些网站中，下面是几个规则的例子

1. 固定的网址，比如我们只需要处理某个固定的域名上的接口，那么这里的`host_permissions` 可以设置为 `["https://gogole.com/*","https://youtube.com/*]`
2. 所有 https 请求 `["https://*/"]`
3. 所有请求 `["*://*/*"]`

让我们来看看 `permissions` 的值，因为我们需要修改响应头的信息，所以需要 `declarativeNetRequest`, `declarativeNetRequestFeedback` 这俩个限。

关于 `declarative_net_request` 的配置这里指定了 `rule_resources` 的配置文件，我们在目录下新建一个 `rules_1.json` 里面的内容如下

```json
[
  {
    "id": 1,
    "priority": 1,
    "action": {
      "type": "modifyHeaders",
      "responseHeaders": [
        {
          "header": "Access-Control-Allow-Origin",
          "operation": "set",
          "value": "*"
        }
      ]
    },
    "condition": { "urlFilter": "|https*", "resourceTypes": ["xmlhttprequest"] }
  }
]
```

这个文件需要注意的有 3 个地方，

# responseHeaders 设置

因为我们要解决请求接口 CORS 报错的问题，也就是在 `responseHeaders` 上添加一个头信息 `Access-Control-Allow-Origin: *` 所以我们在这里配置了头信息的设置

# urlFilter 设置
urlFilter 是基于我们刚刚在 manifest 中配置的 `host_permissions` 基础上，进行了进一步的控制，这里我们设置为了 `|https*` , 这个与正则的写法还不一样，
这里的 `|` 意思相当于正则中的 `^`, 更多的语法可以参考 google 的文档 [urlFilter 配置](https://developer.chrome.com/docs/extensions/reference/declarativeNetRequest/#:~:text=The%20pattern%20which%20is%20matched%20against%20the%20network%20request%20url.%20Supported%20constructs)

# resourceTypes
resourceTypes 是基于 `host_permissions` , `urlFilter` 之后再次进一步细节的控制，用来限定那些类型的请求会被处理，这里我们传入了 `xmlhttprequest` ，这代表着只有 ajax 的请求才会添加 CORS header，具体配置可以参考 [resourceTypes 配置](https://developer.chrome.com/docs/extensions/reference/declarativeNetRequest/#:~:text=This%20describes%20the%20resource%20type%20of%20the%20network%20request)

# 总结
这个插件非常简单，也就俩文件，他们分别是

# manifest.json
```json
{
  "name": "CORSAnyWhere",
  "version": "1.0",
  "manifest_version": 3,
  "declarative_net_request": {
    "rule_resources": [
      {
        "id": "ruleset_1",
        "enabled": true,
        "path": "rules_1.json"
      }
    ]
  },
  "action": {},
  "permissions": ["declarativeNetRequest", "declarativeNetRequestFeedback"],
  "host_permissions": ["*://*/*"],
  "icons":{
      "16":"./icons/favicon-16x16.png",
      "32":"./icons/favicon-32x32.png",
      "128":"./icons/apple-touch-icon.png"
  }
}
```

# rules_1.json
```json
[
  {
    "id": 1,
    "priority": 1,
    "action": {
      "type": "modifyHeaders",
      "responseHeaders": [
        { "header": "Access-Control-Allow-Origin", "operation": "set", "value": "*" }
      ]
    },
    "condition": { "urlFilter": "|https*", "resourceTypes": ["xmlhttprequest"] }
  }
]
```
