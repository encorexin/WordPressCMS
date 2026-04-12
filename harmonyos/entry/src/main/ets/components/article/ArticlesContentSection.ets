import { ResourceColors, Typography, Spacing, ComponentSize } from '../../constants/DesignTokens'
import { Article } from '../../models/Article'
import { BasicDataSource, calcCachedCount } from '../../utils/BasicDataSource'
import { ArticleListItemCardComponent } from './ArticleListItemCard'

export class ArticleListItemViewModel {
  article: Article = new Article()
  siteName: string = ''
  isSelected: boolean = false
}

export class ArticleContentSectionState {
  isLoading: boolean = true
  hasArticles: boolean = false
  hasResults: boolean = false
  batchMode: boolean = false
  noResultsTitle: string = ''
  noResultsDescription: string = ''
}

@Component
export struct ArticlesContentSectionComponent {
  @Prop state: ArticleContentSectionState = new ArticleContentSectionState()
  dataSource: BasicDataSource<ArticleListItemViewModel> = new BasicDataSource<ArticleListItemViewModel>([])
  onCreate: () => void = () => {}
  onReset: () => void = () => {}
  onOpen: (articleId: string) => void = (_articleId: string) => {}
  onPreview: (article: Article) => void = (_article: Article) => {}
  onDelete: (article: Article) => void = (_article: Article) => {}
  onToggleSelection: (articleId: string) => void = (_articleId: string) => {}

  build() {
    if (this.state.isLoading) {
      this.buildLoadingView()
    } else if (!this.state.hasArticles) {
      this.buildEmptyView()
    } else if (!this.state.hasResults) {
      this.buildNoResultsView()
    } else {
      this.buildArticleList()
    }
  }

  @Builder
  private buildLoadingView() {
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
  private buildEmptyView() {
    Column({ space: Spacing.BASE }) {
      SymbolGlyph($r('sys.symbol.doc_filled_on_doc'))
        .fontSize(64)
        .fontColor([ResourceColors.TEXT_HINT])
        .opacity(0.5)

      Text('暂无文章')
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(ResourceColors.TEXT_PRIMARY)

      Text('可直接新建文章，也可以从主题或关键词带入文章草稿；进入后的内容会在这里继续管理')
        .fontSize(Typography.BODY)
        .fontColor(ResourceColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)

      Button('新建文章', { type: ButtonType.Capsule })
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .backgroundColor(ResourceColors.PRIMARY)
        .fontColor(ResourceColors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY)
        .fontWeight(FontWeight.Medium)
        .margin({ top: Spacing.SM })
        .onClick(() => {
          this.onCreate()
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(Spacing.XL)
  }

  @Builder
  private buildNoResultsView() {
    Column({ space: Spacing.BASE }) {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(64)
        .fontColor([ResourceColors.TEXT_HINT])
        .opacity(0.5)

      Text(this.state.noResultsTitle)
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(ResourceColors.TEXT_PRIMARY)

      Text(this.state.noResultsDescription)
        .fontSize(Typography.BODY)
        .fontColor(ResourceColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)

      Button('查看全部文章', { type: ButtonType.Capsule })
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .fontColor(ResourceColors.PRIMARY)
        .backgroundColor('transparent')
        .borderWidth(1)
        .borderColor(ResourceColors.BORDER)
        .fontSize(Typography.BODY)
        .margin({ top: Spacing.SM })
        .onClick(() => {
          this.onReset()
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(Spacing.XL)
  }

  @Builder
  private buildArticleList() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      List({ space: Spacing.MD }) {
        LazyForEach(this.dataSource, (item: ArticleListItemViewModel) => {
          ListItem() {
            ArticleListItemCardComponent({
              article: item.article,
              batchMode: this.state.batchMode,
              isSelected: item.isSelected,
              siteName: item.siteName,
              onToggleSelection: () => {
                this.onToggleSelection(item.article.id)
              },
              onOpen: () => {
                this.onOpen(item.article.id)
              },
              onPreview: () => {
                this.onPreview(item.article)
              },
              onDelete: () => {
                this.onDelete(item.article)
              }
            })
          }
        }, (item: ArticleListItemViewModel) => item.article.id)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .width('100%')
      .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.SM, bottom: 100 })
      .cachedCount(calcCachedCount(10))

      if (!this.state.batchMode) {
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.square_and_pencil'))
            .fontSize(ComponentSize.ICON_MD)
            .fontColor([ResourceColors.TEXT_ON_PRIMARY])
        }
        .width(ComponentSize.BUTTON_HEIGHT)
        .height(ComponentSize.BUTTON_HEIGHT)
        .backgroundColor(ResourceColors.PRIMARY)
        .shadow({ radius: 10, color: ResourceColors.SHADOW_FLOATING, offsetX: 0, offsetY: 4 })
        .margin({ right: Spacing.BASE, bottom: Spacing.BASE })
        .onClick(() => {
          this.onCreate()
        })
      }
    }
    .width('100%')
    .layoutWeight(1)
  }
}
