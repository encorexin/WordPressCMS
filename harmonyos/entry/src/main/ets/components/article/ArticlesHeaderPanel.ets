import { ResourceColors, Typography, Spacing, ComponentSize } from '../../constants/DesignTokens'

@Component
export struct ArticlesHeaderPanelComponent {
  @Prop totalCount: number = 0
  @Prop draftCount: number = 0
  @Prop pendingCount: number = 0
  @Prop publishedCount: number = 0
  @Prop hasArticles: boolean = false
  @Prop batchMode: boolean = false
  onToggleBatchMode: () => void = () => {}
  onOpenCreate: () => void = () => {}

  build() {
    Row() {
      Column({ space: Spacing.XS }) {
        Text('文章管理')
          .fontSize(Typography.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(ResourceColors.PRIMARY)
        Text(`共 ${this.totalCount} 篇 · 草稿 ${this.draftCount} · 待处理 ${this.pendingCount} · 已发布 ${this.publishedCount}`)
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_SECONDARY)
          .maxLines(2)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.hasArticles) {
        Button(this.batchMode ? '退出批量' : '批量操作', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontColor(this.batchMode ? ResourceColors.TEXT_ON_PRIMARY : ResourceColors.PRIMARY)
          .backgroundColor(this.batchMode ? ResourceColors.PRIMARY : ResourceColors.BG_SECONDARY)
          .fontSize(Typography.BODY)
          .margin({ right: Spacing.SM })
          .onClick(() => {
            this.onToggleBatchMode()
          })
      }

      Button('新建文章', { type: ButtonType.Capsule })
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .backgroundColor(ResourceColors.PRIMARY)
        .fontColor(ResourceColors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY)
        .fontWeight(FontWeight.Medium)
        .onClick(() => {
          this.onOpenCreate()
        })
    }
    .width('100%')
    .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.SM, bottom: Spacing.BASE })
    .alignItems(VerticalAlign.Bottom)
  }
}
