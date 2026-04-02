import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import {
  CommandDialog,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
  CommandSeparator,
} from "@/components/ui/command";
import {
  FileText,
  Tag,
  Layout,
  Lightbulb,
  Search,
  Loader2,
} from "lucide-react";
import { useAuth } from "@/context/LocalAuthProvider";
import { globalSearch, getSearchTypeInfo, type SearchResult } from "@/db/search";
import { useDebounce } from "@/hooks/use-debounce";
import { logger } from "@/utils/logger";

// 图标映射
const iconMap = {
  FileText,
  Tag,
  Layout,
  Lightbulb,
};

interface GlobalSearchProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

export function GlobalSearch({ open, onOpenChange }: GlobalSearchProps) {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<SearchResult[]>([]);
  const [loading, setLoading] = useState(false);

  const debouncedQuery = useDebounce(query, 200);

  // 执行搜索
  const performSearch = useCallback(
    async (searchQuery: string) => {
      if (!searchQuery.trim()) {
        setResults([]);
        return;
      }

      setLoading(true);
      try {
        const searchResults = await globalSearch(searchQuery, {
          userId: user?.id,
          limit: 20,
        });
        setResults(searchResults);
      } catch (error) {
        logger.error("搜索失败:", error);
        setResults([]);
      } finally {
        setLoading(false);
      }
    },
    [user?.id]
  );

  // 监听搜索词变化
  useEffect(() => {
    performSearch(debouncedQuery);
  }, [debouncedQuery, performSearch]);

  // 关闭时重置
  useEffect(() => {
    if (!open) {
      setQuery("");
      setResults([]);
    }
  }, [open]);

  // 处理选择
  const handleSelect = useCallback(
    (result: SearchResult) => {
      navigate(result.path);
      onOpenChange(false);
    },
    [navigate, onOpenChange]
  );

  // 按类型分组结果
  const groupedResults = results.reduce(
    (acc, result) => {
      if (!acc[result.type]) {
        acc[result.type] = [];
      }
      acc[result.type].push(result);
      return acc;
    },
    {} as Record<string, SearchResult[]>
  );

  // 类型排序
  const typeOrder: SearchResult["type"][] = [
    "article",
    "keyword",
    "template",
    "topic",
  ];

  return (
    <CommandDialog open={open} onOpenChange={onOpenChange} title="全局搜索" description="搜索文章、关键词、模板、主题">
      <CommandInput
        placeholder="搜索文章、关键词、模板、主题..."
        value={query}
        onValueChange={setQuery}
      />
      <CommandList>
        {loading && (
          <div className="py-6 text-center text-muted-foreground">
            <Loader2 className="h-5 w-5 animate-spin mx-auto mb-2" />
            <span className="text-sm">搜索中...</span>
          </div>
        )}

        {!loading && query.trim() && results.length === 0 && (
          <CommandEmpty className="py-6 text-center">
            <Search className="h-8 w-8 mx-auto mb-2 text-muted-foreground/50" />
            <p className="text-sm text-muted-foreground">
              未找到与 &quot;{query}&quot; 相关的内容
            </p>
            <p className="text-xs text-muted-foreground/70 mt-1">
              试试搜索文章标题、关键词或模板名称
            </p>
          </CommandEmpty>
        )}

        {!loading &&
          typeOrder.map((type, index) => {
            const items = groupedResults[type];
            if (!items || items.length === 0) return null;

            const typeInfo = getSearchTypeInfo(type);
            const Icon = iconMap[typeInfo.icon as keyof typeof iconMap];

            return (
              <div key={type}>
                {index > 0 && <CommandSeparator />}
                <CommandGroup
                  heading={
                    <div className="flex items-center gap-2 px-1">
                      <Icon className="h-3.5 w-3.5" />
                      <span>{typeInfo.label}</span>
                      <span className="text-xs text-muted-foreground">
                        ({items.length})
                      </span>
                    </div>
                  }
                >
                  {items.map((item) => (
                    <CommandItem
                      key={item.id}
                      value={`${type}-${item.id}`}
                      onSelect={() => handleSelect(item)}
                      className="cursor-pointer"
                    >
                      <div className="flex items-start gap-3 w-full min-w-0">
                        <div
                          className={`flex-shrink-0 w-6 h-6 rounded flex items-center justify-center ${typeInfo.bgColor}`}
                        >
                          <Icon className={`h-3.5 w-3.5 ${typeInfo.color}`} />
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium truncate">
                            {item.title}
                          </p>
                          {item.subtitle && (
                            <p className="text-xs text-muted-foreground truncate">
                              {item.subtitle}
                            </p>
                          )}
                        </div>
                      </div>
                    </CommandItem>
                  ))}
                </CommandGroup>
              </div>
            );
          })}

        {!query.trim() && !loading && (
          <div className="py-8 text-center text-muted-foreground">
            <Search className="h-10 w-10 mx-auto mb-3 opacity-30" />
            <p className="text-sm">输入关键词开始搜索</p>
            <div className="flex items-center justify-center gap-2 mt-4 text-xs">
              <kbd className="px-1.5 py-0.5 rounded bg-muted border">
                ↑↓
              </kbd>
              <span>选择</span>
              <kbd className="px-1.5 py-0.5 rounded bg-muted border ml-2">
                ↵
              </kbd>
              <span>确认</span>
              <kbd className="px-1.5 py-0.5 rounded bg-muted border ml-2">
                Esc
              </kbd>
              <span>关闭</span>
            </div>
          </div>
        )}
      </CommandList>
    </CommandDialog>
  );
}
