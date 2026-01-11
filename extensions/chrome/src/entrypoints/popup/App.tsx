import React, { useEffect, useState } from "react";
import { sendMessage, type ExtensionState } from "@/lib/types/messages";
import Login from "./components/Login";
import Unlock from "./components/Unlock";
import CodeList from "./components/CodeList";

type View = "loading" | "login" | "unlock" | "codes" | "error";

export default function App() {
  const [view, setView] = useState<View>("loading");
  const [email, setEmail] = useState<string | undefined>();
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    console.log("App mounted, checking state...");
    checkState();
  }, []);

  const checkState = async () => {
    try {
      console.log("Fetching extension state...");
      const state = await sendMessage({ type: "GET_STATE" });
      console.log("Got state:", state);
      updateView(state);
    } catch (e) {
      console.error("Failed to get state:", e);
      setError(String(e));
      setView("login");
    }
  };

  const updateView = (state: ExtensionState) => {
    console.log("Updating view based on state:", state);
    setEmail(state.email);
    if (!state.isLoggedIn) {
      console.log("Setting view to login");
      setView("login");
    } else if (state.isLocked) {
      console.log("Setting view to unlock");
      setView("unlock");
    } else {
      console.log("Setting view to codes");
      setView("codes");
    }
  };

  const handleLoginComplete = () => {
    console.log("Login complete, switching to codes view");
    setView("codes");
  };

  const handleUnlock = () => {
    console.log("Unlock complete, switching to codes view");
    setView("codes");
  };

  const handleLock = async () => {
    console.log("Locking extension...");
    await sendMessage({ type: "LOCK" });
    setView("unlock");
  };

  const handleLogout = async () => {
    console.log("Logging out...");
    await sendMessage({ type: "LOGOUT" });
    setView("login");
    setEmail(undefined);
  };

  console.log("Rendering App with view:", view);

  if (view === "loading") {
    return (
      <div className="flex items-center justify-center min-h-[400px] bg-gray-900">
        <div className="text-white">Loading...</div>
      </div>
    );
  }

  if (view === "error") {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] bg-gray-900 p-4">
        <div className="text-red-400 mb-4">Something went wrong</div>
        <div className="text-gray-500 text-sm mb-4">{error}</div>
        <button
          onClick={() => window.location.reload()}
          className="px-4 py-2 bg-[#8F33D6] text-white rounded-lg"
        >
          Reload
        </button>
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
