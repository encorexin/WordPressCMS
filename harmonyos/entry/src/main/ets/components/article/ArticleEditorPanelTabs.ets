import { ResourceColors, Typography, Spacing, AnimDuration } from '../../constants/DesignTokens'

@Component
export struct ArticleEditorPanelTabsComponent {
  @Prop activePanel: string = 'ai'
  @Prop versionsCount: number = 0
  onChange: (panelKey: string) => void = (_panelKey: string) => {}

  @Builder
  private buildTab(label: string, panelKey: string): void {
    Column() {
      Text(label)
        .fontSize(Typography.BODY)
        .fontWeight(this.activePanel === panelKey ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.activePanel === panelKey ? ResourceColors.PRIMARY : ResourceColors.TEXT_SECONDARY)
        .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.SM, bottom: Spacing.SM })

      Divider()
        .width(this.activePanel === panelKey ? '100%' : '0%')
        .strokeWidth(2)
        .color(ResourceColors.PRIMARY)
        .animation({ duration: AnimDuration.FAST })
    }
    .onClick(() => {
      this.onChange(panelKey)
    })
  }

  build() {
    Row({ space: 0 }) {
      this.buildTab('AI 生成', 'ai')
      this.buildTab('发布设置', 'publish')
      this.buildTab(`版本历史${this.versionsCount > 0 ? ` (${this.versionsCount})` : ''}`, 'version')
    }
    .width('100%')
    .padding({ top: Spacing.LG })
    .justifyContent(FlexAlign.Start)
  }
}
