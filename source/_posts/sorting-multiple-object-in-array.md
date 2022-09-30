---
title: 针对对象数组进行多重排序
date: 2022-08-28 21:14:52
description: 对象数组 Object[] 中针对字段，进行多次排序
---

# 快捷通道
如果你的数组的多重排序需求是写死的，可以使用 [thenby](https://www.npmjs.com/package/thenby)

只需要下面几行就 ok 了
```javascript
data.sort(
    firstBy(function (v) { return v.name.length; })
    .thenBy("population")
    .thenBy("id")
);
```

# 场景

我们来看看，如果这个过滤规则是动态，比如 table 上面的字段过滤，我们应该如何处理


```javascript

//  假设我们有一个数组 需要进行多重排序
const rows = [
  {
    fields: {
      price: 19,
      value: 8,
      name: "hotdog",
    },
  },
  {
    fields: {
      price: 12,
      value: 2,
      name: "buger",
    },
  },
  {
    fields: {
      price: 19,
      value: 44,
      name: "coolcat",
    },
  },
];

//  这里的 sortConfigs 是动态的
const sortConfigs = [
  { field: "price", mode: "asc" },
  { field: "price", mode: "desc" },
];

const customSorter = function (left, right, field): number {
  return left.fields[field] - right.fields[field];
};

//  这里是参考 antd vue 的思路
//  https://github.com/vueComponent/ant-design-vue/blob/797a1c6c8f6757048bf7356dba935e1a9d0508ed/components/table/hooks/useSorter.tsx#L272
rows.sort((left, right) => {
  for (let i = 0; i < sortConfigs.length; i++) {
    const currentConfig = sortConfigs[i];
    const field = currentConfig.field;
    const mode = currentConfig.mode;
    let res = customSorter(left, right, currentConfig.field);

    //  最关键的是下面这个判断，
    //  for 循环会把每个排序规则都执行一遍
    //  如果当前规则下，res 的值为 0 时，则进行 continue 这样下一条规则就会继续执行排序
    //  如果 res 不等于 0，则代表排序已完成
    if (res !== 0) {
      return mode === "asc" ? res : res * -1;
    }
  }

  return 0;
});
```
