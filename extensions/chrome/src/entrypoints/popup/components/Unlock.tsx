import React, { useEffect, useState } from "react";
import { sendMessage } from "@/lib/types/messages";
import ThemeToggle from "./ThemeToggle";
import Button from "./Button";

interface Props {
  email?: string;
  onUnlock: () => void;
  onLogout: () => void;
}

// Eye icon for show password
const EyeIcon = () => (
  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
  </svg>
);

// Eye off icon for hide password
const EyeOffIcon = () => (
  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
  </svg>
);

export default function Unlock({ email, onUnlock, onLogout }: Props) {
  const [usePasscode, setUsePasscode] = useState(false);
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    chrome.storage.local.get(["appLockEnabled", "encryptedMasterKey", "appLockSalt"], (result) => {
      const enabled = !!result.appLockEnabled;
      const hasKey = !!result.encryptedMasterKey && !!result.appLockSalt;
      setUsePasscode(enabled && hasKey);
    });
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!password) return;

    setLoading(true);
    setError("");

    try {
      const result = usePasscode
        ? await sendMessage({
            type: "UNLOCK_WITH_PASSCODE",
            passcode: password,
          })
        : await sendMessage({
            type: "UNLOCK",
            password,
          });

      if (result.success) {
        onUnlock();
      } else {
        setError(result.error || (usePasscode ? "Invalid passcode" : "Invalid password"));
        setPassword("");
      }
    } catch (e) {
      setError("Unlock failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-[400px] bg-[var(--ente-background)] text-[var(--ente-text)] p-4 flex flex-col relative">
      <div className="absolute top-2 right-2">
        <ThemeToggle />
      </div>
      {/* Header */}
      <div className="text-center mb-6">
        <div className="flex items-center justify-center gap-2">
          <svg width="53" height="18" viewBox="0 0 53 18" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M47.7422 4.68917C50.2884 4.68917 52.4566 6.50434 52.4566 9.90777V17.6474H48.675V10.4624C48.675 8.89934 47.6918 8.16824 46.4816 8.16824C45.0951 8.16824 44.1371 8.97497 44.1371 10.7649V17.6474H40.3555V0H44.1371V6.22702C44.8177 5.29423 46.0783 4.68917 47.7422 4.68917Z" fill="#8F33D6"/>
            <path d="M38.9733 8.67213H36.3766V13.1344C36.3766 14.2185 37.3094 14.3193 38.9733 14.2185V17.6471C34.032 18.1513 32.595 16.6639 32.595 13.1344V8.67213H30.5781V5.0418H32.595V1.71191L36.3766 1.71261V5.0418H38.9733V8.67213Z" fill="#8F33D6"/>
            <path d="M25.7883 5.04199H29.5698V17.6473H25.7883V16.4624C25.1076 17.3952 23.847 18.0002 22.1831 18.0002C19.6369 18.0002 17.4688 16.1851 17.4688 12.7816V5.04199H21.2503V12.227C21.2503 13.7901 22.2336 14.5212 23.4437 14.5212C24.8302 14.5212 25.7883 13.7144 25.7883 11.9245V5.04199Z" fill="#8F33D6"/>
            <path d="M12.7314 17.6474L11.849 14.8743H5.29423L4.41186 17.6474H0L6.00012 0H11.1431L17.1432 17.6474H12.7314ZM6.50434 11.0927H10.6389L8.5716 4.61354L6.50434 11.0927Z" fill="#8F33D6"/>
          </svg>
        </div>
      </div>

      {/* Lock Icon */}
      <div className="text-center mb-4">
        <div className="inline-flex items-center justify-center w-16 h-16 bg-[var(--ente-paper)] rounded-full">
          <svg
            className="w-8 h-8 text-[var(--ente-accent)]"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
            />
          </svg>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="flex-1 flex flex-col">
        <div className="mb-2 text-sm text-[var(--ente-text-muted)] text-center">
          {usePasscode ? "Enter your passcode" : "Extension is locked"}
        </div>
        {email && (
          <div className="mb-4 text-[var(--ente-accent-soft)] text-center text-sm">{email}</div>
        )}

        <div className="mb-4 relative">
          <input
            type={showPassword ? "text" : "password"}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder={usePasscode ? "Passcode" : "Enter your password"}
            className="w-full px-3 py-2.5 pr-10 bg-[var(--ente-paper)] border border-[var(--ente-stroke)] rounded-lg text-[var(--ente-text)] text-base placeholder-[color:var(--ente-text-faint)] focus:outline-none focus:border-[var(--ente-accent)]"
            autoFocus
            disabled={loading}
          />
          <button
            type="button"
            onClick={() => setShowPassword(!showPassword)}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-[var(--ente-text-muted)] hover:text-[var(--ente-text)] transition-colors"
          >
            {showPassword ? <EyeOffIcon /> : <EyeIcon />}
          </button>
        </div>

        {error && (
          <div className="mb-4 text-red-400 text-sm text-center">{error}</div>
        )}

        <Button
          type="submit"
          variant="primary"
          fullWidth
          disabled={loading || !password}
        >
          {loading ? "Unlocking..." : "Unlock"}
        </Button>

        <Button
          type="button"
          onClick={onLogout}
          variant="text"
          tone="danger"
          fullWidth
          className="mt-4"
        >
          {usePasscode ? "Forgot passcode? Logout" : "Logout"}
        </Button>
      </form>
    </div>
  );
}
