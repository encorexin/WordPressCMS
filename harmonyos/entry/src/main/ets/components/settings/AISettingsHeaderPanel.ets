// AI 设置页面头部区域组件

import { ResourceColors, Typography, Spacing, ComponentSize } from '../../constants/DesignTokens'

@Component
export struct AISettingsHeaderPanelComponent {
  onOpenAdd: () => void = () => {}

  build() {
    Row() {
      Text('AI 设置')
        .fontSize(Typography.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(ResourceColors.PRIMARY)
        .layoutWeight(1)

      Button('添加配置', { type: ButtonType.Capsule })
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .backgroundColor(ResourceColors.PRIMARY)
        .fontColor(ResourceColors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY)
        .fontWeight(FontWeight.Medium)
        .onClick(() => {
          this.onOpenAdd()
        })
    }
    .width('100%')
    .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.SM, bottom: Spacing.BASE })
    .alignItems(VerticalAlign.Bottom)
  }
}
