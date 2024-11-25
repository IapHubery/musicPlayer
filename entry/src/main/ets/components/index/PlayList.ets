import { Song } from '../../model/Song'
import ProviderFeature from '../../viewmodel/ProviderManager'

@Component
export default struct PlayList {

  @Link showPlayList: boolean

  @StorageLink('PlayListTitle') playListTitle: string = '我的歌曲'
  @Watch('getCurrentIndex') @StorageLink('CurrentPlayList') currentPlayList: Array<Song> = []
  @Watch('getCurrentIndex') @StorageProp('CurrentPlaySong') currentPlaySong: Song = Song.getEmpty()
  @State currentIndex: number = -1
  private providerFeature?: ProviderFeature
  private componentHeight: number = 570
  @Watch('deleteSong')@State deleteIndex: number = -1

  private listScroller: Scroller = new Scroller()
  async aboutToAppear(): Promise<void> {
    this.providerFeature = await ProviderFeature.getInstance()
    this.getCurrentIndex()
  }

  getCurrentIndex() {
    for (let index = 0; index < this.currentPlayList.length; index++) {
      if (this.currentPlaySong.id == this.currentPlayList[index].id) {
        this.currentIndex = index
      }
    }
    if (!this.showPlayList) {
      this.listScroller.scrollToIndex(this.currentIndex)
    }
  }

  // 等待删除动画完成
  deleteSong() {
    if (this.deleteIndex != -1) {
      setTimeout(() => {
        this.currentPlayList.splice(this.deleteIndex, 1)
        this.getCurrentIndex()
        this.deleteIndex = -1
      }, 300)
    }
  }



  build() {
    Column() {
      Row() {
        Text('当前播放列表：' + this.playListTitle)
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .height('12%')
      .padding({ left: '5%' })
      List({ scroller: this.listScroller }) {
        ForEach(this.currentPlayList, (song: Song, index) => {
          ListItem() {
            Row() {
              Row() {
                Text(song.name)
                  .fontSize(18)
                  .fontColor(this.currentIndex == index ? Color.Green : Color.Black)
                Text(' - ' + song.singerName)
                  .fontColor(this.currentIndex == index ? Color.Green : Color.Black)
              }
              .width('75%')
              Row() {
                Image($r('app.media.ic_public_cancel'))
                  .width(16)
                  .onClick(() => {
                    if (this.currentIndex == index) {
                      this.providerFeature?.nextSong(true)
                    }
                    this.deleteIndex = index
                  })
                Blank()
                Image($r('app.media.ic_public_drag_handle'))
                  .width(16)
              }
              .width('15%')
            }
            .width('100%')
            .height('12.5%')
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.currentIndex == index ? $r('app.color.light_grey') : Color.White)
            .transition({ type: TransitionType.Delete, opacity: 0 })
            .onClick(() => {
              if (this.currentIndex != index) {
                this.providerFeature?.changeSong(this.currentPlayList[index])
              }
            })
          }
          .offset({ x: this.deleteIndex == index ? '-100%' : 0 })
          .animation({ duration: 300 })
          .onDragStart(() => {
            console.info('拖拽开始')
          })
        })
      }
      .width('100%')
      .height('70%')
      .scrollBar(BarState.Off)
      .divider({ strokeWidth: 1, color: $r('app.color.light_grey'), startMargin: '5%', endMargin: '5%' })
      .tabIndex(this.currentIndex)
    }
    .width('100%')
    .height(this.componentHeight)
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 25, topRight: 25 })
    .position({ y: this.showPlayList ? '40%' : '100%' })
    .animation({ duration: 300 })
  }
}