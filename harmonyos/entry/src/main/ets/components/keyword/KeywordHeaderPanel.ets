// 关键词页面头部区域组件

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

@Component
export struct KeywordHeaderPanelComponent {
  @Link searchQuery: string
  @Prop unusedCount: number = 0
  @Prop usedCount: number = 0
  @Prop totalCount: number = 0
  @Prop groupCount: number = 0
  @Prop showSummary: boolean = false
  onOpenAdd: () => void = () => {}
  onOpenFetch: () => void = () => {}

  build() {
    Column() {
      Row() {
        Column({ space: Spacing.XS }) {
          Text('关键词库')
            .fontSize(Typography.TITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor(ResourceColors.PRIMARY)

          Text(`${this.unusedCount} 个待带入文章 / ${this.usedCount} 个已进入文章流程 / 共 ${this.totalCount} 个关键词`)
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_SECONDARY)
            .maxLines(2)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row({ space: Spacing.SM }) {
          Button('手动添加', { type: ButtonType.Capsule })
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .backgroundColor(ResourceColors.PRIMARY)
            .fontColor(ResourceColors.TEXT_ON_PRIMARY)
            .fontSize(Typography.BODY)
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.onOpenAdd()
            })

          Button('AI 获取', { type: ButtonType.Capsule })
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.PRIMARY)
            .backgroundColor('transparent')
            .borderWidth(1)
            .borderColor(ResourceColors.BORDER)
            .onClick(() => {
              this.onOpenFetch()
            })
        }
      }
      .width('100%')
      .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.SM, bottom: Spacing.BASE })
      .alignItems(VerticalAlign.Bottom)

      Row() {
        TextInput({ placeholder: '搜索关键词...', text: $$this.searchQuery })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .borderRadius(Radius.MD)
          .backgroundColor(ResourceColors.BG_SECONDARY)
          .padding({ left: Spacing.BASE, right: Spacing.BASE })
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .placeholderColor(ResourceColors.TEXT_HINT)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.SM })

      if (this.showSummary) {
        Column({ space: Spacing.XS }) {
          Text(`待带入文章 ${this.unusedCount} · 已进入文章流程 ${this.usedCount} · 分组 ${this.groupCount}`)
            .fontSize(Typography.CAPTION)
            .fontWeight(FontWeight.Medium)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .width('100%')

          Text('关键词会按分组沉淀，并保留带入文章编辑器的次数，方便围绕同一词簇持续补写文章。')
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.TEXT_SECONDARY)
            .width('100%')
        }
        .width('100%')
        .margin({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.SM })
        .padding(Spacing.MD)
        .borderRadius(Radius.MD)
        .backgroundColor(ResourceColors.BG_SECONDARY)
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
  }
}
