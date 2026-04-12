import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'
import { Topic } from '../../models/Topic'
import { BasicDataSource, calcCachedCount } from '../../utils/BasicDataSource'
import { TopicItemCardComponent } from './TopicItemCard'

export class TopicGroupViewModel {
  category: string = ''
  topics: Topic[] = []
}

@Component
export struct TopicGroupListComponent {
  @Prop isLoading: boolean = false
  @Prop totalCount: number = 0
  dataSource: BasicDataSource<TopicGroupViewModel> = new BasicDataSource<TopicGroupViewModel>([])
  onOpenAdd: () => void = () => {}
  onOpenGenerate: () => void = () => {}
  onWriteTopic: (topic: Topic) => void = (_topic: Topic) => {}
  onMarkUsed: (topic: Topic) => void = (_topic: Topic) => {}
  onDeleteTopic: (topic: Topic) => void = (_topic: Topic) => {}

  build() {
    if (this.isLoading) {
      this.buildLoadingView()
    } else if (this.totalCount === 0) {
      this.buildEmptyView()
    } else {
      this.buildGroupList()
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
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(64)
        .fontColor([ResourceColors.TEXT_HINT])
        .opacity(0.5)

      Text('暂无主题')
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(ResourceColors.TEXT_PRIMARY)

      Text('添加主题来沉淀文章方向，后续可带入文章编辑器继续写作')
        .fontSize(Typography.BODY)
        .fontColor(ResourceColors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)

      Row({ space: Spacing.MD }) {
        Button('手动添加', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.BODY)
          .fontColor(ResourceColors.PRIMARY)
          .backgroundColor('transparent')
          .borderWidth(1)
          .borderColor(ResourceColors.BORDER)
          .onClick(() => {
            this.onOpenAdd()
          })

        Button('AI 生成', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .backgroundColor(ResourceColors.PRIMARY)
          .fontColor(ResourceColors.TEXT_ON_PRIMARY)
          .fontSize(Typography.BODY)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.onOpenGenerate()
          })
      }
      .margin({ top: Spacing.SM })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(Spacing.XL)
  }

  @Builder
  private buildGroupList() {
    List({ space: Spacing.MD }) {
      LazyForEach(this.dataSource, (groupItem: TopicGroupViewModel) => {
        ListItem() {
          this.buildGroupCard(groupItem.category, groupItem.topics)
        }
      }, (groupItem: TopicGroupViewModel) => groupItem.category)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.XL })
    .cachedCount(calcCachedCount(12))
  }

  @Builder
  private buildGroupCard(category: string, topics: Topic[]) {
    Column({ space: Spacing.MD }) {
      Row() {
        Row({ space: Spacing.SM }) {
          Text(category)
            .fontSize(Typography.BODY_LARGE)
            .fontWeight(FontWeight.Medium)
            .fontColor(ResourceColors.TEXT_PRIMARY)
          Text(`${topics.length}`)
            .fontSize(Typography.LABEL)
            .fontColor(ResourceColors.TEXT_ON_PRIMARY)
            .backgroundColor(ResourceColors.PRIMARY)
            .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
            .borderRadius(Radius.FULL)
        }
        .layoutWeight(1)
      }
      .width('100%')

      Column({ space: Spacing.SM }) {
        ForEach(topics, (topic: Topic) => {
          TopicItemCardComponent({
            topic: topic,
            stateLabel: this.getTopicStateLabel(topic),
            stateHint: this.getTopicStateHint(topic),
            writeActionLabel: this.getWriteActionLabel(topic),
            onWrite: () => {
              this.onWriteTopic(topic)
            },
            onMarkUsed: () => {
              this.onMarkUsed(topic)
            },
            onDelete: () => {
              this.onDeleteTopic(topic)
            }
          })
        }, (topic: Topic) => topic.id)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.BASE)
    .borderRadius(Radius.LG)
    .backgroundColor(ResourceColors.BG_SECONDARY)
  }

  private getTopicStateLabel(topic: Topic): string {
    return topic.used ? '已进入文章流程' : '待带入文章'
  }

  private getTopicStateHint(topic: Topic): string {
    return topic.used
      ? '这个主题已带入文章编辑器，可继续打开编辑器补写或调整内容。'
      : '点击“写文章”会把主题带入文章编辑器，并自动标记为已进入文章流程。'
  }

  private getWriteActionLabel(topic: Topic): string {
    return topic.used ? '继续写文章' : '写文章'
  }
}
