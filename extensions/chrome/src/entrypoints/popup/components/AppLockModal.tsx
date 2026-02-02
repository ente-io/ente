import React, { useEffect, useMemo, useState } from "react";
import { sendMessage } from "@/lib/types/messages";
import Button from "./Button";

interface Props {
  open: boolean;
  onClose: () => void;
}

export default function AppLockModal({ open, onClose }: Props) {
  const [enabled, setEnabled] = useState(false);
  const [passcode, setPasscode] = useState("");
  const [confirm, setConfirm] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!open) return;
    chrome.storage.local.get(["appLockEnabled"], (result) => {
      setEnabled(!!result.appLockEnabled);
    });
    setPasscode("");
    setConfirm("");
    setError(null);
    setSaving(false);
  }, [open]);

  const canSave = useMemo(() => {
    if (!passcode || !confirm) return false;
    if (passcode.length < 6) return false;
    if (passcode !== confirm) return false;
    return true;
  }, [passcode, confirm]);

  if (!open) return null;

  const handleSave = async () => {
    setError(null);
    if (!canSave) return;
    setSaving(true);
    try {
      const result = await sendMessage({ type: "SET_APP_LOCK_PASSCODE", passcode });
      if (!result.success) {
        setError(result.error || "Failed to set passcode");
      } else {
        setEnabled(true);
        onClose();
      }
    } catch (e) {
      setError("Failed to set passcode");
    } finally {
      setSaving(false);
    }
  };

  const handleDisable = async () => {
    setError(null);
    setSaving(true);
    try {
      const result = await sendMessage({ type: "DISABLE_APP_LOCK" });
      if (!result.success) {
        setError(result.error || "Failed to disable passcode lock");
      } else {
        setEnabled(false);
        onClose();
      }
    } catch {
      setError("Failed to disable passcode lock");
    } finally {
      setSaving(false);
    }
  };

  return (
    <>
      <div className="fixed inset-0 bg-black/60 z-20" onClick={onClose} />
      <div className="fixed inset-0 z-30 flex items-center justify-center p-4">
        <div className="w-full max-w-sm bg-[var(--ente-paper)] border border-[var(--ente-stroke)] rounded-xl shadow-2xl overflow-hidden">
          <div className="px-4 py-3 flex items-center justify-between">
            <div className="text-sm font-semibold text-[var(--ente-text)]">Passcode lock</div>
            <button
              onClick={onClose}
              className="p-1 rounded-md text-[var(--ente-text-faint)] hover:text-[var(--ente-text)] hover:bg-[var(--ente-hover)] transition-colors"
              aria-label="Close"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>

          <div className="px-4 py-4">
            <div className="text-xs text-[var(--ente-text-faint)] mb-3">
              Set a local passcode to unlock the extension without re-entering your account password.
              If you forget it, you can log out and sign in again.
            </div>

            <div className="space-y-3">
              <input
                type="password"
                value={passcode}
                onChange={(e) => setPasscode(e.target.value)}
                placeholder="New passcode (min 6 chars)"
                className="w-full px-3 py-2.5 bg-[var(--ente-paper-2)] border border-[var(--ente-stroke)] rounded-lg text-[var(--ente-text)] text-sm placeholder-[color:var(--ente-text-faint)] focus:outline-none focus:border-[var(--ente-accent)]"
                autoFocus
                disabled={saving}
              />
              <input
                type="password"
                value={confirm}
                onChange={(e) => setConfirm(e.target.value)}
                placeholder="Confirm passcode"
                className="w-full px-3 py-2.5 bg-[var(--ente-paper-2)] border border-[var(--ente-stroke)] rounded-lg text-[var(--ente-text)] text-sm placeholder-[color:var(--ente-text-faint)] focus:outline-none focus:border-[var(--ente-accent)]"
                disabled={saving}
              />
            </div>

            {error && <div className="mt-3 text-sm text-red-400">{error}</div>}
          </div>

          <div className="px-4 py-3 flex items-center justify-between gap-2">
            <Button
              onClick={handleDisable}
              disabled={!enabled || saving}
              variant="text"
              title="Remove passcode lock (you will unlock with your account password again)."
            >
              Disable
            </Button>
            <Button
              onClick={handleSave}
              disabled={!canSave || saving}
              variant="primary"
              className="text-sm py-2"
            >
              {saving ? "Saving..." : enabled ? "Change" : "Enable"}
            </Button>
          </div>
        </div>
      </div>
    </>
  );
}
