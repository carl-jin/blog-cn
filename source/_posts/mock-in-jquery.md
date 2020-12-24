---
title: mock-in-jquery
date: 2020-12-23 19:22:25
tags:
  - 模拟数据
  - jquery
  - mock
categories:
  - Front End
description: 如何在Jquery中使用mock.js模拟数据?
---

# jquery-mockjax

要想使 jquery 与 mock.js 结合使用, 我们需要使用 mock.js 衍生出的包[jquery-mockjax](https://github.com/jakerella/jquery-mockjax)

# 安装

#### 可以通过网页引入

```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery-mockjax/2.6.0/jquery.mockjax.min.js"></script>
```

#### 或者使用 webpack 引入

下载

```shell script
$ npm i jquery-mockjax -D
```

引入

```js
import "jquery-mockjax/dist/jquery.mockjax.min.js";
```

# 使用

在使用之前, 确保已经引入 jquery, 并且需要在 jquery-mockjax 之前引入 jquery

创建 mock.js, 内容为下

具体配置可以查看官方文档[jquery-mockjax](https://github.com/jakerella/jquery-mockjax)

```javascript
$.mockjax({
  //  需要拦截的$.ajax请求地址
  url: "/pictures",
  //  response里面定义要返回的模拟数据
  response: function(settings) {
    let array = [];
    let widths = [282];
    let heights = [282, 390, 450, 200, 320, 500, 352, 100];
    for (let i = 0; i < 20; i++) {
      let randomSize = {
        width: widths[Math.floor(Math.random() * widths.length)],
        height: heights[Math.floor(Math.random() * heights.length)]
      };
      array.push({
        id: Math.ceil(Math.random() * 9999),
        link: "###",
        title: "我是标题",
        like: Math.ceil(Math.random() * 9999),
        cover: {
          src: `http://dummyimage.com/${randomSize.width}x${randomSize.height}`,
          width: randomSize.width,
          height: randomSize.height
        }
      });
    }
    //  赋值给 responseText 即可
    this.responseText = {
      data: array,
      meta: {
        total: 4,
        current: settings.data.page
      }
    };
  }
});
```

该文件可以在 html 中引入

```html
<script src="./mock.js"></script>
```

或者通过 webpack 引入

```javascript
import "./mock.js";
```

> 注意: 不管以哪种方式引用, 请确保引用文件的顺序, jquery -> jquery-mockjax -> mock.js

引用后, 直接按正常使用`$.ajax`方法即可.

只要`mock.js`中配置的接口路径能正确匹配, 就会拦截请求, 返回模拟的数据

```javascript
$.ajax({
  url: "/pictures",
  data: this.query
}).then(data => {
  //  这里接受到的data就是上文定义的 this.responseText 里面的内容
  console.log(data);
});
```

# 提示

如果发现即使按照正确方式引入文件

`jquery -> jquery-mockjax -> mock.js -> $.ajax`

依然没有拦截数据, 请检查 接口请求路径是否一致, 并且保证,

mock.js 中使用的 jquery 与\$.ajax 调用的 jquery 是同一个 jquery

(页面有可能会出现引入两次 jquery 的问题)
