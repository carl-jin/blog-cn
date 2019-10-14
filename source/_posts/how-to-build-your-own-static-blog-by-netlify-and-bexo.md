---
title: Netlify + Hexo 快速搭建属于你自己的静态站点
date: 2019-10-10 23:04:16
tags:
  - 博客
  - Netlify
  - Hexo
  - github
  - Github Pages
categories:
  - blog
description: 想拥有一个属于自己的静态博客? 只需要跟着以下步骤你将在10分钟内拥有属于自己的静态博客.
---

![Imgur](https://i.imgur.com/0mQ4qvU.png)

# 准备工作

1. 注册属于你自己的 [Github 账号](https://github.com)
2. 确保[Nodejs](https://nodejs.org/en/) 已经安装

# 在 github 中创建你的 blog 资料库

进入[Github New Repository Page](https://github.com/new), 并且给其起名叫`blog`(实际上你可以取任何名字,只要你能记住),
我们并不需要`README`和`license`你可以直接跳过, 或者过后自己创建

创建完成后需要记住你的`资料库链接`(git repository url)这里等会儿需要用到!
![git_repository](https://i.imgur.com/k2tKJD3.png)

# 安装 hexo

打开你的命令行`terminal` 或者 `command prompt`, 输入以下命令安装全局的`hexo`

```bash
npm install -g hexo-cli
```

现在你已经安装完成了, 让我们开始使用 hexo 吧
输入以下命令来初始化你的 blog

```
hexo init <你想要的项目存放的本地地址>
```

让我们`cd`到 blog 的工作目录

```
cd <项目存放的本地地址>
```

npm dependencies 已经都安装过了, 我们只需要执行以下命令将可看到效果 (需要在 hexo 生成的 blog 目录下执行)

```bash
hexo g
hexo s
```

node 将会建立一个服务器用于展示 blog 效果, 默认将会是[http://localhost:4000](http://localhost:4000)
你可以直接点击进行访问
![hexo_default](https://i1.wp.com/laesporadelhongo.com/wp-content/uploads/2017/07/crear-un-blog-con-nodejs.png)

# 与 Github 的资料库关联

如果要将 blog 放到 github 上进行托管,只需要在 blog 的工作目录执行以下命令即可

```bash
git init
git add .
git commit -m "first commit"
git remote add origin <在上面提到的资料库链接>
```

现在让我们把 blog 推送到 github 上

```bash
git push -u origin master
```

#   是时候放到Netlify进行托管了
访问[Netlify](https://www.netlify.com/)的官方网站, 首先你需要注册一个帐号, 点击右上角的`Sign up`.
我们已经有`GitHub`帐号了, 这里我们可以直接使用`GitHub`登入即可.
点击右上角的`New site from Git`
![New site from Git](https://i.imgur.com/fYhDg2r.png)

然后点击从`GitHub`上进行部署, 这里会提示你需要`GitHub`授权, 直接一步步确认即可.
![](https://i.imgur.com/6KUqM6x.png)

选择第一步我们在GitHub上建立的`资料库`即可. (下图中的资料库名称将由第一步中建立的资料库名决定)
![](https://i.imgur.com/LhjBA2s.png)

默认情况下这里什么都不需要修改, 如果你有特殊需求也可以进行相应的配置
![](https://i.imgur.com/KbqR2w7.png)

点击`Deploy Site`后会进入,`Overview`的页面, 如下图提示站点部署正在处理中...
![](https://i.imgur.com/QWjaNNF.png)
这将会花费大概2~3分钟, 等待的时间不妨阅读下面的一些说明.
[Hexo](https://hexo.io/zh-cn/docs/index.html) 另外官方也提供中文文档.
> Hexo 是一个快速、简洁且高效的博客框架。Hexo 使用 Markdown（或其他渲染引擎）解析文章，在几秒内，即可利用靓丽的主题生成静态网页。
[Netlify](https://www.netlify.com/) 官方提供免费账号, 对于个人博客来说, 基本上够用. 
如果你的网站配额不够用, 完全可以用使用`GitHub`的[Actions](https://github.com/features/actions)代替!
> Netlify提供快速构建静态网站服务,其中包含连续部署与serverless等等

当部署完成后, Netlify会提供一个免费的子域名供你的博客使用,如下图点击链接后就可以看到刚刚我们使用hexo搭建的`blog`了
[](https://i.imgur.com/K71vVNt.png)

#   与你自己的域名绑定 (前提你得有自己的域名) 
依次点击下图, 可以在此面板找到Netlify提供的`Netlify DNS`服务器,
![](https://i.imgur.com/z3J1AHv.png)
大概长下面这样子
```
dns1.p02.nsone.net
dns2.p02.nsone.net
dns3.p02.nsone.net
dns4.p02.nsone.net
```
只需将你的购买的域名的DNS服务器指向上述Netlify提供的DNS服务器即可

#   配置免费的HTTPS
`Netlify`提供免费的SSL证书,(实际SSL本来就可以申请到免费的证书,只不过区别是Netlify帮你申请,还是你自己申请而已)
只需在下图的`HTTPS`面板, 点击获取即可!
![](https://i.imgur.com/jVzkZdo.png)


#   如何更新blog?
如果要修改的Blog(添加新文章,调整样式,换主题)之类的,只需要在本地的`blog`目录修改好后,
提交到执行以下命令提交到`github`上后,Netlify会把新更新的内容自动部署上!
```bash
git add .
git commit -m "你这次提交的描述"
git push
```

你可以在`Overview`中实时看到Netlify的部署情况.
当然你也可以点击进去,看到具体的详情.如果有报错也很方便用于debug.
总体来说还是非常方便的.
![](https://i.imgur.com/k9UShJM.png)

#   Hexo与Netlify使用还是比较大众化的,非常容易上手.现在何不自己动手试试呢?

#   如果你在部署中遇到任何问题, 均可以在下方讨论

