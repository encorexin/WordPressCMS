// 仪表盘页面快捷操作区组件

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

@Component
export struct DashboardQuickActionsPanelComponent {
  onCreateArticle: () => void = () => {}
  onOpenSites: () => void = () => {}
  onOpenAISettings: () => void = () => {}
  onOpenDataManagement: () => void = () => {}

  build() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('快捷操作')
          .fontSize(Typography.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(ResourceColors.TEXT_PRIMARY)
        Blank()
      }
      .width('100%')

      Row({ space: Spacing.MD }) {
        this.buildActionButton('新建文章', 'square_and_pencil', ResourceColors.PRIMARY, this.onCreateArticle)
        this.buildActionButton('管理站点', 'link', ResourceColors.SUCCESS, this.onOpenSites)
      }
      .width('100%')

      Row({ space: Spacing.MD }) {
        this.buildActionButton('AI 设置', 'gearshape', ResourceColors.WARNING, this.onOpenAISettings)
        this.buildActionButton('数据管理', 'square_and_arrow_down', ResourceColors.ERROR, this.onOpenDataManagement)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.BASE)
    .backgroundColor(ResourceColors.BG_SECONDARY)
    .borderRadius(Radius.LG)
  }

  @Builder
  private buildActionButton(label: string, iconName: string, bgColor: ResourceColor, onClickAction: () => void): void {
    Column() {
      Column({ space: Spacing.SM }) {
        SymbolGlyph($r(`sys.symbol.${iconName}`))
          .fontSize(ComponentSize.ICON_MD)
          .fontColor([ResourceColors.TEXT_ON_PRIMARY])

        Text(label)
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_ON_PRIMARY)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ top: Spacing.LG, bottom: Spacing.LG })
      .backgroundColor(bgColor)
      .borderRadius(Radius.MD)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(onClickAction)
    }
    .layoutWeight(1)
  }
}
