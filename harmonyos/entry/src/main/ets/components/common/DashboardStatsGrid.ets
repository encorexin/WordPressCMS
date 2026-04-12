// 仪表盘页面统计卡片网格组件

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

export class DashboardStatsState {
  isLoading: boolean = true
  articleCount: number = 0
  publishedCount: number = 0
  draftCount: number = 0
  siteCount: number = 0
  templateCount: number = 0
  keywordCount: number = 0
}

@Component
export struct DashboardStatsGridComponent {
  @Prop isLoading: boolean = true
  @Prop articleCount: number = 0
  @Prop publishedCount: number = 0
  @Prop draftCount: number = 0
  @Prop siteCount: number = 0
  @Prop templateCount: number = 0
  @Prop keywordCount: number = 0

  build() {
    Column({ space: Spacing.MD }) {
      Row({ space: Spacing.MD }) {
        this.buildStatCard('doc_filled_on_doc', ResourceColors.PRIMARY, this.articleCount, '文章数')
        this.buildStatCard('link', ResourceColors.SUCCESS, this.siteCount, '站点数')
      }
      .width('100%')

      Row({ space: Spacing.MD }) {
        this.buildStatCard('folder', ResourceColors.WARNING, this.templateCount, '模板数')
        this.buildStatCard('magnifyingglass', ResourceColors.ERROR, this.keywordCount, '关键词数')
      }
      .width('100%')

      Row({ space: Spacing.MD }) {
        this.buildStatCard('checkmark_circle_fill', ResourceColors.SUCCESS, this.publishedCount, '已发布')
        this.buildStatCard('doc_text', ResourceColors.TEXT_HINT, this.draftCount, '草稿')
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: Spacing.LG })
  }

  @Builder
  private buildStatCard(iconName: string, iconColor: ResourceColor, count: number, label: string): void {
    Column() {
      Column({ space: Spacing.SM }) {
        SymbolGlyph($r(`sys.symbol.${iconName}`))
          .fontSize(ComponentSize.ICON_LG)
          .fontColor([iconColor])
          .opacity(0.8)

        Text(this.isLoading ? '-' : `${count}`)
          .fontSize(Typography.TITLE_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(ResourceColors.TEXT_PRIMARY)

        Text(label)
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_SECONDARY)
      }
      .width('100%')
      .padding(Spacing.BASE)
      .backgroundColor(ResourceColors.BG_CARD)
      .borderRadius(Radius.LG)
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)', offsetY: 2 })
    }
    .layoutWeight(1)
  }
}
