import { webview } from '@kit.ArkWeb'
import { ResourceColors, Typography, Spacing } from '../../constants/DesignTokens'

@Component
export struct ArticlePreviewSheetComponent {
  @Prop previewUrl: string = ''
  controller: webview.WebviewController = new webview.WebviewController()
  onPageReady: () => void = () => {}

  build() {
    Column() {
      Column() {
        Row()
          .width(36)
          .height(4)
          .borderRadius(2)
          .backgroundColor(ResourceColors.DIVIDER)
      }
      .width('100%')
      .padding({ top: Spacing.SM, bottom: Spacing.SM })
      .justifyContent(FlexAlign.Center)

      Row() {
        Text('预览模式')
          .fontSize(Typography.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank()
          .width(36)
          .height(36)
      }
      .width('100%')
      .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.SM })
      .alignItems(VerticalAlign.Center)

      Divider()
        .width('100%')
        .strokeWidth(0.5)
        .color(ResourceColors.DIVIDER)

      Web({ src: this.previewUrl, controller: this.controller })
        .width('100%')
        .layoutWeight(1)
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .onPageEnd(() => {
          this.onPageReady()
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ResourceColors.BG_PRIMARY)
  }
}
