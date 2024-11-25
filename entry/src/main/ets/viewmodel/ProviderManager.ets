import Logger from '../common/utils/Logger';
import { MediaPlayer } from '../common/utils/MediaPlayerUtil';
import { Song } from '../model/Song'
import { avSession } from '@kit.AVSessionKit';
import { media } from '@kit.MediaKit';
import { AVPlayerState, MyPlayMode } from '../common/constants/Constants';
import FileUtil from '../common/utils/FileUtil';
import Lyric from '../model/Lyric';

const TAG = 'ProviderFeature';

export default class ProviderFeature {
  private static providerSelf: ProviderFeature | undefined = undefined;


  private originPlayList: Song[] = []
  private currentPlayListLink?: SubscribedAbstractProperty<Array<Song>>
  private currentPlaySongLink?: SubscribedAbstractProperty<Song | undefined>
  private currentProgressLink?: SubscribedAbstractProperty<number>
  private changeSeekFlagLink?: SubscribedAbstractProperty<boolean>
  private lyricLink?: SubscribedAbstractProperty<string>
  private lyricListLink?: SubscribedAbstractProperty<Array<Lyric>>
  private playModeLink?: SubscribedAbstractProperty<string>
  private isPlayingLink?: SubscribedAbstractProperty<boolean>
  private mediaPlayer?: MediaPlayer
  private avPlayer?: media.AVPlayer

  static async getInstance(): Promise<ProviderFeature> {
    Logger.info(TAG, ' provider getInstance');
    if (!ProviderFeature.providerSelf) {
      Logger.info(TAG, ' new provider');
      ProviderFeature.providerSelf = new ProviderFeature();
      await ProviderFeature.providerSelf.init();
    }
    return ProviderFeature.providerSelf;
  }

  private constructor() {

  }

  private async init() {
    this.currentPlaySongLink = AppStorage.setAndLink('CurrentPlaySong', undefined)
    this.currentPlayListLink = AppStorage.setAndLink('CurrentPlayList', [])
    this.currentProgressLink = AppStorage.setAndLink('CurrentProgress', 0)
    this.changeSeekFlagLink = AppStorage.setAndLink('ChangeSeekFlag', false)
    this.lyricLink = AppStorage.setAndLink('Lyric', '')
    this.lyricListLink = AppStorage.setAndLink('LyricList', [])
    this.playModeLink = AppStorage.setAndLink('PlayMode', MyPlayMode.LIST_CYCLE)
    this.isPlayingLink = AppStorage.setAndLink('IsPlaying', false)
    this.mediaPlayer = await MediaPlayer.getInstance()
    this.mediaPlayer.on(AVPlayerState.COMPLETED, () => { this.nextSong(false) })
    this.avPlayer = this.mediaPlayer.getAvPlayer()
  }

  async playOrChange(song: Song) {
    if (this.currentPlaySongLink?.get() == undefined) {
      this.currentPlaySongLink?.set(song)
      await this.play(song)
    } else {
      if (!(this.currentPlaySongLink.get()?.id == song.id)) {
        this.currentPlaySongLink.set(song)
        this.isPlayingLink?.set(false)
        await this.changeSong(song)
      }
    }
  }

  async play(song: Song | undefined) {
    Logger.info(`当前播放器状态: ${this.avPlayer?.state}`)
    if (this.avPlayer?.state == AVPlayerState.PAUSED) {
      this.avPlayer?.play()
    } else if (this.avPlayer?.state == AVPlayerState.IDLE || this.avPlayer?.state == AVPlayerState.RELEASED) {
      if (this.avPlayer?.state == AVPlayerState.RELEASED) {
        this.avPlayer?.reset()
      }
      if (song) {
        // 加载歌词
        this.handleLyric(song)
        await this.mediaPlayer?.loadFromFile(song.songPath)
        this.currentPlaySongLink?.set(song)
      }
    }
  }

  setLyric(element: string, lyricList: Array<Lyric>) {
    let split = element.split(']')
    if (split[1].trim()) {
      let timeStr = split[0].replace('[', '')
      let min = Number(timeStr.slice(0, 2))
      let sec = Number(timeStr.slice(3))
      let words = split[1].trimStart()
      lyricList.push(new Lyric(min * 60 * 1000 + sec * 1000, words))
    }
  }

  // 解析歌词
  handleLyric(song: Song) {
    const temp: Array<Lyric> = []
    if (song.wordsPath) {
      // this.lyricLink?.set(FileUtil.readFile(song.wordsPath))
      const fileContent = FileUtil.readFile(song.wordsPath).split('\n')
      let startIndex = -1
      for (let index = 0; index < fileContent.length; index++) {
        const element = fileContent[index];
        if (startIndex != -1 && element.startsWith('[')) {
          this.setLyric(element, temp)
        } else if (element.indexOf('00:00') != -1) {
          startIndex = index
          this.setLyric(element, temp)
        }
        // Logger.info('' + this.wordsLink?.get())
      }
      this.lyricListLink?.set(temp)
    }
  }

  changePlayMode() {
    if (this.playModeLink?.get() == MyPlayMode.LIST_CYCLE) {
      this.playModeLink.set(MyPlayMode.SINGLE_CYCLE)
    } else if (this.playModeLink?.get() == MyPlayMode.SINGLE_CYCLE) {
      this.playModeLink?.set(MyPlayMode.RANDOM)
      const playList = this.currentPlayListLink?.get()
      if (playList != undefined) {
        for (let index = 0; index < playList.length; index++) {
          const song: Song = playList[index];
          const random = Math.floor(Math.random() * playList.length)
          if (random == index) {
            continue
          }
          let temp: Song = playList[random]
          playList[random] = song
          playList[index] = temp
        }

      }
    } else {
      this.playModeLink?.set(MyPlayMode.LIST_CYCLE)
      if (this.originPlayList.length > 0) {
        this.currentPlayListLink?.set(this.originPlayList)
      }
    }
  }

  async lastSong() {
    const currentPlayList = this.currentPlayListLink?.get()
    if (currentPlayList) {
      let songIndex = -1
      for (let index = 0;index < currentPlayList.length;index++) {
        if (this.currentPlaySongLink?.get()?.id == currentPlayList[index].id) {
          if (index == 0)
            songIndex = currentPlayList.length - 1
          else
            songIndex = index - 1
        }
      }
      await this.changeSong(currentPlayList[songIndex])
    }
  }

  async nextSong(isClick: boolean) {
    const currentPlayList = this.currentPlayListLink?.get()
    if (currentPlayList) {
      let songIndex = -1
      const playMode = this.playModeLink?.get()
      if (isClick || (!isClick && (playMode == MyPlayMode.LIST_CYCLE || playMode == MyPlayMode.RANDOM))) {
        for (let index = 0;index < currentPlayList.length;index++) {
          if (this.currentPlaySongLink?.get()?.id == currentPlayList[index].id) {
            if (index == currentPlayList.length - 1)
              songIndex = 0
            else
              songIndex = index + 1
          }
        }
        await this.changeSong(currentPlayList[songIndex])
      } else if (!isClick && playMode == MyPlayMode.SINGLE_CYCLE) {
        this.avPlayer?.seek(0)
        if (this.avPlayer?.state == AVPlayerState.COMPLETED) {
          this.avPlayer?.play()
        }
      }
    }
  }

  async changeSong(song: Song) {
    if (this.currentPlaySongLink?.get() != undefined) {
      await this.avPlayer?.reset()
      this.changeSeekFlagLink?.set(false)
      this.handleLyric(song)
      await this.mediaPlayer?.loadFromFile(song.songPath)
      this.currentPlaySongLink?.set(song)
    }
  }

  seek(seek: number) {
    if (this.currentProgressLink && (this.avPlayer?.state == AVPlayerState.PLAYING || this.avPlayer?.state == AVPlayerState.PAUSED)) {
      this.avPlayer?.seek(seek)
    }
  }

  pause() {
    if (this.avPlayer?.state == AVPlayerState.PLAYING) {
      this.avPlayer?.pause()
    }
  }

  setPlayList(songs: Song[]) {
    this.currentPlayListLink?.set([])
    this.originPlayList = []
    for (let index = 0; index < songs.length; index++) {
      const song = songs[index]
      this.currentPlayListLink?.get().push(song)
      this.originPlayList.push(song)
    }
  }
}