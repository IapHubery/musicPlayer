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

export default class SongSqlUtil extends EntryAbility {

  static queryBySongNameAndSinger(songName: string, singerId: string) {
    const sql = 'SELECT * FROM song WHERE name = \'' + songName + '\' AND singer_id = \'' + singerId + '\' LIMIT 0, 1'
    const songs = SongSqlUtil.handleSong(sql)
    return songs
  }

  static querySong(searchKey: string, limit: number[]) {
    let sql = ''
    if (searchKey)
      sql = 'SELECT song.*, singer.name as singer_name FROM song LEFT JOIN singer ON song.singer_id = singer.id WHERE song.search_key like \'%' + searchKey + '%\' LIMIT ' + limit[0] + ', ' + limit[1]
    else
      sql = 'SELECT song.*, singer.name as singer_name FROM song LEFT JOIN singer ON song.singer_id = singer.id LIMIT ' + limit[0] + ', ' + limit[1]
    const songs = SongSqlUtil.handleSong(sql)
    return songs
  }

  static queryBySinger(singerId: string, limit: number[]) {
    const sql = 'SELECT song.*, singer.name singer_name FROM song LEFT JOIN singer ON song.singer_id = singer.id WHERE singer_id = \'' + singerId + '\' LIMIT ' + limit[0] + ', ' + limit[1]
    const songs = SongSqlUtil.handleSong(sql)
    return songs
  }

  private static handleSong(sql: string) {
    const songs: Song[] = []
    if (rdbStore != undefined) {
      const resultSet = rdbStore.querySqlSync(sql)
      while (resultSet.goToNextRow()) {
        const id = resultSet.getString(resultSet.getColumnIndex('id'));
        const name = resultSet.getString(resultSet.getColumnIndex('name'));
        let singerName: string = ''
        if (sql.indexOf('singer_name') != -1)
          singerName = resultSet.getString(resultSet.getColumnIndex('singer_name'));
        const searchKey = resultSet.getString(resultSet.getColumnIndex('search_key'));
        const coverPath = resultSet.getString(resultSet.getColumnIndex('cover_path'))
        const songPath = resultSet.getString(resultSet.getColumnIndex('song_path'))
        const wordsPath = resultSet.getString(resultSet.getColumnIndex('words_path'))
        const isFavor = resultSet.getLong(resultSet.getColumnIndex('is_favor'))
        const singerId = resultSet.getString(resultSet.getColumnIndex('singer_id'))
        const song: Song = new Song(id, name, searchKey, coverPath, songPath, wordsPath, isFavor, singerId)
        if (coverPath)
          song.coverUri = fileUri.getUriFromPath(coverPath)
        if (singerName != '')
          song.singerName = singerName
        songs.push(song)
        Logger.info(`id=${id}, 歌手id=${singerId}, 歌手名称=${song.singerName}, 歌曲名称=${name}, 封面路径=${coverPath}, 歌曲路径=${songPath}, 歌词路径=${wordsPath}, 搜索关键字=${searchKey}, 喜爱=${isFavor}`);
      }
    }
    return songs
  }

  static queryFavor(limit: number[]) {
    let sql: string
    if (limit.length == 2)
      sql = 'SELECT song.*, singer.name as singer_name FROM song LEFT JOIN singer ON song.singer_id = singer.id WHERE song.is_favor = \'1\' LIMIT ' +  limit[0] + ', ' + limit[1]
    else
      sql = 'SELECT song.*, singer.name as singer_name FROM song LEFT JOIN singer ON song.singer_id = singer.id WHERE song.is_favor = \'1\''
    const songs = SongSqlUtil.handleSong(sql)
    return songs
  }

  /**
   * 根据歌单查找歌曲
   * @param songListId
   */
  static queryBySongList(songListId: string, limit: number[]) {
    let songs: Song[] = []
    if (rdbStore != undefined) {
      const sql = 'SELECT song.*, singer.name as singer_name FROM song_song_list LEFT JOIN song ON song_song_list.song_id = song.id LEFT JOIN singer ON song.singer_id = singer.id WHERE song_song_list.song_list_id = \'' + songListId + '\' LIMIT ' + limit[0] + ', ' + limit[1]
      songs = SongSqlUtil.handleSong(sql)
    }
    return songs
  }



}