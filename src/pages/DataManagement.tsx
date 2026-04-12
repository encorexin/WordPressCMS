import { useState, useEffect, useRef } from "react";
import { Button } from "@/components/ui/button";
import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
} from "@/components/ui/card";
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";
import { toast } from "sonner";
import { logger } from "@/utils/logger";
import {
    Download,
    Upload,
    Database,
    Loader2,
    FileJson,
    AlertTriangle,
    HardDrive,
    FileText,
    FileSpreadsheet,
    ChevronDown,
    Lightbulb,
    Tags,
    FileCode,
    Settings,
    Lock,
} from "lucide-react";
import {
    exportAllData,
    downloadExportFile,
    exportTableData,
    exportEncryptedTableData,
    exportToCSV,
    exportArticlesToMarkdown,
    exportTopicsToText,
    exportKeywordsToText,
    exportAISettingsToJSON,
    exportAISettingsFull,
    readImportFile,
    validateImportData,
    importData,
    getDataStats,
    TABLE_NAMES,
    type ExportData,
    type ExportDataPlain,
    type ExportTableName,
} from "@/db/dataExport";
import { useAuth } from "@/context/LocalAuthProvider";
import { hasEncryptionKey } from "@/db/encryptedDatabase";

export default function DataManagement() {
    const { user, isDecrypted } = useAuth();
    const fileInputRef = useRef<HTMLInputElement>(null);
    const [loading, setLoading] = useState(true);
    const [exporting, setExporting] = useState(false);
    const [importing, setImporting] = useState(false);
    const [stats, setStats] = useState<Record<string, number>>({});
    const [showImportDialog, setShowImportDialog] = useState(false);
    const [pendingImportData, setPendingImportData] = useState<ExportData | null>(null);
    const [encryptExport, setEncryptExport] = useState(true); // 默认加密导出

    const isExportDataPlain = (data: unknown): data is ExportDataPlain => {
        if (!data || typeof data !== "object") return false;
        return (
            "users" in data &&
            "articles" in data &&
            "wordpress_sites" in data &&
            "article_templates" in data &&
            "keywords" in data &&
            "topics" in data
        );
    };

    useEffect(() => {
        loadStats();
    }, []);

    const loadStats = async () => {
        try {
            setLoading(true);
            const data = await getDataStats();
            setStats(data);
        } catch (error) {
            logger.error("加载统计失败:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleExport = async () => {
        if (!user?.id) {
            toast.error("请先登录");
            return;
        }

        // 如果选择加密导出，检查是否已解密
        if (encryptExport && (!isDecrypted || !hasEncryptionKey())) {
            toast.error("数据未解密，请重新登录后再导出加密数据");
            return;
        }

        try {
            setExporting(true);
            const data = await exportAllData(user.id, encryptExport);
            downloadExportFile(data);
            toast.success(data.encrypted ? "加密数据导出成功" : "数据导出成功");
        } catch (error) {
            toast.error("导出失败: " + (error instanceof Error ? error.message : '未知错误'));
            logger.error("数据导出失败:", error);
        } finally {
            setExporting(false);
        }
    };

    const handleExportTable = async <K extends ExportTableName>(
        tableName: K,
        format: 'json' | 'csv',
        encrypted: boolean = false
    ) => {
        try {
            setExporting(true);

            if (encrypted) {
                // 加密导出
                const data = await exportEncryptedTableData(tableName, user?.id);
                downloadExportFile(data);
                toast.success(`${TABLE_NAMES[tableName] || tableName} 加密导出成功`);
            } else {
                // 明文导出
                const data = await exportTableData(tableName, user?.id);
                if (format === 'csv') {
                    exportToCSV<Record<string, unknown>>(data.data as unknown as Record<string, unknown>[], tableName);
                } else {
                    downloadExportFile(data);
                }
                toast.success(`${TABLE_NAMES[tableName] || tableName} 导出成功`);
            }
        } catch (error) {
            const message = error instanceof Error ? error.message : '导出失败';
            toast.error(message);
        } finally {
            setExporting(false);
        }
    };

    const handleExportArticlesMarkdown = async () => {
        try {
            setExporting(true);
            const { data: articles } = await exportTableData('articles', user?.id);
            exportArticlesToMarkdown(articles);
            toast.success("文章导出为 Markdown 成功");
        } catch (error) {
            const message = error instanceof Error ? error.message : '导出失败';
            toast.error(message);
        } finally {
            setExporting(false);
        }
    };

    const handleExportTopicsText = async () => {
        try {
            setExporting(true);
            const { data: topics } = await exportTableData('topics', user?.id);
            exportTopicsToText(topics);
            toast.success("主题导出成功");
        } catch (error) {
            const message = error instanceof Error ? error.message : '导出失败';
            toast.error(message);
        } finally {
            setExporting(false);
        }
    };

    const handleExportKeywordsText = async () => {
        try {
            setExporting(true);
            const { data: keywords } = await exportTableData('keywords', user?.id);
            exportKeywordsToText(keywords);
            toast.success("关键词导出成功");
        } catch (error) {
            const message = error instanceof Error ? error.message : '导出失败';
            toast.error(message);
        } finally {
            setExporting(false);
        }
    };

    const handleImportClick = () => {
        fileInputRef.current?.click();
    };

    const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        try {
            const data = await readImportFile(file);
            const isValid = validateImportData(data);

            if (!isValid) {
                toast.error("无效的备份文件格式");
                return;
            }

            setPendingImportData(data);
            setShowImportDialog(true);
        } catch (error) {
            toast.error("无法读取文件");
            logger.error("读取导入文件失败:", error);
        }

        // 重置文件输入
        if (fileInputRef.current) {
            fileInputRef.current.value = "";
        }
    };

    const handleConfirmImport = async () => {
        if (!pendingImportData) return;
        if (!user?.id) {
            toast.error("请先登录");
            return;
        }

        try {
            setImporting(true);
            setShowImportDialog(false);

            const result = await importData(pendingImportData, user.id, { overwrite: true });

            if (result.success) {
                if (pendingImportData.encrypted) {
                    toast.success("加密数据导入成功");
                } else {
                    toast.success(`导入成功: ${result.imported} 条数据`);
                }
                await loadStats();
            } else {
                toast.error(result.errors.join(', '));
            }
        } catch (error) {
            toast.error("导入失败");
            logger.error("数据导入失败:", error);
        } finally {
            setImporting(false);
            setPendingImportData(null);
        }
    };

    const statItems = [
        { key: "users", label: "用户", icon: Database },
        { key: "wordpress_sites", label: "站点", icon: HardDrive },
        { key: "articles", label: "文章", icon: FileJson },
        { key: "article_templates", label: "模板", icon: FileCode },
        { key: "keywords", label: "关键词", icon: Tags },
        { key: "topics", label: "主题", icon: Lightbulb },
    ];

    return (
        <div className="container mx-auto p-4 sm:p-6 lg:p-8 max-w-3xl space-y-6">
            {/* 数据统计 */}
            <Card className="border-0 shadow-lg">
                <CardHeader className="pb-4">
                    <div className="flex items-center space-x-3">
                        <div className="p-2 bg-gradient-to-br from-green-500 to-emerald-500 rounded-lg">
                            <Database className="h-5 w-5 text-white" />
                        </div>
                        <div>
                            <CardTitle className="text-xl">数据管理</CardTitle>
                            <CardDescription>备份和恢复您的数据</CardDescription>
                        </div>
                    </div>
                </CardHeader>
                <CardContent>
                    {loading ? (
                        <div className="flex justify-center py-8">
                            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                        </div>
                    ) : (
                        <div className="grid grid-cols-3 sm:grid-cols-6 gap-3 mb-6">
                            {statItems.map((item) => {
                                const Icon = item.icon;
                                return (
                                    <div
                                        key={item.key}
                                        className="p-3 rounded-lg bg-gray-50 dark:bg-gray-800/50 text-center"
                                    >
                                        <Icon className="h-4 w-4 mx-auto mb-1 text-muted-foreground" />
                                        <div className="text-xl font-bold">{stats[item.key] || 0}</div>
                                        <div className="text-xs text-muted-foreground">{item.label}</div>
                                    </div>
                                );
                            })}
                        </div>
                    )}

                    <div className="space-y-3">
                        {/* 加密选项开关 */}
                        <div className="flex items-center justify-between p-3 rounded-lg bg-gray-50 dark:bg-gray-800/50">
                            <div className="flex items-center gap-2">
                                <Lock className="h-4 w-4 text-muted-foreground" />
                                <Label htmlFor="encrypt-export" className="text-sm cursor-pointer">
                                    加密导出
                                </Label>
                            </div>
                            <Switch
                                id="encrypt-export"
                                checked={encryptExport}
                                onCheckedChange={setEncryptExport}
                                disabled={!isDecrypted}
                            />
                        </div>

                        {/* 完整备份 */}
                        <Button
                            onClick={handleExport}
                            className="w-full bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600"
                            disabled={exporting || importing}
                            size="lg"
                        >
                            {exporting ? (
                                <>
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                    导出中...
                                </>
                            ) : (
                                <>
                                    <Download className="mr-2 h-4 w-4" />
                                    {encryptExport ? '导出加密完整备份' : '导出完整备份 (JSON)'}
                                </>
                            )}
                        </Button>

                        {/* 分类导出 */}
                        <div className="grid grid-cols-2 gap-3">
                            {/* 文章导出 */}
                            <DropdownMenu>
                                <DropdownMenuTrigger asChild>
                                    <Button variant="outline" className="w-full" disabled={exporting}>
                                        <FileText className="mr-2 h-4 w-4" />
                                        导出文章
                                        <ChevronDown className="ml-auto h-4 w-4" />
                                    </Button>
                                </DropdownMenuTrigger>
                                <DropdownMenuContent>
                                    <DropdownMenuLabel>选择格式</DropdownMenuLabel>
                                    <DropdownMenuSeparator />
                                    <DropdownMenuItem onClick={() => handleExportTable('articles', 'json')}>
                                        <FileJson className="mr-2 h-4 w-4" />
                                        JSON 格式
                                    </DropdownMenuItem>
                                    <DropdownMenuItem onClick={() => handleExportTable('articles', 'csv')}>
                                        <FileSpreadsheet className="mr-2 h-4 w-4" />
                                        CSV 格式
                                    </DropdownMenuItem>
                                    <DropdownMenuItem onClick={handleExportArticlesMarkdown}>
                                        <FileText className="mr-2 h-4 w-4" />
                                        Markdown 格式
                                    </DropdownMenuItem>
                                    {isDecrypted && (
                                        <>
                                            <DropdownMenuSeparator />
                                            <DropdownMenuItem onClick={() => handleExportTable('articles', 'json', true)}>
                                                <Lock className="mr-2 h-4 w-4" />
                                                加密 JSON 格式
                                            </DropdownMenuItem>
                                        </>
                                    )}
                                </DropdownMenuContent>
                            </DropdownMenu>

                            {/* 主题导出 */}
                            <DropdownMenu>
                                <DropdownMenuTrigger asChild>
                                    <Button variant="outline" className="w-full" disabled={exporting}>
                                        <Lightbulb className="mr-2 h-4 w-4" />
                                        导出主题
                                        <ChevronDown className="ml-auto h-4 w-4" />
                                    </Button>
                                </DropdownMenuTrigger>
                                <DropdownMenuContent>
                                    <DropdownMenuLabel>选择格式</DropdownMenuLabel>
                                    <DropdownMenuSeparator />
                                    <DropdownMenuItem onClick={() => handleExportTable('topics', 'json')}>
                                        <FileJson className="mr-2 h-4 w-4" />
                                        JSON 格式
                                    </DropdownMenuItem>
                                    <DropdownMenuItem onClick={() => handleExportTable('topics', 'csv')}>
                                        <FileSpreadsheet className="mr-2 h-4 w-4" />
                                        CSV 格式
                                    </DropdownMenuItem>
                                    <DropdownMenuItem onClick={handleExportTopicsText}>
                                        <FileText className="mr-2 h-4 w-4" />
                                        文本格式
                                    </DropdownMenuItem>
                                </DropdownMenuContent>
                            </DropdownMenu>

                            {/* 关键词导出 */}
                            <DropdownMenu>
                                <DropdownMenuTrigger asChild>
                                    <Button variant="outline" className="w-full" disabled={exporting}>
                                        <Tags className="mr-2 h-4 w-4" />
                                        导出关键词
                                        <ChevronDown className="ml-auto h-4 w-4" />
                                    </Button>
                                </DropdownMenuTrigger>
                                <DropdownMenuContent>
                                    <DropdownMenuLabel>选择格式</DropdownMenuLabel>
                                    <DropdownMenuSeparator />
                                    <DropdownMenuItem onClick={() => handleExportTable('keywords', 'json')}>
                                        <FileJson className="mr-2 h-4 w-4" />
                                        JSON 格式
                                    </DropdownMenuItem>
                                    <DropdownMenuItem onClick={() => handleExportTable('keywords', 'csv')}>
                                        <FileSpreadsheet className="mr-2 h-4 w-4" />
                                        CSV 格式
                                    </DropdownMenuItem>
                                    <DropdownMenuItem onClick={handleExportKeywordsText}>
                                        <FileText className="mr-2 h-4 w-4" />
                                        文本格式
                                    </DropdownMenuItem>
                                </DropdownMenuContent>
                            </DropdownMenu>

                            {/* 模板导出 */}
                            <DropdownMenu>
                                <DropdownMenuTrigger asChild>
                                    <Button variant="outline" className="w-full" disabled={exporting}>
                                        <FileCode className="mr-2 h-4 w-4" />
                                        导出模板
                                        <ChevronDown className="ml-auto h-4 w-4" />
                                    </Button>
                                </DropdownMenuTrigger>
                                <DropdownMenuContent>
                                    <DropdownMenuLabel>选择格式</DropdownMenuLabel>
                                    <DropdownMenuSeparator />
                                    <DropdownMenuItem onClick={() => handleExportTable('article_templates', 'json')}>
                                        <FileJson className="mr-2 h-4 w-4" />
                                        JSON 格式
                                    </DropdownMenuItem>
                                    <DropdownMenuItem onClick={() => handleExportTable('article_templates', 'csv')}>
                                        <FileSpreadsheet className="mr-2 h-4 w-4" />
                                        CSV 格式
                                    </DropdownMenuItem>
                                </DropdownMenuContent>
                            </DropdownMenu>

                            {/* AI设置导出 */}
                            <DropdownMenu>
                                <DropdownMenuTrigger asChild>
                                    <Button variant="outline" className="w-full" disabled={exporting}>
                                        <Settings className="mr-2 h-4 w-4" />
                                        导出 AI 设置
                                        <ChevronDown className="ml-auto h-4 w-4" />
                                    </Button>
                                </DropdownMenuTrigger>
                                <DropdownMenuContent>
                                    <DropdownMenuLabel>选择格式</DropdownMenuLabel>
                                    <DropdownMenuSeparator />
                                    <DropdownMenuItem onClick={async () => {
                                        try {
                                            setExporting(true);
                                            await exportAISettingsToJSON();
                                            toast.success("AI 设置已导出（API Key 已隐藏）");
                                        } catch (error) {
                                            toast.error("导出失败");
                                        } finally {
                                            setExporting(false);
                                        }
                                    }}>
                                        <FileJson className="mr-2 h-4 w-4" />
                                        安全导出（隐藏 Key）
                                    </DropdownMenuItem>
                                    <DropdownMenuItem onClick={async () => {
                                        try {
                                            setExporting(true);
                                            await exportAISettingsFull();
                                            toast.success("AI 设置已完整导出（含 API Key）");
                                        } catch (error) {
                                            toast.error("导出失败");
                                        } finally {
                                            setExporting(false);
                                        }
                                    }}>
                                        <Download className="mr-2 h-4 w-4" />
                                        完整导出（含 API Key）
                                    </DropdownMenuItem>
                                </DropdownMenuContent>
                            </DropdownMenu>
                        </div>

                        {/* 导入按钮 */}
                        <Button
                            onClick={handleImportClick}
                            variant="outline"
                            className="w-full"
                            disabled={exporting || importing}
                            size="lg"
                        >
                            {importing ? (
                                <>
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                    导入中...
                                </>
                            ) : (
                                <>
                                    <Upload className="mr-2 h-4 w-4" />
                                    从备份文件恢复
                                </>
                            )}
                        </Button>

                        <input
                            type="file"
                            ref={fileInputRef}
                            onChange={handleFileSelect}
                            accept=".json"
                            className="hidden"
                        />
                    </div>
                </CardContent>
            </Card>

            {/* 提示信息 */}
            <div className="bg-amber-50 dark:bg-amber-950/30 p-4 rounded-lg">
                <div className="flex items-start space-x-2">
                    <AlertTriangle className="h-5 w-5 text-amber-500 mt-0.5 flex-shrink-0" />
                    <div className="text-sm text-amber-700 dark:text-amber-300">
                        <p className="font-medium mb-1">重要提示</p>
                        <ul className="list-disc list-inside text-amber-600 dark:text-amber-400 space-y-1">
                            <li>导入数据会覆盖现有所有数据</li>
                            <li>建议在导入前先导出当前数据作为备份</li>
                            <li>支持导出为 JSON、CSV、Markdown、文本等格式</li>
                            <li>定期导出数据可防止意外丢失</li>
                        </ul>
                    </div>
                </div>
            </div>

            {/* 导入确认对话框 */}
            <AlertDialog open={showImportDialog} onOpenChange={setShowImportDialog}>
                <AlertDialogContent>
                    <AlertDialogHeader>
                        <AlertDialogTitle>确认导入数据</AlertDialogTitle>
                        <AlertDialogDescription>
                            导入将会覆盖现有的所有数据。此操作无法撤销。
                            {pendingImportData && !pendingImportData.encrypted && isExportDataPlain(pendingImportData.data) && (
                                <div className="mt-4 p-3 bg-gray-100 dark:bg-gray-800 rounded-lg text-sm">
                                    <p className="font-medium mb-2">备份文件信息：</p>
                                    <p>导出时间：{new Date(pendingImportData.exportedAt).toLocaleString()}</p>
                                    <p>版本：{pendingImportData.version}</p>
                                    <p className="mt-2">
                                        包含：{pendingImportData.data.users.length} 用户,{" "}
                                        {pendingImportData.data.articles.length} 文章,{" "}
                                        {pendingImportData.data.wordpress_sites.length} 站点,{" "}
                                        {pendingImportData.data.article_templates.length} 模板,{" "}
                                        {pendingImportData.data.keywords.length} 关键词,{" "}
                                        {pendingImportData.data.topics.length} 主题
                                    </p>
                                </div>
                            )}
                        </AlertDialogDescription>
                    </AlertDialogHeader>
                    <AlertDialogFooter>
                        <AlertDialogCancel>取消</AlertDialogCancel>
                        <AlertDialogAction
                            onClick={handleConfirmImport}
                            className="bg-red-500 hover:bg-red-600"
                        >
                            确认导入
                        </AlertDialogAction>
                    </AlertDialogFooter>
                </AlertDialogContent>
            </AlertDialog>
        </div>
    );
}
