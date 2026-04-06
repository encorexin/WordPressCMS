// 模板管理页面 — 文章生成模板 CRUD

import { Colors, Typography, Spacing, Radius, ComponentSize } from '../constants/DesignTokens'
import { ArticleTemplate } from '../models/ArticleTemplate'
import { TemplateDao } from '../services/db/TemplateDao'
import { TemplateCardComponent } from '../components/template/TemplateCard'
import { TemplateFormDialogComponent } from '../components/template/TemplateFormDialog'
import { Logger } from '../utils/Logger'
import { UiFeedback } from '../utils/UiFeedback'

// 默认模板定义
class DefaultTemplate {
  name: string = ''
  description: string = ''
  systemPrompt: string = ''
}

const DEFAULT_TEMPLATES: DefaultTemplate[] = [
  {
    name: '技术教程',
    description: '适用于技术文章、编程教程等',
    systemPrompt: `你是一位经验丰富的技术作者，擅长撰写清晰易懂的技术教程。

请根据用户提供的关键词创作一篇技术教程文章：

要求：
1. 使用通俗易懂的语言解释技术概念
2. 包含代码示例（如适用）
3. 分步骤讲解，循序渐进
4. 提供实践建议和注意事项
5. 使用 Markdown 格式，代码块需标注语言
6. 字数 1000-1500 字`,
  },
  {
    name: '产品评测',
    description: '适用于产品介绍、评测类文章',
    systemPrompt: `你是一位专业的产品评测作者，擅长客观分析产品优缺点。

请根据用户提供的关键词创作一篇产品评测文章：

要求：
1. 客观公正地分析产品特点
2. 从多个维度评价（功能、性能、价格、用户体验等）
3. 列出产品优点和缺点
4. 与同类产品进行对比（如适用）
5. 给出购买建议
6. 使用 Markdown 格式
7. 字数 800-1200 字`,
  },
  {
    name: 'SEO 文章',
    description: '适用于搜索引擎优化的内容',
    systemPrompt: `你是一位 SEO 内容专家，擅长撰写对搜索引擎友好的文章。

请根据用户提供的关键词创作一篇 SEO 优化文章：

要求：
1. 关键词自然融入标题和正文
2. 使用清晰的标题层级（H1、H2、H3）
3. 开头段落包含核心关键词
4. 每个段落聚焦一个主题
5. 适当使用列表和表格
6. 结尾包含 CTA（行动号召）
7. 使用 Markdown 格式
8. 字数 1000-1500 字`,
  },
  {
    name: '新闻稿',
    description: '适用于新闻报道、公告类文章',
    systemPrompt: `你是一位专业的新闻编辑，擅长撰写客观准确的新闻稿。

请根据用户提供的关键词创作一篇新闻稿：

要求：
1. 遵循新闻写作规范（倒金字塔结构）
2. 开头概括核心内容（5W1H）
3. 语言客观、准确、简洁
4. 引用相关数据和事实
5. 保持中立立场
6. 使用 Markdown 格式
7. 字数 500-800 字`,
  },
  {
    name: '博客文章',
    description: '适用于个人博客、生活分享',
    systemPrompt: `你是一位有亲和力的博客作者，擅长用轻松的语气分享见解。

请根据用户提供的关键词创作一篇博客文章：

要求：
1. 语气亲切、自然，像与朋友对话
2. 融入个人观点和感受
3. 使用生动的比喻和例子
4. 段落简短，易于阅读
5. 可以适当使用表情符号
6. 使用 Markdown 格式
7. 字数 800-1200 字`,
  },
  {
    name: '操作指南',
    description: '适用于步骤教程、使用说明',
    systemPrompt: `你是一位技术文档专家，擅长撰写清晰的操作指南。

请根据用户提供的关键词创作一篇操作指南：

要求：
1. 使用编号列表，步骤清晰
2. 每个步骤独立、具体、可执行
3. 包含必要的前置条件和注意事项
4. 适当配合说明性文字
5. 使用 Markdown 格式
6. 字数 600-1000 字`,
  },
]

@Component
export struct TemplatesPageContent {
  @Consume('navPathStack') navPathStack: NavPathStack
  @StorageProp('currentUserId') currentUserId: string = ''

  @State templates: ArticleTemplate[] = []
  @State isLoading: boolean = true
  @State showFormDialog: boolean = false
  @State editingTemplate: ArticleTemplate | null = null

  aboutToAppear(): void {
    this.loadTemplates()
  }

  // 初始化默认模板（带去重检查）
  private async initDefaultTemplates(): Promise<void> {
    if (this.currentUserId.length === 0) {
      return
    }
    try {
      // 先清理重复模板
      await this.cleanDuplicateTemplates()
      // 获取现有模板名称集合
      const existingTemplates = await TemplateDao.findByUserId(this.currentUserId)
      const existingNames: Set<string> = new Set()
      for (const t of existingTemplates) {
        existingNames.add(t.name)
      }
      // 只添加不存在的默认模板
      let addedCount = 0
      for (const template of DEFAULT_TEMPLATES) {
        if (!existingNames.has(template.name)) {
          await TemplateDao.insert(
            this.currentUserId,
            template.name,
            template.description,
            template.systemPrompt
          )
          addedCount++
        }
      }
      if (addedCount > 0) {
        UiFeedback.showToast({ message: `已添加 ${addedCount} 个默认模板`, duration: 2000 })
      }
    } catch (err) {
      Logger.error('Init default templates failed: %{public}s', String(err))
    }
  }

  // 清理重复模板（保留最新的）
  private async cleanDuplicateTemplates(): Promise<number> {
    try {
      const templates = await TemplateDao.findByUserId(this.currentUserId)
      const seen: Map<string, string> = new Map() // name -> id (保留最新的)
      const toDelete: string[] = []
      for (const template of templates) {
        if (seen.has(template.name)) {
          const oldId = seen.get(template.name)
          if (oldId !== undefined) {
            toDelete.push(oldId)
          }
        }
        seen.set(template.name, template.id)
      }
      for (const id of toDelete) {
        await TemplateDao.deleteById(id)
      }
      return toDelete.length
    } catch (err) {
      Logger.error('Clean duplicate templates failed: %{public}s', String(err))
      return 0
    }
  }

  // 重置默认模板
  private async resetDefaultTemplates(): Promise<void> {
    UiFeedback.showConfirm({
      title: '重置默认模板',
      message: '这将重新创建所有默认模板（不会删除已有模板），确定继续吗？',
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '重置',
        fontColor: Colors.PRIMARY,
        action: () => {
          this.doResetDefaultTemplates()
        }
      }
    })
  }

  private async doResetDefaultTemplates(): Promise<void> {
    try {
      // 获取现有模板名称集合
      const existingTemplates = await TemplateDao.findByUserId(this.currentUserId)
      const existingNames: Set<string> = new Set()
      for (const t of existingTemplates) {
        existingNames.add(t.name)
      }
      // 添加不存在的默认模板
      let addedCount = 0
      for (const template of DEFAULT_TEMPLATES) {
        if (!existingNames.has(template.name)) {
          await TemplateDao.insert(
            this.currentUserId,
            template.name,
            template.description,
            template.systemPrompt
          )
          addedCount++
        }
      }
      await this.loadTemplates()
      if (addedCount > 0) {
        UiFeedback.showToast({ message: `已重置 ${addedCount} 个默认模板`, duration: 2000 })
      } else {
        UiFeedback.showToast({ message: '所有默认模板已存在', duration: 2000 })
      }
    } catch (err) {
      Logger.error('Reset default templates failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '重置失败' })
    }
  }

  // ========== 构建 UI ==========

  build() {
    NavDestination() {
      Stack() {
        Column() {
          // 顶部工具栏
          this.ToolbarArea()

          // 内容区
          if (this.isLoading) {
            this.LoadingView()
          } else if (this.templates.length === 0) {
            this.EmptyView()
          } else {
            this.TemplatesList()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(Colors.BG_PRIMARY)

        // 表单对话框
        if (this.showFormDialog) {
          TemplateFormDialogComponent({
            show: this.showFormDialog,
            editingTemplate: this.editingTemplate,
            onSave: (name: string, desc: string, prompt: string) => {
              this.handleSave(name, desc, prompt)
            },
            onClose: () => {
              this.closeFormDialog()
            }
          })
        }
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true)
  }

  // ========== 工具栏 ==========

  @Builder
  ToolbarArea() {
    Row() {
      // 标题 + 数量
      Column({ space: Spacing.XS }) {
        Text('模板管理')
          .fontSize(Typography.TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Colors.TEXT_PRIMARY)
        Text(`共 ${this.templates.length} 个模板`)
          .fontSize(Typography.BODY)
          .fontColor(Colors.TEXT_SECONDARY)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Row({ space: Spacing.SM }) {
        // 重置默认模板按钮
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.arrow_counterclockwise'))
            .fontSize(ComponentSize.ICON_SM)
            .fontColor([Colors.PRIMARY])
        }
        .width(40)
        .height(40)
        .backgroundColor(Colors.BG_SECONDARY)
        .onClick(() => {
          this.resetDefaultTemplates()
        })

        // 新建按钮
        Button('新建', { type: ButtonType.Capsule })
          .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
          .backgroundColor(Colors.PRIMARY)
          .fontColor(Colors.TEXT_ON_PRIMARY)
          .fontSize(Typography.BODY)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.openFormDialog()
          })
      }
    }
    .width('100%')
    .padding({ left: Spacing.BASE, right: Spacing.BASE, top: Spacing.SM, bottom: Spacing.BASE })
    .alignItems(VerticalAlign.Bottom)
  }

  // ========== 加载中 ==========

  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color(Colors.PRIMARY)
      Text('加载中...')
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_HINT)
        .margin({ top: Spacing.SM })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // ========== 空状态 ==========

  @Builder
  EmptyView() {
    Column({ space: Spacing.BASE }) {
      SymbolGlyph($r('sys.symbol.doc_filled_on_doc'))
        .fontSize(64)
        .fontColor([Colors.TEXT_HINT])
        .opacity(0.5)

      Text('暂无模板')
        .fontSize(Typography.SUBTITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(Colors.TEXT_PRIMARY)

      Text('创建自定义模板来快速生成文章')
        .fontSize(Typography.BODY)
        .fontColor(Colors.TEXT_SECONDARY)
        .textAlign(TextAlign.Center)

      Button('新建模板', { type: ButtonType.Capsule })
        .height(ComponentSize.BUTTON_HEIGHT_COMPACT)
        .backgroundColor(Colors.PRIMARY)
        .fontColor(Colors.TEXT_ON_PRIMARY)
        .fontSize(Typography.BODY)
        .fontWeight(FontWeight.Medium)
        .margin({ top: Spacing.SM })
        .onClick(() => {
          this.openFormDialog()
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(Spacing.XL)
  }

  // ========== 模板列表 ==========

  @Builder
  TemplatesList() {
    Scroll() {
      Column({ space: Spacing.MD }) {
        ForEach(this.templates, (template: ArticleTemplate) => {
          TemplateCardComponent({
            template: template,
            onEdit: () => {
              this.openEditDialog(template)
            },
            onDelete: () => {
              this.confirmDelete(template)
            }
          })
        }, (template: ArticleTemplate) => template.id)
      }
      .width('100%')
      .padding({ left: Spacing.BASE, right: Spacing.BASE, bottom: Spacing.XL })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  // ========== 业务逻辑 ==========

  private async loadTemplates(): Promise<void> {
    if (this.currentUserId.length === 0) {
      this.isLoading = false
      return
    }
    try {
      this.isLoading = true
      // 初始化默认模板（首次使用）
      await this.initDefaultTemplates()
      this.templates = await TemplateDao.findByUserId(this.currentUserId)
    } catch (err) {
      Logger.error('Load templates failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '加载模板失败' })
    } finally {
      this.isLoading = false
    }
  }

  private openFormDialog(): void {
    this.editingTemplate = null
    this.showFormDialog = true
  }

  private openEditDialog(template: ArticleTemplate): void {
    this.editingTemplate = template
    this.showFormDialog = true
  }

  private closeFormDialog(): void {
    this.showFormDialog = false
    this.editingTemplate = null
  }

  private async handleSave(name: string, description: string, systemPrompt: string): Promise<void> {
    if (name.trim().length === 0) {
      UiFeedback.showToast({ message: '请输入模板名称' })
      return
    }
    if (systemPrompt.trim().length === 0) {
      UiFeedback.showToast({ message: '请输入系统提示词' })
      return
    }

    try {
      if (this.editingTemplate !== null) {
        // 更新
        this.editingTemplate.name = name.trim()
        this.editingTemplate.description = description.trim()
        this.editingTemplate.systemPrompt = systemPrompt.trim()
        await TemplateDao.update(this.editingTemplate)
        UiFeedback.showToast({ message: '模板已更新', duration: 2000 })
      } else {
        // 新建
        await TemplateDao.insert(
          this.currentUserId,
          name.trim(),
          description.trim(),
          systemPrompt.trim()
        )
        UiFeedback.showToast({ message: '模板已创建', duration: 2000 })
      }
      this.closeFormDialog()
      await this.loadTemplates()
    } catch (err) {
      Logger.error('Save template failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '保存失败' })
    }
  }

  private confirmDelete(template: ArticleTemplate): void {
    UiFeedback.showConfirm({
      title: '确认删除',
      message: `确定要删除模板"${template.name}"吗？此操作无法撤销。`,
      autoCancel: true,
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '删除',
        fontColor: Colors.ERROR,
        action: () => {
          this.handleDelete(template)
        }
      }
    })
  }

  private async handleDelete(template: ArticleTemplate): Promise<void> {
    try {
      await TemplateDao.deleteById(template.id)
      UiFeedback.showToast({ message: '模板已删除', duration: 2000 })
      await this.loadTemplates()
    } catch (err) {
      Logger.error('Delete template failed: %{public}s', String(err))
      UiFeedback.showToast({ message: '删除失败' })
    }
  }
}
