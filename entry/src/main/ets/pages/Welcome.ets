import Logger from '../common/utils/Logger'
import { display, router } from '@kit.ArkUI'
import Router from '../route/Router'
import Setting from '../model/Setting'
import { ScreenInfo } from '../common/constants/Constants'

@Entry
@Component
struct Welcome {

  onPageShow() {
    Logger.info('Welcome!')
    // setInterval(function() {}.bind(this), 3000)
    // this.pathStack.replacePath({ name: 'Index' })
    setTimeout(() => {
      router.replaceUrl({
        url: Router.MAIN_PAGE
      })
    }, 1000);
  }

  aboutToAppear(): void {
    AppStorage.setAndLink('UserSetting', Setting.getInstance())
    AppStorage.setAndLink('ShowLoad', false)
    AppStorage.setAndLink('UpgradeTotal', 0)
    AppStorage.setAndLink('CurrentUpgradeNum', 0)
    const displayInfo = display.getDefaultDisplaySync()
    ScreenInfo.WIDTH = Math.round(px2vp(displayInfo.width))
    ScreenInfo.HEIGHT = Math.round(px2vp(displayInfo.height))
  }

  build() {
    Column() {
      Text('Hello')
        .fontSize(24)
        .fontWeight(FontWeight.Regular)
      Text('new World！')
        .fontSize(24)
        .fontWeight(FontWeight.Regular)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}