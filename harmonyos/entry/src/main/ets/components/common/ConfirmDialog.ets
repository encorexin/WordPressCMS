// 确认对话框组件

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

@CustomDialog
export struct ConfirmDialog {
  controller?: CustomDialogController
  @Prop title: string = '确认'
  @Prop message: string = ''
  @Prop confirmText: string = '确认'
  @Prop cancelText: string = '取消'
  @Prop confirmFontColor: ResourceColor = ResourceColors.PRIMARY
  @Prop cancelFontColor: ResourceColor = ResourceColors.TEXT_PRIMARY
  onConfirm: () => void = () => {}
  onCancel: () => void = () => {}

  build() {
    Column({ space: Spacing.LG }) {
      // 标题
      Text(this.title)
        .fontSize(Typography.SUBTITLE)
        .fontColor(ResourceColors.TEXT_PRIMARY)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .width('100%')

      // 消息
      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
          .width('100%')
      }

      // 按钮行
      Row({ space: Spacing.MD }) {
        Button(this.cancelText)
          .type(ButtonType.Capsule)
          .layoutWeight(1)
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.BODY)
          .backgroundColor(ResourceColors.BG_SECONDARY)
          .fontColor(this.cancelFontColor)
          .onClick(() => {
            this.controller?.close()
            this.onCancel()
          })

        Button(this.confirmText)
          .type(ButtonType.Capsule)
          .layoutWeight(1)
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.BODY)
          .backgroundColor(ResourceColors.BG_SECONDARY)
          .fontColor(this.confirmFontColor)
          .onClick(() => {
            this.controller?.close()
            this.onConfirm()
          })
      }
      .width('100%')
    }
    .padding(Spacing.LG)
    .width('100%')
    .constraintSize({ minWidth: 280, maxWidth: 320 })
    .backgroundColor(ResourceColors.BG_CARD)
    .borderRadius(Radius.LG)
  }
}
