// 状态徽章组件 — 展示文章/站点状态标签

import { ResourceColors, Typography, Spacing, Radius } from '../../constants/DesignTokens'

/** 状态信息模型，避免动态属性访问 */
interface StatusInfo {
  label: string
  bgColor: ResourceColor
  textColor: ResourceColor
}

@Component
export struct StatusBadge {
  @Prop status: string = 'draft'

  private getStatusInfo(): StatusInfo {
    switch (this.status) {
      case 'published':
        return { label: '已发布', bgColor: ResourceColors.SUCCESS_SOFT_BG, textColor: ResourceColors.SUCCESS }
      case 'draft':
        return { label: '草稿', bgColor: ResourceColors.BG_SECONDARY, textColor: ResourceColors.TEXT_SECONDARY }
      case 'generating':
        return { label: '生成中', bgColor: ResourceColors.INFO_SOFT_BG, textColor: ResourceColors.PRIMARY }
      case 'active':
        return { label: '正常', bgColor: ResourceColors.SUCCESS_SOFT_BG, textColor: ResourceColors.SUCCESS }
      case 'inactive':
        return { label: '停用', bgColor: ResourceColors.BG_SECONDARY, textColor: ResourceColors.TEXT_HINT }
      case 'error':
        return { label: '异常', bgColor: ResourceColors.INFO_SOFT_BG, textColor: ResourceColors.ERROR }
      default:
        return { label: this.status, bgColor: ResourceColors.BG_SECONDARY, textColor: ResourceColors.TEXT_SECONDARY }
    }
  }

  build() {
    const info: StatusInfo = this.getStatusInfo()
    Text(info.label)
      .fontSize(Typography.CAPTION)
      .fontColor(info.textColor)
      .backgroundColor(info.bgColor)
      .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
      .borderRadius(Radius.SM)
  }
}
