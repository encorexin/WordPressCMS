// 数据管理页面危险操作区组件

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

@Component
export struct DataDangerZonePanelComponent {
  @Prop isBusy: boolean = false
  onClear: () => void = () => {}

  build() {
    Column({ space: Spacing.MD }) {
      Row({ space: Spacing.SM }) {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(ComponentSize.ICON_LG)
          .fontColor([ResourceColors.ERROR])

        Column({ space: Spacing.XS }) {
          Text('3. 清除本地数据')
            .fontSize(Typography.SUBTITLE)
            .fontWeight(FontWeight.Medium)
            .fontColor(ResourceColors.ERROR)

          Text('仅在确认备份可用后执行，此操作不可恢复')
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_SECONDARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      Text('警告：此操作会永久删除当前账户在本机上的文章、文章版本、站点、模板、关键词、主题和 AI 设置。请先确认已完成备份且备份文件可用，此操作不可恢复。')
        .fontSize(Typography.CAPTION)
        .fontColor(ResourceColors.ERROR)
        .width('100%')

      Button('清除本地数据', { type: ButtonType.Capsule })
        .width('100%')
        .height(ComponentSize.BUTTON_HEIGHT)
        .backgroundColor(ResourceColors.ERROR)
        .fontColor(ResourceColors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY_LARGE)
        .fontWeight(FontWeight.Medium)
        .enabled(!this.isBusy)
        .onClick(() => {
          this.onClear()
        })
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(Radius.LG)
    .backgroundColor(ResourceColors.BG_SECONDARY)
  }
}
