import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import Logger from '../common/utils/Logger';

export let rdbStore: relationalStore.RdbStore | undefined = undefined;

const TAG = 'SqlUtil'
export class EntryAbility extends UIAbility {

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.log('onCreate')
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    console.log('onDestroy')
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    console.log('初始化sql')
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Welcome', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
    });

    let mainWindow = windowStage.getMainWindowSync();
    mainWindow.setWindowSystemBarEnable(["status"]);
    mainWindow.setWindowSystemBarProperties({
      statusBarColor: '#00000000'
    })
    mainWindow.setWindowLayoutFullScreen(true)

    const STORE_CONFIG :relationalStore.StoreConfig= {
      name: 'music.db', // 数据库文件名
      securityLevel: relationalStore.SecurityLevel.S1 // 数据库安全级别
    }
    // 判断数据库版本，如果不匹配则需进行升降级操作
    // 假设当前数据库版本为3，表结构：EMPLOYEE (NAME, AGE, SALARY, CODES, IDENTITY)
    const SQL_CREATE_SONG = 'CREATE TABLE IF NOT EXISTS song(id VARCHAR(20) PRIMARY KEY, name VARCHAR(100), search_key VARCHAR(100), cover_path VARCHAR(500), song_path VARCHAR(500), words_path VARCHAR(500), is_favor INTEGER DEFAULT 0, singer_id VARCHAR(20), play_count INTEGER DEFAULT 0)'; // 建表Sql语句, IDENTITY为bigint类型，sql中指定类型为UNLIMITED INT
    const SQL_CREATE_SINGER = 'CREATE TABLE IF NOT EXISTS singer(id VARCHAR(20) PRIMARY KEY, name VARCHAR(100), search_key VARCHAR(100), cover_path VARCHAR(500), is_favor INTEGER DEFAULT 0)'
    const SQL_CREATE_SONG_LIST = 'CREATE TABLE IF NOT EXISTS song_list(id VARCHAR(20) PRIMARY KEY, name VARCHAR(100), cover_path VARCHAR(500))'
    const SQL_CREATE_SONG_SONG_LIST = 'CREATE TABLE IF NOT EXISTS song_song_list(id INTEGER PRIMARY KEY AUTOINCREMENT, song_list_id VARCHAR(20), song_id VARCHAR(20))'
    relationalStore.getRdbStore(this.context, STORE_CONFIG, (err, store) => {
      rdbStore = store
      if (err) {
        console.error(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
        return;
      }
      // 当数据库创建时，数据库默认版本为0
      if (store.version === 0) {
        store.executeSql(SQL_CREATE_SONG); // 创建数据表
        store.executeSql(SQL_CREATE_SINGER);
        store.executeSql(SQL_CREATE_SONG_LIST);
        store.executeSql(SQL_CREATE_SONG_SONG_LIST);
        store.version = 1
      }
    });
  }


  onWindowStageDestroy(): void {
    console.log('onWindowStageDestroy')
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    console.log('onForeground')
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    console.log('onBackground')
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
