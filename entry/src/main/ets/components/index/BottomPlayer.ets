import Constants, { ScreenInfo } from '../../common/constants/Constants'
import { Song } from '../../model/Song'
import ProviderFeature from '../../viewmodel/ProviderManager'
import { resourceManager } from '@kit.LocalizationKit'
import { image } from '@kit.ImageKit'
import { effectKit } from '@kit.ArkGraphics2D'
import DetailPlayer from './DetailPlayer'
import Cover from '../common/Cover'
import PlayList from './PlayList'

let context = getContext(this)
@Component
export default struct BottomPlayer {

  @Watch('getCurrentIndex') @StorageLink('CurrentPlaySong') currentPlaySong: Song = Song.getEmpty()
  @StorageLink('CurrentProgress') currentProgress: number = 0
  @Watch('getCurrentIndex') @StorageProp('CurrentPlayList') currentPlayList: Array<Song> | undefined = undefined

  @State currentPlayIndex: number = -1
  @Watch('playing')@StorageLink('IsPlaying') isPlaying: boolean = false
  @Watch('closeDetailPlayer') @State showDetail: boolean = false
  @State showDetailImage: boolean = false
  @State detailBackgroundColor: string = ''
  @Watch('changeAngle') @State angle: number = 0
  @Link showPlayList: boolean

  private providerFeature?: ProviderFeature

  async aboutToAppear() {
    this.providerFeature = await ProviderFeature.getInstance()
    this.getCurrentIndex('')
  }

  playing() {
    if (this.isPlaying) {
      this.angle++
    }
  }

  changeAngle() {
    if (this.isPlaying) {
      setTimeout(() => {
        if (this.angle === 360) {
          this.angle = 0
        } else
          this.angle += 0.1
      }, this.showDetail ? 10 : 5)
    }
  }

  closeDetailPlayer() {
    if (this.showDetail) {
      this.showDetailImage = true
      setTimeout(() => {
        this.showDetailImage = false
      }, 300)
    }
    else {
      this.showDetailImage = true
      setTimeout(() => {
        this.showDetailImage = false
      }, 300)
    }
  }

  getCurrentIndex(field: string) {
    if (field == 'currentPlaySong')
      this.angle = 0
    if (this.currentPlayList && this.currentPlaySong) {
      for (let index = 0; index < this.currentPlayList.length; index++) {
        const song = this.currentPlayList[index];
        if (this.currentPlaySong?.id == song.id) {
          this.currentPlayIndex = index
        }
      }
    }
  }


  build() {
    Column() {
      Column() {
        Image(this.currentPlaySong?.coverUri ? this.currentPlaySong?.coverUri : $r('app.media.first'))
            // .animation({ duration: 300 })
      }
      .width(this.showDetail ? 300 : 50)
      .height(this.showDetail ? 300 : 50)
      .alignItems(HorizontalAlign.Start)
      // .justifyContent(FlexAlign.Center)
      .zIndex(1)
      .borderRadius(this.showDetail ? 150 : 25)
      .position({ x: this.showDetail ? (ScreenInfo.WIDTH - 300) / 2 : '4%', y: this.showDetail ? -(ScreenInfo.HEIGHT - 200) : 0 })
      .animation({ duration: 300 })
      .clip(true)
      .rotate({
        x: 0,
        y: 0,
        z: 1,
        angle: this.angle,
        centerX: '50%',
        centerY: '50%'
      })
      .visibility(this.showDetailImage ? Visibility.Visible : Visibility.Hidden)
      .onClick(() => {
        this.showDetail = true
      })
      Row() {
        Swiper() {

          ForEach(this.currentPlayList, (song: Song, index) => {
            Row() {
                if (!this.showDetail) {
                  Image(song.coverUri ? song.coverUri : $r('app.media.first'))
                    .width(50)
                    .borderRadius(25)
                    .rotate({
                      x: 0,
                      y: 0,
                      z: 1,
                      angle: this.currentPlayIndex == index ? this.angle : 0,
                      centerX: '50%',
                      centerY: '50%'
                    })
                }
                Text(song.name + ' - ' + song.singerName)
                  .margin({ left: this.showDetail ? 66 : 16 })
            }
            .width('100%')
            .padding({ left: 16 })
            .onClick(() => {
              this.showDetail = true
            })
          })
        }
        .layoutWeight(1)
        .height('100%')
        .zIndex(1)
        .loop(true)
        .indicator(false)
        .index(this.currentPlayIndex)
        .onChange(async (index) => {
          if (this.currentPlayIndex != index) {
            this.currentPlayIndex = index
            if (this.currentPlayList) {
              this.isPlaying = false
              this.angle = 0
              this.providerFeature?.changeSong(this.currentPlayList[this.currentPlayIndex])
            }
          }
        })
        Row() {
          Button({ stateEffect: true }) {
            Column() {
              Progress({ value: Math.floor(this.currentProgress / 1000), total: Math.floor(this.currentPlaySong.duration / 1000), type: ProgressType.Ring })
                .height($r('app.float.play_button_height'))
                .color(Color.Black)
                .style({ strokeWidth: 2 })
              Image(this.isPlaying ? $r('app.media.ic_public_pause') : $r('app.media.ic_public_play'))
                .width(16)
                .position({ x: 8, y: 8 })
            }
          }
          .height($r('app.float.play_button_height'))
          .backgroundColor(Color.White)
          .aspectRatio(1)
          .id('PlayOrPause')
          .onClick(async () => {
            if (!this.isPlaying) {
              if (this.currentPlayList)
                this.providerFeature?.play(this.currentPlaySong);
            } else {
              this.providerFeature?.pause();
            }
          })
          Column () {
            Image($r('app.media.ic_public_view_list'))
              .width(28)
              .onClick(() => {
                this.showPlayList = true
              })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.End)
        }
        .width('25%')
        .height('100%')
        .padding({ right: 16 })
        /*.linearGradient({
          angle: 90,
          colors: [
            ['#00ffffff', 0.1],
            ['#2affffff', 0.2],
            ['#59ffffff', 0.3],
            ['#88ffffff', 0.4],
            [Color.White, 1]
          ]
        })*/
      }
      .width('100%')
      .height('6%')

      DetailPlayer({ showDetail: this.showDetail, showDetailImage: this.showDetailImage, detailBackgroundColor: this.detailBackgroundColor, angle: this.angle })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .borderRadius({ topLeft: 25, topRight: 25 })
    .shadow({
      radius: 10,
      color: $r('app.color.bottom_player_shadow_color'),
      offsetY: 2
    })
  }
}