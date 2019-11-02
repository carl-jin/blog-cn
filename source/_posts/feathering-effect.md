---
title: 网页羽化效果
date: 2019-11-01 19:57:00
tags:
  - Front End
categories:
  - Front End
description: 羽化是ps术语，羽化原理是令选区内外衔接部分虚化，起到渐变的作用从而达到自然衔接的效果，是ps及其其它版本中的处理图片的重要工具。那么本文将介绍如何实现
---

# 需求

![点这里](https://i.imgur.com/y6103sE.png)
先说需求, 如上图所示, 要实现内容区域在浏览器顶部与底部羽化效果.

# 便捷通道!

1. 如果背景非图片与视频, 仅是纯色的话, 直接使用 css3 中的`linear-gradient`, 在上面盖个渐变色即可, 非常简单.
   ```css
   .feathering {
     background-image: linear-gradient(
       to bottom,
       rgba(255, 255, 255, 0) 84%,
       rgba(255, 255, 255, 1) 100%
     );
   }
   ```
2. 如果背景色不固定, 比如是渐变, 随机或者是视频与图片 **且**此时内容区域为**纯**文本,
   可以直接使用`-webkit-background-clip`实现([注意兼容](https://caniuse.com/#feat=mdn-css_properties_background-clip_text))

   ```css
   .feathering {
     background-image: linear-gradient(
       to bottom,
       rgba(255, 255, 255, 0) 84%,
       rgba(255, 255, 255, 1) 100%
     );
     -webkit-background-clip: text;
     -webkit-text-fill-color: transparent;
   }
   ```

> 如果以上两种情况都不适合你的话, 那还是老老实实的跟着下面走吧!

# 思路

1. 使用`canvas`渲染出背景图片(或者视频)
2. 结合`canvas`中的[globalCompositeOperation](https://developer.mozilla.org/zh-TW/docs/Web/API/Canvas_API/Tutorial/Compositing)与[createLinearGradient](https://developer.mozilla.org/zh-CN/docs/Web/API/CanvasRenderingContext2D/createLinearGradient)处理背景图
3. 将背景图悬浮到内容上层, 并且给个 css 样式`pointer-events: none;`

# 直接上 CodePen!
{% codepen GRRyWOg %}

> 可以在上面`codepen`中的文本区域滚动, 看到效果已经实现了!

# 代码分析
> 这里主要分析JS代码为主
```javascript
//    step 2 设置后面会用到的合成渐变
let gradient = ctx.createLinearGradient(0, 0, 0, height);
gradient.addColorStop(0, "rgba(0,0,0,1)");
gradient.addColorStop(0.22, "rgba(0,0,0,0)");
gradient.addColorStop(0.78, "rgba(0,0,0,0)");
gradient.addColorStop(1, "rgba(0,0,0,1)");
ctx.fillStyle = gradient;
ctx.fillRect(0, 0, width, height);
```
这里设置渐变的主要目的是为了后续使用`canvas`中的, [globalCompositeOperation](https://developer.mozilla.org/zh-TW/docs/Web/API/Canvas_API/Tutorial/Compositing) 我们将其值设置为`source-in`, 
该值的主要目的是**只保留新、旧图形重叠的新图形区域，其余皆变为透明。**, 也就意味着以内容高度为基准, `0~0.22` 与 `0.78~1` 这个黑色渐变区域将会显示图片,
而`0.22~0.78`这个区域将会呈现透明效果.

```javascript
//    step 3 将图片渲染到canvas里面
let oImg = new Image();
oImg.onload = () => {
  ctx.globalCompositeOperation = "source-in";
  ctx.drawImage(oImg, 0, 0, width, height);
};
oImg.src = `https://i.imgur.com/9EjhC6W.jpg`;
```
这里需要**注意**的地方是`ctx.drawImage`必须要确保调用时图片**已加载**不然啥效果都没有, 所以我们把它放到了`oImg.onload`里面执行.
我们在`drawImage`之间设置了`globalCompositeOperation`来告诉canvas我们要以那种合成效果绘制图片.

# 总结
如果你考虑兼容与可控性, 那么使用`canvas`将是最好的方式.
