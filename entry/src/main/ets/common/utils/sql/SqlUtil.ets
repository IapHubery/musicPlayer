import { EntryAbility, rdbStore } from '../../../entryability/EntryAbility'
import { Singer } from '../../../model/Singer'
import { Song } from '../../../model/Song'
import Logger from '../Logger'
import { fileUri } from '@kit.CoreFileKit'
import { relationalStore } from '@kit.ArkData'
import { SongsWrap } from '../../../model/SongsWrap'
import data from '@ohos.telephony.data'
import { window } from '@kit.ArkUI'

export default class SqlUtil extends EntryAbility {

  static insertOrUpdate(tableName: string, key: string, value: string, valueBucket: relationalStore.ValuesBucket) {
    if (rdbStore != undefined) {
      const resultSet = rdbStore.querySqlSync('SELECT COUNT(' + key + ') AS count FROM ' + tableName + 'WHERE ' + key + '= \'' + value + '\'')
      let count = 0
      while (resultSet.goToNextRow()) {
        count = resultSet.getLong(resultSet.getColumnIndex('count'));
      }
      if (count == 0)
        SqlUtil.insert(tableName, valueBucket)
      else
        SqlUtil.update(tableName, key, value, valueBucket)
    }
  }

  static insert(tableName: string, valueBucket: relationalStore.ValuesBucket) {
    if(rdbStore != undefined) {
      const rowId = (rdbStore as relationalStore.RdbStore).insertSync(tableName, valueBucket)
      Logger.info('插入表:' + tableName + ' 插入数据rows:' + rowId)
    }
  }

  /**
   * 更新
   * @param tableName 表名
   * @param key 唯一键名
   * @param value 唯一键值
   * @param valueBucket 实体类
   */
  static update(tableName: string, key: string, value: string, valueBucket: relationalStore.ValuesBucket) {
    if(rdbStore != undefined) {
      let predicates = new relationalStore.RdbPredicates(tableName);
      predicates.equalTo(key, value);
      return rdbStore.updateSync(valueBucket, predicates, undefined)
      /*(rdbStore as relationalStore.RdbStore).update(valueBucket, predicates,(err, rows) => {
        if (err) {
          console.error(`Updated failed, code is ${err.code},message is ${err.message}`);
          return;
        }
        Logger.info('更新表:' + tableName + ' 更新数据id:' + rows)
      })*/
    }
    return -1
  }

  static delete(tableName: string, key: string, value: string) {
    if(rdbStore != undefined) {
      let predicates = new relationalStore.RdbPredicates(tableName);
      predicates.equalTo(key, value);
      return rdbStore.deleteSync(predicates)
    }
    return -1
  }

  static queryPlayList() {

  }


}