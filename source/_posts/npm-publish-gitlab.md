---
title: 如何将项目以 npm 的形式发布到私有的 gitlab 上
date: 2022-11-30 22:42:49
description: 按照官方的文档跑不通？本文将手把手教你如何包发布到 gitlab 上
---

> 官方文档就不吐槽了

# 需求

> sass 是个私人组织，不是公开的

首先让我们来看下需要完成什么功能

在我们内部的 gitlab 上，有一个项目，它的路径为以下
`https://gitlab.myown.com/saas/front-end/lib/create-msg`

我们希望当执行 `git push origin master --follow-tags` 命令时候，能执行 ci 的自动部署

将打包好的文件发布到名为 `sass` 的这个组织下面，也就是 `https://gitlab.myown.com/groups/saas/-/packages`。

这样其人想使用这个包时只需要执行 `npm i @saas/create-msg` 安装即可

# 准备工作

首先根据官方文档，我们需要准备以下几个变量

### SERVER_HOST_NAME

你可以简单的理解为域名，就是 `https://gitlab.myown.com/saas/front-end/lib/create-msg` 这个链接中的 `gitlab.myown.com`

### SCOPE_SLUG

项目所在组的 slug，就是 `https://gitlab.myown.com/saas/front-end/lib/create-msg` 这个链接中的 `saas`

### PROJECT_ID

项目的 ID，就是你点击 `https://gitlab.myown.com/saas/front-end/lib/create-msg` 这个链接进去后的 Project ID （在名称下方，图标右方）

> 注意这里是 project id 是项目 id， 不是 saas 的 id，saas 的 ID 叫 Group Id 不要搞错了

### AUTH_TOKEN

token 你可以用个人 token 也可以用 deploy token，这里建议使用 deploy token
让我们来看下如何获取
首先进入 `https://gitlab.myown.com/saas/-/settings/repository`, 如果你打不开，可能要找管理员让他给你创建一个
在 Deploy Tokens 里面新建一个 token，Scopes 中只需要选择 `read_package_registry` 和 `write_package_registry` 即可
创建好后，你将得到一个 token `9KwdxdDvBTc3BYdcy1b4`

我们已 json 的形式表述，就是这样的

```json
{
  "SERVER_HOST_NAME": "gitlab.myown.com",
  "SCOPE_SLUG": "saas",
  "PROJECT_ID": "921",
  "AUTH_TOKEN": "9KwdxdDvBTc3BYdcy1b4"
}
```

请先把上面这些值准备好

# 发布
我们来看下怎么将 `create-msg` 这个项目打包发布上去

这里我们采用 CI 来进行部署，毕竟 github action 用习惯了，还是比较喜欢 push 以下就自动部署的

我们在 `create-msg` 这个项目的根目录下面新建一个`.gitlab-ci.yml`文件内容如以下

```yaml
image: node:latest

variables:
  SERVER_HOST_NAME: gitlab.myown.com
  SCOPE_SLUG: saas
  PROJECT_ID: 921
  AUTH_TOKEN: 9KwdxdDvBTc3BYdcy1b4

stages:
  - build

build:
  stage: build
  script:
    - npm install
    - npm run build
    - echo "@${SCOPE_SLUG}:registry=https://${SERVER_HOST_NAME}/api/v4/projects/${PROJECT_ID}/packages/npm/">.npmrc
    - echo "//${SERVER_HOST_NAME}/api/v4/packages/npm/:_authToken=${AUTH_TOKEN}">>.npmrc
    - echo "//${SERVER_HOST_NAME}/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${AUTH_TOKEN}">>.npmrc
    - npm publish
```

注意这些变量你都可以在 `https://gitlab.myown.com/saas/-/settings/ci_cd` 中设置，而不需要写死
如果你不想每个项目都去设置一边 PROJECT_ID ，那么你可以用 gitlab 提供的变量 `CI_PROJECT_ID`, 来代替 PROJECT_ID


这样当我们提交代码到 `create-msg` 上时，它就会自动发布这个包


# 如何安装一个包

## 创建 npmrc 
首先你需要在项目根目录创建一个 `.npmrc` 文件，内容如下
```text
@saas:registry=https://gitlab.myown.com/api/v4/packages/npm/
//gitlab.myown.com/api/v4/packages/npm/:_authToken=9KwdxdDvBTc3BYdcy1b4
```
> 关于为什么 `_authToken` 会明文出现在项目中，请查看[https://youtu.be/OqS6jb22AFE?t=1143](https://youtu.be/OqS6jb22AFE?t=1143)
