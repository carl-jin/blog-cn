---
title: Google Drive Structure - 如何快速生成谷歌Drive的文件树
date: 2019-11-15 11:23:28
tags:
  - Google Drive
categories:
  - Front End
  - Google 接口系列
description: 如何生成 Google Drive 的文件树? 本文将介绍几种实现方式, 并分析每种方式的优缺点.
---

# 快速入口

如果你只是想快速获取 Google Drive 下指定文件夹的目录树, 对其实现方法与优缺点并无兴趣的话,
直接用我的开源项目吧[https://github.com/carl-jin/DriveTreeCreator](https://github.com/carl-jin/DriveTreeCreator)

# 引言

> The first thing to understand is that in Google Drive, Folders are not folders!
> in Google Drive, a Folder is NOT a container, so much so that in the first release of Google Drive,
> they weren't even called Folders, they were called Collections.
> 摘自 [https://stackoverflow.com/a/41741521](https://stackoverflow.com/a/41741521)

##### 个人理解的意思为:

Google Drive 中的 Folder 并不是真正意义上的 **Folder**,与我们常认为的文件夹不同,
它不是一个容器, 起初 Google 称其为**收藏夹**, 类似常见的**Tag**,
但区别于 Tag 的是, Collections 中还可以包含另外的 Collections,
这也间接的实现了父子关系.
正因如此, 要获取 Google Drive 文件树并不简单.
而且 Google Drive API 也未提供相关接口, 且 Google Drive API 只能获取子级文件,
不能获取孙子级文件. 现在已知的实现方法就是通过递归遍历.
下面将介绍几种递归遍历实现方法, 并列举其优缺点.

# 准备工作

本文将使用 [Google Drive V3 API](https://developers.google.com/drive/api/v3/),
官方现已提供`Java`,`Node.js`,`Python`与`Javascript`对应的实现库,
在开始前我们需要获取`clientId`与`APIKey`大概长这个样子
(当然下面是我做过修改的,你并不能直接用)关于如何获取 clientId 与 APIKey,
可以参考我另一篇帖子[如何获取 Google Drive API Key](https://carljin.com/how-to-enable-google-drive-api-and-get-client-credentials.html)

```javascript
{
    clientId: "898500841412-h6n32afah3uqbjp4i9lu2r4a7jbdon5u8.apps.googleusercontent.com",
    APIKey: "AIzaSyAHz9dtTpA2yTvVriBqJzDYt58do8rnsW4"
}
```

此外我特地在 Google Drive 建立了用于测试的目录, 结构如下:

```
test
├── images
|   ├── 1.jpg
|   ├── 2.jpg
|   └── cats
|       ├── 1.jpg
|       └── 2.jpg
└── index.html
```

### 注意

因为 Google Drive API 调用需要服务器环境, 通过浏览器直接访问本地文件是不行的,
也就说我们需要通过`http://localhost:3000`去访问我们的测试文件,
而不是`file:///C:***`, 这里我推荐直接用`Yeoman`的`Generator`即可,
这里我使用的是[gulp-with-es6](https://github.com/carl-jin/generator-gulp-es6), 默认会以`localhost:3000`作为启动环境.
关于如何使用`Yeoman`, 如果有兴趣也可以参考我的另一篇文章[Yeoman 安装与入门](https://carljin.com/getting-started-with-yeoman.html)
此外 Google Drive API 因出于安全考虑, 对接口调用域名进行了限制, 我们需要在[Google Developers Console](https://console.developers.google.com/)中进行配置,
如下图把你的测试域名, 添加上来即可, 这里我在本地`localhost:3000`做测试, 所以填写的是`http://localhost:3000`
![google drive console](https://i.imgur.com/ZLE2XZn.png)

# 实现方法

以下内容会涉及到 [Google Drive API](https://developers.google.com/drive/API/v3/about-sdk) 的接口调用.
如果你还未对其有了解, 可以参考我另一篇帖子 [Google Drive API 快速入门](#)
本文将主要讲解基于 `Javascript` 的实现方法, 其他语言实现方法也都大同小异.
要说区别也无非与两种

1. 如果你用的是`python`,`node.js`或者`php`, 你需要引用`credentials.json`文件来处理权限验证
   而使用`js`直接可以让用户在浏览器进行权限验证
2. 多线程的调用与管理问题, `python`的多线程处理还是较为简单的.

## 方法 一: 直接递归遍历

```javascript
//  step 1 加载 Google API SDK
let tag = document.createElement("script");
tag.onload = main;
tag.src = "https://APIs.google.com/js/API.js";
document.body.appendChild(tag);

function main() {
  //  step 2 加载相关API
  //  使用 OAuth 2.0 访问 Google APIs
  //  https://developers.google.com/identity/protocols/OAuth2
  window.gAPI.load("client:auth2", () => {
    //  加载 Google Drive V3 API
    window.gAPI.client.load("drive", "v3", async () => {
      await window.gAPI.client.init({
        //  下面的 APIKey 和 clientId 请使用自己的, 这里使用的已经进行修改.
        //  你是不能直接使用的, 关于如何获取, 上文中已经提到
        APIKey: "AIzaSyAHz9dtTpA2yTvVriBqJzDYt58do8rnsW4",
        clientId:
          "898500841412-h6n32afah3uqbjp4i9lu2r4a7jbdon5u8.apps.googleusercontent.com",
        //  Google Drive V3 授权范围
        //  这个将会提示用户该应用程序将需要哪些权限
        //  https://developers.google.com/drive/API/v2/about-auth
        scope: "https://www.googleAPIs.com/auth/drive.readonly"
      });

      //  step 3 弹出登入授权框
      if (!window.gAPI.auth2.getAuthInstance().isSignedIn.get()) {
        window.gAPI.auth2
          .getAuthInstance()
          .signIn({ prompt: "select_account" });
      }

      //  step 4 一切准备就绪, 开始递归遍历目录
      //  建立的测试 test 目录的 ID
      //  如果你要获取自己的文件夹, 替换成自己文件夹的ID即可 (这个文件夹必须是你当前登入账号能访问的)
      let folderId = "1KjpYmHtbn2NcMHkYW_mzKOg5aN6y-oup";
      fetch(folderId).then(res => {
        //  现在就得到我们要的结果啦!
        console.log(res);
      });
    });
  });
}

/**
 * 递归 抓取 Google Drive 指定文件ID的目录树
 * @param folderId
 * @returns {Promise<void>}
 */
async function fetch(folderId) {
  let files = await fetchFilesInParent(folderId);
  if (files.length > 0) {
    files.map(async item => {
      if (item.mimeType === "application/vnd.google-apps.folder") {
        item.children = await fetch(item.id);
      }
    });
  }
  return files;
}

/**
 * 获取指定Google Drive指定文件夹 ID 下面的文件
 */
function fetchFilesInParent(folderId) {
  return new Promise(resolve => {
    //  调取 Google Drive V3 API 中 files 下面的 list 方法
    //  https://developers.google.com/drive/API/v3/reference/files/list
    window.gAPI.client.drive.files
      .list({
        spaces: "drive",
        //  这里我们使用 in parents 进行搜索, 其他搜索规则可以参考
        //  https://developers.google.com/drive/API/v3/search-files
        q: `'${folderId}' in parents`
      })
      .then(res => {
        resolve(res.result.files);
      });
  });
}
```

部分功能点, 已经在上诉代码中加了注释, 如果还有不懂的地方, 请在下面留言提交, 我会尽快回复哈.
先让我们看下打印出的结果

```json
[
  {
    "kind": "drive#file",
    "id": "1fs0AJqaNiAAr2t7Z_AnabC11JMBnAbIa",
    "name": "images",
    "mimeType": "application/vnd.google-apps.folder",
    "children": [
      {
        "kind": "drive#file",
        "id": "1O6R6iQ1ayX6T-T_x7zkGl88bZCLiIArS",
        "name": "cats",
        "mimeType": "application/vnd.google-apps.folder",
        "children": [
          {
            "kind": "drive#file",
            "id": "1pPKoAdDi25q6Mng2su-7xe9Tg9gSH9Eg",
            "name": "1.jpg",
            "mimeType": "image/jpeg"
          },
          {
            "kind": "drive#file",
            "id": "1-3ufUdb2CSyrw66jfw9Q_h1qrkmZxUPK",
            "name": "2.jpg",
            "mimeType": "image/jpeg"
          }
        ]
      },
      {
        "kind": "drive#file",
        "id": "1lOSxwqUR3JcfB0Lp6Zf1ouxwFdW0amot",
        "name": "2.jpg",
        "mimeType": "image/jpeg"
      },
      {
        "kind": "drive#file",
        "id": "1pM3cFuUtDzlAJbU9q6sOUVdQJ-aO-wHQ",
        "name": "1.jpg",
        "mimeType": "image/jpeg"
      }
    ]
  },
  {
    "kind": "drive#file",
    "id": "1wWY6eJVm_0u44MXWNonkl9Wu1jnyVUAP",
    "name": "index.html",
    "mimeType": "text/html"
  }
]
```

上述结果完全达到了我们想要的结果,
我使用`console.time()`计算了整个过程所需要耗费的时间为`167.93505859375ms`,
这么看来速度也很理想.
但是经过本人实战项目使用后

> 实战项目需要生成 Google Drive 至少 **1 万** 多条的文件目录树, 而且层级特别深, 能达到 5~6 级,

该方法的缺点也逐渐暴露出来

#### 优点

1. 实现简单, 代码通俗易懂且易控制.
2. 用户验证很简单, 直接在浏览器中进行登入即可.
3. 抓取**少量**文件目录树很快(此处的少,包含目录层级深度)

#### 缺点

1. 大量递归文件耗时很长, 取决于你文件的层级深度与文件量, 此时也暴露了 JS 的另外一个缺点就是线程管理, 此条缺点本人使用`python`多线程进行处理, 是可以完美解决的.
2. 致命缺点, 遍历大文件时因需要不断的发送 API 调用请求, 导致并发量太高, 1 分钟内的 API 调用配额很容易超出, 一旦超出就会得到以下报错.
   ![quotas](https://i.imgur.com/A4smJUd.png)

##### 方法一 总结

适合少量文件且目录层级不深的文件树获取,
如果你要抓取大量且目录层级很深的目录结构估计得考虑其他方法了.
当然你也可能想, 那我控制递归的间隔不就能避免 1 分钟内的配额超出问题了吗?
确实是可以避免, 而且使用 python 的线程池也很好处理, 但是这会大量增加请求时间.
本人的实在项目中, 尝试生成 1 万+的目录数据, 控制其 API 调用频率, 花费了 2~3 个小时. 算了吧...

## 方法 二: 使用 Google Apps Script

关于`Google Apps Script`的使用, 可以参考我的另一篇文章[Google Apps Script 快速入门与实践](https://developers.google.com/apps-script),
这里就不过多描述了, 因为其并非本文重点.
Google Apps Script 代码如下, 此文件是以.gs 结尾,但是语法是跟 Javascript 一样的.

```javascript
function generateFolderTree(id) {
  var obj = {};

  try {
    var parentFolder = DriveApp.getFolderById(id);
    obj = getFolderInfo(parentFolder);

    getChildrenFiles(parentFolder, obj);
    return JSON.stringify(obj);
  } catch (e) {
    Logger.log(e.toString());
  }
}

//  递归获取指定文件夹的子级信息
function getChildrenFiles(parent, obj) {
  var childFolders = parent.getFolders();
  while (childFolders.hasNext()) {
    var childFolder = childFolders.next();
    obj.children.push(
      getChildrenFiles(childFolder, getFolderInfo(childFolder))
    );
  }

  //  遍历下面的文件
  var files = parent.getFiles();
  while (files.hasNext()) {
    var file = files.next();
    obj.children.push({
      name: file.getName(),
      url: file.getUrl(),
      id: file.getId()
    });
  }

  return obj;
}

//  获取一个文件夹的信息
//  更多参数可以查看这里
//  https://developers.google.com/apps-script/reference/drive/drive-app#properties
function getFolderInfo(folder) {
  return {
    name: folder.getName(),
    url: folder.getUrl(),
    id: folder.getId(),
    children: []
  };
}
```

看我们的 JS 调用部分

```javascript
//  step 1 加载 Google API SDK
let tag = document.createElement("script");
tag.onload = main;
tag.src = "https://APIs.google.com/js/API.js";
document.body.appendChild(tag);

function main() {
  //  step 2 加载相关API
  //  使用 OAuth 2.0 访问 Google APIs
  //  https://developers.google.com/identity/protocols/OAuth2
  window.gAPI.load("client:auth2", () => {
    //  加载 Google Drive V3 API
    window.gAPI.client.load("script", "v1", async () => {
      await window.gAPI.client.init({
        //  下面的 APIKey 和 clientId 请使用自己的, 这里使用的已经进行修改.
        //  你是不能直接使用的, 关于如何获取, 上文中已经提到
        APIKey: "AIzaSyAHzBdtTpA7yT0VriAQJzEYt58do8rnsW4",
        clientId:
          "898500841412-h6n3afm23uq8jp4i9luDr547jbdon4u8.apps.googleusercontent.com",
        scope: "https://www.googleAPIs.com/auth/drive.readonly"
      });

      //  step 3 弹出登入授权框
      if (!window.gAPI.auth2.getAuthInstance().isSignedIn.get()) {
        window.gAPI.auth2
          .getAuthInstance()
          .signIn({ prompt: "select_account" });
      }

      //  step 4 一切准备就绪, 开始执行远程API
      let res = await window.gAPI.client.script.scripts.run({
        scriptId: "Mf1V5aQjnjyjtGwJYbhhPFaquHH5LbPfM",
        resource: {
          function: "generateFolderTree",
          parameters: "1KjpYmHtbn2NcMHkYW_mzKOg5aN6y-oup",
          devMode: true
        }
      });
      console.log(res);
    });
  });
}
```

部分功能点，已经在上诉代码中加了注释，如果还有不懂的地方，请在下面留言提交，我会尽快回复哈.
先让我们看下打印出的结果

```json
{
  "name": "test",
  "url": "https://drive.google.com/drive/folders/1KjpYmHtbn2NcMHkYW_mzKOg5aN6y-oup",
  "id": "1KjpYmHtbn2NcMHkYW_mzKOg5aN6y-oup",
  "children": [
    {
      "name": "images",
      "url": "https://drive.google.com/drive/folders/1fs0AJqaNiAAr2t7Z_AnabC11JMBnAbIa",
      "id": "1fs0AJqaNiAAr2t7Z_AnabC11JMBnAbIa",
      "children": [
        {
          "name": "cats",
          "url": "https://drive.google.com/drive/folders/1O6R6iQ1ayX6T-T_x7zkGl88bZCLiIArS",
          "id": "1O6R6iQ1ayX6T-T_x7zkGl88bZCLiIArS",
          "children": [
            {
              "name": "1.jpg",
              "url": "https://drive.google.com/file/d/1pPKoAdDi25q6Mng2su-7xe9Tg9gSH9Eg/view?usp=drivesdk",
              "id": "1pPKoAdDi25q6Mng2su-7xe9Tg9gSH9Eg"
            },
            {
              "name": "2.jpg",
              "url": "https://drive.google.com/file/d/1-3ufUdb2CSyrw66jfw9Q_h1qrkmZxUPK/view?usp=drivesdk",
              "id": "1-3ufUdb2CSyrw66jfw9Q_h1qrkmZxUPK"
            }
          ]
        },
        {
          "name": "2.jpg",
          "url": "https://drive.google.com/file/d/1lOSxwqUR3JcfB0Lp6Zf1ouxwFdW0amot/view?usp=drivesdk",
          "id": "1lOSxwqUR3JcfB0Lp6Zf1ouxwFdW0amot"
        },
        {
          "name": "1.jpg",
          "url": "https://drive.google.com/file/d/1pM3cFuUtDzlAJbU9q6sOUVdQJ-aO-wHQ/view?usp=drivesdk",
          "id": "1pM3cFuUtDzlAJbU9q6sOUVdQJ-aO-wHQ"
        }
      ]
    },
    {
      "name": "index.html",
      "url": "https://drive.google.com/file/d/1wWY6eJVm_0u44MXWNonkl9Wu1jnyVUAP/view?usp=drivesdk",
      "id": "1wWY6eJVm_0u44MXWNonkl9Wu1jnyVUAP"
    }
  ]
}
```

上述结果也完全达到了我们想要的结果,
我使用`console.time()`计算了整个过程所需要耗费的时间为`1756.237060546875ms`,
速度比第一种方法慢了近 10 倍!但是还在可接受范围
再次经过实战之后(还是之前的项目 1 万+的文件与 5~6 级深的目录树), 总结以下优缺点

#### 优点

1. 整个过程只需要发送一次 Google Script API, 完美的避免了单位时间内配额超出的问题
2. 用户验证很简单, 直接在浏览器中进行登入即可.
3. 抓取**少量**文件目录树还算快(此处的少,包含目录层级深度)

#### 缺点

1. 大量递归文件耗时很长, 取决于你文件的层级深度与文件量, 在测试中看到速度比方法一慢了 10 倍.
2. 还需要掌握 Google Apps Script 的编写与调用, 相对于没接触过的同学来说入门难度大.
3. 致命缺点, 免费版脚本(Google Apps Script)最大执行时间只有**6 分钟**!!!, [官方对照表](https://developers.google.com/apps-script/guides/services/quotas#current_limitations)
   这意味着如果你的目录多点, 文件夹在多点, 一旦执行时间超过 6 分钟将会报错. 这里经过测试, 大概超过 100 个文件夹夹就不行了.

##### 方法二 总结

依然只适合少量文件且目录层级不深的文件树获取,
但是不管怎么样避免了单位时间内配额溢出的问题.
如果你的项目要在 6 分钟之内能执行完, 那这个方法将是不错的选择.

## 方法 三: 使用 DriveTreeCreator

经过对[Google Drive Search Files](https://developers.google.com/drive/API/v3/search-files)接口的研究, 得出以下几条关键点,

1. 只能通过`'parentId' in parents`, 这种规则,获取父 ID 为指定 ID 下对应的文件夹与文件.
   我们并不能获取孙子级文件夹与文件.
2. 通过`list`方法获取的文件中包含`parents`字段, 该字段包含了父文件夹的信息.
3. 我们可以通过`'ownerName' in owners`, 获取指定用户下面的所有文件夹(此规则在 Google Drive Search Files 中并未暴露, 但是确实可用)

根据以上情况, 那么我们要生成大量文件的目录树也相对简单.
思路如下

1. 通过`'ownerName' in owners`获取该用户下的**所有**文件夹与文件,
   当然你也可以不传`q`让其直接获取你整个 Google Drive 下的文件夹与文件
2. 获取完数据后, 根据`parents`字段, 在本地递归遍历生成文件树.

针对以上思路, 本人开源了一个 Github 项目[DriveTreeCreator](https://github.com/carl-jin/DriveTreeCreator), 以下代码均会直接调用该项目.
直接上代码!

```javascript
//  引入上面提到的DriveTreeCreator
//  原文件, 你可以到这里找到
//  https://github.com/carl-jin/DriveTreeCreator/blob/master/app/js/DriveTreeCreator.js
import DriveTreeCreator from "./DriveTreeCreator";

(async () => {
  let D = new DriveTreeCreator({
    googleAPI: {
      //  下面的 APIKey 和 clientId 请使用自己的, 这里使用的已经进行修改.
      //  你是不能直接使用的, 关于如何获取, 上文中已经提到
      clientId:
        "898500841412-h6n3afm23uq8jp4i7lu2r547jbdon5u8.apps.googleusercontent.com",
      APIKey: "AIzaSyAHz9dtvpA7yT0VaiBQJzDYt58do8rnsW4",
      folderId: "1KjpYmHtbn2NcMHkYW_mzKOg5aN6y-oup",
      //  owner字段该如何填写, 请看项目的README.md
      //  https://github.com/carl-jin/DriveTreeCreator
      owner: "carjin@gmail.com"
    }
  });

  //  step 3
  //  initialization google API environment
  await D.init();

  //  step 4
  //  get pop page to sign in google account
  !D.isSignIn() && (await D.signIn());

  //  step 5
  //  time to roll!
  let data = await D.start();
  console.log(data);
})();
```

让我们来看下输出的结果

```json
[
  {
    "id": "1KjpYmHtbn2NcMHkYW_mzKOg5aN6y-oup",
    "name": "test",
    "createdTime": "2019-11-15T19:34:31.578Z",
    "webViewLink": "https://drive.google.com/embeddedfolderview?id=1KjpYmHtbn2NcMHkYW_mzKOg5aN6y-oup",
    "mimeType": "application/vnd.google-apps.folder",
    "parents": ["0AFDXKiy2B1jWUk9PVA"],
    "children": [
      {
        "id": "1fs0AJqaNiAAr2t7Z_AnabC11JMBnAbIa",
        "name": "images",
        "createdTime": "2019-11-15T19:35:14.498Z",
        "webViewLink": "https://drive.google.com/embeddedfolderview?id=1fs0AJqaNiAAr2t7Z_AnabC11JMBnAbIa",
        "mimeType": "application/vnd.google-apps.folder",
        "parents": ["1KjpYmHtbn2NcMHkYW_mzKOg5aN6y-oup"],
        "children": [
          {
            "id": "1pM3cFuUtDzlAJbU9q6sOUVdQJ-aO-wHQ",
            "name": "1.jpg",
            "size": "51708",
            "createdTime": "2019-11-15T19:36:28.178Z",
            "webContentLink": "https://drive.google.com/uc?id=1pM3cFuUtDzlAJbU9q6sOUVdQJ-aO-wHQ&export=download",
            "webViewLink": "https://drive.google.com/file/d/1pM3cFuUtDzlAJbU9q6sOUVdQJ-aO-wHQ/preview?usp=drivesdk",
            "mimeType": "image/jpeg",
            "parents": ["1fs0AJqaNiAAr2t7Z_AnabC11JMBnAbIa"],
            "fileExtension": "jpg",
            "downloadUrl": "https://doc-0g-0k-docs.googleusercontent.com/docs/securesc/56tl562cpoqujghiphtr0ad4n92jmcee/ehcte4kmvjqdci2ju8uuu90lb7u71mqe/1573869600000/04850587943627626541/04850587943627626541/1pM3cFuUtDzlAJbU9q6sOUVdQJ-aO-wHQ?e=download&gd=true"
          },
          {
            "id": "1lOSxwqUR3JcfB0Lp6Zf1ouxwFdW0amot",
            "name": "2.jpg",
            "size": "51708",
            "createdTime": "2019-11-15T19:36:41.722Z",
            "webContentLink": "https://drive.google.com/uc?id=1lOSxwqUR3JcfB0Lp6Zf1ouxwFdW0amot&export=download",
            "webViewLink": "https://drive.google.com/file/d/1lOSxwqUR3JcfB0Lp6Zf1ouxwFdW0amot/preview?usp=drivesdk",
            "mimeType": "image/jpeg",
            "parents": ["1fs0AJqaNiAAr2t7Z_AnabC11JMBnAbIa"],
            "fileExtension": "jpg",
            "downloadUrl": "https://doc-0c-0k-docs.googleusercontent.com/docs/securesc/56tl562cpoqujghiphtr0ad4n92jmcee/bo20r75s5q5fgu07r8al0rqf1qhfv2a3/1573869600000/04850587943627626541/04850587943627626541/1lOSxwqUR3JcfB0Lp6Zf1ouxwFdW0amot?e=download&gd=true"
          },
          {
            "id": "1O6R6iQ1ayX6T-T_x7zkGl88bZCLiIArS",
            "name": "cats",
            "createdTime": "2019-11-15T19:39:20.962Z",
            "webViewLink": "https://drive.google.com/embeddedfolderview?id=1O6R6iQ1ayX6T-T_x7zkGl88bZCLiIArS",
            "mimeType": "application/vnd.google-apps.folder",
            "parents": ["1fs0AJqaNiAAr2t7Z_AnabC11JMBnAbIa"],
            "children": [
              {
                "id": "1pPKoAdDi25q6Mng2su-7xe9Tg9gSH9Eg",
                "name": "1.jpg",
                "size": "51708",
                "createdTime": "2019-11-15T19:39:29.694Z",
                "webContentLink": "https://drive.google.com/uc?id=1pPKoAdDi25q6Mng2su-7xe9Tg9gSH9Eg&export=download",
                "webViewLink": "https://drive.google.com/file/d/1pPKoAdDi25q6Mng2su-7xe9Tg9gSH9Eg/preview?usp=drivesdk",
                "mimeType": "image/jpeg",
                "parents": ["1O6R6iQ1ayX6T-T_x7zkGl88bZCLiIArS"],
                "fileExtension": "jpg",
                "downloadUrl": "https://doc-0c-0k-docs.googleusercontent.com/docs/securesc/56tl562cpoqujghiphtr0ad4n92jmcee/av6of2rnbcjadmsbu9i6dg361ikq9t3k/1573869600000/04850587943627626541/04850587943627626541/1pPKoAdDi25q6Mng2su-7xe9Tg9gSH9Eg?e=download&gd=true"
              },
              {
                "id": "1-3ufUdb2CSyrw66jfw9Q_h1qrkmZxUPK",
                "name": "2.jpg",
                "size": "51708",
                "createdTime": "2019-11-15T19:39:25.880Z",
                "webContentLink": "https://drive.google.com/uc?id=1-3ufUdb2CSyrw66jfw9Q_h1qrkmZxUPK&export=download",
                "webViewLink": "https://drive.google.com/file/d/1-3ufUdb2CSyrw66jfw9Q_h1qrkmZxUPK/preview?usp=drivesdk",
                "mimeType": "image/jpeg",
                "parents": ["1O6R6iQ1ayX6T-T_x7zkGl88bZCLiIArS"],
                "fileExtension": "jpg",
                "downloadUrl": "https://doc-14-0k-docs.googleusercontent.com/docs/securesc/56tl562cpoqujghiphtr0ad4n92jmcee/g9jgqg9ormutb19tnf244vn66ptqio9i/1573869600000/04850587943627626541/04850587943627626541/1-3ufUdb2CSyrw66jfw9Q_h1qrkmZxUPK?e=download&gd=true"
              }
            ]
          }
        ]
      },
      {
        "id": "1wWY6eJVm_0u44MXWNonkl9Wu1jnyVUAP",
        "name": "index.html",
        "size": "0",
        "createdTime": "2019-11-15T19:34:56.184Z",
        "webContentLink": "https://drive.google.com/uc?id=1wWY6eJVm_0u44MXWNonkl9Wu1jnyVUAP&export=download",
        "webViewLink": "https://drive.google.com/file/d/1wWY6eJVm_0u44MXWNonkl9Wu1jnyVUAP/preview?usp=drivesdk",
        "mimeType": "text/html",
        "parents": ["1KjpYmHtbn2NcMHkYW_mzKOg5aN6y-oup"],
        "fileExtension": "html",
        "downloadUrl": "https://doc-0c-0k-docs.googleusercontent.com/docs/securesc/56tl562cpoqujghiphtr0ad4n92jmcee/hu925dg4nlp5tpmg1hjn5m5hcc9ijd7o/1573869600000/04850587943627626541/04850587943627626541/1wWY6eJVm_0u44MXWNonkl9Wu1jnyVUAP?e=download&gd=true"
      }
    ]
  }
]
```

上述结果也完全达到了我们想要的结果,
我使用`console.time()`计算了整个过程所需要耗费的时间为`272.864990234375ms`,
速度与第一种方法基本上差不多, 因为每次理想批量获取 1000 条
(这是 google 给的限制, 实际上只返回了 460 条)实际速度要比第一种递归遍历快多了.
现在实战项目就是用的这种方法, 获取 1 万+的文件与 5~6 级深的目录树也不到 1 分钟. 还是非常快的. 总结以下优缺点

#### 优点

1. API 只进行了少量的调取, 1 万份文件才发送大概 21 条请求, 基本上避免了单位时间内配额溢出的问题
2. 用户验证很简单, 直接在浏览器中进行登入即可.
3. 不管少量还是大量文件, 因为是本地进行递归生成目录树, 抓取生成都很快.
4. 因为已经有现成的开源类(上面有提到), 调用起来还是及其方便的.

#### 缺点

1. 你可能需要引入一个 12k 的源文件, 压缩完大概 2~3kb.
2. 因为每次都要获取指定用户下面的所有文件, 所以一些没有用到的文件也被抓取了下来.
   这意味着如果你的 Google Drive 里面有很多无关的文件, 这将会大大拖慢效率.
   不过这块对应的解决方法是单独在开一个 Google 账号, 然后把要抓取的文件共享给他就行.
   这样这个新开的账号里面只有目标文件夹, 就不会造成资源浪费的问题了. 本人在实战项目中也是这样干的.

##### 方法三 总结

不管层级深浅, 速度表现相对于来说算是最好的, 实现方式也较为简单.
极大程度的避免了单位时间内配额溢出的问题
如果你的项目文件数量庞大, 这将是一个不错的解决方案.

# 总结

如果你只需要生成少量文件树, 那么**方法一**是不错的选择.
如果你的文件夹与文件数量在 50+~100 之间, 那么**方案二**是不错的选择.
在任何情况下, 方法三都是**最好**的选择! 没有之一.

> 本文纯手写, 总结了项目开发中针对 Google Drive 目录树生成的几种方法.
> 如果你有任何的疑问或者有更好的获取方法, 请在下方留言让我们一起贡献社区.
