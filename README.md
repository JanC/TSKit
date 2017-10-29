# TSKit

![badge-languages] ![badge-pms]


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

### Connect

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
