---
title: "手把手带你写 Flutter 系统音量插件"
date: 2019-11-23T16:46:38+08:00
draft: false
Tags: ["Flutter"]
---

> 认真读完本文就能掌握编写一个 Flutter 系统音量插件的技能，支持调节系统音量以及监听系统音量变化。
> 如有不当之处敬请指正。

<p style="text-align:center;">
<img src=https://gitee.com/befovy/images/raw/master/images/2019/11/23/20191123170646.gif/>
</p>

<!--more-->

## 0、背景
我最近在做一个 Flutter 视频播放器插件 fijkplayer，感兴趣可以看我的 [github](https://github.com/befovy/fijkplayer)。在 0.1.0 版本之后考虑增加调节系统音量功能。google 一番，找到了相关的 Flutter 插件（Flutter 的生态真的是建立挺快的）。但仔细了解插件的功能之后，感觉有些不满足我的需求，同时由于我的 fijkplayer 本身就是一个插件，想尽量避免依赖额外的插件，所以我干嘛不自己动手造一个？这可比播放器插件简单多了。<br />本文写作时播放器插件 fijkplayer 上已经完成了音量调节和监控的功能，为了文档内容清晰，把相关的代码又单独抽出来作为一个小项目 [flutter_volume](https://github.com/befovy/flutter_volume) 。

## 1、环境介绍
搭建 Flutter 环境这里不专门讲了。直接从 Flutter 插件的开发环境入手。<br />本文使用的 Flutter 版本和环境是 <br />`[✓] Flutter is fully installed. (Channel stable, v1.9.1+hotfix.2, on Mac OS X 10.14.6 18G95, locale zh-Hans-CN)` 

### 创建插件
新建一个叫做 flutter_volume 的 Flutter 插件：`flutter create --org com.befovy -t plugin -i objc flutter_volume` 。<br />`flutter create` 命令使用参数 `-t` 选择模版，可选值为 `app`  `package`  `plugin`，分别用于创建 Flutter 应用程序，Flutter 包（纯 dart 代码实现的功能）， Flutter 插件（和主机系统交互）。

我在开始写 fijkplayer 的时候，默认插件语言还是 java 和 objc，现在1.9 版本，都已经默认使用 kotlin 和 swift 了。Swift 我还不太熟悉，kotlin 了解一些，并且 Android studio 的 java 转换 kotlin 很强大，我这里新的小项目 flutter_volume 就也使用 kotlin 和 objc 了。如果要修改创建 Flutter 插件使用的编程语言，可以使用参数 `-i` 和 `-a` 。<br />例如 `flutter create -t plugin -a java -i swift flutter_volume`

### 插件目录结构
先在 Android Studio 中安装  Flutter 插件和 Dart 插件。
![](https://gitee.com/befovy/images/raw/master/images/2019/11/23/20191123170737.png)

然后使用 Android Studio 打开刚才创建的 plugin 项目目录 flutter_volume。注意是使用 Android Studio 中的 “Open an existing Android Studio project" 菜单。

使用 Android Studio 打开 Flutter 项目后，其结构如下。<br />Flutter plugin 的功能实现基本上就是 dart 代码和 android 本地 kotlin/java 以及 iOS 本地 swift/objc 代码互相调用。<br />实现这些功能的代码就在下图中 libs 目录中的 dart 源文件，android/src 目录中的 java/kotlin 源文件，以及 ios/Classes 目录中的 objc/swift 源文件。<br />在这个 Android Studio 工程中随便打开一个 android 目录内的文件，都会编辑器右上角出现 “Open for Editing in Android Studio” 的可点击链接，打开 ios 文件夹的任意文件，都会出现类似 “Open for Editing in XCode” 的可点击链接。

![](https://gitee.com/befovy/images/raw/master/images/2019/11/23/20191123170812.png)

在我使用的这个版本 flutter 中，新项目直接使用 Xcode 打开会存在一些问题。解决办法是先在 example/ios 文件夹，运行 `pod install` 。之后再点击 “Open for Editing in XCode” 打开 Xcode 项目，或者使用 Xcode 打开 example/ios/Runner.xcworkspace 工程。<br />划重点<br />**先在命令后 example/ios 文件夹，运行 `pod install`，然后再打开 Xcode 项目**。

打开 xcode 后看到，插件的 objc/swift 代码被 pod 使用文件链接套了很长的路径，写iOS插件主要就是在这个文件夹的代码中实现功能。（截图还是 swift 的插件项目，后来为了进度改成了 objc，毕竟对 swift 不太熟悉）

![](https://gitee.com/befovy/images/raw/master/images/2019/11/23/20191123171126.png)

点击 Open for Editing in Android Studio 打开新的 Android Studio 项目，等 gradle 自动同步完成。 <br />这是一个完整的 Android App 工程，flutter_volume 插件作为一个 Android 工程的 modue 存在。插件的功能实现也主要是修改这个 module 中的代码。

![](https://gitee.com/befovy/images/raw/master/images/2019/11/23/20191123171210.png)


上面的 Xcode 工程以及这个 Android Studio 工程，都是可以运行的 App 工程，这个 Flutter 工具已经帮我们打理好了，创建 Flutter plugin 的时候就默认带有 example。<br />上面大图 1 中 example 文件夹中的目录结构就和一个普通的 Flutter App 目录结构一样，只是这里 Flutter App 使用相对路径依赖的外层文件夹的 flutter_volume 插件。<br />大图 2 和 大图 3 打开的其实就是 example 文件中 android 和 iOS 项目。

这种 Flutter 工具自动生成的插件目录结构确实对程序员非常友好，写了插件立马就能在 demo 中看到效果。

## 2、Flutter Native 通信方式
Flutter 应用可以在 iOS 和 Android 平台运行，肯定要和原生系统进行各种各样的交互。交互的部分主要是在 flutter engine 中，以及大量的 flutter 插件中。

### MethodChannel

Flutter 框架提供了这样的交互方式。消息通过 Method Channel 在客户端（UI）和主机（platform）之间传递。<br />官方文档这里使用的是 platform channels，翻译的时候我使用了更具体直接的表述 Method Channel<br />见下图（图片来源 [https://flutter.dev/docs/development/platform-integration/platform-channels](https://flutter.dev/docs/development/platform-integration/platform-channels)）

![](https://gitee.com/befovy/images/raw/master/images/2019/11/23/20191123171847.png)

翻译一段官方的释义
> 在客户端，MethodChannel 可以发送与方法调用相对应的消息。 在平台方面，Android 上的 MethodChannel和 iOS 上的 FlutterMethodChannel 允许接收方法调用并发送回结果。 这些类使您可以使用很少的“样板代码”来开发平台插件。
> 注意：如果需要，方法调用也可以反向发送，平台充当Dart中实现的方法的客户端。


上图形象表达了 Flutter 发送消息到 native 端的过程。<br />同时，我们需要注意，这个过程可以反过来从 native 端主动发送消息到 Flutter 端。即在 native 端创建 MethodChannel 并进行方法调用，Flutter 端进行方法处理并且发送会方法调用结果。实际中更常用的是对于这个模式的更高一层封装 EventChannel。Native 端进行 event 发送，Flutter 端进行 event 响应。<br />MethodChannel 和 EventChannel 都会在后面实战环节使用到，一看即会。

在 Flutter 客户端和 native 平台方面传递数据都是需要经过编码再解码。<br />编码的方式默认的是用`StandardMethodCodec`，此外还有 `JSONMethodCodec` 。`StandardMethodCodec`<br />编解码效率更高。

### 编码数据类型

MethodCodec 支持的数据类型以及在 dart 、iOS 和 Android 中的对应关系如下表。

| Dart | Android | iOS |
| --- | --- | --- |
| null | null | nil (NSNull when nested) |
| bool | java.lang.Boolean | NSNumber numberWithBool: |
| int | java.lang.Integer | NSNumber numberWithInt: |
| int, if 32 bits not enough | java.lang.Long | NSNumber numberWithLong: |
| double | java.lang.Double | NSNumber numberWithDouble: |
| String | java.lang.String | NSString |
| Uint8List | byte[] | FlutterStandardTypedData typedDataWithBytes: |
| Int32List | int[] | FlutterStandardTypedData typedDataWithInt32: |
| Int64List | long[] | FlutterStandardTypedData typedDataWithInt64: |
| Float64List | double[] | FlutterStandardTypedData typedDataWithFloat64: |
| List | java.util.ArrayList | NSArray |
| Map | java.util.HashMap | NSDictionary |

## 3、Volume 接口

前面提到是要在一个视频播放器插件中调整系统的音量。经过梳理，先整理出初步需要的接口。主要有增大音量、减小音量、静音、获取音量、设置音量。同时还有激活音量变化监听、设置音量变化监听、关闭音量变化监听。为了使用方便，还增加了一个 VolumeWatcher 的 Widget，在其中成对使用了新增音量变化监听，取消音量变化监听接口。

部分代码如下，完整代码请 [点击链接查看](https://github.com/befovy/flutter_volume/blob/6965560892/lib/flutter_volume.dart) 。
```dart
class VolumeVal {
  final double vol;
  final int type;
}

typedef VolumeCallback = void Function(VolumeVal value);

class FlutterVolume {
  static const double _step = 1.0 / 16.0;
  static const MethodChannel _channel =
      const MethodChannel('com.befovy.flutter_volume');

  static _VolumeValueNotifier _notifier =
      _VolumeValueNotifier(VolumeVal(vol: 0, type: 0));

  static StreamSubscription _eventSubs;

  void enableWatcher() {
    if (_eventSubs == null) {
      _eventSubs = EventChannel('com.befovy.flutter_volume/event')
          .receiveBroadcastStream()
          .listen(_eventListener, onError: _errorListener);
      _channel.invokeMethod("enable_watch");
    }
  }

  void disableWatcher() {
    _channel.invokeMethod("disable_watch");
    _eventSubs?.cancel();
    _eventSubs = null;
  }

  static void _eventListener(dynamic event) {
    final Map<dynamic, dynamic> map = event;
    switch (map['event']) {
      case 'vol':
        double vol = map['v'];
        int type = map['t'];
        _notifier.value = VolumeVal(vol: vol, type: type);
        break;
      default:
        break;
    }
  }
  
  static Future<double> up({double step = _step, int type = STREAM_MUSIC}) {
    return _channel.invokeMethod("up", <String, dynamic>{
      'step': step,
      'type': type,
    });
  }

  static void addVolListener(VoidCallback listener) {
    _notifier.addListener(listener);
  }
}

class VolumeWatcher extends StatefulWidget {
  final VolumeCallback watcher;
  final Widget child;

  VolumeWatcher({
    @required this.watcher,
    @required this.child,
  });

  @override
  _VolumeWatcherState createState() => _VolumeWatcherState();
}
```
这里既使用了 MethodChannel， 也使用了 EventChannel。Flutter 使用 MethodChannel 发送方法调用请求到 native 侧，并获取方法的调用结果。为了避免 UI 卡顿，方法调用都使用异步模式。EventChannel 则是在 Flutter 端处理 native 发送的事件通知。<br />在 Flutter 中，所有 Channel 的 name 必须是不重复的，否则消息发送会出错。

- `MethodChannel`  的使用很简单，使用 name 参数构造一个 `MethodChannel`  ，并使用 `invokeMethod`  进行消息和参数的发送，并返回异步的结果。
- `EventChannel` 使用稍微复杂一些，但都是一些样板代码。构造 `EventChannel` 并监听事件广播，注册事件处理函数和错误处理函数。使用完成后再取消广播订阅。

接口设计中，我加上了不同音频类型的可选参数 `type` ，但在初期的实现中，只会实现媒体声音类型的相关功能。<br />这个可选参数保证后期的功能实现，接口不发生变化。

完整的代码变更可以看github 上这个提交。<br />[https://github.com/befovy/flutter_volume/commit/c8ff0f583b3372d22f764bcaf377f1a6bc64cf39](https://github.com/befovy/flutter_volume/commit/c8ff0f583b3372d22f764bcaf377f1a6bc64cf39)

## 4、iOS 功能实现

### FlutterPluginRegistrar
FlutterPluginRegistrar 是 flutter 插件在 iOS 环境中的上下文，提供插件上下文信息，以及 App 回调事件信息。<br />FlutterPluginRegistrar 的实例对象需要保存在 Plugin class 的成员变量中，方便后续使用。<br />将 FlutterVolumePlugin 的无参 init 函数调整为 initWithRegistrar 。
```objectivec
@implementation FlutterVolumePlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"com.befovy.flutter_volume"
                                  binaryMessenger:[registrar messenger]];
  FlutterVolumePlugin *instance =
      [[FlutterVolumePlugin alloc] initWithRegistrar:registrar];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRegistrar:
    (NSObject<FlutterPluginRegistrar> *)registrar {
  self = [super init];
  if (self) {
    _registrar = registrar;
  }
  return self;
}
@end
```

### iOS 监听音量变化
ios 系统通知中心有关于音量变化的广播，监听音量变化只需要在通知中心注册通知即可。<br />根据接口设计，监听系统音量变化，有两个接口调用控制功能开启或者关闭。<br />音量监听的主要代码实现如下：
```objectivec
@implementation FlutterVolumePlugin
- (void)enableWatch {
  if (_eventListening == NO) {
    _eventListening = YES;

    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(volumeChange:)
               name:@"AVSystemController_SystemVolumeDidChangeNotification"
             object:nil];
      
    _eventChannel = [FlutterEventChannel
                    eventChannelWithName:@"com.befovy.flutter_volume/event"
                    binaryMessenger:[_registrar messenger]];
    [_eventChannel setStreamHandler:self];
  }
}

- (void)disableWatch {
  if (_eventListening == YES) {
    _eventListening = NO;

    [[NSNotificationCenter defaultCenter]
        removeObserver:self
                  name:@"AVSystemController_SystemVolumeDidChangeNotification"
                object:nil];
    [_eventChannel setStreamHandler:nil];
    _eventChannel = nil;
  }
}

- (void)volumeChange:(NSNotification *)notification {
  NSString *style = [notification.userInfo
      objectForKey:@"AVSystemController_AudioCategoryNotificationParameter"];
  CGFloat value = [[notification.userInfo
      objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"]
      doubleValue];
  if ([style isEqualToString:@"Audio/Video"]) {
    [self sendVolumeChange:value];
  }
}

- (void)sendVolumeChange:(float)value {
  if (_eventListening) {
      NSLog(@"valume val %f\n", value);
    [_eventSink success:@{@"event" : @"volume", @"vol" : @(value)}];
  }
}
@end
```

enableWatch 中在通知中心注册关于音量变化的处理函数。然后构造 FlutterEventChannel 并且设置 handler。<br />disableWatch 中移除在通知中心注册的回调，然后删除 EventChannel 的 handler，并删除 eventChannel 对象。<br />需要注意的是，dart中 `EventChannel('xxx').receiveBroadcastStream()` 的调用一定要在 native 端执行完成 `FlutterEventChannel setStreamHandler` 方法之后，否则会出现 `onListen` 方法找不到的错误。

### 系统音量修改
iOS 中没有公开的修改系统音量接口，但是还有其他途径实现音量修改。目前使用最广泛的就是在 UI 中插入一个不可见的 MPVolumeView，然后模拟 UI 操作调整其中的 MPVolumeSlider。

```objectivec
@implementation FlutterVolumePlugin
- (void)initVolumeView {
  if (_volumeView == nil) {
    _volumeView =
        [[MPVolumeView alloc] initWithFrame:CGRectMake(-100, -100, 10, 10)];
    _volumeView.hidden = YES;
  }
  if (_volumeViewSlider == nil) {
    for (UIView *view in [_volumeView subviews]) {
      if ([view.class.description isEqualToString:@"MPVolumeSlider"]) {
        _volumeViewSlider = (UISlider *)view;
        break;
      }
    }
  }
  if (!_volumeInWindow) {
    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    if (window != nil) {
      [window addSubview:_volumeView];
      _volumeInWindow = YES;
    }
  }
}

- (float)getVolume {
  [self initVolumeView];
  if (_volumeViewSlider == nil) {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    CGFloat currentVol = audioSession.outputVolume;
    return currentVol;
  } else {
    return _volumeViewSlider.value;
  }
}

- (float)setVolume:(float)vol {
  [self initVolumeView];
  if (vol > 1.0) {
    vol = 1.0;
  } else if (vol < 0) {
    vol = 0.0;
  }
  [_volumeViewSlider setValue:vol animated:FALSE];
  vol = _volumeViewSlider.value;
  return vol;
}
@end
```
完整 iOS 插件代码 [点我查看](https://github.com/befovy/flutter_volume/blob/e933f97c4bb64988300aeb71211dee3fd08cd59f/ios/Classes/FlutterVolumePlugin.m)

## 5、Android 功能实现
Android Flutter 插件开发离不开 flutter engine 中的接口 Registrar。通过 Registrar 的方法可以获取 activity、 context 等 Android 开发中重要对象。

### Registrar
```java
 public interface Registrar {
    Activity activity();
    Context context();
    Context activeContext();
    ....
 }
```
 
```kotlin
class FlutterVolumePlugin(registrar: Registrar): MethodCallHandler {
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "flutter_volume")
      channel.setMethodCallHandler(FlutterVolumePlugin(registrar))
    }
  }
  private val mRegistrar: Registrar = registrar
}
```

对自动生成的 Plugin class 进行修改，增加 mRegistrar 成员变量（见上面代码片段），在成员函数 `onMethodCall` 中处理 method call 的时候就可以获取 activity、context 等重要变量。

比如 Android 系统中音量修改使用的 AudioManager 。
```kotlin
 class FlutterVolumePlugin(registrar: Registrar): MethodCallHandler {
   private fun audioManager(): AudioManager {
     val activity = mRegistrar.activity()
     return activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager
   }
 }
```

Android 中音量调节功能的实现主要就是 AudioManager 的 API 调用，以及对 flutter onMethodCall 方法的处理。详细的内容请[点击查看源代码](https://github.com/befovy/flutter_volume/blob/d3bef08778/android/src/main/kotlin/com/befovy/flutter_volume/FlutterVolumePlugin.kt)。

### 监听音量的变化
Android 系统中使用广播通知 BroadcastReceiver 获取音量变化。<br />根据接口设计，监听系统音量变化，有两个接口调用控制功能开启或者关闭。<br />在 `enableWatch` 方法中，先修改标记变量 `mWatching` ， 然后创建 `EventChannel` 并且调用 `setStreamHandler` 方法。最后，注册广播接收器，接受系统音量变化的通知。<br />需要注意的是，dart中 `EventChannel('xxx').receiveBroadcastStream()`的调用一定要在 native 端执行完成 `setStreamHandler` 方法之后，否则会出现 `onListen` 方法找不到的错误。
```kotlin
class FlutterVolumePlugin(registrar: Registrar) : MethodCallHandler {
	private fun enableWatch() {
        if (!mWatching) {
            mWatching = true
            mEventChannel = EventChannel(mRegistrar.messenger(), "com.befovy.flutter_volume/event")
            mEventChannel!!.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(o: Any?, eventSink: EventChannel.EventSink) {
                    mEventSink.setDelegate(eventSink)
                }

                override fun onCancel(o: Any?) {
                    mEventSink.setDelegate(null)
                }
            })

            mVolumeReceiver = VolumeReceiver(this)
            val filter = IntentFilter()
            filter.addAction(VOLUME_CHANGED_ACTION)
            mRegistrar.activeContext().registerReceiver(mVolumeReceiver, filter)
        }

    }

    private fun disableWatch() {
        if (mWatching) {
            mWatching = false
            mEventChannel!!.setStreamHandler(null)
            mEventChannel = null

            mRegistrar.activeContext().unregisterReceiver(mVolumeReceiver)
            mVolumeReceiver = null
        }
    }
}
```

在获取音量变化通知 BroadcastReceiver 的 onReceive 方法中， 使用 EventChannel 发送到事件内容到 flutter 侧。
```kotlin

private class VolumeReceiver(plugin: FlutterVolumePlugin) : BroadcastReceiver() {
    private var mPlugin: WeakReference<FlutterVolumePlugin> = WeakReference(plugin)
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "android.media.VOLUME_CHANGED_ACTION") {
            val plugin = mPlugin.get()
            if (plugin != null) {
                val volume = plugin.getVolume()
                val event: MutableMap<String, Any> = mutableMapOf()
                event["event"] = "vol"
                event["v"] = volume
                event["t"] = AudioManager.STREAM_MUSIC
                plugin.sink(event)
            }
        }
    }
}

class FlutterVolumePlugin(registrar: Registrar) : MethodCallHandler {
    fun sink(event: Any) {
        mEventSink.success(event)
    }
}
```
详细的内容请[点击查看源代码](https://github.com/befovy/flutter_volume/blob/d3bef08778/android/src/main/kotlin/com/befovy/flutter_volume/FlutterVolumePlugin.kt)。

### 音量区间映射
在 Android 系统中，音量最大值有可能不一样，范围不是 [0, 1]。此插件获取音量最大值后，将音量又线性映射到 [0, 1] 的范围中。另一点需要注意，android 音量调节不是无级调节，有一个调节的最小单元，将这个最小单元映射到 [0, 1] 范围中的一个 delta 值，并保证调节音量 step 值大于等于这个最小单元 delta 值，否则音量调节无效。<br />在插件的 API 实现中，如果调用 `up` 或 `down` 接口， `step` 参数值小于 `delta` ，则会被修改为 `delta`  的值，保证 `up` 或 `down` 接口的调用都是有效的。

## 6、插件 Demo

flutter 插件创建的默认目录中都包含一个 example 文件夹。里面是一个完整的 flutter app 工程目录，使用相对路径的方式引用了外层文件夹中的 flutter 插件。
```yaml
dev_dependencies:
  flutter_volume:
    path: ../
```

在 lib/main.dart 中引入插件 <br />import 'package:flutter_volume/flutter_volume.dart';

然后简单写几个按钮，在 onPressed 中调用 flutter_volume.dart 中的API 就可以完整插件的示例 App。<br />详细内容请看完整的源代码  [example/lib/main.dart](https://github.com/befovy/flutter_volume/blob/080d45cf0ba5596418450836e4f31551fe1b4e8f/example/lib/main.dart)

## 7、发布插件
完成了插件或者 dart 包的开发测试之后，可以将其发布到 [Pub](https://pub.dartlang.org/) 上，这样其他开发人员就可以快捷方便地使用它。<br />Flutter 的依赖管理 pubspec 支持通过本地路径和 Git 导入依赖，但使用 pub 可以更方便进行插件版本管理。

> volume   flutter_volume 这几个名字都已经被占坑了，我就暂时不发布到 pub 了

发布插件到 pub ，需要登录 google 账号，请预先准备梯子。

在发布之前，先检查 `pubspec.yaml`、`README.md` 以及 `CHANGELOG.md` 、 `LICENSE` 文件，以确保其内容的完整性和正确性。<br />`pubspec.yaml` 里除了插件的依赖，还包含一些插件以及作者的元信息，需要把这些补上：
```yaml
name: flutter_volume
description: A Plugin for Volume Control and Monitoring, support iOS and Android
version: 0.0.1
author: befovy
homepage: blog.befovy.com
```
然后, 运行 dry-run 命令以查看插件是否还有别的问题:
```bash
flutter packages pub publish --dry-run
```
如果命令输出 `Package has 0 warnings` ，则表示一切正常。<br />最后，运行发布命令 `flutter packages pub publish` <br />如果是第一次发布，会提示验证 Google 账号。
```
Looks great! Are you ready to upload your package (y/n)? y
Pub needs your authorization to upload packages on your behalf.
In a web browser, go to https://accounts.google.com/o/oauth2/auth?access_type=offline*****.....(省略一千字)
Then click "Allow access".

Waiting for your authorization...
Successfully authorized.
Uploading...
Successful uploaded package.
```
成功授权之后便可以继续上传，上传成功后，会提示 `Successful uploaded package` 。<br />发布后，可以在 https://pub.dartlang.org/packages/${plugin_name} 查看发布情况。

<p style="text-align:center;">
<img src=https://gitee.com/befovy/images/raw/master/assets/wechat_pub.png/>
</p>

<a name="2hHEs"></a>
# 参考资料
> [https://flutter.dev/docs/development/platform-integration/platform-channels](https://flutter.dev/docs/development/platform-integration/platform-channels)



