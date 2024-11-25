import { relationalStore } from '@kit.ArkData'
import { avSession } from '@kit.AVSessionKit'

export class Song {
  id: string
  name: string
  searchKey: string
  coverPath: string
  coverUri?: string
  songPath: string
  wordsPath: string
  isFavor: number = 0
  singerId: string
  singerName?: string
  playCount: number = 0
  duration: number = 0

  static getEmpty() {
    return new Song('', '', '', '', '', '', 0, '')
  }

  constructor(id: string, name: string, searchKey: string, coverPath: string,
    songPath: string, wordsPath: string, isFavor: number, singerId: string) {
    this.id = id
    if (name)
      this.name = name
    else
      this.name = '未知'
    this.searchKey = searchKey
    this.coverPath = coverPath
    this.songPath = songPath
    this.wordsPath = wordsPath
    this.isFavor = isFavor
    this.singerId = singerId
  }

  toValuesBucket(): relationalStore.ValuesBucket {
    return {
      id: this.id,
      name: this.name,
      search_key: this.searchKey,
      cover_path: this.coverPath,
      song_path: this.songPath,
      words_path: this.wordsPath,
      is_favor: this.isFavor,
      singer_id: this.singerId
    }
  }

  toAvQueueItem() {
    const avMediaDescription: avSession.AVMediaDescription = {
      assetId: this.id,
      title: this.name,
      subtitle: this.singerName,
      description: '',
      mediaImage: this.coverUri ? this.coverUri : 'app.media.first',
      extras: {
        'extras': 'any'
      }
    }
    const avQueueItem: avSession.AVQueueItem = {
      itemId: 0,
      description: avMediaDescription
    }
    return avQueueItem
  }
}