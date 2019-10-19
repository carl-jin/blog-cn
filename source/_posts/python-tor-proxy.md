---
title: tor + python = 快速安全的免费代理
date: 2019-10-19 17:34:22
tags:
  - python
  - tor
  - proxy
  - 代理
  - vpn
categories:
  - python
description: 免费代理慢?免费代理不安全?免费代理总是被google检测出流量异常? 为何不用现成的Tor作为代理? 本文将介绍如何使用python + Tor获取免费的代理
---

![tor](https://i.imgur.com/SZ1xdH6.png)

# 什么是 Tor?

[Tor](https://www.torproject.org/)即“洋葱路由器”，创造这项服务的目的是让人们匿名浏览互联网。它是一个分散式系统，允许用户通过中继网络连接，而无需建立直接连接。这种方法的好处是，您可以对您访问的网站隐藏 IP 地址，因为您的连接是在不同服务器之间随机变换的，无法追踪您的踪迹。

# 准备工作

1. 安装 Tor 浏览器, 并确保已经运行(即使打开啥都不干都行, 这样才能保证Tor的代理服务器被挂起)
2. 安装 python
3. 安装 python 的[stem](https://pypi.org/project/stem/)模块, stem主要功能就是通过 python 与 Tor 进行交互, 更多具体内容可以到[Stem官网](https://stem.torproject.org/)查看
4. 安装 python 的[requests](https://pypi.org/project/requests/)模块, 该模块可有可无, 主要是用于验证代理是否生效.

# 直接上代码

```python
from stem import Signal
from stem.control import Controller
import requests
import json


def switch_proxy():
    """
    切换 Tor 代理地址
    :return: NULL
    """
    with Controller.from_port() as controller:
        controller.authenticate()
        controller.signal(Signal.NEWNYM)


for i in range(10):
    switch_proxy()
    proxies = {'http': 'socks5://127.0.0.1:9150',
               'https': 'socks5://127.0.0.1:9150'}
    output = requests.get("https://httpbin.org/ip", proxies=proxies)
    print(json.loads(output.content))
```

输出结果. 可以看到每次请求ip地址都切换了.

```bash
{'origin': '36.89.190.223, 36.89.190.223'}
{'origin': '181.118.155.4, 181.118.155.4'}
{'origin': '195.170.15.66, 195.170.15.66'}
{'origin': '181.196.205.250, 181.196.205.250'}
{'origin': '110.74.216.216, 110.74.216.216'}
{'origin': '74.113.173.78, 74.113.173.78'}
{'origin': '178.32.80.238, 178.32.80.238'}
{'origin': '113.203.238.179, 113.203.238.179'}
{'origin': '212.210.138.140, 212.210.138.140'}
{'origin': '193.117.138.126, 193.117.138.126'}
```

# 代码解析

1. 12~14 行代码主要功能是切换代理地址,你可以在官网[stem.Controller](https://stem.torproject.org/api/control.html)中看到详细说明与其他功能的使用
2. 14 行代码就是通知 Tor 我们要换一个信号
   > 官方说法 "signal newnym" will make Tor switch to clean circuits, so new application requests don't share any circuits with old ones.
   > 翻译意思是, `single newnym`会切换一个新的线路, 这条线路上的任何请求都不会跟旧线路有关联.
   > 也就是说我们可以通过`controller.signal(Signal.NEWNYM)`告诉 Tor 我们需要换一个线路(你也可以理解为代理)
3. 19~20 设置`requests`模块的代理地址. 这里需要注意有`2`点

   1. 要想代理服务器生效, 请务必先运行 tor 浏览器且不关闭,因为这样才能保证代理服务器被挂起. 如果你把 tor 浏览器关了,代理服务器也被杀死了.
      ```bash
      #    如果你得到以下报错,就是因为tor浏览器未运行导致代理服务器也没被挂起导致的, 只需要打开tor浏览器就行.
      stem.SocketError: [WinError 10061] No connection could be made because the target machine actively refused it
      ```
   2. port端口号`9150`, 看了一些相关的技术文章中说到Tor的代理服务器是本地`127.0.0.1`端口号为`9050`, 但实际上此时我用的Tor版本是8.5.5默认代理服务器端口号是`9150`
      那么该如何查看端口号呢? 只需到Tor的options面板搜索proxy在Network Proxy弹出框中可以看到SOCKS Host的Port为9150.如下图所示
      ![options](https://i.imgur.com/QIpEoSU.png)
      
备注:
如果你得到以下报错的话

```bash
requests.exceptions.InvalidSchema: Missing dependencies for SOCKS support.
```

是因为 request 需要 socks 支持, 只需安装一下 socks 支持就行了:

```bash
pip install requests[socks]
```

# 声明
此文章主要目的是为了和大家分享,仅供参考学习, 我不容忍任何人以任何目的使用此文章涉及的技术来创建非法的Web爬虫或者任何非法活动.
要注意一点的是, 某些阻止Tor出口节点的IP. 因此即使你使用tor的代理切换了IP也可能在其站点上起不到什么作用.
