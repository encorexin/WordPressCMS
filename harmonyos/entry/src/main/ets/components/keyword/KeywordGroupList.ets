// 关键词分组列表组件

import { ResourceColors, Typography, Spacing, Radius, ComponentSize } from '../../constants/DesignTokens'
import { Keyword } from '../../models/Keyword'
import { BasicDataSource, calcCachedCount } from '../../utils/BasicDataSource'
import { KeywordItemCardComponent } from './KeywordItemCard'

export class KeywordGroupViewModel {
  groupName: string = ''
  keywords: Keyword[] = []
  usedCount: number = 0
  useTotal: number = 0
}

@Component
export struct KeywordGroupListComponent {
  dataSource: BasicDataSource<KeywordGroupViewModel> = new BasicDataSource<KeywordGroupViewModel>([])
  onDeleteGroup: (groupName: string) => void = (_groupName: string) => {}
  onWrite: (keyword: Keyword) => void = (_keyword: Keyword) => {}
  onDeleteKeyword: (keyword: Keyword) => void = (_keyword: Keyword) => {}

  private getKeywordStateLabel(keyword: Keyword): string {
    return keyword.useCount > 0 ? '已进入文章流程' : '待带入文章'
  }

  private getKeywordStateHint(keyword: Keyword): string {
    return keyword.useCount > 0
      ? `已带入文章编辑器 ${keyword.useCount} 次，可继续围绕这个关键词补写文章。`
      : '点击"写文章"即可把这个关键词带入文章编辑器，开始新的文章草稿。'
  }

  private getWriteActionLabel(keyword: Keyword): string {
    return keyword.useCount > 0 ? '继续写文章' : '写文章'
  }

  @Builder
  private buildGroupCard(groupItem: KeywordGroupViewModel): void {
    Column({ space: Spacing.MD }) {
      Row() {
        Row({ space: Spacing.SM }) {
          Text(groupItem.groupName)
            .fontSize(Typography.BODY_LARGE)
            .fontWeight(FontWeight.Medium)
            .fontColor(ResourceColors.TEXT_PRIMARY)

          Text(`${groupItem.keywords.length}`)
            .fontSize(Typography.LABEL)
            .fontColor(ResourceColors.TEXT_ON_PRIMARY)
            .backgroundColor(ResourceColors.PRIMARY)
            .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
            .borderRadius(Radius.FULL)
        }
        .layoutWeight(1)

        Button('删除分组', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .fontSize(Typography.CAPTION)
          .fontColor(ResourceColors.ERROR)
          .backgroundColor(Color.Transparent)
          .borderWidth(1)
          .borderColor(ResourceColors.ERROR)
          .onClick(() => {
            this.onDeleteGroup(groupItem.groupName)
          })
      }
      .width('100%')

      Text(groupItem.usedCount > 0
        ? `${groupItem.usedCount} 个关键词已进入文章流程 · 累计带入编辑器 ${groupItem.useTotal} 次`
        : '这组关键词还未进入文章流程，可直接从任一关键词开始写文章')
        .fontSize(Typography.CAPTION)
        .fontColor(ResourceColors.TEXT_SECONDARY)
        .width('100%')

      Column({ space: Spacing.SM }) {
        ForEach(groupItem.keywords, (keyword: Keyword) => {
          KeywordItemCardComponent({
            keyword,
            stateLabel: this.getKeywordStateLabel(keyword),
            stateHint: this.getKeywordStateHint(keyword),
            writeActionLabel: this.getWriteActionLabel(keyword),
            onWrite: () => {
              this.onWrite(keyword)
            },
            onDelete: () => {
              this.onDeleteKeyword(keyword)
            }
          })
        }, (keyword: Keyword) => keyword.id)
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.BASE)
    .borderRadius(Radius.LG)
    .backgroundColor(ResourceColors.BG_SECONDARY)
  }

  build() {
    List({ space: Spacing.MD }) {
      LazyForEach(this.dataSource, (groupItem: KeywordGroupViewModel) => {
        ListItem() {
          this.buildGroupCard(groupItem)
        }
      }, (groupItem: KeywordGroupViewModel) => groupItem.groupName)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.XL })
    .cachedCount(calcCachedCount(12))
  }
}
