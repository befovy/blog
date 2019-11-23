---
title: "我的 gitee 图床，自动上传、压缩、获取图片 url"
date: 2019-11-23T19:02:45+08:00
draft: false
---

之前在 github pages 上部署的博客图片访问一直很慢，主要是没钱买图床。
今天又花功夫用 gitee 和其他的工具给自己做了一个图床。

gitee 做图床的优点：

* 访问速度快
* ddd

结合本文提供的一套工具组合可以实现：

* 图片选中一键上传
* 剪贴板图片一键上传
* 上传完成后复制图片网址到剪贴板
* 图片上传自动压缩
* 依然完全免费

<!--more-->


# 文中用到的工具

* 码云 [gitee](https://gitee.com/) ，使用码云中的公开仓库作为图床，可以外链访问
* github，图片自动上传到 github 公开仓库
* github actions 自动把 github 仓库中的图片同步到 gitee 仓库
* github app [ImgBot](https://github.com/marketplace/imgbot) 自动压缩图片
* github actions 自动合并 ImgBot 发起的图片压缩后的 pull request
* [PicGo](https://github.com/Molunerfinn/PicGo) 图片自动上传 


# 搭建步骤

搭建步骤中是有一些问题费了些时间，但是有了我帮你踩了所有的坑并且总结这篇教程后，看到这里的你一定能够顺利搭建自己的免费好用的图床。

本文教程使用了 github action，如果你的 github 还有没激活 actions 的话，你可以使用其他的 ci 工具实现。 github 仓库中如果看不到下面这个 actions 图标，就说明还不支持 actions 功能。
![](https://gitee.com/befovy/images/raw/master/images/2019/11/23/20191123192701.png)


## github 仓库和设置

首先需要创建一个 github 仓库，比如 https://github.com/befovy/images ，创建步骤略过。

为 github 仓库安装 [ImgBot 机器人](https://imgbot.net/)。 
打开 ImgBot 网站，点击 【try for free】， ImgBot 声称开源项目能够一直免费使用其服务。
从 ImgBot 网站跳转到 github 网站后，点击 【Set up a plan】 按钮，在下一步中选择 【Open Source】 这一个免费计划。下一步是【Install it for free】。
最后到这下图这个步骤，你可以选择为所有仓库开启此功能，也可以只选择为刚刚创建的图床仓库打开 ImgBot。

<p style="text-align:center;">
<img src=https://gitee.com/befovy/images/raw/master/images/2019/11/23/20191123193909.png  width="350"/>
</p>

## 使用 github actions 自动同步到 gitee

在 gitee 也上创建一个仓库用来保存图床图片。然后为 gitee 新建一个 ssh key。并把公钥增加在 gitee 账户的设置中。

在之前创建的 github 图床仓库中编辑 actions 配置文件，新增一个 [.github/workflows/gitee.yml](https://github.com/befovy/images/blob/master/.github/workflows/gitee.yml)

```yml
name: Push to gitee

on: 
  push:
    branches:
      - master
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v1
   
    - name: Set SSH Key
      env: 
        SSH_KEY: ${{ secrets.GITEE_SSH_KEY }}
        SSH_KEY_PUB: ${{ secrets.GITEE_SSH_PUB }}
      run: |
        mkdir -p ~/.ssh
        ssh-keyscan -H gitee.com >> ~/.ssh/known_hosts
        echo ${SSH_KEY} > ~/.ssh/id_rsa
        sed -i -e "s#\\\\n#\n#g" ~/.ssh/id_rsa
        chmod 600 ~/.ssh/id_rsa
        echo ${SSH_KEY_PUB} > ~/.ssh/id_rsa.pub
        chmod 600 ~/.ssh/id_rsa.pub
     
    - name: Push to gitee
      run: |
        git switch -c master
        git remote add gitee git@gitee.com:befovy/images.git
        git push --set-upstream gitee master -f 
```

这个 actions 中主要是 checkout 当前仓库文件，配置 gitee 的 ssh 密钥，推送 git 仓库到 gitee。

密钥不能明文写在 actions 配置文件，需要保存在仓库的设置中。 在 github 仓库 设置选项中，选择左侧的 Secrets。把前面生成的 ssh 公钥和私钥都保存起来。注意私钥本身由好多行组成，但是 actions secrets 这里好像换行符会出问题，所以我们先把私钥中所有的换行用 `\n` 替换掉，替换完后私钥只剩下一行文本。 保存在这个页面的 secrets 可以在 actions 配置中使用。
我保存的名称分别是 `GITEE_SSH_KEY` 和 `GITEE_SSH_PUB` ，在 actions 配置文件中的使用方式是 `${{ secrets.GITEE_SSH_KEY }}` 。

![](https://gitee.com/befovy/images/raw/master/images/2019/11/23/20191123200528.png)

在 gitee.yml  中，我从 secrets 中取出私钥，保存在 .ssh/id_rsa 中又通过命令把其中的 `\n` 全部换成了真正的换行符。 这就是我踩过的一个大坑，不这么做后面 git push 会出错。


配置好 ssh 后，可以通过 git 命令把仓库内容 push 到 gitee 中去。
注意，github actions 中的 checkout 检出当前内容后，git 是在一个游离状态，没有分支名。需要先 `git switch -c master` 设置当前为 master 分支。


## PicGo 配置

[PicGo](https://github.com/Molunerfinn/PicGo) 是用 Electron-Vue 开发的一个图片自动上传至图床的工具。先下载安装 PicGo 到电脑中。
PicGo 支持 github、新浪、七牛等多种图床。也可以安装插件支持 gitee 图床，但是 gitee 上不能配置图片自动压缩，所以我在 github 绕了一圈，图片在 github 压缩后再同步到 gitee。

PicGo 设置如图， 我用了 githubPlus 插件，其实用默认的 github 图床功能就行。
![](https://gitee.com/befovy/images/raw/master/images/2019/11/23/20191123201205.png)
图中用到的 token 在 https://github.com/settings/tokens 页面生成。

自己修改一下 PicGo 的上传图片快捷键，选择一张图片上传。上传完成后 url 会自动复制到剪切板。 等 github actions 执行完成后，就可以通过剪贴板中的 url 访问到保存在 gitee 的图片了， gitee 的图片访问确实很快。

## github actions 自动合并 ImgBot 的 pr

上传图片后，很快 ImgBot 就会对图片进行压缩，并在 github 的仓库中发起一个 pull request。手动点击合并按钮对我来说实在是太麻烦了，能不能自动搞呢。有了 actions 没啥不能的，

在 github actions 配置新增一个文件，[.github/workflow/merge.yml](https://github.com/befovy/images/blob/master/.github/workflows/merge.yml)
```yml
name: Merge Imgbot

on:
  pull_request:
    types:
      - opened
      - ready_for_review
  pull_request_review:
    types:
      - submitted
  status: {}

jobs:
  automerge:
    runs-on: ubuntu-latest
    steps:
      - name: automerge
        uses: "pascalgn/automerge-action@v0.6.1"
        env:
          GITHUB_TOKEN: "${{ secrets.GIT_MERGE_TOKEN }}"
          MERGE_LABELS: ""
          MERGE_METHOD: "squash"
          MERGE_COMMIT_MESSAGE: "pull-request-description"
          MERGE_FORKS: "false"
          MERGE_RETRIES: "2"
          MERGE_RETRY_SLEEP: "10000"
          UPDATE_METHOD: "rebase"
```

这个 actions 配置中用到了 pascalgn/automerge-action，简化了对于 pull request 的操作。
注意设置 MERGE_LABLES 要留空，否则你必须给 pull request 打上对应的 lable 后，才能自动合并。 这里再一次用到了 secrets 保存了 github token，和上一步配置 PicGo 用到的 token 一样。

现在的流程是：



1. 电脑中 PicGo 客户端自动上传图片到 github 仓库。
2. master 分支的 push 操作触发 actions 将仓库同步到 gitee。
3. ImgBot 稍后会发起 pull request 合并经过压缩的图片
4. pull request 触发 actions 自动进行分支合并，并 push 到目标分支(master)
5. master 分支 push 操作再次触发 actions 将仓库同步到 gitee。



手动触发步骤1后，其余步骤完全自动化运行。进一步步骤2还可以省去一些环境。

```yml
    - name: Push to gitee
      run: |
        git switch -c master
        git remote add gitee git@gitee.com:befovy/images.git
        imgbot=`git rev-parse HEAD | git show -s --format='%ae' | grep imgbot` || echo "no imgbot"
        [[ ! -z "$imgbot" ]] && git push --set-upstream gitee master -f || echo "Ingore push"
```

判断提交作者是否是 imgbot，如果不是，不进行 push 到 gitee 的操作。



------

完结
