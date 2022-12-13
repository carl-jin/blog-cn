---
title: 移动端开发路上的坑
date: 2019-10-29 21:11:18
tags:
  - 移动端开发
  - Web开发
categories:
  - Front End
description: 在平时的H5移动端开发时，我们难免会遇到各种各样的坑点，这篇文章就带着大家来看看怎么解决，文章较长，建议收藏方便以后查阅！
---
> 本文转载自一位不愿透露姓名的开发者

# 前言

在平时的 H5 移动端开发时，我们难免会遇到各种各样的坑点，这篇文章就带着大家来看看怎么解决，文章较长，建议收藏方便以后查阅！

## 弹出框中的滚动事件冒泡导致 body 也滚动

如下图所示，当弹出框内容在滚动时，如果滚动到边界，会导致页面内容也会跟着滚动
![](https://i.imgur.com/sUl9iBK.jpg?200x)

#### 解决方案 一

在显示对话框时，将 `html` 和 `body` 的 `height` 都设置为 100%，`overflow` 都设置为 `hidden`，`position` 都设置为 `relative`, 然后在对话框关闭时将 `html` 和 `body` 的 `height` 与 `overflow` 属性都设置为 `auto`。

##### 缺点

当瞬间给 html 和 body 身上设置`{height:100%;overflow:hidden;position:relative;}`时，页面会返回到顶部，性能会受影响。

#### 解决方法

当弹框弹出时记录下此时的滚动条高度，当关闭弹框时 赋值给 window

```javascript
var offsetTop = window.scrollTop;
window.scrollTo(0, offsetTop);
```

#### 解决方案 二

在 body 内加一层`div.scroll-wrapper`，这个 div 包含页面的所有显示内容但不包含弹出框，`.scroll-wrapper`和`html`还有`body`的`height`都为`100%`，
`html`和`body`的`overflow`为`hidden`，`.scroll-wrapper`的`overflow为scroll`。
让`.scroll-wrapper`的`div`来控制页面内容的滚动。
因为弹出框是通过 fix 布局不属于`.scroll-wrapper`的子元素，所以滚动不会冒泡到`.scroll-wrapper`上。
DOM 结构：

```html
<body>
  <div class="scroll-wrapper">
      <div class="banner">
          banner
      </div>
      <div class="content">
          <p>p </p>
      </div>
  </div>
  <div id="mask">
</body>
```

CSS 代码

```css
html,
body {
  height: 100%;
  overflow: hidden;
}
.scroll-wrapper {
  overflow: scroll;
}
```

##### 缺点

1. js 无法监听 window 的滚事件，以及元素 的 offsetTop 值也会随页面滚动变化 （页面需要用到的 window.scrollTop 和 offsetTop 时）
2. ios 设备上自设的滚动条相当卡顿，下面会提到。

### 最终解决方案：😄

当触发弹出层时禁止 document 身上的默认触摸行为：

```javascript
document.addEventListener("touchmove", _preventDefault, { passive: false });
```

> passive: false 这个必须得加，兼容 ios.
> 当关闭弹出层时开启 document 身上的触摸行为：

```javascript
document.removeEventListener(
  "touchmove",
  ev => {
    ev.preventDefault();
  },
  { passive: false }
);
```

## ios 设备自定义滚动条不流畅问题

#### 解决方案 一

给滚动元素添加 css 属性：

```css
-webkit-overflow-scrolling: touch;
```

> 原理：这也可以开启了 IOS 系统的硬件加速功能，所以会提升用户体验。

##### 缺点

###### 缺点 1. 在苹果手机上使用了`-webkit-overflow-scrolling:touch;`后，

可能会导致使用`position:fixed;`固定定位的元素，随着页面一起滚动，只有滚动停止时才会恢复原位，但是如果不用`-webkit-overflow-scrolling:touch;`这个属性的话，
使用`overflow-y:scroll`;属性的盒子滑动就会非常不流畅。

###### 对应处理方法

使用 overflow-y 属性的元素不应该和固定元素在一个层级，使用 overflow-y 属性的元素外面加一层和固定元素在同一层级可以解决该问题。

###### 缺点 2. 最严重的，页面会出现假死，滚动到底部，滚不动了。

为什么会有卡住不动的这个 bug？
最常见的例子就是：

1. 在 safari 上，使用了-webkit-overflow-scrolling:touch 之后，页面偶尔会卡住不动。
2. 在 safari 上，点击其他区域，再在滚动区域滑动，滚动条无法滚动的 bug。
3. 通过动态添加内容撑开容器，结果根本不能滑动的 bug。
   这个 bug 产生于 ios8 以上（不十分肯定，但在 ios5~7 上需要手动使用 translateZ(0)打开硬件加速）。
   Safari 对于 overflow-scrolling 用了原生控件来实现。
   对于有-webkit-overflow-scrolling 的网页，会创建一个 UIScrollView，提供子 layer 给渲染模块使用。

###### `-webkit-overflow-scrolling:touch`的其他坑：

除此之外，这个属性还有很多 bug，包括且不限于以下几种：

1. 滚动中 scrollTop 属性不会变化
2. 手势可穿过其他元素触发元素滚动
3. 滚动时暂停其他 transition

###### 对应处理方法

1. 保证使用了该属性的元素上没有设置定位
   如果出现偶尔卡住不动的情况，那么在使用该属性的元素上不设置定位或者手动设置定位为 static
   ```css
   position: static;
   ```
   这样会解决`部分`因为定位(relative、fixed、absolute)导致的页面偶尔不能滚动的 bug。
   但是滑动到顶部继续手指往下滑，或者到底部继续往上滑，还是会触发卡住的问题（其实是整个页面上下回弹），说他算 bug，其实就是 ios8 以上的特性，
   如果滚动区域大一点，用户不会觉得这是 bug，如果小了，用户会不知道发生了什么而卡住了。
   视频在这，[https://www.youtube.com/watch?v=MkAVYbO_joo](https://www.youtube.com/watch?v=MkAVYbO_joo)
2. 如果添加动态内容页面不能滚动，让子元素 height+1
   如果在`-webkit-overflow-scrolling:touch`属性的元素上，想通过动态添加内容来撑开容器，触发滚动，是有 bug 的，页面是会卡住不动的。
   国内没有人讨论这个问题，国外倒是很多，例如下面的描述：
   ![https://i.imgur.com/yaBiBJf.jpg](https://i.imgur.com/yaBiBJf.jpg)
   收集了很多资料，用了之后，下面的方法真正的解决了我的问题，真是直呼神奇，方案如下图：
   图一：
   ![https://i.imgur.com/AJfzhbX.jpg](https://i.imgur.com/AJfzhbX.jpg)
   图二：
   ![https://i.imgur.com/lyaQebD.jpg](https://i.imgur.com/lyaQebD.jpg)
   方法就是在`webkit-overflow-scrolling:touch`属性的下一层子元素上，将`height`加 1%或 1px。从而主动触发`scrollbar`
   ```css
   main-inner {
     min-height: calc(100% + 1px);
   }
   /*你也可以直接加伪元素上：*/
   main:after {
     min-height: calc(100% + 1px);
   }
   ```
   这个方案不得不说真的好用。。当然还有其他方案，不过要写 js 或者 jq 了，麻烦。

`不过`，非弹出层的横向自定义的滚动使用该 css 属性还能凑合。

##### 最终解决方案：😄

就是使用[iScroll](https://github.com/cubiq/iscroll)这样的库

## ios 设备自定义滑块无法控制原生滚动条

如下图我想通过这个按钮来快速滚动页面
查了一些资料，这种交互在 app 中比较常见，应用在网页中的没查到

##### 对应处理方法

1. 自定义滚动盒子及滑块；
2. 使用插件 [iScroll](https://github.com/cubiq/iscroll) ,[jquery-custom-content-scroller](http://manos.malihu.gr/jquery-custom-content-scroller/)

###### 缺点

使用以上办法，js 无法监听 window 的滚事件，以及元素 的 offsetTop 值也会随页面滚动变化 （页面需要用到的 window.scrollTop 和 offsetTop 时）

## 移动端 ios 直接设置 currentTime 无效解决方法

##### 情况: 音乐从一个页面进入另一个页面后，要接着上一页面播放时间播放，所以进入新页面后设置 currentTime 为上个页面播放时间

安卓是页面加载时触发；ios 是 play()后才触发
ios：直接给`currentTime`赋值是无效的，会变成 0

###### 最终解决方案：😄

在判断音乐可播放时（canplay）再设置 currentTime，但是注意这个只能触发一次

```javascript
$(this._audio).one("canplay", () => {
  //设置播放时间
  this._audio.currentTime = isPercentage
    ? Math.floor(this._audio.duration * (num / 100))
    : num;
});
```

## safari 利用原生滚动实现元素悬浮及动画

#### 情况 1 利用原生滚动实现滚动悬浮效果卡顿问题（fixed,translateY）

原因分析：
iOS 最先响应屏幕反应。
响应顺序依次为`Touch——Media——Service——Core`架构，当用户只要触摸接触了屏幕之后，
系统就会最优先去处理屏幕显示也就是 Touch 这个层级，然后才是媒体（Media），服务（Service）以及 Core 架构。
![https://i.imgur.com/vTqMivL.jpg](https://i.imgur.com/vTqMivL.jpg)
所以说，当系统接收到 Touch 事件之后会优先响应，此时会暂停屏幕上包括 js、css 的渲染。
这个时候不光是 css 动画不动了，哪怕页面没有加载完如果你手指头还停留在屏幕上那么页面也不会继续加载，直到你的手松开。
> 请注意，[iOS设备会在滚动过程中冻结DOM操作](https://stackoverflow.com/questions/20318002/animate-on-scroll-in-mobile-safari)，并在滚动完成时将其排队以应用。我们目前正在研究允许在滚动开始之前应用DOM操作的方法。

#### 解决方法
1. 自定义滚动元素
   缺点:
   1. 浏览器的导航栏及工具栏无法隐藏
   2. 需要执行动画的元素的offsetTop 会随滚动减小
2. 使用滚动插件
   缺点:
   1. 浏览器的导航栏及工具栏无法隐藏
   2. 无法获取元素的 offsetTop 值来达到准确的fixed 定位，部分插件会提供滚动值，如 iScroll.

#### 最终解决方案：😄
1. 滚动中出发元素fixed的事件改为 css 属性 position:sticky 实现悬浮；


## 额外知识
写动画时注意一下几点:
1. 尽量使用transform实现动画，避免使用height,width,margin,padding,left等；
2. 要求较高时，可以开启浏览器GPU硬件加速：让浏览器在渲染动画时从CPU转向GPU
   ```css
    webkit-transform: translate3d(0,0,0);
    // 或
    webkit-transform: translateZ(0);
    
    // 值为0并没有真正使用3D效果，但浏览器却因此开启了GPU硬件加速模式。
    // 通过开启GPU硬件加速虽然可以提升动画渲染性能或解决一些棘手问题，但使用仍需谨慎，
    // 使用前一定要进行严谨的测试，否则它反而会大量占用浏览网页用户的系统资源，尤其是在移动端，肆无忌惮的开启GPU硬件加速会导致大量消耗设备电量，降低电池寿命等问题
   ```
3. 如动画过程有闪烁（通常发生在动画开始的时候），可以尝试下面的Hack
   通过-webkit-transform:transition3d/translateZ开启GPU硬件加速之后，
   有些时候可能会导致浏览器频繁闪烁或抖动，可以尝试以下办法解决之
   ```css
    backface-visibility: hidden;
    perspective: 1000;
    // -webkit-transform-style: preserve-3d; /*保留3D空间*/
   ```
4. 尽可能少的使用box-shadows与gradients，box-shadows与gradients往往都是页面的性能杀手，尤其是在一个元素同时都使用了它们.
5. 尽可能的让动画元素不在文档流中，以减少重排
   ```css
    position: fixed;
    position: absolute;
   ```
   我们一起来看下CSS3动画其中一些属性性能消耗图:
   ![https://i.imgur.com/qdsIPkZ.jpg](https://i.imgur.com/qdsIPkZ.jpg)
   性能消耗图，由此可见最受欢饮和性能最好的莫过于`transform`和`opacity`了
   原因：CSS动画属性会触发整个页面的重排`relayout`、重绘`repaint`、重组`recomposite`
   Paint通常是其中最花费性能的，尽可能避免使用触发paint的CSS动画属性，
   这也是为什么我们推荐在CSS动画中使用`webkit-transform: translateX(3em)`的方案代替使用`left: 3em`，
   因为left会额外触发layout与paint，而`webkit-transform`只触发整个页面`composite`
   （这也是为什么推荐在CSS动画中使用`webkit-transform: translateX(500px)`的方案代替使用`left: 500px`）；

### 页面绘制优化
1. 简化浏览器重绘的复杂度
   绘制，是填充像素的过程，这些像素将最终显示在用户的屏幕上。通常，这个过程是整个渲染流水线中耗时最长的一环，因此也是最需要避免发生的一环。
   1. CSS属性中，除了transform和opacity之外，修改任何属性都会触发绘制
   2. 如果布局被触发，那么接下来绘制一定会被触发。因为改变一个元素的几何属性就意味着该元素的所有像素都需要重新渲染！
   3. 如果改变元素的非几何属性，也可能触发绘制，比如背景、文字颜色或者阴影效果，尽管这些属性的改变不会触发布局。
2. 减小浏览器重绘区域
   绘制并非总是在内存中的单层画面里完成的。实际上，浏览器在必要时将会把一帧画面绘制成多层画面，然后将这若干层画面合并成一张图片显示到屏幕上。
   ![https://i.imgur.com/0S2bmHf.jpg](https://i.imgur.com/0S2bmHf.jpg)
   这种绘制方式的好处是，使用tranforms来实现移动效果的元素将会被正常绘制，同时不会触发对其他元素的绘制。
   在页面中创建一个新的渲染层的最好方式就是使用CSS属性will-change，Chrome/Opera/Firefox都支持该属性。
   同时再与transform属性一起使用，就会创建一个新的组合层：
   ```css
   .moving-element {
    will-change: transform;
   }
   ```
   对于那些目前还不支持will-change属性、但支持创建渲染层的浏览器，比如Safari和Mobile Safari，
   你可以使用一个3D transform属性来强制浏览器创建一个新的渲染层：
   ```css
   .moving-element {
    transform: translateZ(0);
   }
   ```
   但需要注意的是：不要创建太多的渲染层。因为每创建一个新的渲染层，就意味着新的内存分配和更复杂的层的管理。
3. 避免大规模、复杂的布局
   上面提到的，由于框架的限制，页面布局相对需求来说复杂很多。开发中应该尽量避免复杂的DOM结构，复杂的DOM结构更容易引起大面积的重绘。
4. 优先使用渲染层合并属性
   渲染层的合并，就是把页面中完成了绘制过程的部分合并成一层，然后显示在屏幕上。
   使用`transform/opacity`来实现动画效果，目前只有`transforms`和`opacity`这两个属性不会触发浏览器的布局和绘制，
   对网页元素这两个属性的修改会直接触发渲染层合并。
5. 优化JavaScript的执行效率
   1. 对于动画效果的实现，避免使用setTimeout或setInterval，请使用[requestAnimationFrame](https://developer.mozilla.org/zh-CN/docs/Web/API/Window/requestAnimationFrame)。
   2. 把耗时长的JavaScript代码放到[Web Workers](https://www.w3schools.com/html/html5_webworkers.asp)中去做。
   这里可以使用`Chrome DevTools`的`Timeline`和`JavaScript Profiler`来分析JavaScript的性能
