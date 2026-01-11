import React, { useEffect, useState, useCallback } from "react";
import { sendMessage } from "@/lib/types/messages";
import type { Code } from "@/lib/types/code";
import CodeItem from "./CodeItem";
import SearchBar from "./SearchBar";

interface Props {
  email?: string;
  onLock: () => void;
  onLogout: () => void;
}

export default function CodeList({ email, onLock, onLogout }: Props) {
  const [codes, setCodes] = useState<Code[]>([]);
  const [filteredCodes, setFilteredCodes] = useState<Code[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [showMenu, setShowMenu] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  const loadCodes = useCallback(async () => {
    console.log("CodeList: Loading codes...");
    try {
      const result = await sendMessage({ type: "GET_CODES" });
      console.log("CodeList: Got", result.codes?.length || 0, "codes");
      setCodes(result.codes || []);
    } catch (e) {
      console.error("CodeList: Failed to load codes:", e);
      setCodes([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadCodes();
  }, [loadCodes]);

  useEffect(() => {
    if (!searchQuery.trim()) {
      setFilteredCodes(codes);
      return;
    }

    const q = searchQuery.toLowerCase();
    const filtered = codes.filter((code) => {
      const issuer = code.issuer?.toLowerCase() ?? "";
      const account = code.account?.toLowerCase() ?? "";
      const note = code.codeDisplay?.note?.toLowerCase() ?? "";
      return issuer.includes(q) || account.includes(q) || note.includes(q);
    });
    setFilteredCodes(filtered);
  }, [codes, searchQuery]);

  const handleSync = async () => {
    setSyncing(true);
    try {
      await sendMessage({ type: "SYNC" });
      await loadCodes();
    } catch (e) {
      console.error("Sync failed:", e);
    } finally {
      setSyncing(false);
    }
  };

  const handleCopy = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setToast("Copied to clipboard");
      setTimeout(() => setToast(null), 2000);
    } catch (e) {
      // Fallback to background script
      await sendMessage({ type: "COPY_TO_CLIPBOARD", text });
      setToast("Copied to clipboard");
      setTimeout(() => setToast(null), 2000);
    }
  };

  if (loading) {
    return (
      <div className="min-h-[400px] bg-gray-900 text-white flex items-center justify-center">
        <div className="text-gray-400">Loading codes...</div>
      </div>
    );
  }

  return (
    <div className="min-h-[400px] max-h-[600px] bg-gray-900 text-white flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between p-3 border-b border-gray-800">
        <div className="flex flex-col">
          <div className="flex items-center gap-2">
            <svg width="40" height="14" viewBox="0 0 53 18" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M47.7422 4.68917C50.2884 4.68917 52.4566 6.50434 52.4566 9.90777V17.6474H48.675V10.4624C48.675 8.89934 47.6918 8.16824 46.4816 8.16824C45.0951 8.16824 44.1371 8.97497 44.1371 10.7649V17.6474H40.3555V0H44.1371V6.22702C44.8177 5.29423 46.0783 4.68917 47.7422 4.68917Z" fill="#8F33D6"/>
              <path d="M38.9733 8.67213H36.3766V13.1344C36.3766 14.2185 37.3094 14.3193 38.9733 14.2185V17.6471C34.032 18.1513 32.595 16.6639 32.595 13.1344V8.67213H30.5781V5.0418H32.595V1.71191L36.3766 1.71261V5.0418H38.9733V8.67213Z" fill="#8F33D6"/>
              <path d="M25.7883 5.04199H29.5698V17.6473H25.7883V16.4624C25.1076 17.3952 23.847 18.0002 22.1831 18.0002C19.6369 18.0002 17.4688 16.1851 17.4688 12.7816V5.04199H21.2503V12.227C21.2503 13.7901 22.2336 14.5212 23.4437 14.5212C24.8302 14.5212 25.7883 13.7144 25.7883 11.9245V5.04199Z" fill="#8F33D6"/>
              <path d="M12.7314 17.6474L11.849 14.8743H5.29423L4.41186 17.6474H0L6.00012 0H11.1431L17.1432 17.6474H12.7314ZM6.50434 11.0927H10.6389L8.5716 4.61354L6.50434 11.0927Z" fill="#8F33D6"/>
            </svg>
          </div>
          {email && (
            <span className="text-sm text-gray-400 mt-0.5">{email}</span>
          )}
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={handleSync}
            disabled={syncing}
            className="p-2 text-gray-400 hover:text-white hover:bg-gray-800 rounded-lg transition-colors"
            title="Sync"
          >
            <svg
              className={`w-5 h-5 ${syncing ? "animate-spin" : ""}`}
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              />
            </svg>
          </button>
          <div className="relative">
            <button
              onClick={() => setShowMenu(!showMenu)}
              className="p-2 text-gray-400 hover:text-white hover:bg-gray-800 rounded-lg transition-colors"
            >
              <svg
                className="w-5 h-5"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z"
                />
              </svg>
            </button>
            {showMenu && (
              <>
                <div
                  className="fixed inset-0"
                  onClick={() => setShowMenu(false)}
                />
                <div className="absolute right-0 mt-2 w-32 bg-gray-800 rounded-lg shadow-lg py-1 z-10">
                  <button
                    onClick={() => {
                      setShowMenu(false);
                      onLock();
                    }}
                    className="w-full px-4 py-2 text-left text-gray-300 hover:bg-gray-700 transition-colors"
                  >
                    Lock
                  </button>
                  <button
                    onClick={() => {
                      setShowMenu(false);
                      onLogout();
                    }}
                    className="w-full px-4 py-2 text-left text-red-400 hover:bg-gray-700 transition-colors"
                  >
                    Logout
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Search */}
      <div className="p-3 border-b border-gray-800">
        <SearchBar value={searchQuery} onChange={setSearchQuery} />
      </div>

      {/* Code List */}
      <div className="flex-1 overflow-y-auto">
        {filteredCodes.length === 0 ? (
          <div className="flex items-center justify-center h-48 text-gray-500">
            {codes.length === 0
              ? "No codes yet. Add codes in the Ente Auth app."
              : "No codes match your search"}
          </div>
        ) : (
          <div className="divide-y divide-gray-800">
            {filteredCodes.map((code) => (
              <CodeItem key={code.id} code={code} onCopy={handleCopy} />
            ))}
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="p-2 border-t border-gray-800 text-center">
        <span className="text-xs text-gray-600">
          {codes.length} code{codes.length !== 1 ? "s" : ""}
        </span>
      </div>

      {/* Toast */}
      {toast && (
        <div className="fixed bottom-4 left-1/2 -translate-x-1/2 px-4 py-2 bg-[#8F33D6] text-white text-sm rounded-xl shadow-lg animate-fade-in">
          {toast}
        </div>
      )}
    </div>
  );
}
