![](https://github.com/noppefoxwolf/Kitsunebi/blob/master/meta/repo-banner.png)

Overlay alpha channel video animation player view using OpenGLES.

![](https://github.com/noppefoxwolf/Kitsunebi/blob/master/meta/animation.gif)

## Example

To run the example project, clone the repo, and run pod install from the Example directory first.

## Usage

At the top of your file, make sure to `import Kitsunebi`

```swift
import Kitsunebi
```

Then, instantiate ConcentricProgressRingView in your view controller:

```swift
private lazy var playerView: KBAnimationView = KBAnimationView(frame: view.bounds)!

override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(playerView)
}
```

You can play transparency video any framerate. mainVideo is colornize video, alphaVideo is alpha channel monotone video. please see example video files.:

```swift
playerView.play(mainVideoURL: Bundle.main.url(forResource: "main", withExtension: "mp4")!,
                    alphaVideoURL: Bundle.main.url(forResource: "alpha", withExtension: "mp4")!,
                    fps: 30)
```

### customize video quality

If video playing are slow, change quality.

```swift
playerView.quality = .low
```

## Installation

Kitsunebi is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Kitsunebi'
```

## Author

Tomoya Hirano, noppelabs@gmail.com

## License

Kitsunebi is available under the MIT license. See the LICENSE file for more info.
