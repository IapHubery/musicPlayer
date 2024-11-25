@Component
export default struct Cover {

  @Link isShow: boolean

  build() {
    if (this.isShow) {
      Column()
        .width('100%')
        .height('120%')
        .position({ x: 0, y: 0 })
        .backgroundBlurStyle(BlurStyle.Thin, { colorMode: ThemeColorMode.DARK, adaptiveColor: AdaptiveColor.DEFAULT })
        .animation({
          duration: 500
        })
        .onClick(() => {
          this.isShow = false
        })
    }
  }
}