![](https://github.com/noppefoxwolf/Kitsunebi/blob/master/meta/repo-banner.png)

Overlay alpha channel video animation player view using Metal.

![](https://github.com/noppefoxwolf/Kitsunebi/blob/master/meta/animation.gif)

## Example

To run the example project, clone the repo, and run pod install from the Example directory first.

## Usage

At the top of your file, make sure to `import Kitsunebi`

```swift
import Kitsunebi
```

Then, instantiate AnimationView in your view controller:

```swift
private lazy var playerView: AnimationView = AnimationView(frame: view.bounds)!

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

## Sample video file

http://basic.ivory.ne.jp

## Backers

<a href="https://opencollective.com/Kitsunebi#backers" target="_blank"><img src="https://opencollective.com/Kitsunebi/backers.svg?width=890"></a>

## MEMO
ffmpeg -i main.mp4  -i alpha.mp4 -filter_complex "nullsrc=size=1500x1334 [base];[0:v] setpts=PTS-STARTPTS, scale=750x1334 [left];[1:v] setpts=PTS-STARTPTS, scale=750x1334 [right];[base][left] overlay=shortest=1 [tmp1];[tmp1][right] overlay=shortest=1:x=750" output.mp4
