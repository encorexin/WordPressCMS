import { useEffect, useCallback } from "react";

export interface HotkeyConfig {
  key: string;
  ctrl?: boolean;
  shift?: boolean;
  alt?: boolean;
  meta?: boolean;
  handler: (event: KeyboardEvent) => void;
  preventDefault?: boolean;
}

/**
 * 快捷键 Hook - 统一管理键盘快捷键
 */
export function useHotkeys(hotkeys: HotkeyConfig[]) {
  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      for (const hotkey of hotkeys) {
        const keyMatch = event.key.toLowerCase() === hotkey.key.toLowerCase();
        const ctrlMatch = hotkey.ctrl ? event.ctrlKey || event.metaKey : true;
        const shiftMatch = hotkey.shift ? event.shiftKey : true;
        const altMatch = hotkey.alt ? event.altKey : true;
        const metaMatch = hotkey.meta ? event.metaKey : true;

        if (keyMatch && ctrlMatch && shiftMatch && altMatch && metaMatch) {
          // 检查是否在输入框中
          const target = event.target as HTMLElement;
          const isInput =
            target.tagName === "INPUT" ||
            target.tagName === "TEXTAREA" ||
            target.isContentEditable;

          // 如果在输入框中且不是特定快捷键，则忽略
          if (isInput && !hotkey.ctrl && !hotkey.meta) {
            continue;
          }

          if (hotkey.preventDefault !== false) {
            event.preventDefault();
          }

          hotkey.handler(event);
          break;
        }
      }
    },
    [hotkeys]
  );

  useEffect(() => {
    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, [handleKeyDown]);
}

/**
 * 简单的单个快捷键 Hook
 */
export function useHotkey(
  key: string,
  handler: (event: KeyboardEvent) => void,
  options: {
    ctrl?: boolean;
    shift?: boolean;
    alt?: boolean;
    meta?: boolean;
    preventDefault?: boolean;
  } = {}
) {
  const { ctrl, shift, alt, meta, preventDefault = true } = options;

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      const keyMatch = event.key.toLowerCase() === key.toLowerCase();
      const ctrlMatch = ctrl ? event.ctrlKey || event.metaKey : true;
      const shiftMatch = shift ? event.shiftKey : true;
      const altMatch = alt ? event.altKey : true;
      const metaMatch = meta ? event.metaKey : true;

      if (keyMatch && ctrlMatch && shiftMatch && altMatch && metaMatch) {
        if (preventDefault) {
          event.preventDefault();
        }
        handler(event);
      }
    };

    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, [key, handler, ctrl, shift, alt, meta, preventDefault]);
}
