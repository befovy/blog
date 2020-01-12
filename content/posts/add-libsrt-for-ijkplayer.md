---
title: "ijkplayer 增加 SRT 协议指南与踩坑"
date: 2020-01-12T10:38:03+08:00
draft: false
Tags: ["ijkplayer", "ffmpeg"]
---
[fijkplayer](https://github.com/befovy/fijkplayer "fijkplayer") 项目开源也有小半年了，这是我第一个开源项目，作为一个 Flutter 媒体播放插件，fijkplayer 有明确存在的实际使用场景，在项目维护上我也是费了不少心思。我为这个项目精心编写了使用文档，并维护了一个交流群。

本周二第一次有用户在群里提出定制开发的需求： **为 fijkplayer 提供 SRT 协议支持**。恰好最近年末有点时间，没犹豫就答应了。本来想着很简单几个小时就能搞定，但结果却硬生生肝了 3 天。

这篇文章总结在 ijkplayer 项目基础上为其增加 SRT 协议支持的过程并附有完整步骤，以及一些需要注意的坑。<br />完整代码修改请看 [这个 github pull request](https://github.com/befovy/ijkplayer/pull/14/files "这个github pull request") 。

## SRT 协议是什么

<img src="https://cdn.jsdelivr.net/gh/befovy/images@master/images/2020/01/12/20200112104433.png"/>

SRT（Secure Reliable Transport） 是比较新的开源安全可靠网络传输协议。正如其名，特点就是安全、可靠。SRT 支持 AES 加密，保障端到端的信息传输安全，SRT 通过前向纠正技术（FEC）保证传输稳定，使用自动重传（ARQ）机制保证传输完整性。<br />SRT 基于 UDT 传输协议，在 UDT 核心思想和机制的基础上做了多项改进，对于音视频流数据优化最为明显，可以用于低延迟音视频的直播业务中。

SRT 是一个开源的解决方案，具有跨平台的协议实现。使用统一 API，在不同平台上可重复构建集成。SRT 已经被领先的开源项目采用，比如知名的跨平台多媒体播放器 VLC 以及音视频领域的瑞士军刀 FFmpeg。

## FFmpeg 对 SRT 协议的支持

FFmpeg 在 4.0 版本（April 20th, 2018, FFmpeg 4.0 "Wu"）中新增了对 SRT 的支持。

> Haivision SRT protocol via libsrt

有了这个支持，才能实现 ijkplayer 播放 srt 流。要知道 ijkplayer 中网络协议、解复用、解码用的都是 FFmpeg 的 API。如果 FFmpeg 没有对 SRT 的支持，那我也不能指望自己能够短期吃透 SRT 协议并加入到 FFmpeg 中。

**ijkplayer 能用 4.0 版本的 FFmpeg 吗？**

ijkplayer 项目中用到的 FFmpeg 中还是有不少修改，增加了好几个 IJK 的 Protocol。编译 ijkplayer 如果直接用未修改的官方 [FFmpeg/FFmpeg](https://github.com/ffmpeg/ffmpeg "FFmpeg/FFmpeg")，是会出现链接错误的。

这里告诉各位一个技巧，快速知悉 B 站开源 FFmpeg 的最近动态。不知道的老铁快去 github 上 Watch 一下 [bilibili/FFmpeg](https://github.com/bilibili/ffmpeg "bilibili/FFmpeg")，目前竟然只有 44 个 Watcher，看来大家都关注光鲜亮丽的 ijkplayer，却忽视了幕后英雄。

<img src="https://cdn.jsdelivr.net/gh/befovy/images@master/images/2020/01/12/20200112104528.png"/>

通过查看 bilibili/FFmpeg 最近更新，发现 bilibili 也已经跟进到 4.0 版本了。需要注意的是 bilibili/FFmpeg master 分支没有变动，需要在 release 下查看最近更新的 tag。
或者 clone 下来使用命令  `git tag --list`  查看更新。

可以看到虽然 ijkplayer 在 0.8.8 版本已经停留了很久，但是背后 FFmpeg 一直在默默更新，已经跟进到了 4.0 版本，并且 ijkplayer 也到了 0.8.20  0.8.23  0.8.25 版本，只不过还没有放出更新。

```java
ff3.4--ijk0.8.7--20180322--001
ff3.4--ijk0.8.7--20180404--001
ff3.4--ijk0.8.7--20180428--001
ff3.4--ijk0.8.7--20180607--001
ff3.4--ijk0.8.7--20180612--001
ff3.4--ijk0.8.8--20180705--001
ff3.4--ijk0.8.8--20180706--001
ff3.4--ijk0.8.8--20191230--001
ff4.0--ijk0.8.20--20180626--001
ff4.0--ijk0.8.20--20180704--001
ff4.0--ijk0.8.23--20180712--001
ff4.0--ijk0.8.23--20180720--001
ff4.0--ijk0.8.25--20180127--001
ff4.0--ijk0.8.25--20180128--001
ff4.0--ijk0.8.25--20180129--001
ff4.0--ijk0.8.25--20180130--001
ff4.0--ijk0.8.25--20180721--001
ff4.0--ijk0.8.25--20180722--001
ff4.0--ijk0.8.25--20180724--001
```

在 2019 年最后一天，大佬还认真在发版本   `ff4.0--ijk0.8.25--20191231--001`

```
commit cc116330834a592e544d20ea5a4472db7c32abb8 (HEAD, tag: ff4.0--ijk0.8.25--20191231--001)
Author: zhenghanchao <zhenghanchao@bilibili.com>
Date:   Mon Dec 30 11:16:47 2019 +0800

    tcp: add ipv6 async check
```

再回到 SRT 上来，FFmpeg 怎么开启对 SRT 的支持呢？<br />打开 FFmpeg，搜索 srt 找到了 `ff_libsrt_protocol` 。进一步找到 configure 文件中的  `libsrt_protocol_deps="libsrt"` 以及

```
enabled libsrt            && require_pkg_config libsrt "srt >= 1.2.0" srt/srt.h srt_socket
--enable-libsrt          enable Haivision SRT protocol via libsrt [no]
```

这看起来和在 FFmpeg 中启动 Openssl 类似。需要在 configure FFmpeg 项目的时候增加参数 `--enable-libsrt`  并让 pkg-config 能够找到编译好的 libsrt 库。

## 行得通吗，桌面端快速尝试

前面简单判断了一下在 ijkplayer 中增加 srt 收流支持的可行性，答案是肯定的。<br />但实际过程有没有坑呢？很难说。所以我先在 MacOS 上进行试验，在 MacOS 上进行试验不需要交叉编译，并且不需要连接手机或者开模拟器，方面快捷。

你说 ijkplayer 不支持 Mac OS 桌面端？

对，官方 ijkplayer 是不支持桌面端，但是我自己给 ijkplayer 增加了桌面端支持，目标是 Windows Linux MacOS 全都支持，虽然还没完成，但是目前实现的部分已经能在 MacOS 上进行播放了，所以用来验证 SRT 可行性不成问题。

### 编译 MacOS 平台的 libsrt 和 FFmpeg

从 [github](https://github.com/Haivision/srt "github") 下载 libsrt 项目，定睛一看这个库用 CMake 进行构建，并且包装了一层 configure 配置，让熟悉 linux 下 configure 、make 流程的用户也能顺利编译项目。

MacOS 下编译 libsrt 的完整脚本见[这里](https://github.com/befovy/ijkplayer/pull/14/files?file-filters%5B%5D=.sh&file-filters%5B%5D=dotfile#diff-9325129d8e466bea4f18e622c3e363c3 "这里")。很简单，基本不会遇到什么问题，主要就是 configure 参数，运行  `./configure --help`  会输出 configure 参数的帮助文档。<br />主要配置的参数如下，设定安装路径，告诉去哪里找 openssl，编译静态库，去掉动态库。

```
FF_CFG_FLAGS="$FF_CFG_FLAGS --cmake-prefix-path=${FF_PREFIX}"
FF_CFG_FLAGS="$FF_CFG_FLAGS --cmake-install-prefix=${FF_PREFIX}"
FF_CFG_FLAGS="$FF_CFG_FLAGS --use-openssl-pc=on"
FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-shared=off"
FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-static=on"
FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-apps=on"
FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-c++-deps=on"
FF_CFG_FLAGS="$FF_CFG_FLAGS --enable-cxx11=on"
```

然后是编译 MacOS 上启用了 srt 的 FFmpeg，参照 FFmpeg 中 enable  openssl 的脚本，加上 enable libsrt 的修改就行，具体内容[看这里](https://github.com/befovy/ijkplayer/pull/14/files#diff-263e458cbb0929a6fc8f3f122705b29c "看这里"))。

这里也基本没什么坑，毕竟桌面原生编译方便，交叉编译真是太痛苦了。

### 测试 srt 流播放

用 ffmpeg 把一个本地文件以 ts 格式推到本机 udp 1234 端口

```
ffmpeg -re -i ./demo.mkv  -f mpegts "udp://127.0.0.1:1234?pkt_size=1316"
```

用刚才编译 libsrt 时生成的可执行文件将 udp 协议转发到 srt 协议

```
./srt-live-transmit udp://:1234 srt://:4201 -v
```

然后就可以使用地址 `srt://127.0.0.1:4201` 进行收流了。  
到这里还都比较顺利，MacOS 版到 ijkplayer 成功收到了 srt 流。

## 编译 Android libsrt 静态库

前面在 MacOS 目标平台验证了 ijkplayer 中增加 srt 的确是可行的，并且在 MacOS 上编译还都挺顺利。但我明白，现在真正的坑在刚刚开始，尤其是对于缺乏交叉编译经验的我来说。如果参数配置不当，会出现各种各样的问题，特别是 Android NDK 还有跨版本兼容问题。

### 坑 No. 1：目标平台识别错误

我配置了 configure 的参数，加上了 android toolchain 的 path，并且增加 compiler-prefix，但是 CMake 执行输出中总是 DARWIN，而不是 Android，这样肯定没法编译了。

`./configure --help` 也没提示平台相关的内容，这怎么办呢？

经过观察，发现 congifure 为识别的参数都会转为大写并把减号替换为下划线作为参数传递给 Cmake 命令，所以增加了参数 `--cmake-system-name=Android` ，这回 Cmake 总算成功识别目标平台了，但是却输出错误，不支持 Android。也就是坑 2.

<a name="Q1Alt"></a>

### 坑 No. 2：libsrt CMake 文件不支持 Android

这个还比较好处理，毕竟我对于 CMake 是相当的熟悉。简单改改，顺便提交一个 [pull request](https://github.com/Haivision/srt/pull/1053 "pull request")。

成功编译处理 Android 目标平台的 libsrt 静态库。根据这个又增加 `--cmake-android-arch-abi=armeabi-v7a`  等编译不同架构的 Android 平台库。

## 编译支持 SRT 的 Android FFmpeg

编译完 Android 目标平台的 libsrt，然后继续编译 FFmpeg。并打开 configure 选项 `--enable-libsrt` 。

### 坑 No. 3: srt_socket 符号找不到

--enable-libsrt 之后，ffmpeg 却找不到 libsrt，查看 ffmpeg config.log，其中出错信息为：找不到符号 srt_socket。 仔细琢磨为什么找不到符号了，明明可以用 nm 命令查看到 libsrt.a 中是有这个符号的。再仔细瞅瞅，发现 config.log 中最后这一次尝试编译一个 test 文件没有 -lsrt，没有链接 srt 库。<br />到这我就怀疑是 pkg-config 出错了，没有找到 libsrt 库。<br />经过一番折腾，把 openssl libsrt 以及 ffmpeg 的 build prefix 都设置为相同目录，它们输出的 pkg config 文件也都在相同目录，这个目录在脚本中设置为 PKG_CONFIG_PATH。<br />总算是没有这个错了。

### 坑 No. 4: pc 文件缺少链接参数

同样是 config.log 中给出错误，这次链接错误非常多，一看全是 C++ new 、 std::string 等等这些 C++ 标准库中的符号。在搜搜有没有遇到同样问题的。最后解决办法是要修改 libsrt 输出的 srt.pc 文件，增加额外的链接库。

```
sed -i '' 's|-lsrt   |-lsrt -lc -lm -ldl -lcrypto -lssl -lstdc++|g' ${FF_PREFIX}/lib/pkgconfig/srt.pc
```

### 坑 No. 5: srand 找不到

最后这个更奇怪了，srand 符号找不到，靠着 google 找到了相关线索，可能是和 ANDROID_API 版本有关。又仔细看前面各个步骤的编译输出，发现编译 libsrt 的时候，总是输出 ANDROID_API 24。<br />所以前面编译的 libsrt.a 是支持 ANDROID_API 大于等于 24 的版本的，对于我要编译的 ffmpeg ANDROID_API 14 或者 21 ，就不兼容了。<br />解决办法是 configure libsrt 的时候增加参数 `--cmake-android-api=$CMAKE_ANDROID_API"`

<img src="https://cdn.jsdelivr.net/gh/befovy/images@master/images/2020/01/12/20200112104604.png"/>


---

## 总结

上面的过程全都写在脚本里了，在合并 pull request 后的 befovy/ijkplayer 项目中，运行下面的命令。

注意我用的是 Android NDK r15c。

```bash
./init/init-android-openssl.sh
./init/init-android-libsrt.sh
./init-android.sh
cd android/contrib

./compile-openssl.sh all
./compile-libsrt.sh all
./compile-ffmpeg.sh all
```

答应了人家的事总要完成的，不然我面子朝哪放呢。自己挖的坑还得自己填。虽然搞这个 Android 交叉编译差点让我放弃。

正经的，这种需求先初步定一个方案，判断可行性。就是前面查看 bilibili/ffmpeg 是否可以支持 4.0 版本，以及 ffmpeg 4.0 版本对 srt 的支持怎么打开。<br />再然后，手头有没有方便快捷的原型可以用于快速验证，也就是前面的 MacOS 版本的 ijkplayer，不得不说这个是真方便。

最后，就是硬着头皮啃硬骨头了。其实我也发现遇到 CMake 的坑，我都填坑比较快，其他就麻烦了，这方面要注意平时的技术积累和总结。也就是我要写这篇文章的原因了。

最后的最后，点个赞呗 ✨ 👍。
