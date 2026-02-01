import React, { useMemo } from "react";
import type { Code } from "@/lib/types/code";

interface Props {
  code: Code;
  otp: string;
  nextOtp: string;
  validFor: number;
  onCopy: (text: string) => void;
}

export default function CodeItem({ code, otp, nextOtp, validFor, onCopy }: Props) {
  const progress = useMemo(() => {
    if (!code.period) return 0;
    return Math.max(0, Math.min(1, validFor / code.period));
  }, [code.period, validFor]);

  const isWarning = progress < 0.4;

  const formatOtp = (raw: string) => {
    const value = raw || "";
    if (value.length === 6) return `${value.slice(0, 3)} ${value.slice(3)}`;
    if (value.length === 8) return `${value.slice(0, 4)} ${value.slice(4)}`;
    return value;
  };

  const handleCopy = () => {
    if (!otp) return;
    onCopy(otp);
  };

  return (
    <div className="ente-code-card" onClick={handleCopy}>
      <div
        className={`ente-code-progress-bar ${isWarning ? "warning" : ""}`}
        style={{ width: `${progress * 100}%` }}
      />

      {code.codeDisplay?.pinned && (
        <>
          <div className="ente-pin-ribbon" />
          <span className="ente-pin-icon" aria-hidden="true">
            <svg viewBox="0 0 24 24" fill="currentColor" width="14" height="14">
              <path d="M16,12V4H17V2H7V4H8V12L6,14V16H11.2V22H12.8V16H18V14L16,12Z" />
            </svg>
          </span>
        </>
      )}

      <div className="ente-code-content">
        <div className="ente-code-left">
          <div className="ente-code-issuer" title={code.issuer}>
            {code.issuer}
          </div>
          <div className="ente-code-account" title={code.account || ""}>
            {code.account || ""}
          </div>
          <div className="ente-code-otp">{formatOtp(otp)}</div>
        </div>
        <div className="ente-code-right">
          <div className="ente-code-next-label">next</div>
          <div className="ente-code-next-otp">{formatOtp(nextOtp)}</div>
        </div>
      </div>
    </div>
  );
}
