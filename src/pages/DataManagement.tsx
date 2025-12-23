import { useState, useEffect, useRef } from "react";
import { useAuth } from "@/context/LocalAuthProvider";
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
import { toast } from "sonner";
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
} from "lucide-react";
import {
    exportAllData,
    downloadExportFile,
    exportTableData,
    exportToCSV,
    exportArticlesToMarkdown,
    exportTopicsToText,
    exportKeywordsToText,
    readImportFile,
    validateImportData,
    importData,
    getDataStats,
    TABLE_NAMES,
    type ExportData,
} from "@/db/dataExport";
import { db } from "@/db/database";

export default function DataManagement() {
    const { user } = useAuth();
    const fileInputRef = useRef<HTMLInputElement>(null);
    const [loading, setLoading] = useState(true);
    const [exporting, setExporting] = useState(false);
    const [importing, setImporting] = useState(false);
    const [stats, setStats] = useState<Record<string, number>>({});
    const [showImportDialog, setShowImportDialog] = useState(false);
    const [pendingImportData, setPendingImportData] = useState<ExportData | null>(null);

    useEffect(() => {
        loadStats();
    }, []);

    const loadStats = async () => {
        try {
            setLoading(true);
            const data = await getDataStats();
            setStats(data);
        } catch (error) {
            console.error("加载统计失败:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleExport = async () => {
        try {
            setExporting(true);
            const data = await exportAllData();
            downloadExportFile(data);
            toast.success("数据导出成功");
        } catch (error) {
            toast.error("导出失败");
            console.error(error);
        } finally {
            setExporting(false);
        }
    };

    const handleExportTable = async (tableName: string, format: 'json' | 'csv') => {
        try {
            setExporting(true);
            const data = await exportTableData(tableName);

            if (format === 'csv') {
                exportToCSV(data.data, tableName);
            } else {
                downloadExportFile(data);
            }

            toast.success(`${TABLE_NAMES[tableName] || tableName} 导出成功`);
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
            const articles = await db.articles.toArray();
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
            const topics = await db.topics.toArray();
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
            const keywords = await db.keywords.toArray();
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
            const validation = validateImportData(data);

            if (!validation.valid) {
                toast.error(validation.error || "无效的备份文件");
                return;
            }

            setPendingImportData(data);
            setShowImportDialog(true);
        } catch (error) {
            toast.error("无法读取文件");
            console.error(error);
        }

        // 重置文件输入
        if (fileInputRef.current) {
            fileInputRef.current.value = "";
        }
    };

    const handleConfirmImport = async () => {
        if (!pendingImportData) return;

        try {
            setImporting(true);
            setShowImportDialog(false);

            const result = await importData(pendingImportData, { clearExisting: true });

            if (result.success) {
                const items = Object.entries(result.stats)
                    .filter(([_, count]) => count > 0)
                    .map(([key, count]) => `${count} ${TABLE_NAMES[key] || key}`)
                    .join(', ');
                toast.success(`导入成功: ${items}`);
                await loadStats();
            } else {
                toast.error(result.message);
            }
        } catch (error) {
            toast.error("导入失败");
            console.error(error);
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
                                    导出完整备份 (JSON)
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
                            {pendingImportData && (
                                <div className="mt-4 p-3 bg-gray-100 dark:bg-gray-800 rounded-lg text-sm">
                                    <p className="font-medium mb-2">备份文件信息：</p>
                                    <p>导出时间：{new Date(pendingImportData.exportedAt).toLocaleString()}</p>
                                    <p>版本：{pendingImportData.version}</p>
                                    <p className="mt-2">
                                        包含：{pendingImportData.data.users?.length || 0} 用户,{" "}
                                        {pendingImportData.data.articles?.length || 0} 文章,{" "}
                                        {pendingImportData.data.wordpress_sites?.length || 0} 站点,{" "}
                                        {pendingImportData.data.article_templates?.length || 0} 模板,{" "}
                                        {pendingImportData.data.keywords?.length || 0} 关键词,{" "}
                                        {pendingImportData.data.topics?.length || 0} 主题
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
