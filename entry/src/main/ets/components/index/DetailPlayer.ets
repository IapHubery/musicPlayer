import { MyPlayMode, ScreenInfo } from '../../common/constants/Constants'
import { Song } from '../../model/Song'
import ProviderFeature from '../../viewmodel/ProviderManager'
import { ClickType } from '@ohos.file.PhotoPickerComponent'
import Cover from '../common/Cover'
import Lyric from '../../model/Lyric'
import Logger from '../../common/utils/Logger'
import { image } from '@kit.ImageKit'
import { effectKit } from '@kit.ArkGraphics2D'
import PlayList from './PlayList'

@Component
export default struct DetailPlayer {

  @Watch('init')@Link showDetail: boolean
  @Prop detailBackgroundColor: string

  @Watch('changeSong')@StorageProp('CurrentPlaySong') currentPlaySong: Song = Song.getEmpty()

  @StorageProp('PlayMode') playMode: string = MyPlayMode.LIST_CYCLE

  @StorageProp('IsPlaying') isPlaying: boolean = false

  // @Watch('changeLyric')@StorageProp('Lyric') lyric: string = ''

  @StorageProp('LyricList') lyricList: Array<Lyric> = []

  @Watch('changeProgress')@StorageProp('CurrentProgress') currentProgress: number = 0
  @State duration: number = this.currentPlaySong.duration
  @State progress: number = this.currentProgress
  @State blockSize: number = 6
  private providerFeature?: ProviderFeature
  @State durationStr: string = ''
  @State progressStr: string = ''
  // 当前是第几句
  @State lyricIndex: number = 0
  @State showPlayList: boolean = false
  @Link angle: number
  @Link showDetailImage: boolean

  async aboutToAppear() {
    this.init()
  }

  async init() {
    this.providerFeature = await ProviderFeature.getInstance()
    this.changeBackgroundColor()
    this.handleWords()
  }

  handleSeconds(seconds: number) {
    const min = Math.floor(seconds / 60)
    const sec = Math.floor(seconds % 60)
    return (min < 10 ? '0' + min : min) + ':' + (sec < 10 ? '0' + sec : sec)
  }

  handleWords() {
    for (let index = 0; index < this.lyricList.length; index++) {
      const lyric = this.lyricList[index]
      if (index != this.lyricList.length - 1) {
        lyric.duration = this.lyricList[index + 1].time - lyric.time
      } else {
        lyric.duration = this.currentPlaySong.duration - lyric.time
      }
    }
  }

  @StorageLink('ChangeSeekFlag') changeSeekFlag: boolean = false

  changeSong() {
    if (this.currentPlaySong?.duration) {
      if (this.currentPlaySong.duration != 0)
        this.duration = this.currentPlaySong.duration
      this.durationStr = this.handleSeconds(Math.floor(this.currentPlaySong?.duration / 1000))
    }
    this.handleWords()
    this.changeBackgroundColor()
  }

  changeProgress() {
    if (!this.changeSeekFlag) {
      this.progress = this.currentProgress
      this.getLyricIndex()
      this.progressStr = this.handleSeconds(Math.floor(this.progress / 1000))
    }
  }

  getLyricIndex() {
    for (let index = 0; index < this.lyricList.length; index++) {
      const lyric = this.lyricList[index];
      if (lyric.time <= this.progress && (lyric.time + lyric.duration) > this.progress) {
        this.lyricIndex = index
        this.scroller.scrollToIndex(this.lyricIndex, true)
      }
    }
  }

  private async changeBackgroundColor() {
    const imageSource = image.createImageSource(this.currentPlaySong?.coverPath);
    const pixelMap: image.PixelMap = await imageSource.createPixelMap()

    effectKit.createColorPicker(pixelMap, (err, colorPicker) => {
      this.detailBackgroundColor = this.handleColor(colorPicker.getAverageColor())
    })
  }

  private handleColor(color: effectKit.Color) {
    return "#" + color.alpha.toString(16) + color.red.toString(16) + color.green.toString(16) + color.blue.toString(16)
  }

  scroller: Scroller = new Scroller()

  build() {

    Column() {
      // 返回
      Row() {
        Image($r('app.media.ic_public_arrow_down_0'))
          .width(32)
          .margin({ top: 16 })
          .fillColor($r('app.color.grey'))
          .onClick(() => {
            this.showDetail = false
          })
      }
      .width('90%')
      .height('16%')
      .alignItems(VerticalAlign.Center)
      // 唱片图
      Image(this.currentPlaySong?.coverUri ? this.currentPlaySong?.coverUri : $r('app.media.first'))
        .width(300)
        .height(300)
        // .justifyContent(FlexAlign.Center)
        .borderRadius(150)
        .visibility(!this.showDetailImage ? Visibility.Visible : Visibility.Hidden)
        .rotate({
          x: 0,
          y: 0,
          z: 1,
          angle: this.angle,
          centerX: '50%',
          centerY: '50%'
        })
      Row()
        .width('100%')
        .height('5%')
      List({ scroller: this.scroller }) {
        ListItem() {
          Row()
            .width('100%')
            .height('33%')
        }
        ForEach(this.lyricList, (lyric: Lyric, index) => {
          ListItem() {
            Row() {
              Text(lyric.words)
                .fontColor(this.lyricIndex == index ? Color.White : $r('app.color.unselect_lyric'))
                .fontSize(this.lyricIndex == index ? 20 : 16)
            }
            .width('100%')
            .height('33%')
          }
        })
        ListItem() {
          Row()
            .width('100%')
            .height('33%')
        }
      }
      .width('90%')
      .height('15%')
      .alignListItem(ListItemAlign.Center)
      .enableScrollInteraction(false)
      .scrollBar(BarState.Off)
      Row() {
        Slider({
          value: this.progress,
          min: 0,
          max: this.duration,
          style: SliderStyle.OutSet
        })
          .blockSize({ width: this.blockSize, height: this.blockSize })
          .selectedColor($r('app.color.slider_selected_color'))
          .onChange((value: number, mode: SliderChangeMode) => {
            this.changeSeekFlag = true
            this.progressStr = this.handleSeconds(Math.floor(value / 1000))
            if (mode == SliderChangeMode.Moving) {
              this.blockSize = 12
            } else if (mode == SliderChangeMode.End) {
              this.blockSize = 6
              this.progress = value
              this.providerFeature?.seek(value)
            }
          })
      }
      .width('90%')
      Row() {
        Column() {
          Text(this.progressStr)
            .fontSize(12)
            .fontColor(this.blockSize == 12 ? Color.White : $r('app.color.progress_unselect_color'))
        }
        .width('50%')
        .alignItems(HorizontalAlign.Start)
        Column() {
          Text(this.durationStr)
            .fontSize(12)
            .fontColor(this.blockSize == 12 ? Color.White : $r('app.color.progress_unselect_color'))
        }
        .width('50%')
        .alignItems(HorizontalAlign.End)
      }
      .width('90%')

      Row() {
        Grid() {
          GridItem() {
            Image(this.playMode == MyPlayMode.LIST_CYCLE ? $r('app.media.ic_public_list_cycle') :
              this.playMode == MyPlayMode.SINGLE_CYCLE ? $r('app.media.ic_public_single_cycle') :
              $r('app.media.ic_public_random'))
              .width(32)
              .fillColor(Color.White)
              .onClick(() => {
                this.providerFeature?.changePlayMode()
              })
          }
          .height('100%')
          GridItem() {
            Image($r('app.media.ic_public_play_last'))
              .width(40)
              .fillColor(Color.White)
              .onClick(async () => {
                await this.providerFeature?.lastSong()
                this.lyricIndex = 0
              })
          }
          .height('100%')
          GridItem() {
            Image(this.isPlaying ? $r('app.media.ic_public_pause') : $r('app.media.ic_public_play'))
              .width(48)
              .fillColor(Color.White)
              .onClick(async () => {
                if (!this.isPlaying) {
                  if (this.currentPlaySong)
                    this.providerFeature?.play(this.currentPlaySong)
                } else {
                  this.providerFeature?.pause();
                }
              })
          }
          .height('100%')

          GridItem() {
            Image($r('app.media.ic_public_play_next'))
              .width(40)
              .fillColor(Color.White)
              .onClick(async () => {
                await this.providerFeature?.nextSong(true)
                this.lyricIndex = 0
              })
          }
          .height('100%')

          GridItem() {
            Image($r('app.media.ic_public_view_list'))
              .width(32)
              .fillColor(Color.White)
              .onClick(() => {
                this.showPlayList = true
              })
          }
          .height('100%')
        }
        .height('15%')
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')

      }
      Cover({ isShow: this.showPlayList })
      PlayList({ showPlayList: this.showPlayList })
    }
    .width('100%')
    .height('110%')
    .backgroundColor(this.detailBackgroundColor)
    .linearGradient({
      angle: 0,
      colors: [
        ['#009d9d9d', 0.1],
        ['#179d9d9d', 0.3],
        ['#2f9d9d9d', 0.5],
        ['#4d9d9d9d', 0.7],
        ['#759d9d9d', 0.9]
      ]
    })
    .offset({ y: this.showDetail ? '-100%' : '7%' })
    .animation({ duration: 300 })
  }
}