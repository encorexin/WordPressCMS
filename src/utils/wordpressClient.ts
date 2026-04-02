import { wpLogger } from "./logger";
import { Result, createError, ErrorCodes } from "./errorHandler";

export interface WordPressSite {
    site_url: string;
    username: string;
    app_password: string;
}

export interface WordPressCategory {
    id: number;
    name: string;
    slug: string;
    parent: number;
    count: number;
}

export interface WordPressPost {
    id: number;
    title: { rendered: string };
    content: { rendered: string };
    status: string;
    slug: string;
    link: string;
    date: string;
    modified: string;
    categories: number[];
}

export interface WordPressUser {
    id: number;
    name: string;
    slug: string;
    avatar_urls?: Record<string, string>;
}

export interface PublishOptions {
    categories?: number[];
    slug?: string;
    status?: "publish" | "draft" | "pending" | "private";
    excerpt?: string;
    featured_media?: number;
}

export interface WordPressError {
    code: string;
    message: string;
    data?: { status: number };
}

export class WordPressClient {
    private baseUrl: string;
    private authHeader: string;
    private timeout: number;

    constructor(site: WordPressSite, timeout = 30000) {
        this.baseUrl = site.site_url.replace(/\/$/, "");
        this.authHeader = this.createAuthHeader(site.username, site.app_password);
        this.timeout = timeout;
    }

    private createAuthHeader(username: string, appPassword: string): string {
        const credentials = btoa(`${username}:${appPassword}`);
        return `Basic ${credentials}`;
    }

    private getApiUrl(endpoint: string): string {
        return `${this.baseUrl}/wp-json/wp/v2${endpoint}`;
    }

    private async request<T>(
        method: string,
        endpoint: string,
        body?: unknown
    ): Promise<Result<T>> {
        const url = this.getApiUrl(endpoint);

        wpLogger.debug(`${method} ${endpoint}`, body ? { body } : "");

        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), this.timeout);

            const response = await fetch(url, {
                method,
                headers: {
                    Authorization: this.authHeader,
                    "Content-Type": "application/json",
                    Accept: "application/json",
                },
                body: body ? JSON.stringify(body) : undefined,
                signal: controller.signal,
            });

            clearTimeout(timeoutId);

            if (!response.ok) {
                const errorData: WordPressError = await response.json().catch(() => ({
                    code: "unknown_error",
                    message: `HTTP ${response.status}`,
                }));

                wpLogger.error(`请求失败: ${endpoint}`, errorData);

                return {
                    success: false,
                    error: createError(
                        ErrorCodes.API_ERROR,
                        errorData.message || `请求失败: ${response.status}`,
                        errorData
                    ),
                };
            }

            const data = await response.json();
            wpLogger.debug(`请求成功: ${endpoint}`);

            return { success: true, data };
        } catch (error) {
            if (error instanceof Error && error.name === "AbortError") {
                wpLogger.warn(`请求超时: ${endpoint}`);
                return {
                    success: false,
                    error: createError(ErrorCodes.NETWORK_ERROR, "请求超时", error),
                };
            }

            wpLogger.error(`网络错误: ${endpoint}`, error);
            return {
                success: false,
                error: createError(
                    ErrorCodes.NETWORK_ERROR,
                    error instanceof Error ? error.message : "网络请求失败",
                    error
                ),
            };
        }
    }

    async testConnection(): Promise<Result<WordPressUser>> {
        wpLogger.info("测试连接...");
        return this.request<WordPressUser>("GET", "/users/me");
    }

    async getCategories(perPage = 100): Promise<Result<WordPressCategory[]>> {
        wpLogger.debug("获取分类列表...");
        return this.request<WordPressCategory[]>(
            "GET",
            `/categories?per_page=${perPage}&orderby=name&order=asc`
        );
    }

    async getCategory(categoryId: number): Promise<Result<WordPressCategory>> {
        return this.request<WordPressCategory>("GET", `/categories/${categoryId}`);
    }

    async getPosts(options?: {
        page?: number;
        perPage?: number;
        status?: string;
    }): Promise<Result<WordPressPost[]>> {
        const params = new URLSearchParams();
        if (options?.page) params.set("page", String(options.page));
        if (options?.perPage) params.set("per_page", String(options.perPage));
        if (options?.status) params.set("status", options.status);

        const query = params.toString() ? `?${params.toString()}` : "";
        return this.request<WordPressPost[]>("GET", `/posts${query}`);
    }

    async getPost(postId: number): Promise<Result<WordPressPost>> {
        return this.request<WordPressPost>("GET", `/posts/${postId}`);
    }

    async createPost(
        title: string,
        content: string,
        options?: PublishOptions
    ): Promise<Result<WordPressPost>> {
        wpLogger.info(`创建文章: ${title}`);

        const body: Record<string, unknown> = {
            title,
            content,
            status: options?.status || "publish",
        };

        if (options?.categories?.length) {
            body.categories = options.categories;
        }
        if (options?.slug) {
            body.slug = options.slug;
        }
        if (options?.excerpt) {
            body.excerpt = options.excerpt;
        }
        if (options?.featured_media) {
            body.featured_media = options.featured_media;
        }

        return this.request<WordPressPost>("POST", "/posts", body);
    }

    async updatePost(
        postId: number,
        title: string,
        content: string,
        options?: PublishOptions
    ): Promise<Result<WordPressPost>> {
        wpLogger.info(`更新文章: ${postId}`);

        const body: Record<string, unknown> = {
            title,
            content,
        };

        if (options?.categories?.length) {
            body.categories = options.categories;
        }
        if (options?.slug) {
            body.slug = options.slug;
        }
        if (options?.status) {
            body.status = options.status;
        }

        return this.request<WordPressPost>("POST", `/posts/${postId}`, body);
    }

    async deletePost(postId: number): Promise<Result<void>> {
        wpLogger.info(`删除文章: ${postId}`);
        return this.request<void>("DELETE", `/posts/${postId}`);
    }

    async uploadMedia(
        file: File,
        title?: string
    ): Promise<Result<{ id: number; source_url: string }>> {
        wpLogger.info(`上传媒体: ${file.name}`);

        const formData = new FormData();
        formData.append("file", file);
        if (title) {
            formData.append("title", title);
        }

        try {
            const response = await fetch(this.getApiUrl("/media"), {
                method: "POST",
                headers: {
                    Authorization: this.authHeader,
                },
                body: formData,
            });

            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}));
                return {
                    success: false,
                    error: createError(
                        ErrorCodes.API_ERROR,
                        errorData.message || `上传失败: ${response.status}`,
                        errorData
                    ),
                };
            }

            const data = await response.json();
            return {
                success: true,
                data: { id: data.id, source_url: data.source_url },
            };
        } catch (error) {
            return {
                success: false,
                error: createError(
                    ErrorCodes.NETWORK_ERROR,
                    error instanceof Error ? error.message : "上传失败",
                    error
                ),
            };
        }
    }

    async getTags(perPage = 100): Promise<Result<Array<{ id: number; name: string; slug: string }>>> {
        return this.request<Array<{ id: number; name: string; slug: string }>>(
            "GET",
            `/tags?per_page=${perPage}`
        );
    }

    async createTag(name: string): Promise<Result<{ id: number; name: string }>> {
        return this.request<{ id: number; name: string }>("POST", "/tags", { name });
    }

    async getSiteInfo(): Promise<
        Result<{
            name: string;
            description: string;
            url: string;
            timezone_string: string;
        }>
    > {
        return this.request<{
            name: string;
            description: string;
            url: string;
            timezone_string: string;
        }>("GET", "");
    }
}

export function createWordPressClient(site: WordPressSite): WordPressClient {
    return new WordPressClient(site);
}

export async function testWordPressConnection(
    site: WordPressSite
): Promise<{ success: boolean; message: string }> {
    const client = new WordPressClient(site);
    const result = await client.testConnection();

    if (result.success) {
        return { success: true, message: `连接成功，用户: ${result.data.name}` };
    }
    return { success: false, message: result.error.message };
}

export async function getWordPressCategories(
    site: WordPressSite
): Promise<{ success: boolean; categories: WordPressCategory[]; message: string }> {
    const client = new WordPressClient(site);
    const result = await client.getCategories();

    if (result.success) {
        return { success: true, categories: result.data, message: "获取成功" };
    }
    return { success: false, categories: [], message: result.error.message };
}

export async function publishToWordPress(
    site: WordPressSite,
    title: string,
    content: string,
    options?: PublishOptions
): Promise<{ success: boolean; postId?: string; message: string }> {
    const client = new WordPressClient(site);
    const result = await client.createPost(title, content, options);

    if (result.success) {
        return {
            success: true,
            postId: String(result.data.id),
            message: "发布成功",
        };
    }
    return { success: false, message: result.error.message };
}

export async function updateWordPressPost(
    site: WordPressSite,
    postId: string,
    title: string,
    content: string,
    options?: PublishOptions
): Promise<{ success: boolean; message: string }> {
    const client = new WordPressClient(site);
    const result = await client.updatePost(Number(postId), title, content, options);

    if (result.success) {
        return { success: true, message: "更新成功" };
    }
    return { success: false, message: result.error.message };
}
