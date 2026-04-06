// 状态徽章组件 — 展示文章/站点状态标签

import { Colors, Typography, Spacing, Radius } from '../../constants/DesignTokens'

@Component
export struct StatusBadge {
  @Prop status: string = 'draft'

  private getStatusInfo(): Record<string, string> {
    switch (this.status) {
      case 'published':
        return { label: '已发布', bgColor: '#E6F9EE', textColor: Colors.SUCCESS }
      case 'draft':
        return { label: '草稿', bgColor: '#FFF3E0', textColor: Colors.WARNING }
      case 'generating':
        return { label: '生成中', bgColor: '#E3F2FD', textColor: Colors.PRIMARY }
      case 'active':
        return { label: '正常', bgColor: '#E6F9EE', textColor: Colors.SUCCESS }
      case 'inactive':
        return { label: '停用', bgColor: '#F5F5F5', textColor: Colors.TEXT_HINT }
      case 'error':
        return { label: '异常', bgColor: '#FFEBEE', textColor: Colors.ERROR }
      default:
        return { label: this.status, bgColor: '#F5F5F5', textColor: Colors.TEXT_SECONDARY }
    }
  }

  build() {
    Text(this.getStatusInfo()['label'])
      .fontSize(Typography.CAPTION)
      .fontColor(this.getStatusInfo()['textColor'])
      .backgroundColor(this.getStatusInfo()['bgColor'])
      .padding({ left: Spacing.SM, right: Spacing.SM, top: 2, bottom: 2 })
      .borderRadius(Radius.SM)
  }
}
