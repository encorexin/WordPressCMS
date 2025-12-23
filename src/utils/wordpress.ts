import type { WordPressSite } from "@/types/types";

// WordPress REST API 基础URL
const getApiUrl = (siteUrl: string) => {
  const cleanUrl = siteUrl.replace(/\/$/, "");
  return `${cleanUrl}/wp-json/wp/v2`;
};

// 创建认证头
const createAuthHeader = (username: string, appPassword: string) => {
  const credentials = btoa(`${username}:${appPassword}`);
  return `Basic ${credentials}`;
};

// 测试WordPress站点连接
export async function testWordPressConnection(
  site: WordPressSite
): Promise<{ success: boolean; message: string }> {
  try {
    const apiUrl = getApiUrl(site.site_url);
    const response = await fetch(`${apiUrl}/users/me`, {
      method: "GET",
      headers: {
        Authorization: createAuthHeader(site.username, site.app_password),
        "Content-Type": "application/json",
      },
    });

    if (response.ok) {
      return { success: true, message: "连接成功" };
    } else {
      const errorData = await response.json().catch(() => ({}));
      return {
        success: false,
        message: errorData.message || `连接失败: ${response.status}`,
      };
    }
  } catch (error) {
    return {
      success: false,
      message: error instanceof Error ? error.message : "连接失败",
    };
  }
}

// 发布文章到WordPress
export async function publishToWordPress(
  site: WordPressSite,
  title: string,
  content: string
): Promise<{ success: boolean; postId?: string; message: string }> {
  try {
    const apiUrl = getApiUrl(site.site_url);
    const response = await fetch(`${apiUrl}/posts`, {
      method: "POST",
      headers: {
        Authorization: createAuthHeader(site.username, site.app_password),
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        title,
        content,
        status: "publish",
      }),
    });

    if (response.ok) {
      const data = await response.json();
      return {
        success: true,
        postId: data.id.toString(),
        message: "发布成功",
      };
    } else {
      const errorData = await response.json().catch(() => ({}));
      return {
        success: false,
        message: errorData.message || `发布失败: ${response.status}`,
      };
    }
  } catch (error) {
    return {
      success: false,
      message: error instanceof Error ? error.message : "发布失败",
    };
  }
}

// 更新WordPress文章
export async function updateWordPressPost(
  site: WordPressSite,
  postId: string,
  title: string,
  content: string
): Promise<{ success: boolean; message: string }> {
  try {
    const apiUrl = getApiUrl(site.site_url);
    const response = await fetch(`${apiUrl}/posts/${postId}`, {
      method: "POST",
      headers: {
        Authorization: createAuthHeader(site.username, site.app_password),
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        title,
        content,
      }),
    });

    if (response.ok) {
      return { success: true, message: "更新成功" };
    } else {
      const errorData = await response.json().catch(() => ({}));
      return {
        success: false,
        message: errorData.message || `更新失败: ${response.status}`,
      };
    }
  } catch (error) {
    return {
      success: false,
      message: error instanceof Error ? error.message : "更新失败",
    };
  }
}
