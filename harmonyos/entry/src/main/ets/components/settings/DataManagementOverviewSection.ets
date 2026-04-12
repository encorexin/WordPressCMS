// 数据管理页面概览区组件

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

export class DataManagementStatsState {
  isLoading: boolean = true
  articleCount: number = 0
  siteCount: number = 0
  templateCount: number = 0
  keywordCount: number = 0
  topicCount: number = 0
  totalCount: number = 0
}

export class DataManagementRestoreFeedbackState {
  title: string = ''
  summary: string = ''
  color: ResourceColor = ResourceColors.TEXT_HINT
}

@Component
export struct DataManagementOverviewSectionComponent {
  @Prop isStatsLoading: boolean = true
  @Prop articleCount: number = 0
  @Prop siteCount: number = 0
  @Prop templateCount: number = 0
  @Prop keywordCount: number = 0
  @Prop topicCount: number = 0
  @Prop totalCount: number = 0
  @Prop restoreTitle: string = ''
  @Prop restoreSummary: string = ''
  @Prop restoreColor: ResourceColor = ResourceColors.TEXT_HINT

  private getTotalCount(): number {
    return this.articleCount + this.siteCount + this.templateCount + this.keywordCount + this.topicCount
  }

  build() {
    Column({ space: Spacing.LG }) {
      this.buildStatsCard()
      this.buildLifecycleCard()

      if (this.restoreSummary.length > 0) {
        this.buildRestoreFeedbackCard()
      }
    }
    .width('100%')
  }

  @Builder
  private buildStatsCard(): void {
    Column({ space: Spacing.MD }) {
      Text('数据概览')
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(ResourceColors.TEXT_PRIMARY)
        .width('100%')

      if (this.isStatsLoading) {
        Row() {
          LoadingProgress()
            .width(24)
            .height(24)
            .color(ResourceColors.PRIMARY)

          Text('加载中...')
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_HINT)
            .margin({ left: Spacing.SM })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding(Spacing.LG)
      } else {
        Row({ space: Spacing.MD }) {
          this.buildStatItem('文章', this.articleCount, $r('sys.symbol.doc_filled_on_doc'))
          this.buildStatItem('站点', this.siteCount, $r('sys.symbol.link'))
        }
        .width('100%')

        Row({ space: Spacing.MD }) {
          this.buildStatItem('模板', this.templateCount, $r('sys.symbol.square_and_pencil'))
          this.buildStatItem('关键词', this.keywordCount, $r('sys.symbol.magnifyingglass'))
        }
        .width('100%')
        .margin({ top: Spacing.MD })

        Row({ space: Spacing.MD }) {
          this.buildStatItem('主题', this.topicCount, $r('sys.symbol.folder'))
          this.buildStatItem('总计', this.totalCount, $r('sys.symbol.highlighter_line'))
        }
        .width('100%')
        .margin({ top: Spacing.MD })
      }
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(Radius.LG)
    .backgroundColor(ResourceColors.BG_SECONDARY)
  }

  @Builder
  private buildLifecycleCard(): void {
    Column({ space: Spacing.SM }) {
      Text('推荐操作顺序')
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(ResourceColors.TEXT_PRIMARY)
        .width('100%')

      Text('先导出并保存文章、文章版本、站点、模板、关键词、主题、AI 设置的当前快照，再在需要时用备份文件恢复这些内容；只有确认备份可用后，再清除本地数据。')
        .fontSize(Typography.BODY)
        .fontColor(ResourceColors.TEXT_SECONDARY)
        .width('100%')

      Text('1. 备份当前数据 -> 2. 需要时从文件恢复备份 -> 3. 确认安全后再清除')
        .fontSize(Typography.CAPTION)
        .fontColor(ResourceColors.PRIMARY)
        .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(Radius.LG)
    .backgroundColor(ResourceColors.BG_SECONDARY)
  }

  @Builder
  private buildRestoreFeedbackCard(): void {
    Column({ space: Spacing.XS }) {
      Text(this.restoreTitle)
        .fontSize(Typography.BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.restoreColor)
        .width('100%')

      Text(this.restoreSummary)
        .fontSize(Typography.CAPTION)
        .fontColor(ResourceColors.TEXT_SECONDARY)
        .width('100%')
    }
    .width('100%')
    .padding(Spacing.MD)
    .borderRadius(Radius.MD)
    .backgroundColor(ResourceColors.BG_SECONDARY)
  }

  @Builder
  private buildStatItem(label: string, count: number, icon: Resource): void {
    Row({ space: Spacing.SM }) {
      SymbolGlyph(icon)
        .fontSize(ComponentSize.ICON_MD)
        .fontColor([ResourceColors.PRIMARY])

      Column({ space: Spacing.XS }) {
        Text(`${count}`)
          .fontSize(Typography.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(ResourceColors.TEXT_PRIMARY)

        Text(label)
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_SECONDARY)
      }
      .alignItems(HorizontalAlign.Start)
    }
    .layoutWeight(1)
    .padding(Spacing.MD)
    .borderRadius(Radius.MD)
    .backgroundColor(ResourceColors.BG_PRIMARY)
  }
}
