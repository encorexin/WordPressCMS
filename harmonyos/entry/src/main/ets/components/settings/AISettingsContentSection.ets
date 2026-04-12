// AI 设置页面内容区域组件

import { ResourceColors, Typography, Spacing, ComponentSize } from '../../constants/DesignTokens'
import { AISettingsModel } from '../../models/AISettings'
import { BasicDataSource, calcCachedCount } from '../../utils/BasicDataSource'
import { AISettingsCardComponent } from '../common/AISettingsCard'

@Component
export struct AISettingsContentSectionComponent {
  @Prop isLoading: boolean = true
  @Prop isTesting: boolean = false
  dataSource: BasicDataSource<AISettingsModel> = new BasicDataSource<AISettingsModel>([])
  onOpenAdd: () => void = () => {}
  onSetDefault: (settings: AISettingsModel) => void = (_settings: AISettingsModel) => {}
  onEdit: (settings: AISettingsModel) => void = (_settings: AISettingsModel) => {}
  onDelete: (settings: AISettingsModel) => void = (_settings: AISettingsModel) => {}
  onTest: (settings: AISettingsModel) => void = (_settings: AISettingsModel) => {}

  @Builder
  private buildLoadingView(): void {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color(ResourceColors.PRIMARY)

      Text('加载中...')
        .fontSize(Typography.BODY)
        .fontColor(ResourceColors.TEXT_HINT)
        .margin({ top: Spacing.SM })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private buildEmptyView(): void {
    Column({ space: Spacing.BASE }) {
      SymbolGlyph($r('sys.symbol.gearshape'))
        .fontSize(64)
        .fontColor([ResourceColors.TEXT_HINT])
        .opacity(0.5)

      Text('暂无 AI 配置')
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(ResourceColors.TEXT_PRIMARY)

      Text('添加 AI 配置以开始使用智能功能')
        .fontSize(Typography.BODY)
        .fontColor(ResourceColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)

      Button('添加配置', { type: ButtonType.Capsule })
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .backgroundColor(ResourceColors.PRIMARY)
        .fontColor(ResourceColors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY)
        .fontWeight(FontWeight.Medium)
        .margin({ top: Spacing.SM })
        .onClick(() => {
          this.onOpenAdd()
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(Spacing.XL)
  }

  @Builder
  private buildSettingsList(): void {
    List({ space: Spacing.MD }) {
      LazyForEach(this.dataSource, (settings: AISettingsModel) => {
        ListItem() {
          AISettingsCardComponent({
            settings,
            isTesting: this.isTesting,
            onSetDefault: () => {
              this.onSetDefault(settings)
            },
            onEdit: () => {
              this.onEdit(settings)
            },
            onDelete: () => {
              this.onDelete(settings)
            },
            onTest: () => {
              this.onTest(settings)
            }
          })
        }
      }, (settings: AISettingsModel) => settings.id)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.XL })
    .cachedCount(calcCachedCount(7))
  }

  build() {
    if (this.isLoading) {
      this.buildLoadingView()
    } else if (this.dataSource.totalCount() === 0) {
      this.buildEmptyView()
    } else {
      this.buildSettingsList()
    }
  }
}
