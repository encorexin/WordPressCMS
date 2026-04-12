import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'

export class ArticleStatusOption {
  value: string = ''
  label: string = ''
}

export class ArticleFiltersPanelState {
  statusOptions: ArticleStatusOption[] = []
  showSiteFilter: boolean = false
  siteOptions: SelectOption[] = []
  siteIds: string[] = []
  selectedSiteIndex: number = 0
  selectedSiteLabel: string = '全部站点'
  showBatchToolbar: boolean = false
  selectedCount: number = 0
  filteredCount: number = 0
  isAllSelected: boolean = false
  summaryText: string = ''
  showReset: boolean = false
}

@Component
export struct ArticlesFilterPanelComponent {
  @Link searchQuery: string
  @Link filterStatus: string
  @Link selectedSiteId: string
  @Prop state: ArticleFiltersPanelState = new ArticleFiltersPanelState()
  onReset: () => void = () => {}
  onToggleSelectAll: (value: boolean) => void = (_value: boolean) => {}
  onOpenBatchDelete: () => void = () => {}

  build() {
    Column() {
      this.buildFilterTabs()

      if (this.state.showSiteFilter) {
        this.buildSiteFilter()
      }

      if (this.state.showBatchToolbar) {
        this.buildBatchToolbar()
      }

      this.buildSearchBar()
      this.buildResultsSummary()
    }
    .width('100%')
  }

  @Builder
  private buildFilterTabs() {
    Row({ space: Spacing.SM }) {
      ForEach(this.state.statusOptions, (option: ArticleStatusOption) => {
        Button(option.label, { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.BODY)
          .fontColor(this.filterStatus === option.value ? ResourceColors.TEXT_ON_PRIMARY : ResourceColors.TEXT_PRIMARY)
          .backgroundColor(this.filterStatus === option.value ? ResourceColors.PRIMARY : ResourceColors.BG_SECONDARY)
          .padding({ left: Spacing.MD, right: Spacing.MD })
          .onClick(() => {
            this.filterStatus = option.value
          })
      }, (option: ArticleStatusOption) => option.value)
    }
    .width('100%')
    .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.BASE, bottom: Spacing.SM })
  }

  @Builder
  private buildSiteFilter() {
    Row({ space: Spacing.SM }) {
      Text('按站点筛选')
        .fontSize(Typography.BODY)
        .fontColor(ResourceColors.TEXT_SECONDARY)

      Select(this.state.siteOptions)
        .selected(this.state.selectedSiteIndex)
        .value(this.state.selectedSiteLabel)
        .font({ size: Typography.BODY, weight: FontWeight.Medium })
        .fontColor(ResourceColors.TEXT_PRIMARY)
        .backgroundColor(ResourceColors.BG_SECONDARY)
        .optionFont({ size: Typography.BODY })
        .optionBgColor(ResourceColors.BG_PRIMARY)
        .onSelect((index: number) => {
          if (index === 0) {
            this.selectedSiteId = ''
          } else {
            this.selectedSiteId = this.state.siteIds[index - 1]
          }
        })
        .layoutWeight(1)

      if (this.selectedSiteId.length > 0) {
        Button('清除', { type: ButtonType.Normal })
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.PRIMARY)
          .backgroundColor(Color.Transparent)
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .onClick(() => {
            this.selectedSiteId = ''
          })
      }
    }
    .width('100%')
    .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.SM })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private buildBatchToolbar() {
    Row({ space: Spacing.SM }) {
      Row({ space: Spacing.SM }) {
        Checkbox()
          .select(this.state.isAllSelected)
          .selectedColor(ResourceColors.PRIMARY)
          .onChange((value: boolean) => {
            this.onToggleSelectAll(value)
          })

        Text(`全选 (${this.state.selectedCount}/${this.state.filteredCount})`)
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.TEXT_PRIMARY)
      }
      .layoutWeight(1)

      Button('删除选中', { type: ButtonType.Capsule })
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .fontSize(Typography.BODY)
        .fontColor(ResourceColors.TEXT_ON_PRIMARY)
        .backgroundColor(ResourceColors.ERROR)
        .enabled(this.state.selectedCount > 0)
        .onClick(() => {
          this.onOpenBatchDelete()
        })
    }
    .width('100%')
    .padding(Spacing.BASE)
    .backgroundColor(ResourceColors.BG_SECONDARY)
    .borderRadius(Radius.MD)
    .margin({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.SM })
  }

  @Builder
  private buildSearchBar() {
    Row() {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(ComponentSize.ICON_MD)
        .fontColor([ResourceColors.TEXT_HINT])
        .margin({ left: Spacing.MD })

      TextInput({ placeholder: '搜索标题或关键词...', text: $$this.searchQuery })
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .backgroundColor(Color.Transparent)
        .padding({ left: Spacing.SM, right: Spacing.BASE })
        .fontSize(Typography.BODY)
        .fontColor(ResourceColors.TEXT_PRIMARY)
        .placeholderColor(ResourceColors.TEXT_HINT)
        .layoutWeight(1)

      if (this.searchQuery.length > 0) {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(ComponentSize.ICON_SM)
          .fontColor([ResourceColors.TEXT_HINT])
          .margin({ right: Spacing.MD })
          .onClick(() => {
            this.searchQuery = ''
          })
      }
    }
    .width('100%')
    .height(ComponentSize.INPUT_HEIGHT)
    .margin({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.BASE })
    .borderRadius(Radius.FULL)
    .backgroundColor(ResourceColors.BG_SECONDARY)
  }

  @Builder
  private buildResultsSummary() {
    Row({ space: Spacing.SM }) {
      Text(this.state.summaryText)
        .layoutWeight(1)
        .fontSize(Typography.CAPTION)
        .fontColor(ResourceColors.TEXT_SECONDARY)

      if (this.state.showReset) {
        Button('重置条件', { type: ButtonType.Normal })
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.PRIMARY)
          .backgroundColor(Color.Transparent)
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .onClick(() => {
            this.onReset()
          })
      }
    }
    .width('100%')
    .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.SM })
    .alignItems(VerticalAlign.Center)
  }
}
