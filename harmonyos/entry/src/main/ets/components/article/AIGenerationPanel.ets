// AI 生成面板组件 — 提取自 ArticleEditorPage.ets

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

@Component
export struct AIGenerationPanelComponent {
  @Prop isGenerating: boolean = false
  @Prop streamText: string = ''
  onStart: () => void = () => {}
  onStop: () => void = () => {}

  build() {
    Column({ space: Spacing.MD }) {
      // 标题
      Row({ space: Spacing.SM }) {
        Text('AI 生成')
          .fontSize(Typography.BODY_LARGE)
          .fontWeight(FontWeight.Medium)
          .fontColor(ResourceColors.TEXT_PRIMARY)
        Blank()
        if (this.isGenerating) {
          Row({ space: Spacing.XS }) {
            LoadingProgress()
              .width(14)
              .height(14)
              .color(ResourceColors.PRIMARY)
            Text('生成中...')
              .fontSize(Typography.CAPTION)
              .fontColor(ResourceColors.PRIMARY)
          }
        }
      }
      .width('100%')

      // 流式输出文本区域
      if (this.streamText.length > 0 || this.isGenerating) {
        Scroll() {
          Text(this.streamText.length > 0 ? this.streamText : '等待生成...')
            .fontSize(Typography.BODY)
            .fontColor(this.streamText.length > 0 ? ResourceColors.TEXT_PRIMARY : ResourceColors.TEXT_HINT)
            .fontFamily('monospace')
            .width('100%')
        }
        .width('100%')
        .constraintSize({ maxHeight: 200 })
        .scrollBar(BarState.Auto)
        .backgroundColor(ResourceColors.BG_SECONDARY)
        .borderRadius(Radius.MD)
        .padding(Spacing.BASE)
      }

      // 操作按钮
      if (this.isGenerating) {
        Button('停止生成')
          .type(ButtonType.Normal)
          .width('100%')
          .height(ComponentSize.BUTTON_HEIGHT)
          .fontSize(Typography.BODY_LARGE)
          .fontColor(ResourceColors.ERROR)
          .backgroundColor('transparent')
          .borderWidth(1)
          .borderColor(ResourceColors.ERROR)
          .borderRadius(Radius.SM)
          .onClick(() => {
            this.onStop()
          })
      } else {
        Button('AI 生成文章')
          .type(ButtonType.Normal)
          .width('100%')
          .height(ComponentSize.BUTTON_HEIGHT)
          .fontSize(Typography.BODY_LARGE)
          .fontColor(ResourceColors.TEXT_ON_PRIMARY)
          .backgroundColor(ResourceColors.PRIMARY)
          .borderRadius(Radius.SM)
          .onClick(() => {
            this.onStart()
          })
      }
    }
    .width('100%')
    .padding(Spacing.BASE)
    .backgroundColor(ResourceColors.BG_CARD)
    .borderRadius(Radius.MD)
  }
}
