import React, { useEffect, useMemo, useState, useCallback } from "react";
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
  const [searchQuery, setSearchQuery] = useState("");
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [showMenu, setShowMenu] = useState(false);
  const [showSearch, setShowSearch] = useState(false);
  const [showSortMenu, setShowSortMenu] = useState(false);
  const [sortOrder, setSortOrder] = useState<"issuer" | "account" | "recent">("issuer");
  const [toast, setToast] = useState<string | null>(null);
  const [recentById, setRecentById] = useState<Record<string, number>>({});
  const [otpById, setOtpById] = useState<Record<string, { otp: string; nextOtp: string; validFor: number }>>({});
  const [prefillSingleMatch, setPrefillSingleMatch] = useState(true);
  const [autoSubmitEnabled, setAutoSubmitEnabled] = useState(true);
  const [showPhishingWarnings, setShowPhishingWarnings] = useState(true);
  const [clipboardAutoClearEnabled, setClipboardAutoClearEnabled] = useState(false);
  const [clipboardAutoClearSeconds, setClipboardAutoClearSeconds] = useState(30);
  const [disabledSitesCount, setDisabledSitesCount] = useState(0);

  const MenuIcon = ({ children }: { children: React.ReactNode }) => (
    <span className="inline-flex items-center justify-center w-4 h-4 text-[var(--ente-text-faint)]">
      {children}
    </span>
  );

  const loadCodes = useCallback(async () => {
    try {
      const result = await sendMessage({ type: "GET_CODES" });
      setCodes(result.codes || []);
    } catch (e) {
      setCodes([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadCodes();
  }, [loadCodes]);

  useEffect(() => {
    chrome.storage.local.get("enteAuthRecentlyUsed", (result) => {
      setRecentById((result.enteAuthRecentlyUsed as Record<string, number>) || {});
    });
  }, []);

  useEffect(() => {
    chrome.storage.local.get("prefillSingleMatch", (result) => {
      const value = result.prefillSingleMatch;
      setPrefillSingleMatch(typeof value === "boolean" ? value : true);
    });
  }, []);

  useEffect(() => {
    chrome.storage.local.get(
      [
        "autoSubmitEnabled",
        "showPhishingWarnings",
        "clipboardAutoClearEnabled",
        "clipboardAutoClearSeconds",
        "disabledSites",
      ],
      (result) => {
        setAutoSubmitEnabled(typeof result.autoSubmitEnabled === "boolean" ? result.autoSubmitEnabled : true);
        setShowPhishingWarnings(typeof result.showPhishingWarnings === "boolean" ? result.showPhishingWarnings : true);
        setClipboardAutoClearEnabled(typeof result.clipboardAutoClearEnabled === "boolean" ? result.clipboardAutoClearEnabled : false);
        setClipboardAutoClearSeconds(typeof result.clipboardAutoClearSeconds === "number" ? result.clipboardAutoClearSeconds : 30);
        setDisabledSitesCount(Array.isArray(result.disabledSites) ? result.disabledSites.length : 0);
      },
    );
  }, []);

  useEffect(() => {
    const onChanged = (
      changes: Record<string, chrome.storage.StorageChange>,
      areaName: string,
    ) => {
      if (areaName !== "local") return;

      if (changes.prefillSingleMatch) {
        const v = changes.prefillSingleMatch.newValue;
        setPrefillSingleMatch(typeof v === "boolean" ? v : true);
      }
      if (changes.autoSubmitEnabled) {
        const v = changes.autoSubmitEnabled.newValue;
        setAutoSubmitEnabled(typeof v === "boolean" ? v : true);
      }
      if (changes.showPhishingWarnings) {
        const v = changes.showPhishingWarnings.newValue;
        setShowPhishingWarnings(typeof v === "boolean" ? v : true);
      }
      if (changes.clipboardAutoClearEnabled) {
        const v = changes.clipboardAutoClearEnabled.newValue;
        setClipboardAutoClearEnabled(typeof v === "boolean" ? v : false);
      }
      if (changes.clipboardAutoClearSeconds) {
        const v = changes.clipboardAutoClearSeconds.newValue;
        setClipboardAutoClearSeconds(typeof v === "number" ? v : 30);
      }
      if (changes.disabledSites) {
        const v = changes.disabledSites.newValue;
        setDisabledSitesCount(Array.isArray(v) ? v.length : 0);
      }
    };

    chrome.storage.onChanged.addListener(onChanged);
    return () => chrome.storage.onChanged.removeListener(onChanged);
  }, []);

  useEffect(() => {
    if (!showSearch) {
      setSearchQuery("");
    }
  }, [showSearch]);

  const filteredCodes = useMemo(() => {
    const q = searchQuery.trim().toLowerCase();
    const base = q
      ? codes.filter((code) => {
          const issuer = code.issuer?.toLowerCase() ?? "";
          const account = code.account?.toLowerCase() ?? "";
          const note = code.codeDisplay?.note?.toLowerCase() ?? "";
          return issuer.includes(q) || account.includes(q) || note.includes(q);
        })
      : [...codes];

    base.sort((a, b) => {
      if (sortOrder === "issuer") {
        return (a.issuer || "").localeCompare(b.issuer || "");
      }
      if (sortOrder === "account") {
        return (a.account || "").localeCompare(b.account || "");
      }
      const aT = recentById[a.id] || 0;
      const bT = recentById[b.id] || 0;
      return bT - aT;
    });

    return base;
  }, [codes, recentById, searchQuery, sortOrder]);

  useEffect(() => {
    // Avoid sending huge payloads and wasting CPU for long lists.
    const MAX_REFRESH = 100;
    const codeIds = filteredCodes.slice(0, MAX_REFRESH).map((c) => c.id);
    if (codeIds.length === 0) return;

    let cancelled = false;

    const refresh = async () => {
      try {
        const result = await sendMessage({ type: "GENERATE_OTPS", codeIds });
        if (cancelled) return;

        const next: Record<string, { otp: string; nextOtp: string; validFor: number }> = {};
        for (const [id, otpResult] of Object.entries(result.otps || {})) {
          if (!otpResult) continue;
          next[id] = {
            otp: otpResult.otp,
            nextOtp: otpResult.nextOtp,
            validFor: otpResult.validFor,
          };
        }
        setOtpById(next);
      } catch {
        // Ignore (locked / not ready).
      }
    };

    refresh();
    const interval = window.setInterval(refresh, 1000);
    return () => {
      cancelled = true;
      window.clearInterval(interval);
    };
  }, [filteredCodes]);

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

  const handleCopy = async (codeId: string, text: string) => {
    try {
      await navigator.clipboard.writeText(text);
    } catch (e) {
      // Fallback to background script
      await sendMessage({ type: "COPY_TO_CLIPBOARD", text });
    }

    const next = { ...recentById, [codeId]: Date.now() };
    setRecentById(next);
    chrome.storage.local.set({ enteAuthRecentlyUsed: next }, () => {});

    setToast("Copied to clipboard");
    setTimeout(() => setToast(null), 1500);

    if (clipboardAutoClearEnabled && clipboardAutoClearSeconds > 0) {
      const copied = text;
      window.setTimeout(async () => {
        try {
          // Only clear if clipboard is unchanged. If readText isn't allowed, do nothing.
          const current = await navigator.clipboard.readText();
          if (current === copied) {
            await navigator.clipboard.writeText("");
          }
        } catch {
          // Ignore: lack of permission/user-gesture makes this unreliable.
        }
      }, clipboardAutoClearSeconds * 1000);
    }
  };

  const togglePrefillSingleMatch = () => {
    const next = !prefillSingleMatch;
    setPrefillSingleMatch(next);
    chrome.storage.local.set({ prefillSingleMatch: next }, () => {});
    setToast(next ? "Prefill single match: on" : "Prefill single match: off");
    setTimeout(() => setToast(null), 1500);
  };

  const toggleAutoSubmit = () => {
    const next = !autoSubmitEnabled;
    setAutoSubmitEnabled(next);
    chrome.storage.local.set({ autoSubmitEnabled: next }, () => {});
    setToast(next ? "Autosubmit: on" : "Autosubmit: off");
    setTimeout(() => setToast(null), 1500);
  };

  const togglePhishingWarnings = () => {
    const next = !showPhishingWarnings;
    setShowPhishingWarnings(next);
    chrome.storage.local.set({ showPhishingWarnings: next }, () => {});
    setToast(next ? "Phishing warnings: on" : "Phishing warnings: off");
    setTimeout(() => setToast(null), 1500);
  };

  const toggleClipboardAutoClear = () => {
    const next = !clipboardAutoClearEnabled;
    setClipboardAutoClearEnabled(next);
    chrome.storage.local.set({ clipboardAutoClearEnabled: next }, () => {});
    setToast(next ? "Clipboard auto-clear: on" : "Clipboard auto-clear: off");
    setTimeout(() => setToast(null), 1500);
  };

  const clearDisabledSites = () => {
    chrome.storage.local.set({ disabledSites: [] }, () => {
      setDisabledSitesCount(0);
    });
    setToast("Cleared disabled sites");
    setTimeout(() => setToast(null), 1500);
  };

  if (loading) {
    return (
      <div className="min-h-[400px] bg-[var(--ente-background)] text-white flex items-center justify-center">
        <div className="text-[var(--ente-text-muted)]">Loading codes...</div>
      </div>
    );
  }

  return (
    <div className="min-h-[400px] max-h-[520px] bg-[var(--ente-background)] text-white flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-[var(--ente-stroke)]">
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
            <span className="text-sm text-[var(--ente-text-faint)] mt-0.5">{email}</span>
          )}
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={handleSync}
            disabled={syncing}
            className="p-2 text-white/60 hover:text-white hover:bg-white/10 rounded-md transition-colors"
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
              onClick={() => setShowSortMenu(!showSortMenu)}
              className={`p-2 rounded-md transition-colors ${
                showSortMenu ? "text-[var(--ente-accent)]" : "text-white/60 hover:text-white hover:bg-white/10"
              }`}
              title="Sort"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h12M4 18h8" />
              </svg>
            </button>
            {showSortMenu && (
              <>
                <div className="fixed inset-0" onClick={() => setShowSortMenu(false)} />
                <div className="absolute right-0 mt-2 w-44 bg-[var(--ente-paper)] border border-[var(--ente-stroke)] rounded-lg shadow-lg py-1 z-10 overflow-hidden">
                  {([
                    ["issuer", "Issuer"],
                    ["account", "Account"],
                    ["recent", "Recently used"],
                  ] as const).map(([key, label]) => (
                    <button
                      key={key}
                      onClick={() => {
                        setSortOrder(key);
                        setShowSortMenu(false);
                      }}
                      className="w-full px-4 py-2 text-left text-sm text-white/90 hover:bg-white/5 transition-colors flex items-center justify-between"
                    >
                      <span>{label}</span>
                      {sortOrder === key && (
                        <svg className="w-4 h-4 text-white/60" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 6L9 17l-5-5" />
                        </svg>
                      )}
                    </button>
                  ))}
                </div>
              </>
            )}
          </div>

          <button
            onClick={() => setShowSearch((v) => !v)}
            className={`p-2 rounded-md transition-colors ${
              showSearch ? "text-[var(--ente-accent)]" : "text-white/60 hover:text-white hover:bg-white/10"
            }`}
            title="Search"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </button>

          <div className="relative">
            <button
              onClick={() => setShowMenu(!showMenu)}
              className="p-2 text-white/60 hover:text-white hover:bg-white/10 rounded-md transition-colors"
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
                <div className="absolute right-0 mt-2 w-36 bg-[var(--ente-paper)] border border-[var(--ente-stroke)] rounded-lg shadow-lg py-1 z-10 overflow-hidden">
                  <button
                    onClick={() => {
                      setShowMenu(false);
                      onLock();
                    }}
                    className="w-full px-4 py-2 text-left text-white/80 hover:bg-white/5 transition-colors flex items-center gap-2"
                  >
                    <MenuIcon>
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M12 17v1m-6 4h12a2 2 0 002-2v-7a2 2 0 00-2-2H6a2 2 0 00-2 2v7a2 2 0 002 2zm10-11V8a4 4 0 10-8 0v3" />
                      </svg>
                    </MenuIcon>
                    Lock
                  </button>
                  <button
                    onClick={() => {
                      setShowMenu(false);
                      togglePrefillSingleMatch();
                    }}
                    className="w-full px-4 py-2 text-left text-white/80 hover:bg-white/5 transition-colors flex items-center justify-between"
                    title="When enabled, focusing an OTP field with exactly one matching code will prefill the OTP (no autosubmit)."
                  >
                    <span className="text-sm flex items-center gap-2">
                      <MenuIcon>
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M12 3v4m0 10v4M4.22 5.22l2.83 2.83m9.9 9.9l2.83 2.83M3 12h4m10 0h4M5.22 19.78l2.83-2.83m9.9-9.9l2.83-2.83" />
                        </svg>
                      </MenuIcon>
                      Prefill 1 match
                    </span>
                    {prefillSingleMatch && (
                      <svg className="w-4 h-4 text-white/60" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 6L9 17l-5-5" />
                      </svg>
                    )}
                  </button>
                  <button
                    onClick={() => {
                      setShowMenu(false);
                      toggleAutoSubmit();
                    }}
                    className="w-full px-4 py-2 text-left text-white/80 hover:bg-white/5 transition-colors flex items-center justify-between"
                    title="When enabled, selecting a code from the in-page dropdown will attempt to submit the form."
                  >
                    <span className="text-sm flex items-center gap-2">
                      <MenuIcon>
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M12 19V5m0 0l-4 4m4-4l4 4" />
                        </svg>
                      </MenuIcon>
                      Autosubmit
                    </span>
                    {autoSubmitEnabled && (
                      <svg className="w-4 h-4 text-white/60" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 6L9 17l-5-5" />
                      </svg>
                    )}
                  </button>
                  <button
                    onClick={() => {
                      setShowMenu(false);
                      togglePhishingWarnings();
                    }}
                    className="w-full px-4 py-2 text-left text-white/80 hover:bg-white/5 transition-colors flex items-center justify-between"
                    title="Warn when the site doesn't match known domains for popular issuers."
                  >
                    <span className="text-sm flex items-center gap-2">
                      <MenuIcon>
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M12 3l8 4v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V7l8-4z" />
                        </svg>
                      </MenuIcon>
                      Phishing warnings
                    </span>
                    {showPhishingWarnings && (
                      <svg className="w-4 h-4 text-white/60" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 6L9 17l-5-5" />
                      </svg>
                    )}
                  </button>
                  <button
                    onClick={() => {
                      setShowMenu(false);
                      toggleClipboardAutoClear();
                    }}
                    className="w-full px-4 py-2 text-left text-white/80 hover:bg-white/5 transition-colors flex items-center justify-between"
                    title="Attempts to clear the clipboard after a delay (best-effort; may be blocked by browser permissions)."
                  >
                    <span className="text-sm flex items-center gap-2">
                      <MenuIcon>
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M9 5h6m-6 0a2 2 0 00-2 2v1h10V7a2 2 0 00-2-2m-6 0a2 2 0 012-2h2a2 2 0 012 2M7 9h10v12H7z" />
                        </svg>
                      </MenuIcon>
                      Clipboard clear
                    </span>
                    {clipboardAutoClearEnabled && (
                      <svg className="w-4 h-4 text-white/60" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 6L9 17l-5-5" />
                      </svg>
                    )}
                  </button>
                  <button
                    onClick={() => {
                      setShowMenu(false);
                      clearDisabledSites();
                    }}
                    className="w-full px-4 py-2 text-left text-white/80 hover:bg-white/5 transition-colors flex items-center justify-between"
                    title="Re-enable autofill on all sites where you previously disabled it."
                    disabled={disabledSitesCount === 0}
                  >
                    <span className="text-sm flex items-center gap-2">
                      <MenuIcon>
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                          <path strokeLinecap="round" strokeLinejoin="round" d="M21 12a9 9 0 11-3-6.7M21 3v6h-6" />
                        </svg>
                      </MenuIcon>
                      Clear disabled
                    </span>
                    <span className="text-xs text-white/50">{disabledSitesCount || ""}</span>
                  </button>
                  <button
                    onClick={() => {
                      setShowMenu(false);
                      onLogout();
                    }}
                    className="w-full px-4 py-2 text-left text-red-400 hover:bg-white/5 transition-colors flex items-center gap-2"
                  >
                    <MenuIcon>
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M15 3h4a2 2 0 012 2v14a2 2 0 01-2 2h-4" />
                        <path strokeLinecap="round" strokeLinejoin="round" d="M10 17l5-5-5-5" />
                        <path strokeLinecap="round" strokeLinejoin="round" d="M15 12H3" />
                      </svg>
                    </MenuIcon>
                    Logout
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Search */}
      {showSearch && (
        <div className="px-4 py-3">
          <SearchBar value={searchQuery} onChange={setSearchQuery} />
        </div>
      )}

      {/* Code List */}
      <div className="flex-1 overflow-y-auto px-4 py-3">
        {filteredCodes.length === 0 ? (
          <div className="flex items-center justify-center h-48 text-white/50">
            {codes.length === 0
              ? "No codes yet. Add codes in the Ente Auth app."
              : "No codes match your search"}
          </div>
        ) : (
          <div className="flex flex-col gap-2">
            {filteredCodes.map((code) => {
              const otp = otpById[code.id]?.otp || "";
              const nextOtp = otpById[code.id]?.nextOtp || "";
              const validFor = otpById[code.id]?.validFor ?? code.period;
              return (
                <CodeItem
                  key={code.id}
                  code={code}
                  otp={otp}
                  nextOtp={nextOtp}
                  validFor={validFor}
                  onCopy={(text) => handleCopy(code.id, text)}
                />
              );
            })}
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="px-4 py-2 border-t border-[var(--ente-stroke)] text-center">
        <span className="text-xs text-[var(--ente-text-faint)]">
          {codes.length} code{codes.length !== 1 ? "s" : ""}
        </span>
      </div>

      {/* Toast */}
      {toast && (
        <div className="fixed bottom-4 left-1/2 -translate-x-1/2 px-4 py-2 bg-[var(--ente-accent)] text-white text-sm rounded-lg shadow-lg animate-fade-in">
          {toast}
        </div>
      )}
    </div>
  );
}
