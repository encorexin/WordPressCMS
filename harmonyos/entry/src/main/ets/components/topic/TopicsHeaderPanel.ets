import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

@Component
export struct TopicsHeaderPanelComponent {
  @Link searchQuery: string
  @Prop unusedCount: number = 0
  @Prop usedCount: number = 0
  @Prop totalCount: number = 0
  onClearUsed: () => void = () => {}
  onOpenAdd: () => void = () => {}
  onOpenGenerate: () => void = () => {}

  build() {
    Column() {
      Row() {
        Column({ space: Spacing.XS }) {
          Text('主题库')
            .fontSize(Typography.TITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor(ResourceColors.PRIMARY)
          Text(`${this.unusedCount} 个待带入文章 / ${this.usedCount} 个已进入文章流程 / 共 ${this.totalCount} 个主题`)
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_SECONDARY)
            .maxLines(2)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row({ space: Spacing.SM }) {
          if (this.usedCount > 0) {
            Button('清除已用', { type: ButtonType.Capsule })
              .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
              .fontSize(Typography.BODY)
              .fontColor(ResourceColors.ERROR)
              .backgroundColor('transparent')
              .borderWidth(1)
              .borderColor(ResourceColors.BORDER)
              .onClick(() => {
                this.onClearUsed()
              })
          }

          Button('手动添加', { type: ButtonType.Capsule })
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.PRIMARY)
            .backgroundColor('transparent')
            .borderWidth(1)
            .borderColor(ResourceColors.BORDER)
            .onClick(() => {
              this.onOpenAdd()
            })

          Button('AI 生成', { type: ButtonType.Capsule })
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .backgroundColor(ResourceColors.PRIMARY)
            .fontColor(ResourceColors.TEXT_ON_PRIMARY)
            .fontSize(Typography.BODY)
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.onOpenGenerate()
            })
        }
      }
      .width('100%')
      .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.SM, bottom: Spacing.BASE })
      .alignItems(VerticalAlign.Bottom)

      Row() {
        TextInput({ placeholder: '搜索主题...', text: $$this.searchQuery })
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

      if (this.totalCount > 0) {
        Row() {
          Column({ space: Spacing.XS }) {
            Text(`待带入文章 ${this.unusedCount} · 已进入文章流程 ${this.usedCount}`)
              .fontSize(Typography.CAPTION)
              .fontWeight(FontWeight.Medium)
              .fontColor(ResourceColors.TEXT_PRIMARY)
              .width('100%')

            Text('主题沉淀的是文章方向；点击“写文章”会带入文章编辑器，进入过文章流程的主题可继续补写。')
              .fontSize(Typography.CAPTION)
              .fontColor(ResourceColors.TEXT_SECONDARY)
              .width('100%')
          }
          .width('100%')
          .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.MD, bottom: Spacing.MD })
          .borderRadius(Radius.MD)
          .backgroundColor(ResourceColors.BG_SECONDARY)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.SM })
      }
    }
    .width('100%')
  }
}
