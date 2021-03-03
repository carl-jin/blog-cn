---
title: 格式化树状数据 
date: 2021-03-03 14:06:33 
tags:
  - front-end 
categories:
  - Front End 
description: 借鉴Vue AST 生成思路
---

### 假设有以下一组数据

每条数据的`pid`为其父级数据的`id`字段, 如果为顶层父级数据`pid`则为0

```typescript
export default [
  {
    id: 2,
    pid: 0,
    name: "Application Config"
  },
  {
    id: 3,
    pid: 2,
    name: "errorHandler"
  },
  {
    id: 4,
    pid: 2,
    name: "warnHandler"
  },
  {
    id: 5,
    pid: 3,
    name: "warnHandler detail"
  },
  {
    id: 6,
    pid: 0,
    name: "Application API"
  },
  {
    id: 7,
    pid: 6,
    name: "component"
  },
  {
    id: 8,
    pid: 6,
    name: "config"
  }
]

```

下面代码展示如何将其格式化成树状结构

```javascript
import Data from './data'

console.log(formatData2Tree(Data))

function formatData2Tree(data) {
  //  首先将数据分成两份, 
  //  1份为顶级的父级数据 也就是pid === 0
  //  另一份为子级数据, 也是pid !== 0, 这些数据可能也是父级数据
  let parents = data.filter(p => p.pid === 0)
  let children = data.filter(c => c.pid !== 0)

  dataToTree(parents, children)

  //  递归实现
  function dataToTree(parents, children) {
    parents.map(p => {
      children.map((c, i) => {
        if (c.pid === p.id) {
          let _c = JSON.parse(JSON.stringify(children))
          _c.splice(i, 1)
          dataToTree([c], _c)

          if (p.children) {
            p.children.push(c)
          } else {
            p.children = [c]
          }
        }
      })
    })
  }
  
  return parents
}

```