// 数据管理页面摘要与恢复结果辅助方法

import { ResourceColors } from '../constants/DesignTokens'
import { ExportData, ImportResult } from '../services/export/DataExportService'

export class DataManagementRestoreResult {
  title: string = ''
  summary: string = ''
  color: ResourceColor = ResourceColors.TEXT_HINT
  toastMessage: string = ''
}

export class DataManagementSummaryHelper {
  static buildBackupSummary(importData: ExportData): string {
    const articleCount = importData.articles ? importData.articles.length : 0
    const versionCount = importData.articleVersions ? importData.articleVersions.length : 0
    const siteCount = importData.sites ? importData.sites.length : 0
    const templateCount = importData.templates ? importData.templates.length : 0
    const keywordCount = importData.keywords ? importData.keywords.length : 0
    const topicCount = importData.topics ? importData.topics.length : 0
    const aiSettingsCount = importData.aiSettings ? importData.aiSettings.length : 0

    return `文章 ${articleCount} 篇、文章版本 ${versionCount} 条、站点 ${siteCount} 个、模板 ${templateCount} 个、关键词 ${keywordCount} 个、主题 ${topicCount} 个、AI 设置 ${aiSettingsCount} 条`
  }

  static buildImportRestoreResult(result: ImportResult): DataManagementRestoreResult {
    const restoreResult = new DataManagementRestoreResult()
    if (result.totalFailed === 0) {
      restoreResult.title = '恢复完成'
      restoreResult.summary = `成功导入 ${result.totalImported} 条数据`
      restoreResult.color = ResourceColors.SUCCESS
      restoreResult.toastMessage = `恢复完成：导入 ${result.totalImported} 条数据`
    } else {
      restoreResult.title = '恢复完成（部分失败）'
      restoreResult.summary = `导入 ${result.totalImported} 条，失败 ${result.totalFailed} 条`
      restoreResult.color = ResourceColors.WARNING
      restoreResult.toastMessage = `恢复完成：导入 ${result.totalImported} 条，失败 ${result.totalFailed} 条`
    }
    return restoreResult
  }

  static buildImportFailureResult(errorText: string): DataManagementRestoreResult {
    const restoreResult = new DataManagementRestoreResult()
    restoreResult.title = '恢复失败'
    restoreResult.summary = errorText
    restoreResult.color = ResourceColors.ERROR
    restoreResult.toastMessage = '恢复失败'
    return restoreResult
  }

  static buildClearSuccessResult(): DataManagementRestoreResult {
    const restoreResult = new DataManagementRestoreResult()
    restoreResult.title = '本地数据已清除'
    restoreResult.summary = '页面统计已刷新'
    restoreResult.color = ResourceColors.WARNING
    restoreResult.toastMessage = '本地数据已清除'
    return restoreResult
  }

  static buildClearFailureResult(errorText: string): DataManagementRestoreResult {
    const restoreResult = new DataManagementRestoreResult()
    restoreResult.title = '清除未完成'
    restoreResult.summary = errorText
    restoreResult.color = ResourceColors.ERROR
    restoreResult.toastMessage = '清除数据失败'
    return restoreResult
  }
}
