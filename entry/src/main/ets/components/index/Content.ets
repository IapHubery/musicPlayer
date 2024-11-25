import SqlUtil from '../../common/utils/sql/SqlUtil'
import { Song } from '../../model/Song'
import { common } from '@kit.AbilityKit';
import FileUtil from '../../common/utils/FileUtil';
import { picker } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import Constants, { ScreenInfo } from '../../common/constants/Constants';
import Setting from '../../model/Setting';
import { Singer } from '../../model/Singer';
import Logger from '../../common/utils/Logger';
import ProviderFeature from '../../viewmodel/ProviderManager';
import { SongsWrap } from '../../model/SongsWrap';
import SongList from '../../model/SongList';
import { router } from '@kit.ArkUI';
import Router from '../../route/Router';
import SongSqlUtil from '../../common/utils/sql/SongSqlUtil';
import SingerSqlUtil from '../../common/utils/sql/SingerSqlUtil';

let context = getContext(this) as common.Context;
let defalutFilePathUri = 'file://docs/storage/Users/currentUser/Download'
// let fileSuffixFilters = ['图片(.png, .jpg)|.png,.jpg', '文档|.txt', '视频|.mp4', '.pdf']
// let fileSuffixFilters = ['音频(.mp3,.flac)|.mp3,.flac', '歌词|.lrc', '图片(.png,.jpg,.webp)|.png,.jpg,.webp']
let fileSuffixFilters = ['.mp3,.flac', '.lrc', '.png,.jpg,.webp']
@Component
export default struct Content {
  @Link pathStack: NavPathStack
  @State songs: Song[] = []
  @State showSongs: Song[][] = []
  @State singers: Singer[] = []

  @Watch('refresh') @Link refreshData: boolean

  private singerPageSize = 20
  private songPageSize = 100

  @State showLoad: boolean = false
  @State upgradeTotal: number = 0
  @State currentUpgradeNum: number = 0

  @StorageLink('IsPlaying') isPlaying: boolean = false

  @StorageLink('CurrentPlaySong') currentPlaySong: Song | undefined = undefined
  @StorageLink('CurrentPlayList') currentPlayList: Array<Song> | undefined = undefined
  private providerFeature?: ProviderFeature

  @Watch('importFiles') @State selectedUris: string[] = []

  private listScroller: Scroller = new Scroller()
  private listIndex: number = 0
  private lastX: number = -1
  // 本地歌曲列表是否要显示
  // 当songListFlag为 true 时，捕捉返回逻辑， 将songListFlag改为false，而不是直接退出应用
  @Link showLocalList:boolean

  async aboutToAppear() {
    this.providerFeature = await ProviderFeature.getInstance()
    this.getData()
  }

  importFiles() {
    if (this.selectedUris.length > 0) {
      if (this.upgradeTotal == 0)
        this.upgradeTotal = this.selectedUris.length
      if (this.currentUpgradeNum > 0)
        this.getData()
      this.showLoad = true
      this.currentUpgradeNum++
      setTimeout(() => {
        FileUtil.importFile(context, this.selectedUris[0])
        this.selectedUris = this.selectedUris.slice(1, this.selectedUris.length)
      }, 1)
    } else {
      this.showLoad = false
      this.currentUpgradeNum = this.upgradeTotal = 0
    }
  }

  /*importFiles() {
    // 显示加载弹窗
    this.showLoad = true
    // 上传文件总数
    this.upgradeTotal = this.selectedUris.length
    for (let index = 0; index < this.selectedUris.length; index++) {
      FileUtil.importFile(context, this.selectedUris[index])
      // 上传完一个文件 数量+1
      this.currentUpgradeNum = this.currentUpgradeNum + 1
    }
    // 关闭加载弹窗
    this.showLoad = false
    // 重置数量
    this.currentUpgradeNum = this.upgradeTotal = 0
  }*/

  private refresh() {
    if (this.refreshData) {
      Logger.info('refreshData')
      this.getData()
    }
  }

  private getData() {
    this.songs = SongSqlUtil.querySong('', [0, this.songPageSize])
    const showSongs: Song[][] = []
    for (let i = 0; i < this.songs.length; i++) {
      const index = Math.floor(i / 3)
      if (showSongs[index] == undefined) {
        showSongs[index] = []
      }
      showSongs[index].push(this.songs[i])
    }
    this.showSongs = showSongs
    /*let setDefaultListFlag = false
    if (this.currentPlayList?.length == 0) {
      setDefaultListFlag = true
    }
    for (let index = 0; index < this.songs.length; index++) {
      if (index ==0) {
        this.currentPlaySong = this.songs[index]
      }
      if (setDefaultListFlag) {
        this.currentPlayList?.push(this.songs[index])
      }
    }*/
    this.singers = SingerSqlUtil.querySinger('', [0, this.singerPageSize])
  }

  build() {
    Row({ space: 20 }) {
      Stack() {
        if (this.songs.length == 0) {
          Column () {
            Image($r('app.media.ic_public_add_norm'))
              .width(32)
              .fillColor('#dbe6fe')

            Text('点击添加音乐')
              .fontSize(32)
              .fontWeight(FontWeight.Regular)
              .fontColor('#dbe6fe')
              .textShadow({
                offsetX: 5,
                radius: 1,
                color: '#d4ddec'
              })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column({ space: 10 }) {
              // 歌手榜
              Column() {
                Text('歌手榜')
                  .fontSize(24)
                  .margin({ left: '5%' })
                Grid() {
                  ForEach(this.singers, (singer: Singer, index) => {
                    GridItem() {
                      Column({ space: 10 }) {
                        Image(singer.coverUri ? singer.coverUri : $r(Constants.DEFAULT_SINGER_COVER))
                          .width(100)
                          .height(150)
                          .borderRadius(10)
                            // .transition(TransitionEffect.scale({x: 0, y: 0}).animation({ duration: 1000 }))
                          .onClick(() => {
                            this.pathStack.pushPathByName('SingerPage', singer)
                          })
                        Text(singer.name)
                      }
                      .alignItems(HorizontalAlign.Center)
                    }
                  })
                }
                .height(220)
                .padding({ left: '5%' })
                .rowsTemplate('1fr')
                .columnsGap(15)
                .scrollBar(BarState.Off)
              }
              .height( this.showLocalList? 0 : '')
              .visibility(this.showLocalList? Visibility.None: Visibility.Visible) // ----
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              // 歌曲列表
              Row() {
                // 返回
                Image($r('app.media.ic_public_arrow_down_0'))
                  .width(32)
                  .fillColor($r('app.color.grey'))
                  .visibility(this.showLocalList? Visibility.Visible: Visibility.None) // -----
                  // .border({ width:1, color: Color.Blue })
                  .margin({ left: 10, top:'3%', bottom:'3%' })
                  .onClick(() => {
                    this.showLocalList = false
                  })
                Text('本地歌曲')
                  .fontSize(24)
                  .margin({ left: this.showLocalList? 10: '5%', top:'3%', bottom:'3%' })
              }
              .backgroundColor($r('app.color.transparent_light_grey'))
              .alignItems(VerticalAlign.Top)
              .width('100%')
              // .border({ width:1, color: Color.Red })
              .onClick( () => {
                // 是否展示本地歌曲列表
                this.showLocalList = true
              })

              // 歌曲列表显示
              Column(){
                // 歌曲列表
                List({ scroller: this.listScroller }) {
                  ForEach(this.showSongs, (songs: Song[], i) => {
                    ListItem() {
                      Column() {
                        ForEach(songs, (song: Song, j) => {
                          // 本地歌曲列表  =====  专辑封面 （ 歌曲名 | 作者 ）
                          Row({ space: 10 }) {
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
                            Image(song.isFavor == 0 ? $r('app.media.ic_public_favor') : $r('app.media.ic_public_favor_filled'))
                              .width(18)
                              .fillColor(song.isFavor == 0 ? Color.Black : Color.Red)
                              .margin({ right: i == this.showSongs.length - 1 ? '10%' : 0})
                              .onClick(() => {
                                if (song.isFavor == 0) {
                                  song.isFavor = 1
                                  SqlUtil.insert('song_song_list', {
                                    song_id: song.id,
                                    song_list_id: '0'
                                  })
                                }
                                else {
                                  song.isFavor = 0
                                  SqlUtil.delete('song_song_list', 'song_id', song.id)
                                }
                                const result: number = SqlUtil.update('song', 'id', song.id, song.toValuesBucket())
                                if (result > 0) {
                                  const songs: Song[] = []
                                  for (let index = 0; index < this.showSongs[i].length; index++) {
                                    songs.push(this.showSongs[i][index])
                                  }
                                  this.showSongs[i] = songs
                                }
                              })
                          }
                          .width('100%')
                          .height(60)
                          .onClick(async () => {
                            this.providerFeature?.setPlayList(this.songs)
                            if (this.currentPlaySong == undefined) {
                              this.currentPlaySong = song
                              await this.providerFeature?.play(song)
                            } else {
                              if (!(this.currentPlaySong.id == song.id)) {
                                this.currentPlaySong = song
                                this.isPlaying = false
                                await this.providerFeature?.changeSong(song)
                              }
                            }
                          })
                        })
                      }
                      .width(i == (this.showSongs.length - 1) ? '100%' : '90%')
                      .padding({ left: '5%' })
                      .alignItems(HorizontalAlign.Start)
                    }
                  })
                }
                .width('100%')
                .height(this.showLocalList? '90%':0 )
                .listDirection(Axis.Vertical)
                .scrollBar(BarState.Off)
                .onTouch((event) => {
                  if (event.type == TouchType.Down) {
                    // 处理 down 事件
                    this.lastX = event.touches[0].x
                  } else if (event.type == TouchType.Cancel || event.type == TouchType.Up) {
                    const xOffset = event.touches[0].x - this.lastX
                    if (xOffset >= 50 && this.listIndex != 0) {
                      this.listScroller.scrollToIndex(--this.listIndex, true)
                    } else if (xOffset <= -50 && this.listIndex < (this.songs.length - 1)) {
                      this.listIndex += 1
                      if (this.listIndex == (this.songs.length - 1)) {
                        this.listScroller.scrollToIndex(++this.listIndex, true)
                      } else
                        this.listScroller.scrollToIndex(this.listIndex, true)
                    } else if ((xOffset > 0 && xOffset < 50) || (xOffset < 0 && xOffset > -50)) {
                      this.listScroller.scrollToIndex(this.listIndex, true)
                    }
                  }
                })
              }
              .width('100%') // 180
              .height(this.showLocalList? '95%' : 0) // 180
              .visibility(this.showLocalList? Visibility.Visible: Visibility.None) // -----
              .alignItems(HorizontalAlign.Start)
              // 歌单
              Column({ space: 10 }) {
                Text('我的歌单')
                  .fontSize(24)
                Row({ space: 5 }) {
                  Column({ space: 5 }) {
                    Column() {
                      Image($r('app.media.ic_public_favor_filled'))
                        .width(36)
                        .fillColor(Color.Red)
                    }
                    .width(100)
                    .height(100)
                    .justifyContent(FlexAlign.Center)
                    .backgroundColor(Color.Pink)
                    .borderRadius(15)
                    .onClick(() => {
                      this.pathStack.pushPathByName('SongListPage', new SongList('0', '我喜欢', ''))
                    })
                    Text('我喜欢')
                  }
                  Column() {
                    Image($r('app.media.ic_public_add'))
                      .width(36)
                      .fillColor($r('app.color.grey'))
                  }
                  .width(100)
                  .height(100)
                  .justifyContent(FlexAlign.Center)
                  .borderRadius(15)
                  .borderWidth(1)
                  .borderColor($r('app.color.grey'))
                  .borderStyle(BorderStyle.Dashed)
                  .onClick(() => {

                  })
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)
              }
              .width('90%')
              .alignItems(HorizontalAlign.Start)
              .visibility(this.showLocalList? Visibility.Hidden: Visibility.Visible) // -----
              Column()
                .width('100%')
                .height('5%')
            }
          }
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.None)
        }
        if (this.showLoad) {
          Column() {
            LoadingProgress()
              .color(Color.Blue)
              .layoutWeight(1)
            Text(this.currentUpgradeNum + '/' + this.upgradeTotal)
          }
          .width(100)
          .height(100)
          .backgroundColor(Color.White)
          .borderRadius(20)
        }
      }
    }
    .width('100%')
    .height('91%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (this.songs.length == 0) {
        const documentSelectOptions = FileUtil.getDocumentSelectOptions(context, defalutFilePathUri, fileSuffixFilters)
        const documentViewPicker = new picker.DocumentViewPicker(context);
        documentViewPicker.select(documentSelectOptions).then((documentSelectResult: Array<string>) => {
          //文件选择成功后，返回被选中文档的uri结果集。
          this.upgradeTotal = documentSelectResult.length
          this.selectedUris = documentSelectResult
          console.info('documentViewPicker.select to file succeed and uris are:' + documentSelectResult);

        }).catch((err: BusinessError) => {
          this.upgradeTotal = this.currentUpgradeNum = 0
          console.error(`Invoke documentViewPicker.select failed, code is ${err.code}, message is ${err.message}`);
        })
      }
    })
  }
}
