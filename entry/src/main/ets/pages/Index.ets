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

  private providerFeature?: ProviderFeature

  @State showPlayList: boolean = false
  @State showDetail:boolean = false
  @State showLocalList:boolean = false
  @State isLocalListEnter:boolean = false

  async aboutToAppear() {
    this.providerFeature = await ProviderFeature.getInstance()
  }

  onBackPress(): boolean | void {
    // 播放列表   阻断返回，防止直接退出应用
    if (this.showPlayList === true ) {
      this.showPlayList = false
      console.log('logData', 'showPlayList 执行')
      return true
    }

    // 歌曲播放界面  this.showPlayList === false
    if (this.showDetail === true  ){
      this.showDetail = false
      console.log('logData', 'showDetail 执行')
      return true
    }

    // 本地歌曲列表
    if (this.showLocalList === true){
      this.showLocalList = false
      this.isLocalListEnter = false
      console.log('logData', 'showLocalList 执行')
      return true
    }
  }

  build() {
    Row() {
      Column() {
        Navigation(this.pathStack) {
          Column() {
            Header({ refreshData: this.refreshData, showSidebar: this.showSidebar })
            Content({ refreshData: this.refreshData, pathStack: this.pathStack,
              showLocalList: this.showLocalList, isLocalListEnter: this.isLocalListEnter})
          }
        }
        .height('90%')
        .hideToolBar(true)
        .hideTitleBar(true)
        // 首页 底部播放器
        if (this.currentPlaySong) {
          BottomPlayer({ showPlayList: this.showPlayList, showDetail:this.showDetail })
          Cover({ isShow: this.showPlayList })
          // 播放列表
          PlayList({ showPlayList: this.showPlayList })
        }
        Cover({ isShow: this.showSidebar })
        // 左上角侧边栏
        Sidebar({ showSidebar: this.showSidebar })
      }
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
  }
}