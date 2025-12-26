import type { WordPressSite } from "@/types/types";

// WordPress 分类类型
export interface WordPressCategory {
  id: number;
  name: string;
  slug: string;
  parent: number;
  count: number;
}

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

// 获取 WordPress 分类列表
export async function getWordPressCategories(
  site: WordPressSite
): Promise<{ success: boolean; categories: WordPressCategory[]; message: string }> {
  try {
    const apiUrl = getApiUrl(site.site_url);
    const response = await fetch(`${apiUrl}/categories?per_page=100`, {
      method: "GET",
      headers: {
        Authorization: createAuthHeader(site.username, site.app_password),
        "Content-Type": "application/json",
      },
    });

    if (response.ok) {
      const categories = await response.json();
      return {
        success: true,
        categories: categories.map((cat: any) => ({
          id: cat.id,
          name: cat.name,
          slug: cat.slug,
          parent: cat.parent,
          count: cat.count,
        })),
        message: "获取成功",
      };
    } else {
      const errorData = await response.json().catch(() => ({}));
      return {
        success: false,
        categories: [],
        message: errorData.message || `获取分类失败: ${response.status}`,
      };
    }
  } catch (error) {
    return {
      success: false,
      categories: [],
      message: error instanceof Error ? error.message : "获取分类失败",
    };
  }
}

// 发布文章到WordPress
export async function publishToWordPress(
  site: WordPressSite,
  title: string,
  content: string,
  options?: {
    categories?: number[];
    slug?: string;
  }
): Promise<{ success: boolean; postId?: string; message: string }> {
  try {
    const apiUrl = getApiUrl(site.site_url);

    const postData: Record<string, any> = {
      title,
      content,
      status: "publish",
    };

    // 添加分类
    if (options?.categories && options.categories.length > 0) {
      postData.categories = options.categories;
    }

    // 添加别名
    if (options?.slug) {
      postData.slug = options.slug;
    }

    const response = await fetch(`${apiUrl}/posts`, {
      method: "POST",
      headers: {
        Authorization: createAuthHeader(site.username, site.app_password),
        "Content-Type": "application/json",
      },
      body: JSON.stringify(postData),
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
  content: string,
  options?: {
    categories?: number[];
    slug?: string;
  }
): Promise<{ success: boolean; message: string }> {
  try {
    const apiUrl = getApiUrl(site.site_url);

    const postData: Record<string, any> = {
      title,
      content,
    };

    // 添加分类
    if (options?.categories && options.categories.length > 0) {
      postData.categories = options.categories;
    }

    // 添加别名
    if (options?.slug) {
      postData.slug = options.slug;
    }

    const response = await fetch(`${apiUrl}/posts/${postId}`, {
      method: "POST",
      headers: {
        Authorization: createAuthHeader(site.username, site.app_password),
        "Content-Type": "application/json",
      },
      body: JSON.stringify(postData),
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

