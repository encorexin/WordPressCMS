// 仪表盘页面功能亮点组件

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

@Component
export struct DashboardFeatureHighlightsComponent {
  build() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('功能亮点')
          .fontSize(Typography.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(ResourceColors.TEXT_PRIMARY)
        Blank()
      }
      .width('100%')
      .margin({ top: Spacing.LG })

      Column({ space: Spacing.MD }) {
        this.buildFeatureCard(
          'doc_filled_on_doc',
          'AI 智能生成',
          'AI 驱动的文章创作，基于关键词和模板自动生成高质量内容',
          ResourceColors.PRIMARY
        )

        this.buildFeatureCard(
          'link',
          '多站点管理',
          '集中管理多个 WordPress 站点，轻松切换发布目标',
          ResourceColors.SUCCESS
        )

        this.buildFeatureCard(
          'folder',
          '模板系统',
          '自定义文章生成模板，支持多种文章类型和风格',
          ResourceColors.WARNING
        )
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private buildFeatureCard(iconName: string, title: string, description: string, accentColor: ResourceColor): void {
    Row({ space: Spacing.MD }) {
      Column() {
        SymbolGlyph($r(`sys.symbol.${iconName}`))
          .fontSize(ComponentSize.ICON_MD)
          .fontColor([accentColor])
      }
      .width(48)
      .height(48)
      .backgroundColor(accentColor + '20')
      .borderRadius(Radius.MD)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Column({ space: Spacing.XS }) {
        Text(title)
          .fontSize(Typography.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .width('100%')

        Text(description)
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_SECONDARY)
          .width('100%')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(Spacing.BASE)
    .backgroundColor(ResourceColors.BG_CARD)
    .borderRadius(Radius.LG)
  }
}
