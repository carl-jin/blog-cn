---
title: Google Drive API Client Credentials - 如何开启Google Drive API 并获得客户端证书?
date: 2019-11-16 18:13:59
tags:
  - Google Drive
categories:
  - Front End
  - Google 接口系列
description: 本文将简单介绍, 如何开启Google Drive API 并且获取credentials.json文件, 已经其中的注意事项.
---

首先打开[Google Developers Console](https://console.developers.google.com)

# 步骤一 建立项目

> 如果你已经有项目了,可以直接跳到第二步

依次点击, 左上角的`选择项目`, 在弹出框中点击右上角的`新建项目`. 如下图
![https://i.imgur.com/7f0oJgw.png](https://i.imgur.com/7f0oJgw.png)

按操作点击后, 进入创建界面, 项目名称只能输入字母、数字、英文单引号、连字符、空格或英文感叹号,
而且一旦确定便无法修改, 不过你不想要了还是可以删除重建的, 不管怎么说, 取名需谨慎.
这里因为作为测试, 就取名为`test`, 点击创建即可.(这个过程可能会等几十秒)

# 步骤二 开启 Google Drive APi

> 如果你已经开启过了, 可以直接跳到第三部

创建完成后, 点击左侧的侧边栏的`库`选项卡. 进入 API 库检索页面. 这里我们搜索关键字`Google Drive API`,
点击下图中的搜索结果即可.
![https://i.imgur.com/tSiqwov.png](https://i.imgur.com/tSiqwov.png)

进入详情页后, 我们点击这里的`启动`按钮即可.
![https://i.imgur.com/OHfp2Op.png](https://i.imgur.com/OHfp2Op.png)

# 步骤三 OAuth 配置同意屏幕

> 此配置主要用于当用户使用此 API 时, 展现给用户的描述信息与安全限制.

依次点击左侧侧边栏的`OAuth 同意屏幕`, 这里必须要填写的是`应用名称`与`已获授权的网域`这两项,
其为选填项目, 这里作为测试就留空了.
如果你用于本地测试,在`已获授权的网域`可以留空, 默认 Google 会允许`localhost`这种域名访问,
但是如果你用的是线上环境, 这里必须要填写线上环境的域名, 比如我的网站要用到填写的就是`carljin.com`
![https://i.imgur.com/n1vHGTz.png](https://i.imgur.com/n1vHGTz.png)
完成后点击最下面的`保存`按钮即可.

# 步骤四 创建客户端凭据

依次点击左侧侧边栏的`凭据`选项卡, 点击`创建凭据`选择下拉中的`OAuth 客户端 ID`
![https://i.imgur.com/RKPkxUU.png](https://i.imgur.com/RKPkxUU.png)

这里我们勾选`Web应用`如果你要用在 Android 或者 IOS 上, 选择对应选项即可.
这里主要需要填写的就是`名称`与`已获授权的JavaScript来源`,
需要注意的是在`已获授权的JavaScript来源`选项中, 如果你要用于本地测试, 需要添加本地 URI 的规则
比如我这里本地测试环境为`http://localhost:3000`, 如果线上使用则添加线上的域名即可,
比如我这里的`https://carljin.com`
这里如果不进行填写, 将没有权限调用 API
![https://i.imgur.com/IrQUr7G.png](https://i.imgur.com/IrQUr7G.png)
填写完成后,点击最下面的`创建`按钮即可.

此时你会得到一个`OAuth 客户端`的`clientId(客户端ID)`与`客户端密钥`(注意这里的密钥不是指 API 密钥)
![https://i.imgur.com/Naqmw1v.png](https://i.imgur.com/Naqmw1v.png)
这里并不需要保存, 因为你随时候可以在[Google Developers Console](https://console.developers.google.com)中查看

此时点击刚刚创建的客户端条目,后面的下载图标,即可获取我们需要的`credentials.json`文件
![https://i.imgur.com/ZxaTfa1.png](https://i.imgur.com/ZxaTfa1.png)

# 如何获取 APIKey (API 密钥)

依次点击, `创建凭据`下拉出现的`API 密钥`即可非常简单.
![https://i.imgur.com/FBiel7W.png](https://i.imgur.com/FBiel7W.png)
如果你没什么需求,也可也不对其进行限制, 直接点关闭即可.

# 总结

到此步, 你已经得到了 Google API 调用时需要的两个参数`clientId`与`APIKey`
分别对应的值如下图所示.
![https://i.imgur.com/wN8er9L.png](https://i.imgur.com/wN8er9L.png)
