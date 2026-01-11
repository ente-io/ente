import React, { useEffect, useState, useCallback } from "react";
import { sendMessage } from "@/lib/types/messages";
import type { Code } from "@/lib/types/code";

interface Props {
  code: Code;
  onCopy: (text: string) => void;
}

export default function CodeItem({ code, onCopy }: Props) {
  const [otp, setOtp] = useState("");
  const [nextOtp, setNextOtp] = useState("");
  const [validFor, setValidFor] = useState(30);

  const refreshOTP = useCallback(async () => {
    try {
      const result = await sendMessage({
        type: "GENERATE_OTP",
        codeId: code.id,
      });
      setOtp(result.otp);
      setNextOtp(result.nextOtp);
      setValidFor(result.validFor);
    } catch (e) {
      console.error("Failed to generate OTP:", e);
    }
  }, [code.id]);

  useEffect(() => {
    refreshOTP();
    const interval = setInterval(refreshOTP, 1000);
    return () => clearInterval(interval);
  }, [refreshOTP]);

  const handleCopy = () => {
    onCopy(otp);
  };

  const progress = (validFor / code.period) * 100;
  const isExpiring = validFor <= 5;

  // Format OTP with spacing for readability
  const formatOtp = (otp: string) => {
    if (otp.length === 6) {
      return `${otp.slice(0, 3)} ${otp.slice(3)}`;
    }
    if (otp.length === 8) {
      return `${otp.slice(0, 4)} ${otp.slice(4)}`;
    }
    return otp;
  };

  return (
    <div
      className="p-3 hover:bg-gray-800/50 cursor-pointer transition-colors"
      onClick={handleCopy}
    >
      <div className="flex items-center justify-between">
        <div className="flex-1 min-w-0">
          {/* Issuer */}
          <div className="flex items-center gap-2">
            <span className="font-medium text-white truncate">
              {code.issuer}
            </span>
            {code.codeDisplay?.pinned && (
              <svg
                className="w-4 h-4 text-yellow-500 flex-shrink-0"
                fill="currentColor"
                viewBox="0 0 20 20"
              >
                <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
              </svg>
            )}
          </div>
          {/* Account */}
          {code.account && (
            <div className="text-sm text-gray-400 truncate">{code.account}</div>
          )}
        </div>

        {/* OTP */}
        <div className="flex-shrink-0 ml-4">
          <div
            className={`text-2xl font-mono font-bold tracking-wider ${
              isExpiring ? "text-red-400" : "text-[#B37FEB]"
            }`}
          >
            {formatOtp(otp)}
          </div>
          {/* Progress bar */}
          <div className="mt-1 h-1 bg-gray-700 rounded-full overflow-hidden w-24">
            <div
              className={`h-full transition-all duration-1000 ease-linear ${
                isExpiring ? "bg-red-500" : "bg-[#8F33D6]"
              }`}
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>
      </div>
    </div>
  );
}
