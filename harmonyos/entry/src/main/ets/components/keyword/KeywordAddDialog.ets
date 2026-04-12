// 关键词添加弹窗组件

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

@Component
export struct KeywordAddDialogComponent {
  @Prop isVisible: boolean = false
  @Link formKeywords: string
  @Link formGroupName: string
  @Prop isSubmitting: boolean = false
  onClose: () => void = () => {}
  onSubmit: () => void = () => {}

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ResourceColors.OVERLAY_MASK)
        .onClick(() => {
          if (!this.isSubmitting) {
            this.onClose()
          }
        })

      Column({ space: Spacing.BASE }) {
        Row() {
          Text('添加关键词')
            .fontSize(Typography.SUBTITLE)
            .fontWeight(FontWeight.Medium)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .layoutWeight(1)

          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(ComponentSize.ICON_MD)
            .fontColor([ResourceColors.TEXT_HINT])
            .onClick(() => {
              if (!this.isSubmitting) {
                this.onClose()
              }
            })
        }
        .width('100%')

        Column({ space: Spacing.XS }) {
          Text('关键词')
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)

          TextArea({ placeholder: '输入关键词，多个用逗号或换行分隔', text: $$this.formKeywords })
            .height(100)
            .borderRadius(Radius.MD)
            .backgroundColor(ResourceColors.BG_SECONDARY)
            .padding({ left: Spacing.BASE, right: Spacing.BASE })
            .fontSize(Typography.BODY_LARGE)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .placeholderColor(ResourceColors.TEXT_HINT)
            .enabled(!this.isSubmitting)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: Spacing.XS }) {
          Text('分组名称（可选）')
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .fontWeight(FontWeight.Medium)

          TextInput({ placeholder: '默认：未分组', text: $$this.formGroupName })
            .height(ComponentSize.INPUT_HEIGHT)
            .borderRadius(Radius.MD)
            .backgroundColor(ResourceColors.BG_SECONDARY)
            .padding({ left: Spacing.BASE, right: Spacing.BASE })
            .fontSize(Typography.BODY_LARGE)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .placeholderColor(ResourceColors.TEXT_HINT)
            .enabled(!this.isSubmitting)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Row({ space: Spacing.MD }) {
          Button('取消', { type: ButtonType.Capsule })
            .layoutWeight(1)
            .height(ComponentSize.BUTTON_HEIGHT)
            .fontSize(Typography.BODY_LARGE)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .backgroundColor(ResourceColors.BG_SECONDARY)
            .enabled(!this.isSubmitting)
            .onClick(() => {
              this.onClose()
            })

          Button(this.isSubmitting ? '保存中...' : '保存', { type: ButtonType.Capsule })
            .layoutWeight(1)
            .height(ComponentSize.BUTTON_HEIGHT)
            .backgroundColor(ResourceColors.PRIMARY)
            .fontColor(ResourceColors.TEXT_ON_PRIMARY)
            .fontSize(Typography.BODY_LARGE)
            .fontWeight(FontWeight.Medium)
            .enabled(!this.isSubmitting)
            .onClick(() => {
              this.onSubmit()
            })
        }
        .width('100%')
        .margin({ top: Spacing.SM })
      }
      .width('100%')
      .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.LG, bottom: Spacing.XL })
      .borderRadius({ topLeft: Radius.XL, topRight: Radius.XL })
      .backgroundColor(ResourceColors.BG_PRIMARY)
      .position({ x: 0, y: '100%' })
      .translate({ y: this.isVisible ? '-100%' : '0' })
      .animation({ duration: 300, curve: Curve.EaseOut })
    }
    .width('100%')
    .height('100%')
  }
}
