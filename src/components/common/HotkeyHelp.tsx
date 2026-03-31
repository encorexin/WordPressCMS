import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Keyboard, FileText, Search, HelpCircle } from "lucide-react";

interface HotkeyHelpProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

interface HotkeyItem {
  keys: string[];
  description: string;
  icon?: React.ReactNode;
}

const globalHotkeys: HotkeyItem[] = [
  {
    keys: ["Ctrl", "K"],
    description: "打开全局搜索",
    icon: <Search className="h-4 w-4" />,
  },
  {
    keys: ["?"],
    description: "显示快捷键帮助",
    icon: <HelpCircle className="h-4 w-4" />,
  },
];

const editorHotkeys: HotkeyItem[] = [
  {
    keys: ["Ctrl", "S"],
    description: "保存文章",
    icon: <FileText className="h-4 w-4" />,
  },
  {
    keys: ["Ctrl", "P"],
    description: "发布文章",
    icon: <FileText className="h-4 w-4" />,
  },
];

function HotkeyRow({ item }: { item: HotkeyItem }) {
  return (
    <div className="flex items-center justify-between py-2">
      <div className="flex items-center gap-3">
        {item.icon && (
          <span className="text-muted-foreground">{item.icon}</span>
        )}
        <span className="text-sm">{item.description}</span>
      </div>
      <div className="flex items-center gap-1">
        {item.keys.map((key, index) => (
          <span key={index} className="flex items-center gap-1">
            <kbd className="inline-flex h-6 select-none items-center justify-center rounded border bg-muted px-2 font-mono text-xs font-medium">
              {key === "Ctrl" ? (
                <>
                  <span className="text-xs">⌘</span>Ctrl
                </>
              ) : (
                key
              )}
            </kbd>
            {index < item.keys.length - 1 && (
              <span className="text-muted-foreground">+</span>
            )}
          </span>
        ))}
      </div>
    </div>
  );
}

export function HotkeyHelp({ open, onOpenChange }: HotkeyHelpProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Keyboard className="h-5 w-5" />
            键盘快捷键
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-4">
          {/* 全局快捷键 */}
          <div>
            <h4 className="text-sm font-medium text-muted-foreground mb-2">
              全局
            </h4>
            <div className="divide-y">
              {globalHotkeys.map((item, index) => (
                <HotkeyRow key={index} item={item} />
              ))}
            </div>
          </div>

          {/* 编辑器快捷键 */}
          <div>
            <h4 className="text-sm font-medium text-muted-foreground mb-2">
              文章编辑
            </h4>
            <div className="divide-y">
              {editorHotkeys.map((item, index) => (
                <HotkeyRow key={index} item={item} />
              ))}
            </div>
          </div>

          {/* 提示 */}
          <div className="text-xs text-muted-foreground bg-muted/50 rounded-lg p-3">
            <p>提示：在输入框中编辑内容时，部分快捷键会被禁用以避免冲突。</p>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
