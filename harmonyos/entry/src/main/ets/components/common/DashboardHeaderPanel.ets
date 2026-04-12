// 仪表盘页面头部区组件

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

@Component
export struct DashboardHeaderPanelComponent {
  roleLabel: string = '用户'
  roleBadgeColor: ResourceColor = ResourceColors.PRIMARY
  onRefresh: () => void = () => {}

  build() {
    Row() {
      Column({ space: Spacing.XS }) {
        Text('WordPress CMS')
          .fontSize(Typography.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(ResourceColors.PRIMARY)

        Row({ space: Spacing.SM }) {
          Text('欢迎回来')
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_SECONDARY)

          Text(this.roleLabel)
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.TEXT_ON_PRIMARY)
            .backgroundColor(this.roleBadgeColor)
            .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
            .borderRadius(Radius.FULL)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button({ type: ButtonType.Circle }) {
        SymbolGlyph($r('sys.symbol.arrow_counterclockwise'))
          .fontSize(ComponentSize.ICON_MD)
          .fontColor([ResourceColors.PRIMARY])
      }
      .width(40)
      .height(40)
      .backgroundColor(ResourceColors.BG_SECONDARY)
      .onClick(() => {
        this.onRefresh()
      })
    }
    .width('100%')
    .padding({ top: Spacing.SM, bottom: Spacing.LG })
    .alignItems(VerticalAlign.Center)
  }
}
