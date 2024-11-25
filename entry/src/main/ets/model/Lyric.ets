export default class Lyric {
  time: number
  words: string
  duration: number = 0

  constructor(time: number, words: string) {
    this.time = time
    this.words = words
  }
}