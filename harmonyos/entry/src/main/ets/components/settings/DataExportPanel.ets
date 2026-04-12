// 数据管理页面导出区组件

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

export class DataExportAction {
  static readonly FULL_BACKUP: string = 'fullBackup'
  static readonly ARTICLES_JSON: string = 'articlesJson'
  static readonly ARTICLES_MARKDOWN: string = 'articlesMarkdown'
  static readonly TOPICS_JSON: string = 'topicsJson'
  static readonly TOPICS_TEXT: string = 'topicsText'
  static readonly KEYWORDS_JSON: string = 'keywordsJson'
  static readonly KEYWORDS_TEXT: string = 'keywordsText'
  static readonly TEMPLATES_JSON: string = 'templatesJson'
  static readonly AI_SETTINGS_SAFE: string = 'aiSettingsSafe'
  static readonly AI_SETTINGS_FULL: string = 'aiSettingsFull'
}

@Component
export struct DataExportPanelComponent {
  @Link encryptExport: boolean
  @Prop isBusy: boolean = false
  onExportAction: (action: string) => void = (_action: string) => {}

  build() {
    Column({ space: Spacing.MD }) {
      Row({ space: Spacing.SM }) {
        SymbolGlyph($r('sys.symbol.square_and_arrow_down'))
          .fontSize(ComponentSize.ICON_LG)
          .fontColor([ResourceColors.PRIMARY])

        Column({ space: Spacing.XS }) {
          Text('1. 备份并导出数据')
            .fontSize(Typography.SUBTITLE)
            .fontWeight(FontWeight.Medium)
            .fontColor(ResourceColors.TEXT_PRIMARY)

          Text('生成当前数据快照，导出到文件后可随时恢复')
            .fontSize(Typography.BODY)
            .fontColor(ResourceColors.TEXT_SECONDARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      Text('会将当前账号下的文章、文章版本、站点、模板、关键词、主题、AI 设置导出为 JSON 备份文件。可选择加密导出保护敏感信息。')
        .fontSize(Typography.CAPTION)
        .fontColor(ResourceColors.TEXT_HINT)
        .width('100%')

      Row({ space: Spacing.SM }) {
        SymbolGlyph($r('sys.symbol.lock'))
          .fontSize(ComponentSize.ICON_MD)
          .fontColor([ResourceColors.PRIMARY])

        Text('加密导出')
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_PRIMARY)
          .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.encryptExport })
          .selectedColor(ResourceColors.PRIMARY)
          .onChange((isOn: boolean) => {
            this.encryptExport = isOn
          })
      }
      .width('100%')
      .padding(Spacing.MD)
      .borderRadius(Radius.MD)
      .backgroundColor(ResourceColors.BG_PRIMARY)

      Button(this.isBusy ? '导出中...' : (this.encryptExport ? '导出加密完整备份' : '导出完整备份 (JSON)'), {
        type: ButtonType.Capsule
      })
        .width('100%')
        .height(ComponentSize.BUTTON_HEIGHT)
        .backgroundColor(ResourceColors.PRIMARY)
        .fontColor(ResourceColors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY_LARGE)
        .fontWeight(FontWeight.Medium)
        .enabled(!this.isBusy)
        .onClick(() => {
          this.onExportAction(DataExportAction.FULL_BACKUP)
        })

      Text('分类导出')
        .fontSize(Typography.BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor(ResourceColors.TEXT_PRIMARY)
        .width('100%')
        .margin({ top: Spacing.SM })

      Column({ space: Spacing.SM }) {
        Row({ space: Spacing.SM }) {
          this.buildExportMenuButton('导出文章', [
            { value: 'JSON 格式', action: () => this.onExportAction(DataExportAction.ARTICLES_JSON) },
            { value: 'Markdown 格式', action: () => this.onExportAction(DataExportAction.ARTICLES_MARKDOWN) }
          ])

          this.buildExportMenuButton('导出主题', [
            { value: 'JSON 格式', action: () => this.onExportAction(DataExportAction.TOPICS_JSON) },
            { value: '文本格式', action: () => this.onExportAction(DataExportAction.TOPICS_TEXT) }
          ])
        }
        .width('100%')

        Row({ space: Spacing.SM }) {
          this.buildExportMenuButton('导出关键词', [
            { value: 'JSON 格式', action: () => this.onExportAction(DataExportAction.KEYWORDS_JSON) },
            { value: '文本格式', action: () => this.onExportAction(DataExportAction.KEYWORDS_TEXT) }
          ])

          this.buildExportMenuButton('导出模板', [
            { value: 'JSON 格式', action: () => this.onExportAction(DataExportAction.TEMPLATES_JSON) }
          ])
        }
        .width('100%')

        Row({ space: Spacing.SM }) {
          this.buildExportMenuButton('导出 AI 设置', [
            { value: '安全导出（隐藏 Key）', action: () => this.onExportAction(DataExportAction.AI_SETTINGS_SAFE) },
            { value: '完整导出（含 Key）', action: () => this.onExportAction(DataExportAction.AI_SETTINGS_FULL) }
          ])
        }
        .width('100%')
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.LG)
    .borderRadius(Radius.LG)
    .backgroundColor(ResourceColors.BG_SECONDARY)
  }

  @Builder
  private buildExportMenuButton(label: string, items: MenuElement[]): void {
    Button(label, { type: ButtonType.Normal })
      .width('50%')
      .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
      .backgroundColor(ResourceColors.BG_PRIMARY)
      .fontColor(ResourceColors.TEXT_PRIMARY)
      .fontSize(Typography.BODY)
      .border({ width: 1, color: ResourceColors.TEXT_HINT, radius: Radius.MD })
      .enabled(!this.isBusy)
      .bindMenu(items)
  }
}
