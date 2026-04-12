import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

@Component
export struct ArticlesBatchDeleteDialogComponent {
  @Prop count: number = 0
  onClose: () => void = () => {}
  onConfirm: () => void = () => {}

  build() {
    Column() {
      Column({ space: Spacing.MD }) {
        Text('确认批量删除')
          .fontSize(Typography.SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(ResourceColors.TEXT_PRIMARY)

        Text(`确定要删除选中的 ${this.count} 篇文章吗？此操作无法撤销。`)
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)

        Row({ space: Spacing.MD }) {
          Button('取消', { type: ButtonType.Capsule })
            .layoutWeight(1)
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .backgroundColor(ResourceColors.BG_SECONDARY)
            .onClick(() => {
              this.onClose()
            })

          Button('删除', { type: ButtonType.Capsule })
            .layoutWeight(1)
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_ON_PRIMARY)
            .backgroundColor(ResourceColors.ERROR)
            .onClick(() => {
              this.onConfirm()
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding(Spacing.LG)
      .backgroundColor(ResourceColors.BG_PRIMARY)
      .borderRadius(Radius.LG)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(ResourceColors.OVERLAY_MASK)
    .onClick(() => {
      this.onClose()
    })
  }
}
