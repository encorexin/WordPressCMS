// 关键词分组删除确认弹窗组件

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

@Component
export struct KeywordGroupDeleteDialogComponent {
  @Prop groupName: string = ''
  @Prop isDeleting: boolean = false
  onClose: () => void = () => {}
  onConfirm: () => void = () => {}

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ResourceColors.OVERLAY_MASK)
        .onClick(() => {
          if (!this.isDeleting) {
            this.onClose()
          }
        })

      Column({ space: Spacing.BASE }) {
        Text('确认删除分组')
          .fontSize(Typography.SUBTITLE)
          .fontWeight(FontWeight.Medium)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .width('100%')

        Text(`确定删除分组「${this.groupName}」下的所有关键词吗？`)
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_SECONDARY)
          .width('100%')

        Text('此操作不可撤销，分组下的所有关键词将被永久删除。')
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.ERROR)
          .width('100%')

        Row({ space: Spacing.MD }) {
          Button('取消', { type: ButtonType.Capsule })
            .layoutWeight(1)
            .height(ComponentSize.BUTTON_HEIGHT)
            .fontSize(Typography.BODY_LARGE)
            .fontColor(ResourceColors.TEXT_PRIMARY)
            .backgroundColor(ResourceColors.BG_SECONDARY)
            .enabled(!this.isDeleting)
            .onClick(() => {
              this.onClose()
            })

          Button(this.isDeleting ? '删除中...' : '确认删除', { type: ButtonType.Capsule })
            .layoutWeight(1)
            .height(ComponentSize.BUTTON_HEIGHT)
            .backgroundColor(ResourceColors.ERROR)
            .fontColor(ResourceColors.TEXT_ON_PRIMARY)
            .fontSize(Typography.BODY_LARGE)
            .fontWeight(FontWeight.Medium)
            .enabled(!this.isDeleting)
            .onClick(() => {
              this.onConfirm()
            })
        }
        .width('100%')
        .margin({ top: Spacing.SM })
      }
      .width('90%')
      .constraintSize({ maxWidth: 400 })
      .padding(Spacing.LG)
      .borderRadius(Radius.LG)
      .backgroundColor(ResourceColors.BG_PRIMARY)
      .shadow({ radius: 10, color: ResourceColors.SHADOW_FLOATING, offsetX: 0, offsetY: 4 })
    }
    .width('100%')
    .height('100%')
  }
}
