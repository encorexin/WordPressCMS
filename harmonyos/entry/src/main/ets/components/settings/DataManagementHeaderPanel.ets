// 数据管理页面头部区组件

import { ResourceColors, Typography, Spacing } from '../../constants/DesignTokens'

@Component
export struct DataManagementHeaderPanelComponent {
  build() {
    Row() {
      Text('数据管理')
        .fontSize(Typography.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(ResourceColors.PRIMARY)

      Row()
        .width(60)
    }
    .width('100%')
    .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.SM, bottom: Spacing.BASE })
    .alignItems(VerticalAlign.Bottom)
  }
}
