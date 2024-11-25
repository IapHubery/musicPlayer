import { EntryAbility, rdbStore } from '../../../entryability/EntryAbility'
import { Singer } from '../../../model/Singer'
import { Song } from '../../../model/Song'
import Logger from '../Logger'
import { fileUri } from '@kit.CoreFileKit'
import { relationalStore } from '@kit.ArkData'
import { SongsWrap } from '../../../model/SongsWrap'
import SqlUtil from './SqlUtil'
import SongSqlUtil from './SongSqlUtil'

export default class SongListSqlUtil extends EntryAbility {

  static querySongList(songListId: string, limit: number[]) {
    if (songListId == '0') {
      const songs = SongSqlUtil.queryFavor(limit)
      return songs
    }
    return []
  }


}