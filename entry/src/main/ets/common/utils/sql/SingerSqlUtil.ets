import { EntryAbility, rdbStore } from '../../../entryability/EntryAbility'
import { Singer } from '../../../model/Singer'
import { Song } from '../../../model/Song'
import Logger from '../Logger'
import { fileUri } from '@kit.CoreFileKit'
import { relationalStore } from '@kit.ArkData'
import { SongsWrap } from '../../../model/SongsWrap'
import data from '@ohos.telephony.data'
import { window } from '@kit.ArkUI'
import Constants from '../../constants/Constants'

export default class SqlUtil extends EntryAbility {
  static querySinger(singerName: string, limit?: number[]) {
    const singers: Singer[] = []
    if(rdbStore != undefined) {
      let sql = ''
      let limitStr = limit? 'LIMIT ' + limit[0] + ', ' + limit[1] : ''
      if (singerName)
        sql = 'SELECT * FROM singer WHERE name like \'%' + singerName + '%\' ' + limitStr
      else
        sql = 'SELECT * FROM singer ' + limitStr
      const resultSet = rdbStore.querySqlSync(sql)
      while (resultSet.goToNextRow()) {
        const id = resultSet.getString(resultSet.getColumnIndex('id'));
        const name = resultSet.getString(resultSet.getColumnIndex('name'));
        const searchKey = resultSet.getString(resultSet.getColumnIndex('search_key'));
        const coverPath = resultSet.getString(resultSet.getColumnIndex('cover_path'))
        const singer: Singer = new Singer(id, name, searchKey, coverPath)
        if (coverPath)
          singer.coverUri = fileUri.getUriFromPath(coverPath)
        singers.push(singer)
        console.info(`id=${id}, 歌手名称=${name}, 封面路径=${coverPath}, 封面URI=${singer.coverUri}`);
      }
    }
    return singers
  }


}