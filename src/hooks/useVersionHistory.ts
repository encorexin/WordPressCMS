import { useCallback, useState } from "react";
import { getArticleVersions, type ArticleVersion } from "@/db/versionService";
import { handleApiError } from "@/utils/errorHandler";

export interface UseVersionHistoryOptions {
    articleId?: string;
    userId?: string;
    onRestore?: (version: ArticleVersion) => void;
}

export function useVersionHistory(options: UseVersionHistoryOptions) {
    const [versions, setVersions] = useState<ArticleVersion[]>([]);
    const [showDialog, setShowDialog] = useState(false);
    const [loading, setLoading] = useState(false);

    const loadVersions = useCallback(async () => {
        if (!options.articleId || !options.userId) return;

        setLoading(true);
        try {
            const data = await getArticleVersions(options.userId, options.articleId);
            setVersions(data.sort((a, b) => b.version_number - a.version_number));
        } catch (error) {
            handleApiError(error, "加载版本历史");
        } finally {
            setLoading(false);
        }
    }, [options.articleId, options.userId]);

    const openDialog = useCallback(async () => {
        setShowDialog(true);
        await loadVersions();
    }, [loadVersions]);

    const closeDialog = useCallback(() => {
        setShowDialog(false);
    }, []);

    const restore = useCallback(
        (version: ArticleVersion) => {
            options.onRestore?.(version);
            setShowDialog(false);
        },
        [options]
    );

    return {
        versions,
        showDialog,
        loading,
        openDialog,
        closeDialog,
        restore,
        loadVersions,
    };
}
