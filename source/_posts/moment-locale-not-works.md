---
title: momentjs 切换语言失效
date: 2022-03-01 15:50:32
description: Moment js 切换语言失效
---

尝试下面这种写法

```typescript
import moment from 'moment/dist/moment';
import zhCn from 'moment/dist/locale/zh-cn';
moment.locale('zh-cn',zh);
```
