import { useCallback, useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { useNavigate, useParams } from "react-router-dom";
import { toast } from "sonner";
import { useAuth } from "@/context/LocalAuthProvider";
import { getArticle, getWordPressSites, updateArticle, createArticle, createArticleVersion } from "@/db/api";
import type { ArticleInput, WordPressSite } from "@/types/types";
import { handleApiError, tryCatchAsync } from "@/utils/errorHandler";
import { aiLogger } from "@/utils/logger";

export interface ArticleFormData extends ArticleInput {
    site_id: string;
}

export function useArticleForm() {
    const { user } = useAuth();
    const navigate = useNavigate();
    const { id } = useParams();
    const isNew = id === "new";

    const [loading, setLoading] = useState(!isNew);
    const [sites, setSites] = useState<WordPressSite[]>([]);
    const [wpPostId, setWpPostId] = useState<string | null>(null);

    const form = useForm<ArticleFormData>({
        defaultValues: {
            title: "",
            content: "",
            keywords: "",
            template: "",
            site_id: "",
        },
    });

    const loadSites = useCallback(async () => {
        if (!user?.id) return;

        const result = await tryCatchAsync(
            () => getWordPressSites(user.id),
            "加载站点"
        );

        if (result.success) {
            setSites(result.data);
        }
    }, [user?.id]);

    const loadArticle = useCallback(
        async (articleId: string) => {
            if (!user?.id) return;

            setLoading(true);
            const result = await tryCatchAsync(
                () => getArticle(user.id, articleId),
                "加载文章"
            );

            if (result.success && result.data) {
                form.reset({
                    title: result.data.title,
                    content: result.data.content || "",
                    keywords: result.data.keywords || "",
                    template: result.data.template || "默认模板",
                    site_id: result.data.site_id || "",
                });

                if (result.data.wordpress_post_id) {
                    setWpPostId(result.data.wordpress_post_id);
                }
            }

            setLoading(false);
        },
        [user?.id, form]
    );

    const saveArticle = useCallback(
        async (data: ArticleFormData) => {
            if (!user?.id) {
                toast.error("用户未登录");
                return false;
            }

            try {
                if (isNew) {
                    await createArticle(user.id, data);
                    toast.success("文章创建成功");
                } else if (id) {
                    await createArticleVersion(id, user.id, {
                        title: data.title,
                        content: data.content || null,
                        keywords: data.keywords || null,
                        template: data.template || null,
                    });
                    await updateArticle(user.id, id, data);
                    toast.success("文章保存成功，已创建版本历史");
                }
                return true;
            } catch (error) {
                handleApiError(error, "保存文章");
                return false;
            }
        },
        [user?.id, isNew, id]
    );

    const handleSave = useCallback(
        async (data: ArticleFormData) => {
            const success = await saveArticle(data);
            if (success) {
                navigate("/articles");
            }
        },
        [saveArticle, navigate]
    );

    useEffect(() => {
        loadSites();
        if (!isNew && id) {
            loadArticle(id);
        }
    }, [id, isNew, loadSites, loadArticle]);

    return {
        form,
        loading,
        sites,
        wpPostId,
        setWpPostId,
        isNew,
        articleId: id,
        handleSave,
        saveArticle,
        loadSites,
    };
}
