// 主题条目卡片组件

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'
import { Topic } from '../../models/Topic'

@Reusable
@Component
export struct TopicItemCardComponent {
  @Prop topic: Topic = new Topic()
  @Prop stateLabel: string = ''
  @Prop stateHint: string = ''
  @Prop writeActionLabel: string = '写文章'
  onWrite: () => void = () => {}
  onMarkUsed: () => void = () => {}
  onDelete: () => void = () => {}

  /**
   * @Reusable 组件复用时重置内部状态
   * 当前组件无 @State 内部状态，但保留此生命周期以防护后续新增状态时遗漏
   */
  aboutToReuse(): void {
    // 当前无内部 @State 需要重置，@Prop 由父组件同步
  }

  build() {
    Column({ space: Spacing.SM }) {
      Row() {
        Text(this.topic.title)
          .fontSize(Typography.BODY_LARGE)
          .fontWeight(FontWeight.Medium)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Text(this.stateLabel)
          .fontSize(Typography.LABEL)
          .fontColor(this.topic.used ? ResourceColors.SUCCESS : ResourceColors.PRIMARY)
          .backgroundColor(this.topic.used ? ResourceColors.SUCCESS_SOFT_BG : ResourceColors.INFO_SOFT_BG)
          .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
          .borderRadius(Radius.FULL)
      }
      .width('100%')

      if (this.topic.description.length > 0) {
        Text(this.topic.description)
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_SECONDARY)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }

      Text(this.stateHint)
        .fontSize(Typography.CAPTION)
        .fontColor(ResourceColors.TEXT_SECONDARY)
        .width('100%')

      if (this.topic.keywords.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.topic.keywords.split(/[,，]/), (kw: string) => {
            if (kw.trim().length > 0) {
              Text(kw.trim())
                .fontSize(Typography.CAPTION)
                .fontColor(ResourceColors.PRIMARY)
                .backgroundColor(ResourceColors.INFO_SOFT_BG)
                .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
                .borderRadius(Radius.FULL)
                .margin({ right: Spacing.XS, bottom: Spacing.XS })
            }
          }, (kw: string, index: number) => `${this.topic.id}_kw_${index}`)
        }
        .width('100%')
      }

      Row({ space: Spacing.SM }) {
        Button(this.writeActionLabel, { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.TEXT_ON_PRIMARY)
          .backgroundColor(ResourceColors.PRIMARY)
          .onClick(() => {
            this.onWrite()
          })

        if (!this.topic.used) {
          Button('标记已进入流程', { type: ButtonType.Capsule })
            .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
            .fontSize(Typography.CAPTION)
            .fontColor(ResourceColors.PRIMARY)
            .backgroundColor('transparent')
            .borderWidth(1)
            .borderColor(ResourceColors.BORDER)
            .onClick(() => {
              this.onMarkUsed()
            })
        }

        Button('删除', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.ERROR)
          .backgroundColor('transparent')
          .borderWidth(1)
          .borderColor(ResourceColors.BORDER)
          .onClick(() => {
            this.onDelete()
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.MD)
    .borderRadius(Radius.MD)
    .backgroundColor(ResourceColors.BG_PRIMARY)
  }
}
