import fs from '@ohos.file.fs'
import picker from '@ohos.file.picker'
import { buffer } from '@kit.ArkTS'
import { Article } from '../../models/Article'
import { ArticleVersion } from '../../models/ArticleVersion'
import { WordPressSite } from '../../models/WordPressSite'
import { ArticleTemplate } from '../../models/ArticleTemplate'
import { Keyword } from '../../models/Keyword'
import { Topic } from '../../models/Topic'
import { AISettingsModel } from '../../models/AISettings'
import { ArticleDao } from '../db/ArticleDao'
import { SiteDao } from '../db/SiteDao'
import { TemplateDao } from '../db/TemplateDao'
import { KeywordDao } from '../db/KeywordDao'
import { TopicDao } from '../db/TopicDao'
import { VersionDao } from '../db/VersionDao'
import { AISettingsDao } from '../db/AISettingsDao'
import { CryptoService } from '../crypto/CryptoService'
import { Logger } from '../../utils/Logger'

export class ExportData {
  version: string = '1.0'
  exportedAt: string = ''
  encrypted: boolean = false
  articles: Article[] = []
  articleVersions: ArticleVersion[] = []
  sites: WordPressSite[] = []
  templates: ArticleTemplate[] = []
  keywords: Keyword[] = []
  topics: Topic[] = []
  aiSettings: AISettingsModel[] = []
}

export class SingleExportData {
  type: string = ''
  exportedAt: string = ''
  count: number = 0
  data: string = '' // JSON stringified array
}

export class ImportResult {
  success: boolean = false
  totalImported: number = 0
  totalFailed: number = 0
  details: string = ''
}

class EncryptedExportWrapper {
  version: string = '1.0'
  exportedAt: string = ''
  encrypted: boolean = true
  payload: string = ''
}

export class DataExportService {
  static async collectAllData(userId: string): Promise<ExportData> {
    const exportData = new ExportData()
    exportData.exportedAt = new Date().toISOString()

    try {
      const articles = await ArticleDao.findByUserId(userId)
      const sites = await SiteDao.findByUserId(userId)
      const templates = await TemplateDao.findByUserId(userId)
      const keywords = await KeywordDao.findByUserId(userId)
      const topics = await TopicDao.findByUserId(userId)
      const aiSettings = await AISettingsDao.findByUserId(userId)

      exportData.articles = articles
      exportData.sites = sites
      exportData.templates = templates
      exportData.keywords = keywords
      exportData.topics = topics
      exportData.aiSettings = aiSettings

      const allVersions: ArticleVersion[] = []
      for (let i = 0; i < articles.length; i++) {
        const article = articles[i]
        const versions = await VersionDao.findByArticleId(article.id)
        for (let j = 0; j < versions.length; j++) {
          allVersions.push(versions[j])
        }
      }
      exportData.articleVersions = allVersions
    } catch (err) {
      Logger.error('Failed to collect all data: %{public}s', String(err))
      throw new Error(String(err))
    }

    return exportData
  }

  static async exportToFile(content: string, defaultFileName: string): Promise<boolean> {
    let file: fs.File | null = null

    try {
      const documentPicker = new picker.DocumentViewPicker()
      const documentSaveOptions = new picker.DocumentSaveOptions()
      documentSaveOptions.newFileNames = [defaultFileName]

      const result = await documentPicker.save(documentSaveOptions)

      if (result === null || result === undefined || result.length === 0) {
        return false
      }

      const uri = result[0]
      file = fs.openSync(uri, fs.OpenMode.WRITE_ONLY)

      fs.writeSync(file.fd, content)

      return true
    } catch (err) {
      Logger.error('Failed to export to file: %{public}s', String(err))
      return false
    } finally {
      if (file !== null) {
        try {
          fs.closeSync(file.fd)
        } catch (closeErr) {
          Logger.error('Failed to close file: %{public}s', String(closeErr))
        }
      }
    }
  }

  static async exportAllData(userId: string, encrypt: boolean): Promise<boolean> {
    try {
      const exportData = await DataExportService.collectAllData(userId)
      let content: string

      if (encrypt) {
        const jsonStr = JSON.stringify(exportData)
        const encryptedStr = await CryptoService.encrypt(jsonStr)
        const encryptedWrapper = new EncryptedExportWrapper()
        encryptedWrapper.version = '1.0'
        encryptedWrapper.exportedAt = new Date().toISOString()
        encryptedWrapper.encrypted = true
        encryptedWrapper.payload = encryptedStr
        content = JSON.stringify(encryptedWrapper)
      } else {
        content = JSON.stringify(exportData)
      }

      const fileName = `wp_cms_backup_${DataExportService.getDateSuffix()}.json`
      return await DataExportService.exportToFile(content, fileName)
    } catch (err) {
      Logger.error('Failed to export all data: %{public}s', String(err))
      return false
    }
  }

  static async exportTableData(userId: string, tableName: string): Promise<boolean> {
    try {
      let data: object[] = []

      if (tableName === 'articles') {
        data = await ArticleDao.findByUserId(userId)
      } else if (tableName === 'topics') {
        data = await TopicDao.findByUserId(userId)
      } else if (tableName === 'keywords') {
        data = await KeywordDao.findByUserId(userId)
      } else if (tableName === 'templates') {
        data = await TemplateDao.findByUserId(userId)
      } else if (tableName === 'aiSettings') {
        data = await AISettingsDao.findByUserId(userId)
      } else {
        Logger.error('Unknown table name: %{public}s', tableName)
        return false
      }

      const content = JSON.stringify(data)
      const fileName = `${tableName}-${DataExportService.getDateSuffix()}.json`
      return await DataExportService.exportToFile(content, fileName)
    } catch (err) {
      Logger.error('Failed to export table data: %{public}s', String(err))
      return false
    }
  }

  static async exportArticlesToMarkdown(userId: string): Promise<boolean> {
    try {
      const articles = await ArticleDao.findByUserId(userId)
      const sections: string[] = []

      for (let i = 0; i < articles.length; i++) {
        const article = articles[i]
        const section = `# ${article.title}

**关键词:** ${article.keywords}
**模板:** ${article.template}
**状态:** ${article.status}
**创建时间:** ${article.createdAt}

---

${article.content}

---
---`
        sections.push(section)
      }

      const content = sections.join('\n')
      const fileName = `articles-${DataExportService.getDateSuffix()}.md`
      return await DataExportService.exportToFile(content, fileName)
    } catch (err) {
      Logger.error('Failed to export articles to markdown: %{public}s', String(err))
      return false
    }
  }

  static async exportTopicsToText(userId: string): Promise<boolean> {
    try {
      const topics = await TopicDao.findByUserId(userId)
      const lines: string[] = []

      for (let i = 0; i < topics.length; i++) {
        const topic = topics[i]
        const usedStatus = topic.used ? '已使用' : '未使用'
        const line = `${i + 1}. ${topic.title}
   描述: ${topic.description}
   关键词: ${topic.keywords}
   分类: ${topic.category}
   状态: ${usedStatus}`
        lines.push(line)
      }

      const content = lines.join('\n')
      const fileName = `topics-${DataExportService.getDateSuffix()}.txt`
      return await DataExportService.exportToFile(content, fileName)
    } catch (err) {
      Logger.error('Failed to export topics to text: %{public}s', String(err))
      return false
    }
  }

  static async exportKeywordsToText(userId: string): Promise<boolean> {
    try {
      const keywords = await KeywordDao.findByUserId(userId)
      const groups: Map<string, Keyword[]> = new Map()

      for (let i = 0; i < keywords.length; i++) {
        const keyword = keywords[i]
        const groupName = keyword.groupName
        if (!groups.has(groupName)) {
          groups.set(groupName, [])
        }
        groups.get(groupName)!.push(keyword)
      }

      const sections: string[] = []
      const groupNames = Array.from(groups.keys())
      for (let i = 0; i < groupNames.length; i++) {
        const groupName = groupNames[i]
        const groupKeywords = groups.get(groupName)!
        const header = `## ${groupName}`
        sections.push(header)

        for (let j = 0; j < groupKeywords.length; j++) {
          const keyword = groupKeywords[j]
          const line = `- ${keyword.keyword} (使用次数: ${keyword.useCount})`
          sections.push(line)
        }
      }

      const content = sections.join('\n')
      const fileName = `keywords-${DataExportService.getDateSuffix()}.txt`
      return await DataExportService.exportToFile(content, fileName)
    } catch (err) {
      Logger.error('Failed to export keywords to text: %{public}s', String(err))
      return false
    }
  }

  static async exportAISettingsSafe(userId: string): Promise<boolean> {
    try {
      const settings = await AISettingsDao.findByUserId(userId)
      const maskedSettings: AISettingsModel[] = []
      for (let i = 0; i < settings.length; i++) {
        const setting = settings[i]
        const masked = new AISettingsModel()
        masked.id = setting.id
        masked.userId = setting.userId
        masked.name = setting.name
        masked.isDefault = setting.isDefault
        masked.apiEndpoint = setting.apiEndpoint
        masked.apiKey = (setting.apiKey && setting.apiKey.length > 8) ? setting.apiKey.substring(0, 8) + '...' : setting.apiKey
        masked.model = setting.model
        masked.systemPrompt = setting.systemPrompt
        masked.imageProvider = setting.imageProvider
        masked.imageApiKey = (setting.imageApiKey && setting.imageApiKey.length > 8) ? setting.imageApiKey.substring(0, 8) + '...' : setting.imageApiKey
        masked.imageEndpoint = setting.imageEndpoint
        masked.imageModel = setting.imageModel
        masked.imageEnabled = setting.imageEnabled
        masked.slugModel = setting.slugModel
        masked.slugEnabled = setting.slugEnabled
        masked.createdAt = setting.createdAt
        masked.updatedAt = setting.updatedAt
        maskedSettings.push(masked)
      }

      const content = JSON.stringify(maskedSettings)
      const fileName = `ai-settings-${DataExportService.getDateSuffix()}.json`
      return await DataExportService.exportToFile(content, fileName)
    } catch (err) {
      Logger.error('Failed to export AI settings: %{public}s', String(err))
      return false
    }
  }

  static async importFromFile(): Promise<string> {
    let file: fs.File | null = null

    try {
      const documentPicker = new picker.DocumentViewPicker()
      const documentSelectOptions = new picker.DocumentSelectOptions()
      documentSelectOptions.maxSelectNumber = 1
      documentSelectOptions.fileSuffixFilters = ['.json']

      const result = await documentPicker.select(documentSelectOptions)

      if (result === null || result === undefined || result.length === 0) {
        return ''
      }

      const uri = result[0]
      file = fs.openSync(uri, fs.OpenMode.READ_ONLY)

      const stat = fs.statSync(file.fd)
      const fileSize = stat.size

      const buf = new ArrayBuffer(fileSize)
      fs.readSync(file.fd, buf)

      const content = buffer.from(buf).toString()

      return content
    } catch (err) {
      Logger.error('Failed to import from file: %{public}s', String(err))
      return ''
    } finally {
      if (file !== null) {
        try {
          fs.closeSync(file.fd)
        } catch (closeErr) {
          Logger.error('Failed to close file: %{public}s', String(closeErr))
        }
      }
    }
  }

  static validateImportData(jsonStr: string): ExportData | null {
    try {
      const parsed = JSON.parse(jsonStr) as ExportData

      if (parsed.version === undefined || parsed.version === null) {
        Logger.error('Import data missing version field')
        return null
      }

      if (parsed.exportedAt === undefined || parsed.exportedAt === null) {
        Logger.error('Import data missing exportedAt field')
        return null
      }

      return parsed
    } catch (err) {
      Logger.error('Failed to validate import data: %{public}s', String(err))
      return null
    }
  }

  static async importData(importData: ExportData, userId: string): Promise<ImportResult> {
    const result = new ImportResult()

    const details: string[] = []
    const siteIdMap: Map<string, string> = new Map()
    const articleIdMap: Map<string, string> = new Map()

    try {
      // Import sites first
      if (importData.sites && importData.sites.length > 0) {
        let importedSites = 0
        for (let i = 0; i < importData.sites.length; i++) {
          const site = importData.sites[i]
          try {
            const oldId = site.id
            const newSite = await SiteDao.insert(
              userId,
              site.siteName,
              site.siteUrl,
              site.username,
              site.appPassword
            )
            siteIdMap.set(oldId, newSite.id)

            if (site.status !== undefined) {
              newSite.status = site.status
              await SiteDao.update(newSite)
            }
            importedSites++
          } catch (siteErr) {
            Logger.error('Failed to import site: %{public}s', String(siteErr))
            result.totalFailed++
            details.push(`Failed to import site: ${site.siteName}`)
          }
        }
        result.totalImported += importedSites
        details.push(`Imported ${importedSites} sites`)
      }

      // Import articles
      if (importData.articles && importData.articles.length > 0) {
        let importedArticles = 0
        for (let i = 0; i < importData.articles.length; i++) {
          const article = importData.articles[i]
          try {
            const oldId = article.id
            const newSiteId = siteIdMap.get(article.siteId) || ''
            const newArticle = await ArticleDao.insert(
              userId,
              article.title,
              newSiteId,
              article.content,
              article.keywords,
              article.template,
              article.wordpressPostId,
              article.status
            )
            articleIdMap.set(oldId, newArticle.id)
            importedArticles++
          } catch (articleErr) {
            Logger.error('Failed to import article: %{public}s', String(articleErr))
            result.totalFailed++
            details.push(`Failed to import article: ${article.title}`)
          }
        }
        result.totalImported += importedArticles
        details.push(`Imported ${importedArticles} articles`)
      }

      // Import article versions
      if (importData.articleVersions && importData.articleVersions.length > 0) {
        let importedVersions = 0
        for (let i = 0; i < importData.articleVersions.length; i++) {
          const version = importData.articleVersions[i]
          try {
            const newArticleId = articleIdMap.get(version.articleId)
            const newSiteId = siteIdMap.get(version.siteId) || ''

            if (newArticleId) {
              await VersionDao.insert(
                newArticleId,
                userId,
                newSiteId,
                version.title,
                version.content,
                version.keywords,
                version.template,
                version.wordpressPostId,
                version.status,
                version.versionNumber
              )
              importedVersions++
            } else {
              Logger.warn('Skipping version import - article not found: %{public}s', version.articleId)
            }
          } catch (versionErr) {
            Logger.error('Failed to import article version: %{public}s', String(versionErr))
            result.totalFailed++
          }
        }
        result.totalImported += importedVersions
        details.push(`Imported ${importedVersions} article versions`)
      }

      // Import templates
      if (importData.templates && importData.templates.length > 0) {
        let importedTemplates = 0
        for (let i = 0; i < importData.templates.length; i++) {
          const template = importData.templates[i]
          try {
            await TemplateDao.insert(
              userId,
              template.name,
              template.description,
              template.systemPrompt
            )
            importedTemplates++
          } catch (templateErr) {
            Logger.error('Failed to import template: %{public}s', String(templateErr))
            result.totalFailed++
            details.push(`Failed to import template: ${template.name}`)
          }
        }
        result.totalImported += importedTemplates
        details.push(`Imported ${importedTemplates} templates`)
      }

      // Import keywords
      if (importData.keywords && importData.keywords.length > 0) {
        let importedKeywords = 0
        for (let i = 0; i < importData.keywords.length; i++) {
          const keyword = importData.keywords[i]
          try {
            const newKeyword = await KeywordDao.insert(
              userId,
              keyword.keyword,
              keyword.groupName
            )
            if (keyword.useCount > 0) {
              newKeyword.useCount = keyword.useCount
              await KeywordDao.update(newKeyword)
            }
            importedKeywords++
          } catch (keywordErr) {
            Logger.error('Failed to import keyword: %{public}s', String(keywordErr))
            result.totalFailed++
            details.push(`Failed to import keyword: ${keyword.keyword}`)
          }
        }
        result.totalImported += importedKeywords
        details.push(`Imported ${importedKeywords} keywords`)
      }

      // Import topics
      if (importData.topics && importData.topics.length > 0) {
        let importedTopics = 0
        for (let i = 0; i < importData.topics.length; i++) {
          const topic = importData.topics[i]
          try {
            const newTopic = await TopicDao.insert(
              userId,
              topic.title,
              topic.description,
              topic.keywords,
              topic.category
            )
            if (topic.used) {
              newTopic.used = topic.used
              await TopicDao.update(newTopic)
            }
            importedTopics++
          } catch (topicErr) {
            Logger.error('Failed to import topic: %{public}s', String(topicErr))
            result.totalFailed++
            details.push(`Failed to import topic: ${topic.title}`)
          }
        }
        result.totalImported += importedTopics
        details.push(`Imported ${importedTopics} topics`)
      }

      // Import AI settings
      if (importData.aiSettings && importData.aiSettings.length > 0) {
        let importedSettings = 0
        for (let i = 0; i < importData.aiSettings.length; i++) {
          const setting = importData.aiSettings[i]
          try {
            const settingToInsert = new AISettingsModel()
            settingToInsert.userId = userId
            settingToInsert.name = setting.name
            settingToInsert.isDefault = setting.isDefault
            settingToInsert.apiEndpoint = setting.apiEndpoint
            settingToInsert.apiKey = setting.apiKey
            settingToInsert.model = setting.model
            settingToInsert.systemPrompt = setting.systemPrompt
            settingToInsert.imageProvider = setting.imageProvider
            settingToInsert.imageApiKey = setting.imageApiKey
            settingToInsert.imageEndpoint = setting.imageEndpoint
            settingToInsert.imageModel = setting.imageModel
            settingToInsert.imageEnabled = setting.imageEnabled
            settingToInsert.slugModel = setting.slugModel
            settingToInsert.slugEnabled = setting.slugEnabled
            const newSetting = await AISettingsDao.insert(settingToInsert)

            if (setting.isDefault) {
              await AISettingsDao.setDefault(userId, newSetting.id)
            }
            importedSettings++
          } catch (settingErr) {
            Logger.error('Failed to import AI settings: %{public}s', String(settingErr))
            result.totalFailed++
            details.push(`Failed to import AI settings: ${setting.name}`)
          }
        }
        result.totalImported += importedSettings
        details.push(`Imported ${importedSettings} AI settings`)
      }

      result.success = result.totalFailed === 0
      result.details = details.join('\n')
    } catch (err) {
      Logger.error('Failed to import data: %{public}s', String(err))
      result.details = result.details + '\nError: ' + String(err)
    }

    return result
  }

  static async decryptImportData(encryptedJson: string): Promise<string> {
    try {
      const parsed = JSON.parse(encryptedJson) as EncryptedExportWrapper

      if (!parsed.payload) {
        throw new Error('Invalid encrypted data: missing payload')
      }

      const decrypted = await CryptoService.decrypt(parsed.payload)
      return decrypted
    } catch (err) {
      Logger.error('Failed to decrypt import data: %{public}s', String(err))
      throw new Error(String(err))
    }
  }

  private static getDateSuffix(): string {
    const date = new Date()
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }
}
