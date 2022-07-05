---
title: 使用 dayjs 将时间按照不同时区显示
date: 2022-07-05 17:47:31
tags:
  - dayjs
categories:
  - Front End
description: 服务器返回的时间字符串，需要按用户所在地区，显示成对应的时间。来一起看看 dayjs 中如何处理
---

# 解决方案

假设我们需要将韩国时间 `Asia/Seoul` 2022-07-05 23:42:48 转换为美国用户 `America/New_York` 显示的时间.

```typescript
import dayjs from 'dayjs'
import utc from 'dayjs/plugin/utc';
import timezone from 'dayjs/plugin/timezone'

//  我们先将韩国时间转换成 moment 对象
let b = dayjs.tz("2022-07-05 23:42:48", "Asia/Seoul")
const timestamp2 = b.utc().unix()
console.log(dayjs.unix(timestamp2).tz('America/New_York').format('YYYY-MM-DD HH:mm:ss'),'dayjs')
```
