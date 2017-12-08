# TSKit

![badge-languages] ![badge-pms]

![](logo.svg)


TSKit is a Objective-C wrapper around the [C TeamSpeak client library](https://www.teamspeak.com/en/teamspeak3sdk.html)

Note: This is still work in progress.

# Installation

## Carthage
[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate Alamofire into your Xcode project using Carthage, specify it in your `Cartfile`:


```ogdl
# Cartfile

github "JanC/TSKit"
```

Run `carthage update` to build the framework and drag the built `TSKit.framework` into your Xcode project.


# Usage

## Connect

```swift
import TSKit

var client = TSClient(host: "localhost",
                      port: 9986,
                      serverNickname: "ios",
                      serverPassword: nil,
                      receiveOnly: true)
                      
client.delegate = self
```

[badge-languages]: https://img.shields.io/badge/languages-Swift%20%7C%20ObjC-orange.svg
[badge-pms]: https://img.shields.io/badge/supports-CocoaPods%20%7C%20Carthage-green.svg


# Development

## Test Server
To run a local SDK server, [download the SDK](https://www.teamspeak.com/en/downloads.html#) and use one of the server examples:

```bash
cd ts3_sdk_3.0.4/examples/server
make -f Makefile.macosx 
./ts3_server_sample 
```

## Library
The `TSKit` uses a compiled "fat" `libts3client.a` static library that is included in the downloaded zip. In order to merge all the architectures for both the iOS Simulator and the device:

```bash
cd ts3_sdk_3.0.4/lib/ios
lipo -create device/libts3client.a simulator/libts3client.a -output  libts3client.a
```

The result is 

```bash
file libts3client.a 
libts3client.a: Mach-O universal binary with 5 architectures: [i386: Mach-O object i386] [x86_64] [arm_v7] [arm_v7s] [arm64]
libts3client.a (for architecture i386):	Mach-O object i386
libts3client.a (for architecture x86_64):	Mach-O 64-bit object x86_64
libts3client.a (for architecture armv7):	Mach-O object arm_v7
libts3client.a (for architecture armv7s):	Mach-O object arm_v7s
libts3client.a (for architecture arm64):	Mach-O 64-bit object arm64
```



