---
title: 无法对文件进行病毒扫描 - 如何禁用Google Drive 大文件无法查毒提示
date: 2019-11-16 15:55:48
tags:
  - Google Drive
categories:
  - Front End
  - Google 接口系列
description: 无法对文件进行病毒扫描 - Google Drive 大文件无法查毒提示, 无论你想下载文件还是要远程播放音频或视频文件, 遇到这个提示直接会导致程序无法正常工作. 本文将介绍如何规避此问题.
---

> 病毒扫描：下载或共享文件之前，Google 云端硬盘会对文件进行扫描，以确认其中是否含有病毒。如果 Google 云端硬盘检测到病毒，用户就无法将受病毒感染的文件转换为 Google 文档、表格或幻灯片。如果用户尝试执行上述操作，系统就会向他们发送警告。
> 文件所有者可以下载受病毒感染的文件，但必须事先了解执行此操作会带来的风险。用户仍然可以与其他人共享文件、通过电子邮件发送受感染的文件，或更改文件的所有权。
> Google 云端硬盘仅会对小于 100 MB 的文件进行病毒扫描。对于大于 100 MB 的文件，系统会显示警告，说明无法扫描该文件。
> [https://support.google.com/a/answer/172541?hl=zh-Hans](https://support.google.com/a/answer/172541?hl=zh-Hans)

# 准备工作

本文将使用 [Google Drive V2 API](https://developers.google.com/drive/api/v2/),
有同学可能要问了, Google Drive V3 API 不是已经出来了吗? 为什么还要用 V2?
原因是 V3 API 接口未提供下文关键的 downloadUrl 字段, 只有 V2 接口才提供.
首先我们要获取`clientId`与`APIKey`
(当然下面是我做过修改的,你并不能直接用)关于如何获取 clientId 与 APIKey,
可以参考我另一篇帖子[如何获取 Google Drive API Key](https://carljin.com/how-to-enable-google-drive-api-and-get-client-credentials.html)

```javascript
{
    clientId: "898500841412-h6n32afah3uqbjp4i9lu2r4a7jbdon5u8.apps.googleusercontent.com",
    APIKey: "AIzaSyAHz9dtTpA2yTvVriBqJzDYt58do8rnsW4"
}
```

# 直接上代码

```javascript
//  step 1 加载 Google API SDK
let tag = document.createElement("script");
tag.onload = main;
tag.src = "https://apis.google.com/js/api.js";
document.body.appendChild(tag);

function main() {
  //  step 2 加载相关API
  //  使用 OAuth 2.0 访问 Google APIs
  //  https://developers.google.com/identity/protocols/OAuth2
  window.gapi.load("client:auth2", () => {
    //  加载 Google Drive V2 API
    window.gapi.client.load("drive", "v2", async () => {
      await window.gapi.client.init({
        //  下面的 APIKey 和 clientId 请使用自己的, 这里使用的已经进行修改.
        //  你是不能直接使用的, 关于如何获取, 上文中已经提到
        clientId:
          "898500841412-h6n3afvh3uq8jp9i9lu2w542jbdon5u8.apps.googleusercontent.com",
        apiKey: "AIzaSyAHz9dtTpA2yTvVriBqJzDYt58do8rnsW4",
        //  Google Drive V2 授权范围
        //  这个将会提示用户该应用程序将需要哪些权限
        //  https://developers.google.com/drive/API/v2/about-auth
        scope: "https://www.googleapis.com/auth/drive"
      });

      //  step 3 弹出登入授权框
      if (!window.gapi.auth2.getAuthInstance().isSignedIn.get()) {
        window.gapi.auth2
          .getAuthInstance()
          .signIn({ prompt: "select_account" });
      }

      //  step 4 获取文件的下载地址
      //  此处的下载地址是指该文件的真实地址, 大概长这个样
      //  https://doc-00-0s-docs.googleusercontent.com/docs/securesc/56tl562cpoqujghiphtr0ad4n92jmcee/3tf9pfo38c9j905jm43f23i8h3tav5vh/1573934400000/00948632806340913802/04850587943627626541/1gxHQ61Zg_-FvRVED_QIezNKDg9bvl1Bi?e=download&gd=true
      //  这里的 fileId 替换成你的文件ID即可
      let fileId = "1gxHQ61Zg_-FeRVEb_QIezNKDg9bva1Bi";
      window.gapi.client.drive.files
        .get({ fileId: fileId, fields: "*" })
        .execute(resp => {
          let link = document.createElement("a");
          //  这里凭借成的href, 不仅可以用来下载
          //  也可以当作audio或者video的流媒体文件播放
          //  同时也可以ajax调取
          let href = `${resp.downloadUrl}&access_token=${encodeURIComponent(
            gapi.auth2
              .getAuthInstance()
              .currentUser.get()
              .getAuthResponse(true).access_token
          )}`;
          link.download = name;
          link.href = href;
          document.body.appendChild(link);
          link.click();
          document.body.removeChild(link);
        });
    });
  });
}
```

执行上面的代码, 文件已经能成功下载下来了.

# 总结

这里需要注意的是我们要使用 Google Drive V2 接口, 因为只有 V2 接口才提供了关键的 downloadUrl 字段.
