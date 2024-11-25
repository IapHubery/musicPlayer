export default class Constants {
  static readonly AUDIO_SUFFIX = '.mp3,.flac'

  static readonly WORDS_SUFFIX = '.lrc'

  static readonly PIC_SUFFIX = '.jpg,.png,.webp'

  // 默认歌手封面
  static readonly DEFAULT_SINGER_COVER = 'app.media.first'
  // 默认歌曲封面
  static readonly DEFAULT_SONG_COVER = 'app.media.first'

  static readonly DEFAULT_FILE_PATH_URI = 'file://docs/storage/Users/currentUser/Download'
}

export class ScreenInfo {
  static WIDTH = 0
  static HEIGHT = 0
}

export class MyPlayMode {
  static LIST_CYCLE = 'listCycle'
  static SINGLE_CYCLE = 'singerCycle'
  static RANDOM = 'random'
}

export enum AVPlayerState {
  IDLE = 'idle',
  INITIALIZED = 'initialized',
  PREPARED = 'prepared',
  PLAYING = 'playing',
  PAUSED = 'paused',
  COMPLETED = 'completed',
  STOPPED = 'stopped',
  RELEASED = 'released'
}