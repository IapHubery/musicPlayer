import { relationalStore } from '@kit.ArkData'

export class Singer {
  id: string
  name: string
  searchKey: string
  coverPath: string
  coverUri?: string
  isFavor: number = 0

  static getEmpty() {
    return new Singer('', '', '', '')
  }

  constructor(id: string, name: string, searchKey: string, coverPath: string) {
    this.id = id
    this.name = name
    this.searchKey = searchKey
    this.coverPath = coverPath
  }

  toValuesBucket(): relationalStore.ValuesBucket {
    return {
      id: this.id,
      name: this.name,
      search_key: this.searchKey,
      cover_path: this.coverPath,
      is_favor: this.isFavor
    }
  }
}