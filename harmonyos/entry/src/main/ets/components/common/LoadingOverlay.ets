// 加载遮罩组件

import { ResourceColors, Typography, Spacing } from '../../constants/DesignTokens'

@Component
export struct LoadingOverlay {
  @Prop isLoading: boolean = false
  @Prop message: string = '加载中...'

  build() {
    if (this.isLoading) {
      Stack() {
        // 半透明背景
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(ResourceColors.OVERLAY_MASK)

        // 加载指示器
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color(ResourceColors.PRIMARY)

          if (this.message.length > 0) {
            Text(this.message)
              .fontSize(Typography.BODY)
              .fontColor(ResourceColors.TEXT_ON_PRIMARY)
              .margin({ top: Spacing.MD })
          }
        }
        .padding(Spacing.LG)
        .backgroundColor(ResourceColors.OVERLAY_MASK_STRONG)
        .borderRadius(12)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
  }
}
