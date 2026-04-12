export class ContentMetrics {
  static countWords(content: string): number {
    if (!content || content.length === 0) return 0
    const chineseChars = content.match(/[\u4e00-\u9fa5]/g) || []
    const englishWords = content.match(/[a-zA-Z]+/g) || []
    return chineseChars.length + englishWords.length
  }

  static estimateTokens(text: string): number {
    if (!text || text.length === 0) return 0
    const chineseChars = text.match(/[\u4e00-\u9fa5]/g) || []
    const chineseCount = chineseChars.length
    const nonChineseCount = Math.max(0, text.length - chineseCount)
    return chineseCount + Math.ceil(nonChineseCount / 4)
  }
}
