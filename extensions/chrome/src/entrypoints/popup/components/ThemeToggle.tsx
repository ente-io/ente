import React, { useEffect, useState } from "react";
import { HugeIcon, hugeSun01 } from "@/lib/ui/hugeicons";

export default function ThemeToggle() {
  const [theme, setTheme] = useState<"dark" | "light">(
    (document.documentElement.dataset.theme as "dark" | "light") || "dark",
  );

  useEffect(() => {
    chrome.storage.local.get(["popupTheme"], (result) => {
      setTheme(result.popupTheme === "light" ? "light" : "dark");
    });

    const onChanged = (changes: Record<string, chrome.storage.StorageChange>, areaName: string) => {
      if (areaName !== "local") return;
      if (changes.popupTheme) {
        setTheme(changes.popupTheme.newValue === "light" ? "light" : "dark");
      }
    };

    chrome.storage.onChanged.addListener(onChanged);
    return () => chrome.storage.onChanged.removeListener(onChanged);
  }, []);

  const toggle = () => {
    const next = theme === "light" ? "dark" : "light";
    chrome.storage.local.set({ popupTheme: next }, () => {});
    setTheme(next);
  };

  return (
    <button
      type="button"
      onClick={toggle}
      className="p-2 rounded-md text-[var(--ente-text-muted)] hover:text-[var(--ente-text)] hover:bg-[var(--ente-hover)] transition-colors"
      title={theme === "light" ? "Switch to dark theme" : "Switch to light theme"}
      aria-label="Toggle theme"
    >
      {/* Use a consistent icon in both themes (matches light-mode icon). */}
      <HugeIcon icon={hugeSun01} size={18} />
    </button>
  );
}
