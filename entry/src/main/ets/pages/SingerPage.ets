import Constants, { ScreenInfo } from '../common/constants/Constants'
import { Song } from '../model/Song'
import { image } from '@kit.ImageKit'
import { effectKit } from '@kit.ArkGraphics2D'
import ProviderFeature from '../viewmodel/ProviderManager'
import SongListComponent from '../components/common/SongListComponent'
import { Singer } from '../model/Singer'
import SongSqlUtil from '../common/utils/sql/SongSqlUtil'

@Builder
export function SingerPageBuilder(name: string, param: object) {
  SingerPage({ singer: param as Singer})
}

@Entry
@Component
struct SingerPage {
  pathStack: NavPathStack = new NavPathStack()
  @StorageLink('CurrentPlaySong') currentPlaySong: Song = Song.getEmpty()
  @StorageLink('IsPlaying') isPlaying: boolean = false
  @State singer: Singer = Singer.getEmpty()
  @State songs: Song[] = []
  @State pageBackgroundColor: string | Color = ''
  @State themeColor: Resource = $r('app.color.white')
  @State showPlayList: boolean = false
  private providerFeature?: ProviderFeature
  async aboutToAppear() {
    this.providerFeature = await ProviderFeature.getInstance()
    this.songs = SongSqlUtil.queryBySinger(this.singer.id, [0, 50])
    this.changeBackgroundColor()
  }

  private async changeBackgroundColor() {
    if (this.songs.length > 0)  {
      const imageSource = image.createImageSource(this.singer.coverPath);
      const pixelMap: image.PixelMap = await imageSource.createPixelMap()

      effectKit.createColorPicker(pixelMap, (err, colorPicker) => {
        this.pageBackgroundColor = this.handleColor(colorPicker.getLargestProportionColor())
      })
    }
  }

  private handleColor(color: effectKit.Color) {
    return "#" + color.alpha.toString(16) + color.red.toString(16) + color.green.toString(16) + color.blue.toString(16)
  }

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column() {
            Row() {
              Image(this.singer.coverUri ? this.singer.coverUri : $r(Constants.DEFAULT_SINGER_COVER))
            }
            .width('100%')
            .height(ScreenInfo.WIDTH)
            .justifyContent(FlexAlign.Center)
            Row({ space: 5 }) {
              Column() {
                Image($r('app.media.ic_public_play'))
                  .width(20)
                  .fillColor(this.themeColor)
              }
              .width(30)
              .height(30)
              .justifyContent(FlexAlign.Center)
              .borderRadius(15)
              .backgroundColor(Color.Red)
              .onClick(() => {
                this.providerFeature?.setPlayList(this.songs)
                this.providerFeature?.playOrChange(this.songs[0])
              })
              Text('播放全部')
            }
            .width('100%')
            .height(50)
            .padding({ left: 10 })
            .backgroundColor(Color.White)
            .borderRadius({ topLeft: 15, topRight: 15 })
            SongListComponent({ songs: this.songs, songList: undefined })
          }
          .width('100%')
        }
        .backgroundColor(this.pageBackgroundColor)
        .scrollBar(BarState.Off)

        Column() {
          Image($r('app.media.ic_public_arrow_left'))
            .width(28)
        }
        .width(32)
        .height(32)
        .borderRadius(16)
        .backgroundColor($r('app.color.transparent_light_grey'))
        .position({ x: 10, y: 30 })
        .onClick(() => {
          this.pathStack.pop()
        })
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
    })
  }
}