// 发布面板组件 — 提取自 ArticleEditorPage.ets

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

@Component
export struct PublishPanelComponent {
  @Prop isPublishing: boolean = false
  @Prop selectedSiteId: string = ''
  onPublish: () => void = () => {}
  onSiteSelect: (siteId: string) => void = (_siteId: string) => {}

  build() {
    Column({ space: Spacing.MD }) {
      // 标题
      Text('发布设置')
        .fontSize(Typography.BODY_LARGE)
        .fontWeight(FontWeight.Medium)
        .fontColor(ResourceColors.TEXT_PRIMARY)
        .width('100%')

      // 站点信息行
      Row() {
        Column({ space: 2 }) {
          Text('发布站点')
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.TEXT_SECONDARY)
          Text(this.selectedSiteId.length > 0 ? this.selectedSiteId : '未选择站点')
            .fontSize(Typography.BODY)
            .fontColor(this.selectedSiteId.length > 0 ? ResourceColors.TEXT_PRIMARY : ResourceColors.TEXT_HINT)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(ComponentSize.ICON_SM)
          .fontColor([ResourceColors.ARROW])
      }
      .width('100%')
      .padding({ top: Spacing.SM, bottom: Spacing.SM })
      .onClick(() => {
        this.onSiteSelect(this.selectedSiteId)
      })

      // 发布按钮
      Button(this.isPublishing ? '发布中...' : '发布到 WordPress', { type: ButtonType.Capsule })
        .width('100%')
        .height(ComponentSize.BUTTON_HEIGHT)
        .backgroundColor(this.isPublishing ? ResourceColors.PRIMARY_DISABLED : ResourceColors.PRIMARY)
        .fontColor(ResourceColors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY_LARGE)
        .fontWeight(FontWeight.Medium)
        .enabled(!this.isPublishing && this.selectedSiteId.length > 0)
        .onClick(() => {
          this.onPublish()
        })
    }
    .width('100%')
    .padding(Spacing.BASE)
    .backgroundColor(ResourceColors.BG_CARD)
    .borderRadius(Radius.MD)
  }
}
