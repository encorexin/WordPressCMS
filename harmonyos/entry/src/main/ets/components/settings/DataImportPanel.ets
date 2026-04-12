// 数据管理页面导入区组件

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

@Component
export struct DataImportPanelComponent {
  @Prop isBusy: boolean = false
  onImport: () => void = () => {}

  build() {
    Column({ space: Spacing.MD }) {
      Row({ space: Spacing.SM }) {
        SymbolGlyph($r('sys.symbol.folder'))
          .fontSize(ComponentSize.ICON_LG)
          .fontColor([ResourceColors.SUCCESS])

        Column({ space: Spacing.XS }) {
          Text('2. 从备份文件恢复数据')
            .fontSize(Typography.SUBTITLE)
            .fontWeight(FontWeight.Medium)
            .fontColor(ResourceColors.TEXT_PRIMARY)

          Text('从之前导出的 JSON 备份文件恢复内容')
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_SECONDARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      Text('点击“从备份文件恢复”后，会打开文件选择器让你选择备份文件。系统会自动检测是否加密，如果是加密文件需要解密。恢复前会显示备份内容摘要，确认后再执行恢复。')
        .fontSize(Typography.CAPTION)
        .fontColor(ResourceColors.TEXT_HINT)
        .width('100%')

      Button(this.isBusy ? '恢复中...' : '从备份文件恢复', { type: ButtonType.Capsule })
        .width('100%')
        .height(ComponentSize.BUTTON_HEIGHT)
        .backgroundColor(ResourceColors.SUCCESS)
        .fontColor(ResourceColors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY_LARGE)
        .fontWeight(FontWeight.Medium)
        .enabled(!this.isBusy)
        .onClick(() => {
          this.onImport()
        })
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(Radius.LG)
    .backgroundColor(ResourceColors.BG_SECONDARY)
  }
}
