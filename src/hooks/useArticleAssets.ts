import { useCallback, useEffect, useState } from "react";
import { toast } from "sonner";
import { useAuth } from "@/context/LocalAuthProvider";
import { getTemplates, getUnusedTopics, initDefaultTemplates, markTopicAsUsed, type ArticleTemplate, type Topic } from "@/db/api";
import { handleApiError } from "@/utils/errorHandler";

export function useArticleAssets() {
    const { user } = useAuth();
    const [templates, setTemplates] = useState<ArticleTemplate[]>([]);
    const [topics, setTopics] = useState<Topic[]>([]);
    const [selectedTemplate, setSelectedTemplate] = useState<ArticleTemplate | null>(null);
    const [selectedTopic, setSelectedTopic] = useState<Topic | null>(null);
    const [loading, setLoading] = useState(false);

    const loadTemplates = useCallback(async () => {
        if (!user?.id) return;

        setLoading(true);
        try {
            await initDefaultTemplates(user.id);
            const data = await getTemplates(user.id);
            setTemplates(data);

            if (data.length > 0 && !selectedTemplate) {
                setSelectedTemplate(data[0]);
            }
        } catch (error) {
            handleApiError(error, "加载模板");
        } finally {
            setLoading(false);
        }
    }, [user?.id, selectedTemplate]);

    const loadTopics = useCallback(async () => {
        if (!user?.id) return;

        try {
            const data = await getUnusedTopics(user.id);
            setTopics(data);
        } catch (error) {
            handleApiError(error, "加载主题");
        }
    }, [user?.id]);

    const selectTopic = useCallback((topic: Topic) => {
        setSelectedTopic(topic);
        toast.success(`已选择主题: ${topic.title}`);
    }, []);

    const clearSelectedTopic = useCallback(() => {
        setSelectedTopic(null);
    }, []);

    const useTopic = useCallback(async () => {
        if (selectedTopic && user?.id) {
            await markTopicAsUsed(user.id, selectedTopic.id);
            setSelectedTopic(null);
            await loadTopics();
        }
    }, [selectedTopic, user?.id, loadTopics]);

    useEffect(() => {
        loadTemplates();
        loadTopics();
    }, [loadTemplates, loadTopics]);

    return {
        templates,
        topics,
        selectedTemplate,
        selectedTopic,
        setSelectedTemplate,
        selectTopic,
        clearSelectedTopic,
        useTopic,
        loadTemplates,
        loadTopics,
        loading,
    };
}
