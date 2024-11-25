export default class Setting {

  static INSTANCE: Setting

  static getInstance() {
    if (!Setting.INSTANCE)
      Setting.INSTANCE = new Setting()
    return Setting.INSTANCE
  }

  // 导入文件重复时设置 0 跳过 1 询问 2 覆盖
  fileRepeat: number = 0
  // 导入完成后是否保存源文件，如果没有复制源文件的话，那么不会删除 0 删除 1 保留
  saveSrcFile: number = 0
}