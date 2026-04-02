import { useCallback, useState } from "react";
import { toast } from "sonner";
import { updateArticleStatus } from "@/db/api";
import type { WordPressSite, WordPressCategory } from "@/types/types";
import { WordPressClient, type PublishOptions } from "@/utils/wordpressClient";
import { wpLogger } from "@/utils/logger";
import { handleApiError } from "@/utils/errorHandler";

export interface UseArticlePublisherOptions {
    articleId?: string;
    wpPostId?: string | null;
    onPublished?: (postId: string) => void;
    onUpdated?: () => void;
}

export function useArticlePublisher(options: UseArticlePublisherOptions) {
    const [publishing, setPublishing] = useState(false);
    const [categories, setCategories] = useState<WordPressCategory[]>([]);
    const [selectedCategories, setSelectedCategories] = useState<number[]>([]);
    const [postSlug, setPostSlug] = useState("");
    const [generatingSlug, setGeneratingSlug] = useState(false);

    const loadCategories = useCallback(async (site: WordPressSite) => {
        const client = new WordPressClient(site);
        const result = await client.getCategories();

        if (result.success) {
            setCategories(result.data);
        } else {
            wpLogger.error("加载分类失败:", result.error.message);
            setCategories([]);
        }
    }, []);

    const publish = useCallback(
        async (
            site: WordPressSite,
            title: string,
            content: string
        ): Promise<{ success: boolean; postId?: string }> => {
            if (!title || !content) {
                toast.error("请填写标题和内容");
                return { success: false };
            }

            setPublishing(true);

            try {
                const client = new WordPressClient(site);
                const publishOptions: PublishOptions = {
                    categories: selectedCategories.length > 0 ? selectedCategories : undefined,
                    slug: postSlug || undefined,
                };

                let result;

                if (options.wpPostId) {
                    result = await client.updatePost(
                        Number(options.wpPostId),
                        title,
                        content,
                        publishOptions
                    );

                    if (result.success && options.articleId) {
                        await updateArticleStatus(options.articleId, "published");
                        toast.success("更新发布成功");
                        options.onUpdated?.();
                    }
                } else {
                    result = await client.createPost(title, content, publishOptions);

                    if (result.success && options.articleId) {
                        const postId = String(result.data.id);
                        await updateArticleStatus(options.articleId, "published", postId);
                        toast.success("发布成功");
                        options.onPublished?.(postId);
                    }
                }

                if (!result.success) {
                    toast.error(result.error.message);
                }

                return {
                    success: result.success,
                    postId: result.success ? String(result.data.id) : undefined,
                };
            } catch (error) {
                handleApiError(error, "发布文章");
                return { success: false };
            } finally {
                setPublishing(false);
            }
        },
        [options, selectedCategories, postSlug]
    );

    const generateSlug = useCallback(
        async (
            title: string,
            aiSettings: { api_endpoint: string; api_key: string; model?: string }
        ) => {
            if (!title) {
                toast.error("请先输入文章标题");
                return null;
            }

            setGeneratingSlug(true);

            try {
                const { generateSEOSlug } = await import("@/utils/aiChat");
                const slug = await generateSEOSlug(title, {
                    endpoint: aiSettings.api_endpoint,
                    apiKey: aiSettings.api_key,
                    model: aiSettings.model,
                });

                if (slug) {
                    setPostSlug(slug);
                    toast.success("已生成 SEO 友好的别名");
                    return slug;
                }

                toast.error("生成失败，返回结果为空");
                return null;
            } catch (error) {
                handleApiError(error, "生成别名");
                return null;
            } finally {
                setGeneratingSlug(false);
            }
        },
        []
    );

    return {
        publishing,
        categories,
        selectedCategories,
        setSelectedCategories,
        postSlug,
        setPostSlug,
        generatingSlug,
        loadCategories,
        publish,
        generateSlug,
    };
}
