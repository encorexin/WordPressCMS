/**
 * HTML 内容净化工具
 * 使用 DOMPurify 防止 XSS 攻击
 */
import DOMPurify from "dompurify";

/**
 * 净化 HTML 内容，移除潜在的 XSS 攻击向量
 * 用于渲染用户输入内容或 AI 生成内容
 */
export function sanitizeHTML(dirty: string): string {
  return DOMPurify.sanitize(dirty, {
    ALLOWED_TAGS: [
      "h1",
      "h2",
      "h3",
      "h4",
      "h5",
      "h6",
      "p",
      "br",
      "hr",
      "ul",
      "ol",
      "li",
      "strong",
      "em",
      "b",
      "i",
      "u",
      "s",
      "del",
      "a",
      "img",
      "blockquote",
      "pre",
      "code",
      "table",
      "thead",
      "tbody",
      "tr",
      "th",
      "td",
      "div",
      "span",
      "figure",
      "figcaption",
    ],
    ALLOWED_ATTR: ["href", "src", "alt", "title", "class", "target", "rel", "width", "height"],
    ALLOW_DATA_ATTR: false,
    ADD_ATTR: ["target"],
  });
}

/**
 * 净化纯文本 — 移除所有 HTML 标签
 */
export function sanitizeText(dirty: string): string {
  return DOMPurify.sanitize(dirty, { ALLOWED_TAGS: [] });
}

/**
 * 净化 Markdown 渲染后的 HTML
 * 比 sanitizeHTML 更宽松，允许代码高亮相关标签
 */
export function sanitizeMarkdownHTML(dirty: string): string {
  return DOMPurify.sanitize(dirty, {
    ADD_TAGS: ["iframe"],
    ADD_ATTR: ["allow", "allowfullscreen", "frameborder", "scrolling"],
    FORBID_TAGS: ["script", "style", "object", "embed", "form", "input"],
    FORBID_ATTR: ["onerror", "onload", "onclick", "onmouseover"],
  });
}
