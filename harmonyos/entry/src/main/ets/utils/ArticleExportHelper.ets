import { ContentMetrics } from './ContentMetrics'

/** HTML 导出浅色主题配色 */
interface HtmlLightTheme {
  bodyBg: string
  bodyText: string
  metaText: string
  metaBg: string
  codeBg: string
  border: string
  link: string
}

/** HTML 导出深色主题配色 */
interface HtmlDarkTheme {
  bodyBg: string
  bodyText: string
  metaText: string
  metaBg: string
  codeBg: string
  border: string
  link: string
}

export class ArticleExportHelper {
  private static readonly LIGHT_THEME: HtmlLightTheme = {
    bodyBg: '#FFFFFF',
    bodyText: '#333333',
    metaText: '#666666',
    metaBg: '#F5F5F5',
    codeBg: '#F4F4F4',
    border: '#333333',
    link: '#0366D6'
  }

  private static readonly DARK_THEME: HtmlDarkTheme = {
    bodyBg: '#0F172A',
    bodyText: '#E5E7EB',
    metaText: '#9CA3AF',
    metaBg: '#1E293B',
    codeBg: '#111827',
    border: '#334155',
    link: '#59A8FF'
  }
  static toMarkdown(title: string, keywords: string, templateName: string, articleStatus: string,
    content: string): string {
    return `# ${title || '无标题'}

**关键词:** ${keywords || '无'}
**模板:** ${templateName || '默认'}
**状态:** ${articleStatus || '草稿'}

---

${content || ''}
`
  }

  static toPlainText(title: string, keywords: string, templateName: string, articleStatus: string,
    content: string): string {
    let text = content || ''
    text = text.replace(/^#{1,6}\s+/gm, '')
    text = text.replace(/\*\*?|\*\*?/g, '')
    text = text.replace(/\[([^\]]+)\]\([^\)]+\)/g, '$1')
    text = text.replace(/!\[([^\]]*)\]\([^\)]+\)/g, '')
    text = text.replace(/```[\s\S]*?```/g, '')
    text = text.replace(/`([^`]+)`/g, '$1')
    text = text.replace(/^---+$/gm, '')
    text = text.replace(/^>\s*/gm, '')
    text = text.replace(/^[\*\-\+]\s+/gm, '')
    text = text.replace(/^\d+\.\s+/gm, '')

    return `${title || '无标题'}
========================================

关键词: ${keywords || '无'}
模板: ${templateName || '默认'}
状态: ${articleStatus || '草稿'}

----------------------------------------

${text}
`
  }

  static toHtml(title: string, keywords: string, templateName: string, articleStatus: string,
    content: string, isDarkTheme: boolean): string {
    const htmlContent = ArticleExportHelper.toHtmlBody(content || '')
    const htmlTitle = title || '无标题'
    const styles = ArticleExportHelper.buildHtmlStyles(isDarkTheme)

    return `<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${htmlTitle}</title>
    <style>${styles}
    </style>
</head>
<body>
    <h1>${htmlTitle}</h1>
    <div class="meta">
        <p>关键词: ${keywords || '无'} | 模板: ${templateName || '默认'} | 状态: ${articleStatus || '草稿'} | 字数: ${ContentMetrics.countWords(content || '')}</p>
    </div>
    <hr>
    <div class="content">
${htmlContent}
    </div>
</body>
</html>`
  }

  private static toHtmlBody(content: string): string {
    let htmlContent = content
    htmlContent = htmlContent.replace(/^######\s+(.+)$/gm, '<h6>$1</h6>')
    htmlContent = htmlContent.replace(/^#####\s+(.+)$/gm, '<h5>$1</h5>')
    htmlContent = htmlContent.replace(/^####\s+(.+)$/gm, '<h4>$1</h4>')
    htmlContent = htmlContent.replace(/^###\s+(.+)$/gm, '<h3>$1</h3>')
    htmlContent = htmlContent.replace(/^##\s+(.+)$/gm, '<h2>$1</h2>')
    htmlContent = htmlContent.replace(/^#\s+(.+)$/gm, '<h1>$1</h1>')
    htmlContent = htmlContent.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    htmlContent = htmlContent.replace(/__(.+?)__/g, '<strong>$1</strong>')
    htmlContent = htmlContent.replace(/\*(.+?)\*/g, '<em>$1</em>')
    htmlContent = htmlContent.replace(/_(.+?)_/g, '<em>$1</em>')
    htmlContent = htmlContent.replace(/\[([^\]]+)\]\(([^\)]+)\)/g, '<a href="$2">$1</a>')
    htmlContent = htmlContent.replace(/```([\s\S]*?)```/g, '<pre><code>$1</code></pre>')
    htmlContent = htmlContent.replace(/`([^`]+)`/g, '<code>$1</code>')

    const paragraphs = htmlContent.split(/\n\n+/)
    return paragraphs.map((paragraph: string) => {
      const trimmed = paragraph.trim()
      if (trimmed.length === 0) {
        return ''
      }
      if (trimmed.startsWith('<h') || trimmed.startsWith('<pre')) {
        return trimmed
      }
      return `<p>${trimmed.replace(/\n/g, '<br>')}</p>`
    }).join('\n')
  }

  private static buildHtmlStyles(isDarkTheme: boolean): string {
    const t = isDarkTheme ? ArticleExportHelper.DARK_THEME : ArticleExportHelper.LIGHT_THEME

    return `
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; line-height: 1.6; background: ${t.bodyBg}; color: ${t.bodyText}; }
        h1 { border-bottom: 2px solid ${t.border}; padding-bottom: 10px; }
        h2, h3, h4, h5, h6 { margin-top: 24px; margin-bottom: 16px; }
        .meta { color: ${t.metaText}; font-size: 0.9em; margin-bottom: 20px; padding: 10px; background: ${t.metaBg}; border-radius: 4px; }
        pre { background: ${t.codeBg}; padding: 16px; overflow-x: auto; border-radius: 4px; }
        code { background: ${t.codeBg}; padding: 2px 6px; border-radius: 3px; font-family: monospace; }
        a { color: ${t.link}; text-decoration: none; }
        a:hover { text-decoration: underline; }
    `
  }
}
