---
title: "Go 打造 Flutter 多版本管理工具：fvm"
date: 2019-12-08T18:31:23+08:00
draft: false
Tags: ["Flutter", "golang"]
---

周末时间用 Go 语言完成了 Flutter 多版本管理工具的初个版本 [fvm v0.1.0](https://github.com/befovy/fvm/)。我必须承认，这个版本完全是在造轮子，而且还是和 [leoafarias fvm](https://github.com/leoafarias/fvm/) 一模一样。

## 为什么造轮子

简单说就是有需求：在开发 [fijkplayer](https://github.com/befovy/fijkplayer) （一个 Flutter 的媒体播放器）的过程中，我逐渐从开始只有 Android、iOS 的移动端版本，发展到 Flutter 桌面版本。在 fijkplayer 桌面版的开发中，我用的是 [go-flutter](https://github.com/go-flutter-desktop/go-flutter) 为 Flutter 提供桌面支持，go-flutter 默认用的是 flutter beta 版本，而移动端 fijkplayer 用的是 Flutter stable 版本。

最开始每次切换我都很痛苦，flutter 切换 channel 需要下载大量内容，channel 切换完成后再跑 flutter doctor 有需要大量的下载，而且还都是国外服务器，下载非常慢。

后来我发现了 leoafarias fvm，但这个工具安装第一次没成功，其实我对 dart native 也不太懂，确实没搞定安装问题。另外 dart native 是不是真的二进制我也没有研究，要是还需要 dart 才能跑起来（就像运行 jar 需要 jvm 一样），其实我是不喜欢桌面端这种带有运行时的东西的。我就需要一个小工具而已。

所以干嘛不自己造（chao）一个呢？

刚好做 go-flutter 开发的时候对其自带工具 [hover 进行过修改](https://github.com/go-flutter-desktop/hover/pull/59) 并合并到了主分支。 hover 也是一个命令行小工具，而且可以直接通过 `go get` 安装， hover 使用库 [spf13/cobra](https://github.com/spf13/cobra) 实现命令行子命令以及参数解析等 “样板代码”，工程结构很简洁、清晰。

另一方面，我虽然很早就学习过 go 语言，并且也在很多小项目（对，主要是我上学时完成的大作业）中用过 go。用的挺多但是不够系统化，写的代码还仅仅是个 demo。最近打算让自己的 go 语言水平再上一个台阶，一个行动是加入了 [GCTT - go 中文翻译组](https://studygolang.com/subject/1) ，翻译一些国外大牛的优质文章，同时我打算认真搞一个 go 项目开源出来。 但是从啥搞起呢， 就从做一个  fvm 开始吧。

是的， 第一个版本 v0.1.0 完全实现了 leoafarias fvm 中的所有逻辑，是个不折不扣的轮子工程。但是后面的版本就从 leoafarias fvm 脱离了，我要开发中国特色的 fvm。

## cobra 创建 go 命令行工具

[spf13/cobra](https://github.com/spf13/cobra) 是一个能够帮我们快速创建 go 命令行工具的 go 库，通过提供了一个生成 "样本代码" 的 go 工具。Go 世界中鼎鼎大名的 Docker、Kubernetes、Hugo 等都用了 cobra 来构建命令。

首先，安装 cobra 工具：
```shell
› go get -u github.com/spf13/cobra/cobra
```

使用 cobra 创建项目 fvm ，并使用 github.com/befovy/fvm 作为包名：
```shell
› cobra init fvm --pkg-name github.com/befovy/fvm
```

使用 cobra add 需要的子命令：
```shell
› cobra add list
› cobra add install
› cobra add remove
› cobra add flutter
› cobra add use
› cobra add config
```

完成这些步骤后我们有了这些文件：
```shell
› tree ./
./
├── LICENSE
├── cmd
│   ├── config.go
│   ├── flutter.go
│   ├── install.go
│   ├── list.go
│   ├── remove.go
│   ├── root.go
│   └── use.go
└── main.go
```

然后我们初始化 go modules ，下载依赖并编译fvm 。

```shell
› go mod init github.com/befovy/fvm
› go mod tidy
› go build
```

编译好的 fvm 出现了，运行一下看看发生什么。

```shell
› ./fvm
A longer description that spans multiple lines and likely contains
examples and usage of using your application. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.

Usage:
  fvm [command]

Available Commands:
  config      A brief description of your command
  flutter     A brief description of your command
  help        Help about any command
  install     A brief description of your command
  list        A brief description of your command
  remove      A brief description of your command
  use         A brief description of your command

Flags:
      --config string   config file (default is $HOME/.fvm.yaml)
  -h, --help            help for fvm
  -t, --toggle          Help message for toggle

Use "fvm [command] --help" for more information about a command.
```

cobra 已经构建好了 fvm 的雏形，并且添加好了子命令。接下来就该实现 fvm 的具体逻辑了。


## fvm 的功能实现

fvm 作为一个 sdk 版本管理工具，让用户能够同时在本地安装并缓存多个 Flutter 版本，并且能够快速在各个版本间切换使用。

其核心逻辑就是在本地文件夹中缓存多个 Flutter 版本，并为项目创建指定 Flutter 版本的软链接。或者在全局环境创建指定版本的 Flutter 软链接。

内部主要功能实现都依赖于 go 语言标准库中的 `os/exec` 包。通过 `os/exec` 可以创建子进程执行命令，并管理子进程的输入输出。

fvm 的各个子命令，基本就是查找一些文件、文件夹，执行以下 git 命令并对其输出进行解析。

具体的实现都在 [代码里](https://github.com/befovy/fvm)，这里不啰嗦了。

实现中要注意检查各种可能的错误，输出错误提示给用户。如果错误影响业务逻辑继续执行，就主动退出程序。

在 fvm v0.1.0 版本中，这方便处理还不够细致。但仅这些我就感觉到了 go 中烦人的 error。后续还要进行重构，用更优雅的代码对 error 进行处理。


## 收获总结

通过实现一个 fvm 我得到了什么呢？ 

* 我给自己写了个工具，方便我切换 Fluter 版本。

* fvm 才只是一个开始，其难度还比不上我以前完成的大作业。但是 fvm 开源了、发布了。恰好刚翻译一片文章，[Go Modules : v2 及更高版本](https://blog.befovy.com/2019/12/v2-go-modules/)， 通过持续更新维护 fvm 我也能实践 Go Modules 背后的理念。

* 这个版本的 fvm 还太简单，用到的知识很少。但是如果以后遇到什么相关新的知识、牛逼idel，我也能在 fvm 中快速试水。毕竟每次用 hello world 试水太乏味了。

最后，希望 fvm 能够得到大家的关注，并且收到反馈。