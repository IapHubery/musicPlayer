import Header from '../components/index/Header';
import Content from '../components/index/Content';
import { Song } from '../model/Song';
import BottomPlayer from '../components/index/BottomPlayer';
import ProviderFeature from '../viewmodel/ProviderManager';
import Cover from '../components/common/Cover';
import PlayList from '../components/index/PlayList';
import Sidebar from '../components/index/Sidebar';


@Entry
@Component
struct Index {
  @State message: string = 'hello World';

  @State pathStack: NavPathStack = new NavPathStack()
  // public avPlayer = new MediaPlayerUtil();

  @State refreshData: boolean = false

  @State angle: number = 0

  @State showSidebar: boolean = false

  @StorageLink('CurrentPlaySong') currentPlaySong: Song | undefined = undefined

  @State showPlayList: boolean = false
  private providerFeature?: ProviderFeature

  @State showLocalList:boolean = false

  async aboutToAppear() {
    this.providerFeature = await ProviderFeature.getInstance()
  }

  onBackPress(): boolean | void {
    if (this.showPlayList) {
      // 如果不显示播放列表，则阻断返回，防止直接退出应用
      this.showPlayList = false
      return true
    }
    if (this.showLocalList === true){
      this.showLocalList = false
      // 如果不显示本地歌曲列表，则阻断返回，防止直接退出应用
      return true
    }
  }

  build() {
    Row() {
      Column() {
        Navigation(this.pathStack) {
          Column() {
            Header({ refreshData: this.refreshData, showSidebar: this.showSidebar })
            Content({ refreshData: this.refreshData, pathStack: this.pathStack, showLocalList: this.showLocalList})
          }
        }
        .height('90%')
        .hideToolBar(true)
        .hideTitleBar(true)
        // 首页 底部播放器
        if (this.currentPlaySong) {
          BottomPlayer({ showPlayList: this.showPlayList })
          Cover({ isShow: this.showPlayList })
          PlayList({ showPlayList: this.showPlayList })
        }
        Cover({ isShow: this.showSidebar })
        Sidebar({ showSidebar: this.showSidebar })
      }
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
  }
}