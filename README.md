# クロスフェードアニメーションGIF

## png -> avi
```
$ brew install mplayer
$ brew list mplayer
/usr/local/Cellar/mplayer/1.3.0/bin/mencoder
/usr/local/Cellar/mplayer/1.3.0/bin/mplayer
/usr/local/Cellar/mplayer/1.3.0/share/man/ (2 files)

$ ~/bin/fade-avi.sh image0.png image2.png image.avi
```

## avi -> gif

```
$ brew install ffmpeg

$ mkdir work
$ ffmpeg -i image.avi -an -r 15  work/%04d.

$ convert work/*.png test2.gif
```