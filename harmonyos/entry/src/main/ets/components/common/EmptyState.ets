// 空状态占位组件

import { Colors, Typography, Spacing, ComponentSize } from '../../constants/DesignTokens'

@Component
export struct EmptyState {
  @Prop icon: Resource = $r('sys.symbol.folder')
  @Prop title: string = '暂无数据'
  @Prop description: string = ''
  @Prop actionText: string = ''
  onAction: () => void = () => {}

  build() {
    Column() {
      SymbolGlyph(this.icon)
        .fontSize(64)
        .fontColor([Colors.TEXT_HINT])
        .opacity(0.5)
        .margin({ bottom: Spacing.BASE })

      Text(this.title)
        .fontSize(Typography.SUBTITLE)
        .fontColor(Colors.TEXT_PRIMARY)
        .margin({ bottom: Spacing.SM })

      if (this.description.length > 0) {
        Text(this.description)
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
          .margin({ bottom: Spacing.LG })
      }

      if (this.actionText.length > 0) {
        Button(this.actionText)
          .type(ButtonType.Capsule)
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.BODY)
          .backgroundColor(Colors.PRIMARY)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .onClick(() => {
            this.onAction()
          })
      }
    }
    .width('100%')
    .padding(Spacing.XL)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
