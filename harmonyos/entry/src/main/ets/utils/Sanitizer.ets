// 输入过滤 — 防 XSS、SQL 注入

export function sanitizeInput(input: string): string {
  if (input.length === 0) {
    return ''
  }
  let result = input
  result = result.replace(/&/g, '&amp;')
  result = result.replace(/</g, '&lt;')
  result = result.replace(/>/g, '&gt;')
  result = result.replace(/"/g, '&quot;')
  result = result.replace(/'/g, '&#x27;')
  return result
}

export function sanitizeUrl(url: string): string {
  if (url.length === 0) {
    return ''
  }
  let result = url.trim()
  // 移除尾部斜杠
  while (result.endsWith('/')) {
    result = result.substring(0, result.length - 1)
  }
  // 确保 https 前缀
  if (!result.startsWith('http://') && !result.startsWith('https://')) {
    result = 'https://' + result
  }
  return result
}

export function isValidEmail(email: string): boolean {
  if (email.length === 0) {
    return false
  }
  const atIndex = email.indexOf('@')
  const dotIndex = email.lastIndexOf('.')
  return atIndex > 0 && dotIndex > atIndex + 1 && dotIndex < email.length - 1
}

export function isValidUrl(url: string): boolean {
  if (url.length === 0) {
    return false
  }
  return url.startsWith('http://') || url.startsWith('https://')
}
