import { fileIo as fs, picker, ReadOptions, WriteOptions } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import Logger from './Logger';
import { Song } from '../../model/Song';
import { Singer } from '../../model/Singer';
import { pinyin4js } from '@ohos/pinyin4js'; // ohpm install @ohos/pinyin4js
import SqlUtil from './sql/SqlUtil';
import Constants from '../constants/Constants';
import IdUtil from './IdUtil';
import Setting from '../../model/Setting';
import util from '@ohos.util';
import SongSqlUtil from './sql/SongSqlUtil';
import SingerSqlUtil from './sql/SingerSqlUtil';

const TAG = 'FileUtil'
export default class FileUtil {

  static userSettingLink: SubscribedAbstractProperty<Setting> = AppStorage.link('UserSetting')

  public static init(context: Context) {
    // context.resourceManager.getRawFd()
  }

  public static delete(path: string) {
    fs.unlink(path, (err: BusinessError) => {
      if (err)
        console.log(err.message);
        Logger.error(TAG, err.message)
    })
  }

  public static copy(srcPath: string, destPath: string): void {
    // 打开文件
    let srcFile = fs.openSync(srcPath, fs.OpenMode.READ_ONLY);
    let destFile = fs.openSync(destPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    // 读取源文件内容并写入至目的文件
    let bufSize = 4096;
    let readSize = 0;
    let buf = new ArrayBuffer(bufSize);
    let readOptions: ReadOptions = {
      offset: readSize,
      length: bufSize
    };
    let readLen = fs.readSync(srcFile.fd, buf, readOptions);
    while (readLen > 0) {
      readSize += readLen;
      let writeOptions: WriteOptions = {
        length: readLen
      };
      fs.writeSync(destFile.fd, buf, writeOptions);
      readOptions.offset = readSize;
      readLen = fs.readSync(srcFile.fd, buf, readOptions);
    }
    // 关闭文件
    fs.closeSync(srcFile);
    fs.closeSync(destFile);
  }

  public static getDocumentSelectOptions(context: Context, defaultFilePathUri: string, fileSuffixFilters: string[]) {

    const documentSelectOptions = new picker.DocumentSelectOptions();
    // 选择文档的最大数目（可选）
    documentSelectOptions.maxSelectNumber = 100;
    // 指定选择的文件或者目录路径（可选）
    if (defaultFilePathUri)
      documentSelectOptions.defaultFilePathUri = defaultFilePathUri;
    // 选择文件的后缀类型['后缀类型描述|后缀类型']（可选） 若选择项存在多个后缀名，则每一个后缀名之间用英文逗号进行分隔（可选），后缀类型名不能超过100,选择所有文件：'所有文件(*.*)|.*';
    if (fileSuffixFilters.length > 0)
      documentSelectOptions.fileSuffixFilters = fileSuffixFilters;
    //选择是否对指定文件或目录授权，true为授权，当为true时，defaultFilePathUri为必选参数，拉起文管授权界面；false为非授权，拉起常规文管界面（可选）
    documentSelectOptions.authMode = true;
    return documentSelectOptions;
  }

  static readFile(path: string) {
    // 打开文件
    let srcFile = fs.openSync(path, fs.OpenMode.READ_ONLY);
    // 读取源文件内容并写入至目的文件
    let bufSize = 4096;
    let readSize = 0;
    let buf = new ArrayBuffer(bufSize);
    let readOptions: ReadOptions = {
      offset: readSize,
      length: bufSize
    };
    let content = ''
    let readLen = fs.readSync(srcFile.fd, buf, readOptions);
    while (readLen > 0) {
      readSize += readLen;
      content += FileUtil.uint8Array2String(new Uint8Array(buf))
      readOptions.offset = readSize;
      readLen = fs.readSync(srcFile.fd, buf, readOptions);
    }
    // 关闭文件
    fs.closeSync(srcFile);
    return content
  }

  private static uint8Array2String(input: Uint8Array) {
    let textDecoder = util.TextDecoder.create("utf-8", { ignoreBOM: true })
    return textDecoder.decodeWithStream(input, { stream: false });
  }

  static importFile(context: Context, uri: string) {
    const fileName = uri.slice(uri.lastIndexOf('/') + 1, uri.lastIndexOf('.'))
    const suffix = uri.slice(uri.lastIndexOf('.') + 1)

    const split = fileName.split('-')
    let songName = ''
    let singerName = ''
    if (split.length == 1) {
      singerName = decodeURI(split[0]).trim()
    } else if (split.length == 2) {
      songName = decodeURI(split[0]).trim()
      singerName = decodeURI(split[1]).trim()
    }
    let singers: Singer[] = []
    if (singerName) {
      singers = SingerSqlUtil.querySinger(singerName, [0, 1])
    }
    let singer: Singer
    if (singers.length > 0)
      singer = singers[0]
    else {
      singer = Singer.getEmpty()
      singer.name = singerName
      const singerNamePinyi: string = pinyin4js.convertToPinyinString(singerName, '|', pinyin4js.WITHOUT_TONE)
      const split = singerNamePinyi.split('|')
      let firstChar: string = ''
      for (let index = 0; index < split.length; index++) {
        const element = split[index];
        firstChar += element.charAt(0)
      }
      singer.searchKey = singerName + ',' + singerNamePinyi.replaceAll('|', '') + ',' + firstChar
      console.info(singer.searchKey)
    }
    if (!singer.id) {
      singer.id = IdUtil.generateId()
      SqlUtil.insert('singer', singer.toValuesBucket())
    }
    // 查询是否有重复数据
    let songs: Song[] = []
    if (songName) {
      songs = SongSqlUtil.queryBySongNameAndSinger(songName, singer.id)
    }
    let song: Song = Song.getEmpty()
    if (songs.length > 0) {
      song = songs[0]
    } else {
      if (songName) {
        song.name = songName
        const songNamePinyi: string = pinyin4js.convertToPinyinString(songName, '|', pinyin4js.WITHOUT_TONE)
        const split = songNamePinyi.split('|')
        let firstChar: string = ''
        for (let index = 0; index < split.length; index++) {
          const element = split[index];
          firstChar += element.charAt(0)
        }
        song.searchKey = songName + ',' + singer.searchKey + ',' + songNamePinyi.replaceAll('|', '') + ',' + firstChar
        console.info(song.searchKey)
        song.isFavor = 0
        song.singerId = singer.id
      }
    }

    // 音频
    const path = context.filesDir + '/' + fileName + '.' + suffix
    if (Constants.AUDIO_SUFFIX.includes(suffix)) {
      FileUtil.handleAudioFile(song, uri, path, songName)
      // 歌词
    } else if (Constants.WORDS_SUFFIX.includes(suffix)) {
      FileUtil.handleWordsFile(song, uri, path, songName)
      // 封面
    } else if (Constants.PIC_SUFFIX.includes(suffix)) {
      FileUtil.handlePicFile(song, singer, uri, path, songName)
    }
  }

  private static handleAudioFile(song: Song, srcPath: string, destPath: string, songName: string) {
    if (songName) {
      if (song.id) {
        if (!song.songPath) {
          song.songPath = destPath
          SqlUtil.update('song', 'id', song.id, song.toValuesBucket())
          FileUtil.copy(srcPath, destPath)
        } else {
          FileUtil.copyFile(srcPath, destPath)
        }
      } else {
        song.id = IdUtil.generateId()
        song.songPath = destPath
        SqlUtil.insert('song', song.toValuesBucket())
        FileUtil.copy(srcPath, destPath)
      }
    }
  }

  private static handleWordsFile(song: Song, srcPath: string, destPath: string, songName: string) {
    if (songName) {
      if (song.id) {
        if (!song.wordsPath) {
          song.wordsPath = destPath
          SqlUtil.update('song', 'id', song.id, song.toValuesBucket())
          FileUtil.copy(srcPath, destPath)
        } else {
          FileUtil.copyFile(srcPath, destPath)
        }
      } else {
        song.id = IdUtil.generateId()
        song.wordsPath = destPath
        SqlUtil.insert('song', song.toValuesBucket())
        FileUtil.copy(srcPath, destPath)
      }
    }
  }

  private static handlePicFile(song: Song, singer: Singer, srcPath: string, destPath: string, songName: string) {
    if (songName) {
      if (song.id) {
        if (!song.coverPath) {
          song.coverPath = destPath
          SqlUtil.update('song', 'id', song.id, song.toValuesBucket())
          FileUtil.copy(srcPath, destPath)
        } else {
          FileUtil.copyFile(srcPath, destPath)
        }
      } else {
        song.id = IdUtil.generateId()
        song.coverPath = destPath
        SqlUtil.insert('song', song.toValuesBucket())
        FileUtil.copy(srcPath, destPath)
      }
    } else {
      if (!singer.coverPath) {
        singer.coverPath = destPath
        SqlUtil.update('singer', 'id', singer.id, singer.toValuesBucket())
        FileUtil.copy(srcPath, destPath)
      } else {
        FileUtil.copyFile(srcPath, destPath)
      }
    }
  }

  private static copyFile(uri: string, destPath: string) {
    if (FileUtil.userSettingLink.get().fileRepeat == 1) {

    } else if (FileUtil.userSettingLink.get().fileRepeat == 2) {
      FileUtil.copy(uri, destPath)
      if (FileUtil.userSettingLink.get().saveSrcFile == 0) {
        FileUtil.delete(uri)
      }
    }
  }
}