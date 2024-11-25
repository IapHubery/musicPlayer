import { media } from '@kit.MediaKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import File from '@system.file';
import { Song } from '../../model/Song';
import { AVPlayerState } from '../constants/Constants';
import Logger from './Logger';
const TAG = 'MediaPlayer'
export class MediaPlayer {

  static mediaPlayer: MediaPlayer

  private count: number = 0;
  private isSeek: boolean = true; // 用于区分模式是否支持seek操作
  private fileSize: number = -1;
  private fd: number = 0;
  private callbackMap: Record<string, object | null> = {};
  
  private avPlayer?: media.AVPlayer

  private isPlaying?: SubscribedAbstractProperty<boolean>

  private currentPlaySongLink: SubscribedAbstractProperty<Song> = AppStorage.link('CurrentPlaySong')
  private currentProgressLink: SubscribedAbstractProperty<number> = AppStorage.link('CurrentProgress')
  private changeSeekFlagLink: SubscribedAbstractProperty<boolean> = AppStorage.link('ChangeSeekFlag')

  static async getInstance() {
    if (!MediaPlayer.mediaPlayer) {
      MediaPlayer.mediaPlayer = new MediaPlayer()
      await MediaPlayer.mediaPlayer.init()
    }
    return MediaPlayer.mediaPlayer
  }

  public getAvPlayer() {
    return this.avPlayer
  }

  private constructor() {
  }

  async init() {
    this.isPlaying = AppStorage.link('IsPlaying')
    if (!this.avPlayer) {
      this.avPlayer = await media.createAVPlayer()
      // 创建状态机变化回调函数
      this.setAVPlayerCallback();
    }
  }

  // 注册avplayer回调函数
  setAVPlayerCallback() {
    // seek操作结果回调函数
    this.avPlayer?.on('seekDone', (seekDoneTime: number) => {
      this.currentProgressLink.set(seekDoneTime)
      this.changeSeekFlagLink.set(false)
      Logger.info(`跳转至 ${seekDoneTime} 毫秒处`);
    })
    // error回调监听函数,当avPlayer在操作过程中出现错误时调用 reset接口触发重置流程
    this.avPlayer?.on('error', (err: BusinessError) => {
      Logger.error(`Invoke avPlayer failed, code is ${err.code}, message is ${err.message}`);
      this.avPlayer?.reset(); // 调用reset重置资源，触发idle状态
    })
    this.avPlayer?.on('durationUpdate', (duration) => {
      Logger.info(`当前歌曲总时长: ${duration} 毫秒`)
      this.currentPlaySongLink.get().duration = duration
      this.currentProgressLink.set(0)
    })
    this.avPlayer?.on('timeUpdate', (data) => {
      this.currentProgressLink.set(data)
    })
    // 状态机变化回调函数
    this.avPlayer?.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
      this.isPlaying?.set(false)
      switch (state) {
        case AVPlayerState.IDLE: // 成功调用reset接口后触发该状态机上报
          Logger.info('AVPlayer state idle called.');
          break;
        case AVPlayerState.INITIALIZED: // avplayer 设置播放源后触发该状态上报
          Logger.info('AVPlayer state initialized called.');
          this.avPlayer?.prepare();
          break;
        case AVPlayerState.PREPARED: // prepare调用成功后上报该状态机
          Logger.info('AVPlayer state prepared called.');
          this.avPlayer?.play(); // 调用播放接口开始播放
          break;
        case AVPlayerState.PLAYING: // play成功调用后触发该状态机上报
          this.isPlaying?.set(true)
          Logger.info('AVPlayer state playing called.');
          break;
        case AVPlayerState.PAUSED: // pause成功调用后触发该状态机上报
          Logger.info('AVPlayer state paused called.');
          break;
        case AVPlayerState.COMPLETED: // 播放结束后触发该状态机上报
          Logger.info('AVPlayer state completed called.');
          const callback = this.callbackMap[AVPlayerState.COMPLETED] as Function//调用播放结束接口
          callback()
          break;
        case AVPlayerState.STOPPED: // stop接口成功调用后触发该状态机上报
          Logger.info('AVPlayer state stopped called.');
          this.avPlayer?.reset(); // 调用reset接口初始化avplayer状态
          break;
        case AVPlayerState.RELEASED:
          Logger.info('AVPlayer state released called.');
          break;
        default:
          Logger.info('AVPlayer state unknown called.');
          break;
      }
    })
  }

  public on(event: string, callback: Function): void {
    Logger.info(TAG, 'AVPlayer on callback event ' + event);
    this.callbackMap[event] = callback;
  }

  async loadFromFile(path: string) {
    let file = fileIo.openSync(path)
    this.fd = file.fd
    let src: media.AVDataSrcDescriptor = {
      fileSize: -1,
      callback: (buf: ArrayBuffer, length: number, pos: number | undefined) => {
        let num = 0;
        if (buf == undefined || length == undefined || pos == undefined) {
          return -1;
        }
        num = fileIo.readSync(this.fd, buf, { offset: pos, length: length });
        if (num > 0 && (this.fileSize >= pos)) {
          return num;
        }
        return -1;
      }
    }
    this.fileSize = fileIo.statSync(path).size
    src.fileSize = this.fileSize
    if (this.avPlayer) {
      this.avPlayer.dataSrc = src;
    }
  }
}