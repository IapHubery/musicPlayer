import Constants from '../../common/constants/Constants'
import { Song } from '../../model/Song'
import SongList from '../../model/SongList'
import ProviderFeature from '../../viewmodel/ProviderManager'

@Component
export default struct SongListComponent {

  providerFeature?: ProviderFeature

  @StorageLink('CurrentPlaySong') currentPlaySong: Song = Song.getEmpty()
  @StorageLink('IsPlaying') isPlaying: boolean = false
  @Prop songList: SongList | undefined
  @StorageLink('PlayListTitle') playListTitle: string = '我的歌曲'
  @State themeColor: Resource = $r('app.color.white')
  @Prop songs: Song[]
  async aboutToAppear() {
    this.providerFeature = await ProviderFeature.getInstance()
  }

  build() {
    List() {
      if (this.songs.length == 0) {
        ListItem() {
          Column() {
            Text('未找到歌曲')
          }
          .width('100%')
        }
      }
      /*ListItem() {
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
          Text('播放全部')
        }
        .width('100%')
        .padding({ left: 10 })
      }
      .width('90%')
      .height(50)*/
      ForEach(this.songs, (song: Song, index) => {
        ListItem() {
          Row() {
            Column() {
              Text(index + 1 + '')
                .fontSize(20)
                .fontColor($r('app.color.dark_grey'))
                .fontWeight(FontWeight.Medium)
            }
            .width(40)
            .height(60)
            .justifyContent(FlexAlign.Center)
            Image(song.coverUri ? song.coverUri : $r(Constants.DEFAULT_SINGER_COVER))
              .width(50)
              .height(50)
              .borderRadius(3)
            Column() {
              Text(song.name)
              Row() {
                Text(song.singerName)
                  .fontSize(14)
                  .fontColor($r('app.color.dark_grey'))
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 10 })
          }
          .width('100%')
          .height(60)
          .onClick(async () => {
            this.providerFeature?.setPlayList(this.songs)
            this.providerFeature?.playOrChange(song)
            if (this.songList) {
              this.playListTitle = this.songList.name
            }
          })
        }
      })
      ListItem()
        .width('100%')
        .height(120)
    }
    .height('100%')
    .width('100%')
    .divider({ strokeWidth: 1, color: $r('app.color.light_grey') })
    .backgroundColor(this.themeColor)
  }
}