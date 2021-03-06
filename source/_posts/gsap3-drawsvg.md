---
title: Gsap3.0 drawSVG - 操作SVG
date: 2020-01-20 21:15:16
tags:
  - gsap
description: gsap3.0 已经发布2个多月来，今天和大家分享如何用gsap3.0做SVG path的动画
---

# 画个SVG线条
1. 打开[method](https://editor.method.ac/), 选着`钢笔工具`，随便画几条线，然后在左上角，依次点击`File`->`Save Image……`即可得到一个SVG
2. 通过浏览器打开下载的SVG文件，右键查看源代码，可以找到SVG的数据，大概张下面这个样子
   ```html
    <svg width="580" height="400" xmlns="http://www.w3.org/2000/svg">
     <!-- Created with Method Draw - http://github.com/duopixel/Method-Draw/ -->
     <g>
      <title>Layer 1</title>
      <path d="m146.5,94.453125c-1,0 -4,0 -12,0c-7,0 -12.160507,-0.378517 -18,1c-6.528755,1.541229 -16.206612,8.878899 -22,19c-6.224617,10.874474 -10.334251,24.580811 -7,33c3.682068,9.29744 11.80616,13.366074 21,18c10.78997,5.438431 22.607208,9.745148 36,17c9.510864,5.152023 13.972519,8.647491 15,13c1.608276,6.812744 2.042313,16.41748 -2,25c-4.019791,8.534714 -12.240479,19.872742 -32,30c-11.256744,5.769379 -22,8 -25,9l-1,0" id="svg_13" stroke-width="1.5" stroke="#000" fill="none"/>
      <path d="m194.5,124.453125c1,0 3.549011,0.606422 7,6c7.23082,11.301117 11.628418,29.087769 17,51c4.67775,19.081894 9.584808,33.168243 13,41c0.893799,2.049667 2.076126,2.38269 3,2c1.306564,-0.541199 2.848038,-3.059479 8,-16c6.800339,-17.080841 13.893097,-39.278137 23,-57c9.141266,-17.788696 18,-31 22,-44l5,-7l0,-3" id="svg_14" stroke-width="1.5" stroke="#000" fill="none"/>
      <path d="m415.5,90.453125c-1,0 -2.03067,-0.087692 -5,1c-5.05658,1.852272 -14.551697,7.534767 -24,15c-9.577728,7.567505 -20.459808,15.37516 -25,28c-4.514923,12.554504 -7.506439,24.242783 -5,35c3.160675,13.565033 6.763794,23.145569 13,33c3.85614,6.09346 6.712006,9.981628 12,11c1.963898,0.37822 5.09021,1.945541 10,1c10.575989,-2.036743 23.157166,-11.490387 34,-21c7.991913,-7.009232 14,-15 14,-17c0,-1 -1,-1 -3,-1l-2,0l-2,0" id="svg_15" stroke-width="1.5" stroke="#000" fill="none"/>
      <path d="m412.5,174.453125c1,0 1.907776,-0.496231 6,-1c6.94754,-0.855286 16,0 25,0c3,0 3.823761,0.486252 6,1c0.973236,0.229752 1.144287,0.934143 2,3c3.630463,8.764694 4.294373,24.056244 6,41c1.416443,14.07103 3,30 4,37l1,3l0,1" id="svg_17" stroke-width="1.5" stroke="#000" fill="none"/>
      <path d="m67.5,506.453125c3,0 4,0 4,1l-1,1" id="svg_18" stroke-width="1.5" stroke="#000" fill="none"/>
     </g>
    </svg>
   ```

# 使用Gsap3.0
来看HTML部分
首先我们需要引用gsap3.0
```html
<html>
    <title></title>
    <body>
      <svg width="580" height="400" xmlns="http://www.w3.org/2000/svg">
         <!-- Created with Method Draw - http://github.com/duopixel/Method-Draw/ -->
         <g>
          <title>Layer 1</title>
          <path d="m146.5,94.453125c-1,0 -4,0 -12,0c-7,0 -12.160507,-0.378517 -18,1c-6.528755,1.541229 -16.206612,8.878899 -22,19c-6.224617,10.874474 -10.334251,24.580811 -7,33c3.682068,9.29744 11.80616,13.366074 21,18c10.78997,5.438431 22.607208,9.745148 36,17c9.510864,5.152023 13.972519,8.647491 15,13c1.608276,6.812744 2.042313,16.41748 -2,25c-4.019791,8.534714 -12.240479,19.872742 -32,30c-11.256744,5.769379 -22,8 -25,9l-1,0" id="svg_13" stroke-width="1.5" stroke="#000" fill="none"/>
          <path d="m194.5,124.453125c1,0 3.549011,0.606422 7,6c7.23082,11.301117 11.628418,29.087769 17,51c4.67775,19.081894 9.584808,33.168243 13,41c0.893799,2.049667 2.076126,2.38269 3,2c1.306564,-0.541199 2.848038,-3.059479 8,-16c6.800339,-17.080841 13.893097,-39.278137 23,-57c9.141266,-17.788696 18,-31 22,-44l5,-7l0,-3" id="svg_14" stroke-width="1.5" stroke="#000" fill="none"/>
          <path d="m415.5,90.453125c-1,0 -2.03067,-0.087692 -5,1c-5.05658,1.852272 -14.551697,7.534767 -24,15c-9.577728,7.567505 -20.459808,15.37516 -25,28c-4.514923,12.554504 -7.506439,24.242783 -5,35c3.160675,13.565033 6.763794,23.145569 13,33c3.85614,6.09346 6.712006,9.981628 12,11c1.963898,0.37822 5.09021,1.945541 10,1c10.575989,-2.036743 23.157166,-11.490387 34,-21c7.991913,-7.009232 14,-15 14,-17c0,-1 -1,-1 -3,-1l-2,0l-2,0" id="svg_15" stroke-width="1.5" stroke="#000" fill="none"/>
          <path d="m412.5,174.453125c1,0 1.907776,-0.496231 6,-1c6.94754,-0.855286 16,0 25,0c3,0 3.823761,0.486252 6,1c0.973236,0.229752 1.144287,0.934143 2,3c3.630463,8.764694 4.294373,24.056244 6,41c1.416443,14.07103 3,30 4,37l1,3l0,1" id="svg_17" stroke-width="1.5" stroke="#000" fill="none"/>
          <path d="m67.5,506.453125c3,0 4,0 4,1l-1,1" id="svg_18" stroke-width="1.5" stroke="#000" fill="none"/>
         </g>
        </svg>

        <!--这里引用的是当前最新版本的gsap-->
        <script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.0.5/gsap.min.js"></script>
        <!--操作SVG需要用到drawSVG参数，这里需要把DrawSVGPlugins3引进来-->
        <!--切记如果不引用的话直接使用drawSVG参数是没作用的。-->
        <script src="https://s3-us-west-2.amazonaws.com/s.cdpn.io/16327/DrawSVGPlugin3.min.js"></script>
    </body>
</html>
```

来看CSS部分
```css
/* 这里需要特别注意，必须要有一下两个属性才能操纵SVG */
/* 如果你发现svg动画执行不了，js也没报错，那么这是第一个需要检查的地方 */
path{
    stroke-width: 1px;
    stroke: red;
}
```

来看js部分
```javascript
//  这里需要注册DrawSVGPlugin才能使用drawSVG参数
gsap.registerPlugin(DrawSVGPlugin);

gsap.from('path',{
  drawSVG:'0%',
  duration:1,
  repeat:-1,
  yoyo:true,
  stagger:1
})
```

# 总结
如果你第一次使用gsap3.0处理svg的话，相信这篇文章里面代码的注释能让你少踩不少坑。
这里放一个codepen的链接，可以查看效果
{% codepen QWwJYeG %}
