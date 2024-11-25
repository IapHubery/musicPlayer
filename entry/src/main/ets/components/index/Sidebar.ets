@Component
export default struct Sidebar {
  @Link showSidebar: boolean
  @StorageLink('IsDarkMode') isDarkMode: boolean = false
  @StorageLink('IsVIP') isVIP: boolean = false

  @State themeColor: Resource = $r('app.color.light_grey')
  @State listColor: Resource = $r('app.color.white')
  // list内距
  private listInsideDistance: number = 20
  build() {
    Column() {
      Row() {

      }
      .width('100%')
      .height('20%')
      List() {
        ListItem() {
          Row({ space: 10 }) {
            Image($r('app.media.ic_message_emoji'))
              .width(22)
              .fillColor('#fd0101')
            Text('VIP模式')
              .layoutWeight(1)
              .letterSpacing(1)
            Toggle({ type: ToggleType.Switch, isOn: this.isVIP })
              .width(50)
              .height(30)
              .margin({ right: this.listInsideDistance })
              .backgroundColor(this.listColor)
          }
          .width('100%')
          .height(50)
          .alignItems(VerticalAlign.Center)
          .padding({ left: this.listInsideDistance })
        }
        ListItem() {
          Row({ space: 10 }) {
            Image($r('app.media.ic_public_donotdisturb'))
              .width(22)
            Text('深色模式')
              .layoutWeight(1)
              .letterSpacing(1)
            Toggle({ type: ToggleType.Switch, isOn: this.isDarkMode })
              .width(50)
              .height(30)
              .margin({ right: this.listInsideDistance })
              .backgroundColor(this.listColor)
          }
          .width('100%')
          .height(50)
          .alignItems(VerticalAlign.Center)
          .padding({ left: this.listInsideDistance })
        }
      }
      .width('90%')
      .height('30%')
      .borderRadius(15)
      .backgroundColor(this.listColor)
      .divider({ strokeWidth: 1, color: this.themeColor, startMargin: this.listInsideDistance })
    }
    .width('70%')
    .height('100%')
    .position({ x: this.showSidebar ? 0 : '-80%', y: 0})
    .animation({ duration: 100 })
    .backgroundColor(this.themeColor)
  }
  // 深色模式
  // 是否开启vip
  //
}