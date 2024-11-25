import { router } from '@kit.ArkUI'
import Constants, { ScreenInfo } from '../common/constants/Constants'
import SongListSqlUtil from '../common/utils/sql/SongListSqlUtil'
import SqlUtil from '../common/utils/sql/SqlUtil'
import { Song } from '../model/Song'
import SongList from '../model/SongList'
import { image } from '@kit.ImageKit'
import { effectKit } from '@kit.ArkGraphics2D'
import BottomPlayer from '../components/index/BottomPlayer'
import Cover from '../components/common/Cover'
import PlayList from '../components/index/PlayList'
import ProviderFeature from '../viewmodel/ProviderManager'
import SongSqlUtil from '../common/utils/sql/SongSqlUtil'
import SongListComponent from '../components/common/SongListComponent'

@Builder
export function SongListPageBuilder(name: string, param: object) {
  SongListPage({ songList: param as SongList })
}

@Entry
@Component
struct SongListPage {
  pathStack: NavPathStack = new NavPathStack()
  @StorageLink('CurrentPlaySong') currentPlaySong: Song = Song.getEmpty()
  @StorageLink('IsPlaying') isPlaying: boolean = false
  @State songList: SongList = new SongList('', '', '')
  @StorageLink('PlayListTitle') playListTitle: string = this.songList.name
  @State songs: Song[] = []
  @State pageBackgroundColor: string | Color = ''
  @State themeColor: Resource = $r('app.color.white')
  @State showPlayList: boolean = false
  private providerFeature?: ProviderFeature
  async aboutToAppear() {
    this.providerFeature = await ProviderFeature.getInstance()
    this.songs = SongSqlUtil.queryBySongList(this.songList.id, [0, 50])
    if (this.songList.id == '0') {
      this.pageBackgroundColor = Color.Pink
    } else
      this.changeBackgroundColor()
  }

  private async changeBackgroundColor() {
    if (this.songs.length > 0)  {
      const imageSource = image.createImageSource(this.songs[0].coverPath);
      const pixelMap: image.PixelMap = await imageSource.createPixelMap()

      effectKit.createColorPicker(pixelMap, (err, colorPicker) => {
        this.pageBackgroundColor = this.handleColor(colorPicker.getAverageColor())
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
              if (this.songList.id == '0')
                Image($r('app.media.ic_public_favor_filled'))
                  .width('50%')
                  .fillColor(Color.Red)
              else
                Image(this.songs.length > 0 ? this.songs[0].coverUri ? this.songs[0].coverUri : $r(Constants.DEFAULT_SINGER_COVER) : $r(Constants.DEFAULT_SINGER_COVER))
                  .width('100%')
            }
            .width('100%')
            .height(ScreenInfo.WIDTH)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.songList.id == '0' ? Color.Pink : '')
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
                if (this.songList) {
                  this.playListTitle = this.songList.name
                } else
                  this.playListTitle = ''
              })
              Text('播放全部')
            }
            .width('100%')
            .height(50)
            .padding({ left: 10 })
            .backgroundColor(Color.White)
            .borderRadius({ topLeft: 15, topRight: 15 })
            SongListComponent({ songs: this.songs, songList: this.songList })
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