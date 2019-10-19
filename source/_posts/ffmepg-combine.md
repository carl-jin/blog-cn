---
title: ffmepg 常用命令
date: 2019-10-13 19:40:16
tags:
  - ffmpeg
categories:
  - python
description: FFMPEG是特别强大的专门用于处理视频的开源库。你既可以使用它的API对视频进行处理，也可以使用它提供的工具，如 ffmpeg, ffplay, ffprobe，来编辑你的视频文件。本文将介绍常用的ffmpeg命令.
---

# 前言

[FFMPEG](https://www.ffmpeg.org/)是特别强大的专门用于处理视频的开源库。你既可以使用它的 API 对视频进行处理，也可以使用它提供的工具，如 ffmpeg, ffplay, ffprobe，来编辑你的视频文件。本文将介绍常用的 ffmpeg 命令.

# 常用参数

```
-y  # 执行命令并不进行询问, 跟 npm init -y类似
-i  # input 后面跟输入视频地址
-vf # 参数用于指定视频滤镜
```

# 缩放视频尺寸(不变形)

> [https://stackoverflow.com/questions/8218363/maintaining-ffmpeg-aspect-ratio](https://stackoverflow.com/questions/8218363/maintaining-ffmpeg-aspect-ratio)
> 将视频高度调整至 1080,`宽度`自适应

```bash
ffmpeg -y -i input.mp4 -vf scale=\"trunc(oh*a/2)*2:1080\" output.mp4
```

将视频宽度调整至 1920,`高度`自适应

```bash
ffmpeg -y -i input.mp4 -vf scale=\"1920:trunc(ow/a/2)*2\" output.mp4
```

# 获取指定时间的视频缩略图

```bash
ffmpeg -y -i input.mp4 -ss 00:00:02 -vframes 1 output.mp4
```

# 添加水印

> 此命令表面上是添加水印或者添加 Logo 到视频中,
> 但实际上是视频叠合功能, 所以有很多用处.
> 比如视频添加背景图, 或者画中画效果

```
ffmpeg -y -i input1.mp4 -i input2.mp4 -filter_complex overlay=120:0 output.mp4
```

参数说明:

- 这里输入了两个视频, 后者层级会比前者高, 也就意味着 `input2.mp4` 会覆盖在 `input1.mp4` 上
- `overlay`=x:y `input2.mp4` 覆盖的起始点, 例子中为 x 轴 120, y 轴 0

# 从视频中抽取可以播放的 h.264

> 此问题常用于 ffmpeg 合并视频时的`Non-monotonous DTS in output stream 0:0;`警告
> 该错误是因为视频拥有不同的时间戳,也有可能从 0 开始.
> 你可以通过`ffprobe`命令查看视频的区别.

```bash
ffmpeg -y -i input.mp4 -c copy -bsf:v h264_mp4toannexb -f mpegts output.ts
```

# 合并视频

```bash
ffmpeg -y -f concat -safe 0 -i filelist.txt -c copy -bsf:a aac_adtstoasc -movflags +faststart output.mp4
```

参数说明:

- `-safe 0` 参数用于处理 `Impossible to open`报错
- `-i filelist.txt` 这里需要传入一个`filelist.txt`文件该文件是需要合并的视频列表,大概长下面这个样子

```text
file '1.ts'
file '2.ts'
file '3.ts'
```

# 去水印

```bash
ffmpeg -y -i input.mp4 -vf delogo=x=0:y=0:w=120:h=80 -q:v 1 -max_muxing_queue_size 1024 output.mp4
```

参数说明:

- `delogo`滤镜接受`x`,`y`,`w`,`h`对应 x 轴,y 轴,宽度,高度. 从而来确定消除水印范围
- `q:v 1`避免视频受损

那么如何去掉多个水印呢? 命令也很简单

```bash
ffmpeg -y -i input.mp4 -vf "delogo=x=0:y=0:w=120:h=80, delogo=x=520:y=0:w=120:h80" -q:v 1 -max_muxing_queue_size 1024 output.mp4
```

# 视频裁切

```bash
ffmpeg -i input.mp4 -q:v 1 -max_muxing_queue_size 1024 -vf crop=1080:1820:0:100 output.mp4
```

参数说明:

- `crop`滤镜接受`width`,`height`,`x`,`y`4 个参数,用来确定裁切的范围

# 视频剪辑

```bash
ffmpeg -y -ss 00:00:02 -i input.mp4 -acodec copy -vcodec copy -t 00:02:34 -q:v 1 output.mp4
```

参数说明:

- `-ss` 参数后跟需要开始剪辑的起始时间,这里是 00:00:02
- `-t` 参数后跟需要结束剪辑的末尾时间,这里是 00:02:34

# ffprobe 命令使用

> ffprobe 命令用于获取视频的详细信息
> 这里以 python 作为演示, 以 json 格式输出视频的信息

```python
from os import popen
import json
# ...
output = popen("ffprobe -v quiet -print_format json -show_format -show_streams input.mp4").read()
json_data = json.loads(output_content)
video_width = json_data['streams'][0]['width']
print(video_width)
```

# 附加

如何水平并列合并图片?依然使用 python 实现

```python
from PIL import Image
# ...
images_array = ['1.png','2.png','3.png']
images = [Image.open(i) for i in images_array]
widths, heights = zip(*(i.size for i in images))
total_width = sum(widths)
max_height = max(heights)
new_im = Image.new('RGB', (total_width, max_height))
x_offset = 0
    for im in images:
        new_im.paste(im, (x_offset, 0))
        x_offset += im.size[0]

new_im.save('output.png')
```

#   总结
ffmpeg 还是很强大的视频处理功能库. 以上只是个人常用命令, 如果也想贡献命令, 请到这里[提交合并](https://github.com/carl-jin/blog-cn/blob/master/source/_posts/ffmepg-combine.md)!
