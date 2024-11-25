import FileUtil from '../../common/utils/FileUtil'
import { picker } from '@kit.CoreFileKit';
import Constants from '../../common/constants/Constants';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import SongSqlUtil from '../../common/utils/sql/SongSqlUtil';
import { Song } from '../../model/Song';
import { Singer } from '../../model/Singer';
import SongListComponent from '../common/SongListComponent';

let context = getContext(this) as common.Context;
let fileSuffixFilters = [Constants.AUDIO_SUFFIX, Constants.WORDS_SUFFIX, Constants.PIC_SUFFIX]
@Component
export default struct Header {

  @Link showSidebar: boolean
  @Link refreshData: boolean
  @State showSearch: boolean = false
  @State singers: Singer[] = []
  @State songs: Song[] = []

  build() {
    Column() {
      Row({ space: 20 }) {

        Column() {
          Image($r('app.media.ic_public_more'))
            .width(24)
            .onClick(() => {
              this.showSidebar = true
            })
        }

        Column() {
          TextInput()
            .onChange((value: string) => {
              if (value) {
                this.songs = SongSqlUtil.querySong(value, [0, 10])
                this.showSearch = true
              } else {
                this.songs = []
                this.showSearch = false
              }
            })
        }
        .width('75%')

        Column() {
          Image($r('app.media.ic_public_add'))
            .width(24)
        }
        .onClick(() => {
          const documentSelectOptions = FileUtil.getDocumentSelectOptions(context, Constants.DEFAULT_FILE_PATH_URI, fileSuffixFilters)
          const documentViewPicker = new picker.DocumentViewPicker(context);
          documentViewPicker.select(documentSelectOptions).then((documentSelectResult: Array<string>) => {
            //文件选择成功后，返回被选中文档的uri结果集。
            console.info('documentViewPicker.select to file succeed and uris are:' + documentSelectResult);
            for (let index = 0; index < documentSelectResult.length; index++) {
              FileUtil.importFile(context, documentSelectResult[index])
            }
            this.refreshData = true
          }).catch((err: BusinessError) => {
            console.error(`Invoke documentViewPicker.select failed, code is ${err.code}, message is ${err.message}`);
          })
        })
      }
      .width('95%')
      .height('9%')
      .margin({ top: '7%' })
      .alignItems(VerticalAlign.Center)
      if (this.showSearch)
        SongListComponent({ songs: this.songs, songList: undefined })
          .height('93%')
    }
  }
}