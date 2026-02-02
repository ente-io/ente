import React, { useEffect, useState } from "react";
import { sendMessage, type ExtensionState } from "@/lib/types/messages";
import Login from "./components/Login";
import Unlock from "./components/Unlock";
import CodeList from "./components/CodeList";
import Button from "./components/Button";

type View = "loading" | "login" | "unlock" | "codes" | "error";

export default function App() {
  const [view, setView] = useState<View>("loading");
  const [email, setEmail] = useState<string | undefined>();
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const applyTheme = (theme: unknown) => {
      const next = theme === "light" ? "light" : "dark";
      document.documentElement.dataset.theme = next;
    };

    chrome.storage.local.get(["popupTheme"], (result) => {
      applyTheme(result.popupTheme);
    });

    const onChanged = (changes: Record<string, chrome.storage.StorageChange>, areaName: string) => {
      if (areaName !== "local") return;
      if (changes.popupTheme) {
        applyTheme(changes.popupTheme.newValue);
      }
    };

    chrome.storage.onChanged.addListener(onChanged);
    return () => chrome.storage.onChanged.removeListener(onChanged);
  }, []);

  useEffect(() => {
    checkState();
  }, []);

  const checkState = async () => {
    try {
      const state = await sendMessage({ type: "GET_STATE" });
      updateView(state);
    } catch (e) {
      console.error("Failed to get state:", e);
      setError(String(e));
      setView("login");
    }
  };

  const updateView = (state: ExtensionState) => {
    setEmail(state.email);
    if (!state.isLoggedIn) {
      setView("login");
    } else if (state.isLocked) {
      setView("unlock");
    } else {
      setView("codes");
    }
  };

  const handleLoginComplete = () => {
    setView("codes");
  };

  const handleUnlock = () => {
    setView("codes");
  };

  const handleLock = async () => {
    await sendMessage({ type: "LOCK" });
    setView("unlock");
  };

  const handleLogout = async () => {
    await sendMessage({ type: "LOGOUT" });
    setView("login");
    setEmail(undefined);
  };

  if (view === "loading") {
    return (
      <div className="flex items-center justify-center min-h-[400px] bg-[var(--ente-background)]">
        <div className="text-[var(--ente-text)]">Loading...</div>
      </div>
    );
  }

  if (view === "error") {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] bg-[var(--ente-background)] p-4">
        <div className="text-red-400 mb-4">Something went wrong</div>
        <div className="text-[var(--ente-text-faint)] text-sm mb-4">{error}</div>
        <Button onClick={() => window.location.reload()} variant="primary">
          Reload
        </Button>
      </div>
    );
  }

  if (view === "login") {
    return <Login onComplete={handleLoginComplete} />;
  }

  if (view === "unlock") {
    return <Unlock email={email} onUnlock={handleUnlock} onLogout={handleLogout} />;
  }

  return <CodeList email={email} onLock={handleLock} onLogout={handleLogout} />;
}
