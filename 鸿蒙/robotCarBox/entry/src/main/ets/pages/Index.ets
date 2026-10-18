import { webview } from '@kit.ArkWeb'

@Entry
@Component
struct Index {
  controller:WebviewController = new webview.WebviewController()

  build() {
    Column() {
      Web({src: $rawfile("oh.html"),controller:this.controller})
        .width('100%')
        .height('100%')
    }
    .height('100%')
    .width('100%')
  }
}