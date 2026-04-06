// 站点卡片组件 — 提取自 SitesPage.ets

import { Colors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'
import { WordPressSite } from '../../models/WordPressSite'

@Component
export struct SiteCardComponent {
  @Prop site: WordPressSite = new WordPressSite()
  isTesting: boolean = false
  onEdit: () => void = () => {}
  onDelete: () => void = () => {}
  onTest: () => void = () => {}

  build() {
    Column({ space: Spacing.MD }) {
      // 标题行: 站点名称 + 状态指示器
      Row() {
        Row({ space: Spacing.SM }) {
          SymbolGlyph($r('sys.symbol.link'))
            .fontSize(ComponentSize.ICON_MD)
            .fontColor([Colors.PRIMARY])
          Text(this.site.siteName)
            .fontSize(Typography.BODY_LARGE)
            .fontWeight(FontWeight.Medium)
            .fontColor(Colors.TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .layoutWeight(1)

        // 状态标签
        Row({ space: 4 }) {
          Circle({ width: 8, height: 8 })
            .fill(this.site.status === 'active' ? Colors.SUCCESS : Colors.TEXT_HINT)
          Text(this.site.status === 'active' ? '已连接' : '未连接')
            .fontSize(Typography.LABEL)
            .fontColor(this.site.status === 'active' ? Colors.SUCCESS : Colors.TEXT_HINT)
        }
        .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
        .borderRadius(Radius.FULL)
        .backgroundColor(this.site.status === 'active' ? '#E6F7F0' : Colors.BG_SECONDARY)
      }
      .width('100%')

      // 站点信息
      Column({ space: Spacing.SM }) {
        // 站点 URL
        Row({ space: Spacing.SM }) {
          SymbolGlyph($r('sys.symbol.link'))
            .fontSize(ComponentSize.ICON_SM)
            .fontColor([Colors.TEXT_HINT])
          Text(this.site.siteUrl)
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')

        // 用户名
        Row({ space: Spacing.SM }) {
          SymbolGlyph($r('sys.symbol.person_2'))
            .fontSize(ComponentSize.ICON_SM)
            .fontColor([Colors.TEXT_HINT])
          Text(this.site.username)
            .fontSize(Typography.CAPTION)
            .fontColor(Colors.TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
        }
        .width('100%')
      }

      // 操作按钮行: 测试连接 / 编辑 / 删除
      Row({ space: Spacing.SM }) {
        Button(this.isTesting ? '测试中...' : '测试连接', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.BODY)
          .fontColor(Colors.PRIMARY)
          .backgroundColor('transparent')
          .borderWidth(1)
          .borderColor(Colors.BORDER)
          .layoutWeight(1)
          .enabled(!this.isTesting)
          .onClick(() => {
            this.onTest()
          })

        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.square_and_pencil'))
            .fontSize(ComponentSize.ICON_SM)
            .fontColor([Colors.TEXT_SECONDARY])
        }
        .width(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .backgroundColor('transparent')
        .borderWidth(1)
        .borderColor(Colors.BORDER)
        .onClick(() => {
          this.onEdit()
        })

        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(ComponentSize.ICON_SM)
            .fontColor([Colors.ERROR])
        }
        .width(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .backgroundColor('transparent')
        .borderWidth(1)
        .borderColor(Colors.BORDER)
        .onClick(() => {
          this.onDelete()
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.BASE)
    .borderRadius(Radius.LG)
    .backgroundColor(Colors.BG_CARD)
  }
}
