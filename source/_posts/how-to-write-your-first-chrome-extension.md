---
title: 翻译 如何创建一个Chrome extension
date: 2021-03-12 07:11:14
tags:
- Google Extension
description: 有没有想过创建Chrome extension会是怎么样的?在这里我会告诉你它有多简单,跟着这些步骤走你的想法将会变成现实!并且你可以立刻发布一个真正的`Extension在Chrome商店中.
---
#   如何创建一个Chrome extension

>[原文](https://medium.freecodecamp.org/how-to-create-and-publish-a-chrome-extension-in-20-minutes-6dc8395d7153)

有没有想过创建Chrome extension会是怎么样的?在这里我会告诉你它有多简单,跟着这些步骤走你的想法将会变成现实!并且你可以立刻发布一个真正的`extension`在Chrome商店中.

# 什么是Chrome Extension?
Chrome Extension 允许你添加一些功能到Chrome浏览器上,而不需要修改页面源代码.这很厉害,因为你可以用Web开发者最熟悉的核心知识`CSS`,`HTML`,`Javascript`来为Chrome开发一个新插件.如果你曾经有开发网页的经验,那么开发一个插件甚至比你吃一顿饭还快.你唯一需要学习的事是如何使用Chrome提供出来的`Javascript API`添加一些功能到Chrome上.

如果你还没有开发页面的经验,我建议还是先通过一些免费的资源去学习如何开发,比如 [freeCodeCamp](https://www.freecodecamp.org/)

# 你想开发什么功能?
在你开发之前,你需要对你想要开发的功能有个大致的想法.它并不需要是一些开创性的想法,我们可以仅仅为了好玩去开发.在这篇文章中,我将会告诉你我的想法还有如何在一个Chrome Extension中实现它.
>所以也就是你在如果是看着这篇文章跟着尝试开发,你并不需要什么想法...只需要跟着作者做就行.但是在你要独立开发时,你就需要一些想法了

# 计划
我用过[Unsplash](https://chrome.google.com/webstore/detail/unsplash-instant/pejkokffkapolfffcgbmdmhdelanoaih)这个插件一段时间,这使我通过[Unsplash](https://chrome.google.com/webstore/detail/unsplash-instant/pejkokffkapolfffcgbmdmhdelanoaih)在新的`TAB`上得到一些不错的背景.
后来我使用[Muzli](https://muz.li/)插件代替的它,这使得默认的`TAB`变成了可以从整个互联网中获取关于设计新闻与例子的页面.

让我们使用这俩插件的灵感,来开发一个新的,这一次比较适合于电影爱好者.我的想法是在每次你打开新的`TAB`时显示一些关于电影的背景图片.
当滚动它时,将会得到一些热门电影与电视节目的好消息.

# 步骤1: 设置一些东西
第一步是创建一个`manifest`文件,名字叫做`manifest.json`.
这是一个Json格式的包含属性的元数据文件,比如像你的插件名,描述,版本号之类的.
在这个文件中,我们将会告诉chrome这个插件将会处理什么与需要哪些权限.

针对于这个`movie`插件,我们需要控制`activeTab`的权限.所以我们的`manifest.json`文件看起来像这样:

```json
    {
     "manifest_version": 2,
     "name": "RaterFox",
     "description": "The most popular movies and TV shows in your   default tab. Includes ratings, summaries and the ability to watch trailers.",
     "version": "1",
     "author": "Jake Prins",
     "browser_action": {
       "default_icon": "tab-icon.png",
       "default_title": "Have a good day"
      },
     "chrome_url_overrides" : {
      "newtab": "newtab.html"
     },
     "permissions": ["activeTab"]
    }
```

正如你所见的一样,`newtab.html`将会是一个`HTML`文件,它将会在每次新的`TAB`打开时被渲染.
要想实现它我们必须要有控制`activeTab`的权限,所以当用户尝试安装这个插件时,
他将会得到一个关于此插件所需的权限警告.

![warn](https://cdn-images-1.medium.com/max/1600/1*jMmZo8AUvcf01GMxTnXqZg.png)

另外比较有趣的事是关于`manifest.json`内的`browser actions`.
在这个例子中我们使用它设置了标题,但这里有很多的参数.例如,每当你点击地址栏中这个插件的图标时要弹出一个页面,你需要做的事像这样:
```json
"browser_action": {
  "default_popup": "popup.html",
 },
```
现在,`popup.html` 将会在弹出窗口里面被渲染,这个弹窗是为了响应用户点击浏览器的行为而创建.
这是一个标准的html文件,你可以自由的控制它的显示.
你只需要发挥一些才华在这个名叫`popup.html`的文件里.

# 步骤2: 测试是否运行成功
下一步是创建一个`newtab.html`并且写入一个`Hello World`:
```html
<!doctype html>
<html>
  <head>
    <title>Test</title>
  </head>
  <body>
    <h1>Hello World!</h1>
  </body>
</html>
```

如果要测试他是否成功运行, 用你的chrome浏览器访问`chrome://extensions`并且在右上角勾选上`Developer mode`.

![DM](https://cdn-images-1.medium.com/max/1600/1*6eljnFW72RcJMOKxF2c-ag.png)

点击`Load unpacked extension`并且选择你插件文件所在的目录.
如果插件运行成功,它将马上被激活,然后在你新开的`tab`页面中,将会看到`Hello World`

# 步骤3: 美化!
现在我们第一个功能已经运行成功,现在是时候美化它了,
我们可以通过在插件目录创建`main.css`文件对其进行简单的样式处理并且在`newtab.html`文件中引用它.
同理如果你要在js文件中实现任何的功能也可以通过这种方式引用.
假设如果你之前开发过web页面,现在你可以通过你的才华让用户看到你想要的效果.

# 收尾
我还需要完成这个movie插件所包含的HTML,CSS与Javascript,我觉得只需要快速的搞定它们,而不需要在这里对代码有过多的描述.

下面是我所做的:

在我的想法中需要一些非常好看的背景图片,所以在Javascript文件中我使用了[TMDb API](https://www.themoviedb.org/)来抓取一些热门的电影.
并且我拿到了它们的背景图并且把它们塞入到一个数组里面.
每当这个页面加载时,它马上会随机从数组里面取出一个图片并把它设置为页面的背景图.
为了使这个页面更有趣些,我还把当前时间添加到了页面右上角.
为了得到更多的信息,它允许当用户点击背景图时跳转到IMDb的页面.

当用户试图往下滚动时,我把一个热门电影替换了当前显示区域.我使用了相同的API用于创建相同的电影卡片,其中包含图片,标题,评分和投票数.
然后当点击任何一张卡片时,它会显示描述还有一个可以观看预告片的按钮.

# 效果
现在只需要一个小小的`manifest.json`文件和一些HTML,CSS与Javascript文件,你可以在每个`tab`上找到一些有趣的东西.

![](https://cdn-images-1.medium.com/max/1600/1*P8NTRn4MiIARJCM83SUxKg.gif)

# 步骤4: 发布它!
当你第一个Chrome插件效果不错并且还能成功运行,这时候该把它发布到Chrome Store里面去了.
点击这个[链接](https://chrome.google.com/webstore/developer/dashboard)将会跳转到Chrome商店的管理页面(如果你还没登入,将会要求你登入google账号).
然后点击`Add New Item`(添加新内容)按钮,接受条款(有趣的事是如果你第一次上传插件,需要花$5的注册费)然后将跳转到插件上传页面.
现在你可以在这张页面上传插件的目录压缩后的zip文件.

![upload](https://cdn-images-1.medium.com/max/1600/1*qZs4NLeppLeQl_StCG7mGw.png)

等待上传完成后,将会看到一个添加更多关于这个插件信息的表单.
你可以添加Icon,详细的描述,上传一些截图等等之类的.

确保你提供了一些图片来展示你的插件,这些图片有助于商店推广你的插件.
提供的图片越多,你的插件也就会越突出.
你可以通过点击`Preview Change`按钮来阅览你的插件在Chrome商店里面的展示效果.
如果你对展示结果满意,点击`Publish changes`即可.

现在你可以通过插件的名称在Chrome商店中进行搜索(在你上传它之后可能需要一段时间才能展示出来).
如果你对此有兴趣,你可以找到[我的插件](https://chrome.google.com/webstore/detail/raterfox-popular-movies-t/pbmdibcifmempicdafabdakcoamfobik)

现在剩下唯一要做的事就是让更多的用户使用它.所以你可能想要分享一篇关于Chrome插件改变你生活的文章到社交平台上.
告诉你的朋友们去下载它.
别忘记分享你的项目在这篇文章下面的评论里面.
我很好奇想看到你都有哪些想法.

# 总结
开发一个Chrome插件对于一个web开发人员来说是小菜一碟的事.
你所需要的能力只不过是一些HTML,CSS,Javascript和会使用一些Chrome提供的基本的API.
你可以仅仅在20分钟内,完成搭建项目并上传到Chrome商店.
开发一个新的插件,让它变得有价值或者效果不错将会花费一些时间,但那完全取决于你.

使用你的创造力开发一些有趣的东西,如果你遇到一些困难,[Chrome](https://developer.chrome.com/extensions)非常优秀的文档可以帮助你.

嗯...那你现在还在等什么?现在是时候开始着手开发了,把你的想法变成现实吧!

再罗嗦一句,别忘记了在下面的评论中分享你的项目,如果你觉得这篇文章对你有用,别忘记了点赞啊!
如果你闲着没事干,还可以给[我的插件](https://chrome.google.com/webstore/detail/raterfox-popular-movies-t/pbmdibcifmempicdafabdakcoamfobik)来个五星好评.
我会非常感谢的.

遇到问题?想反馈?在评论中描述它.
