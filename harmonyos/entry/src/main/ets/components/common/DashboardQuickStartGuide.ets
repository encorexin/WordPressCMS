// 仪表盘页面快速开始引导组件

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

export class DashboardSetupState {
  hasSites: boolean = false
  hasAISettings: boolean = false
  hasTemplates: boolean = false
  hasArticles: boolean = false
  completedSteps: number = 0
  isSetupComplete: boolean = false
}

@Component
export struct DashboardQuickStartGuideComponent {
  @Prop hasSites: boolean = false
  @Prop hasAISettings: boolean = false
  @Prop hasTemplates: boolean = false
  @Prop hasArticles: boolean = false
  onOpenSites: () => void = () => {}
  onOpenAISettings: () => void = () => {}
  onOpenTemplates: () => void = () => {}
  onCreateArticle: () => void = () => {}

  private getCompletedSteps(): number {
    let count = 0
    if (this.hasSites) { count++ }
    if (this.hasAISettings) { count++ }
    if (this.hasTemplates) { count++ }
    if (this.hasArticles) { count++ }
    return count
  }

  build() {
    Column({ space: Spacing.MD }) {
      Row() {
        Text('快速开始')
          .fontSize(Typography.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(ResourceColors.TEXT_PRIMARY)
        Blank()
      }
      .width('100%')

      Row({ space: Spacing.SM }) {
        Text(`${this.getCompletedSteps()}/4`)
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.PRIMARY)
          .fontWeight(FontWeight.Medium)

        Text('步骤完成')
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_SECONDARY)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      Column({ space: Spacing.SM }) {
        this.buildStepItem(this.hasSites, '添加 WordPress 站点', this.onOpenSites)
        this.buildStepItem(this.hasAISettings, '配置 AI 设置', this.onOpenAISettings)
        this.buildStepItem(this.hasTemplates, '创建文章模板', this.onOpenTemplates)
        this.buildStepItem(this.hasArticles, '创作第一篇文章', this.onCreateArticle)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.BASE)
    .backgroundColor(ResourceColors.BG_CARD)
    .borderRadius(Radius.LG)
    .margin({ top: Spacing.LG })
  }

  @Builder
  private buildStepItem(isCompleted: boolean, label: string, onClickAction: () => void): void {
    Row({ space: Spacing.SM }) {
      if (isCompleted) {
        SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
          .fontSize(ComponentSize.ICON_SM)
          .fontColor([ResourceColors.SUCCESS])
      } else {
        SymbolGlyph($r('sys.symbol.circle'))
          .fontSize(ComponentSize.ICON_SM)
          .fontColor([ResourceColors.TEXT_HINT])
      }

      Text(label)
        .fontSize(Typography.BODY)
        .fontColor(isCompleted ? ResourceColors.TEXT_SECONDARY : ResourceColors.TEXT_PRIMARY)
        .fontWeight(isCompleted ? FontWeight.Regular : FontWeight.Medium)
        .decoration({ type: isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None })
        .layoutWeight(1)

      if (!isCompleted) {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(ComponentSize.ICON_SM)
          .fontColor([ResourceColors.TEXT_HINT])
      }
    }
    .width('100%')
    .padding({ top: Spacing.SM, bottom: Spacing.SM })
    .onClick(onClickAction)
  }
}
