---
title: Webstorm 中配置 vue3 + antd Vue + tailwindcss 开发环境
date: 2022-04-26 21:17:13
tags:
  - Front End
  - Webstorm
description: 记录处理 Webstorm 不提示语法，或者提示混乱等一系列问题
---

# 背景
既然要折腾，我们先看下 webstorm 中有哪些不理想的问题

1. HTML 中编写 Tag 的 class 属性，提示混乱，甚至把 node_modules 里面的样式名称都提示出来了，见 [How to exclude class name (html class attr) suggestions from node_modules?][https://youtrack.jetbrains.com/issue/WEB-55582]
2. antd 按需引入时，使用组件没有任何的语法提示
3. ~~vue3 的 setup 支持不佳~~
4. ~~tailwindcss 支持不佳~~

# class 提示问题
因为我们使用了 tailwindcss 理所应当的希望编辑代码时候，能有样式名称的提示。但是它好像索引了整个 node_modules 中的样式文件

![img](https://youtrack.jetbrains.com/api/files/74-1317882?sign=MTY1MTI3NjgwMDAwMHwxMS0xfDc0LTEzMTc4ODJ8WDVNVWFhd2ZpZlhlTV9OY2hLQVZaMm5pSVhL%0D%0ARVNiaWhHRVJwSlp0NFh2Zw0K%0D%0A&updated=1650311954043)

即使我们设置了 exclude 也没用

![img](https://youtrack.jetbrains.com/api/files/74-1317886?sign=MTY1MTI3NjgwMDAwMHwxMS0xfDc0LTEzMTc4ODZ8alBGSlVKY09wV1hWanhDTHladmZzb0h5N1h3%0D%0ASGJRYkxIREhUMHk0X3pQTQ0K%0D%0A&updated=1650312064180)

## 解决方法
这个原因是，项目中默认会在 `Preferences | Languages & Frameworks | JavaScript | Libraries` 中默认存在一个 `node_modules` 的配置，因此导致即使我们把 node_modules 的文件夹设置为 exclude, 但是它依然会索引 node_modules 里面的文件。

我们只需要把它左边的复选框取消掉勾选即可

## 注意
如果我们把 node_modules 左边的复选框取消掉后，会导致整个项目的代码提示（只要涉及到 npm 的包）都会失效，比如 vue, vue-router, pinia 我们如果在 script 中编写 composition api 现在直接自动引入都没有了。

这个原因是我们把 node_moduels 取消后，关于 vue 包的索引都消失了，我们需要照葫芦画瓢把 vue 这个库的依赖再次添加到 `Preferences | Languages & Frameworks | JavaScript | Libraries` 中， 

点击右侧的 `ADD` 后，添加对应的几个需要代码提示的包即可，比如 `vue, @vue`

后续如果遇到有些 npm 的包，我们在编写代码时，没有语法提示，也不会自动引入时，我们只需要在此处进行下配置即可

## 后续
此时会出现一个矛盾的问题，比如一个包，我们需要提示里面的 js 代码部分，比如导出的 methods 或者变量，但是同时也不希望它的 css 文件被索引

如果我们直接讲这个包，添加到 `Libraries` 中，它会同时给 css 文件建立索引。

为了解决这个问题，我们只需要讲这个包导出的文件，添加到配置文件中即可 (按住 shift 键可以加选)

# antd 语法提示
语法不提示问题请参考
[如何修复 WebStorm 不提示 antd-vue 3 的组件问题](https://carljin.com/webstorm-antd-vue-intelligent-code-completion.html)

# vue3 的 setup 支持不佳
截止到当前最新的 2022.1.1 版本已经对 vue3 的支持很完善了，[https://youtrack.jetbrains.com/issue/WEB-46511](https://youtrack.jetbrains.com/issue/WEB-46511) 更新下编辑器版本即可

# tailwindcss 支持不佳
截止到当前最新的 2022.1.1 版本已经对 tailwindcss 的支持很完善了，[https://www.jetbrains.com/help/webstorm/tailwind-css.html](https://www.jetbrains.com/help/webstorm/tailwind-css.html) 更新下编辑器版本即可