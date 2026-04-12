// AI 设置卡片组件

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'
import { AISettingsModel } from '../../models/AISettings'

@Reusable
@Component
export struct AISettingsCardComponent {
  @Prop settings: AISettingsModel = new AISettingsModel()
  @Prop isTesting: boolean = false
  onSetDefault: () => void = () => {}
  onEdit: () => void = () => {}
  onDelete: () => void = () => {}
  onTest: () => void = () => {}

  /**
   * @Reusable 组件复用时重置内部状态
   * 当前组件无 @State 内部状态，但保留此生命周期以防护后续新增状态时遗漏
   */
  aboutToReuse(): void {
    // 当前无内部 @State 需要重置，@Prop 由父组件同步
  }

  build() {
    Column({ space: Spacing.MD }) {
      Row() {
        Row({ space: Spacing.SM }) {
          Text(this.settings.name)
            .fontSize(Typography.BODY_LARGE)
            .fontWeight(FontWeight.Medium)
            .fontColor(ResourceColors.TEXT_PRIMARY)

          if (this.settings.isDefault) {
            Text('默认')
              .fontSize(Typography.LABEL)
              .fontColor(ResourceColors.TEXT_ON_PRIMARY)
              .backgroundColor(ResourceColors.PRIMARY)
              .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
              .borderRadius(Radius.FULL)
          }
        }
        .layoutWeight(1)
      }
      .width('100%')

      Column({ space: Spacing.XS }) {
        Text(this.settings.apiEndpoint)
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_HINT)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Row({ space: Spacing.SM }) {
        Text('模型：')
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_SECONDARY)
        Text(this.settings.model)
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')

      Row({ space: Spacing.SM }) {
        Text('已用 Token：')
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_SECONDARY)
        Text(`${this.settings.tokensUsed}`)
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_PRIMARY)
      }
      .width('100%')

      Row({ space: Spacing.SM }) {
        if (!this.settings.isDefault) {
          Button('设为默认', { type: ButtonType.Normal })
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.PRIMARY)
            .backgroundColor(Color.Transparent)
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .onClick(() => {
              this.onSetDefault()
            })
        }

        Button('编辑', { type: ButtonType.Normal })
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.PRIMARY)
          .backgroundColor(Color.Transparent)
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .onClick(() => {
            this.onEdit()
          })

        Button('删除', { type: ButtonType.Normal })
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.ERROR)
          .backgroundColor(Color.Transparent)
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .onClick(() => {
            this.onDelete()
          })

        Button(this.isTesting ? '测试中...' : '测试连接', { type: ButtonType.Normal })
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.SUCCESS)
          .backgroundColor(Color.Transparent)
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .enabled(!this.isTesting)
          .onClick(() => {
            this.onTest()
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.BASE)
    .borderRadius(Radius.LG)
    .backgroundColor(ResourceColors.BG_SECONDARY)
  }
}
