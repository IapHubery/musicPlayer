export default class SongList {
  id: string
  name: string
  coverPath: string
  coverUri: string = ''

  constructor(id: string, name: string, coverPath: string) {
    this.id = id
    this.name = name
    this.coverPath = coverPath
  }
}