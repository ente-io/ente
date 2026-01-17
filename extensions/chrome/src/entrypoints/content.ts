/**
 * Content script for OTP field detection and autofill.
 *
 * This script runs on all pages and:
 * 1. Detects OTP input fields
 * 2. Shows autofill suggestions
 * 3. Injects OTP values when selected
 */
import type { SiteMatch } from "@/lib/types/messages";

export default defineContentScript({
  matches: ["<all_urls>"],
  runAt: "document_idle",
  main() {
    // Skip iframes and non-HTTPS pages (except localhost for dev)
    if (window.top !== window) return;
    if (location.protocol !== "https:" && location.hostname !== "localhost") {
      return;
    }

    // CSS for autofill UI
    const AUTOFILL_STYLES = `
.ente-auth-autofill-container {
  position: absolute;
  z-index: 2147483647;
  background: #1a1a1a;
  border: 1px solid #333;
  border-radius: 8px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  max-width: 300px;
  overflow: hidden;
}

.ente-auth-autofill-header {
  padding: 8px 12px;
  background: #222;
  border-bottom: 1px solid #333;
  display: flex;
  align-items: center;
  gap: 8px;
}

.ente-auth-autofill-logo {
  color: #8F33D6;
  font-weight: bold;
  font-size: 14px;
}

.ente-auth-autofill-title {
  color: #888;
  font-size: 12px;
}

.ente-auth-autofill-list {
  max-height: 200px;
  overflow-y: auto;
}

.ente-auth-autofill-item {
  padding: 10px 12px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: space-between;
  transition: background 0.2s;
}

.ente-auth-autofill-item:hover {
  background: #2a2a2a;
}

.ente-auth-autofill-issuer {
  color: #fff;
  font-size: 14px;
  font-weight: 500;
}

.ente-auth-autofill-account {
  color: #888;
  font-size: 12px;
  margin-top: 2px;
}

.ente-auth-autofill-otp {
  color: #B37FEB;
  font-family: monospace;
  font-size: 16px;
  font-weight: bold;
  letter-spacing: 2px;
}

.ente-auth-autofill-empty {
  padding: 12px;
  color: #888;
  text-align: center;
  font-size: 13px;
}
`;

    // OTP field detection selectors
    const OTP_FIELD_SELECTORS = [
      'input[autocomplete="one-time-code"]',
      'input[name*="otp" i]',
      'input[name*="totp" i]',
      'input[name*="2fa" i]',
      'input[name*="mfa" i]',
      'input[name*="verification" i]',
      'input[name*="authenticator" i]',
      'input[id*="otp" i]',
      'input[id*="totp" i]',
      'input[id*="2fa" i]',
      'input[id*="mfa" i]',
      'input[id*="verification" i]',
      'input[placeholder*="code" i]',
      'input[placeholder*="otp" i]',
      'input[aria-label*="code" i]',
      'input[aria-label*="otp" i]',
    ];

    // Additional heuristics for OTP fields
    const isLikelyOTPField = (input: HTMLInputElement): boolean => {
      const maxLength = input.maxLength;
      if (maxLength >= 4 && maxLength <= 8) {
        return true;
      }

      if (input.type === "tel" || input.type === "number") {
        const parent = input.closest("form");
        if (parent) {
          const labels = parent.querySelectorAll("label");
          for (const label of labels) {
            const text = label.textContent?.toLowerCase() ?? "";
            if (
              text.includes("code") ||
              text.includes("otp") ||
              text.includes("verification") ||
              text.includes("2fa") ||
              text.includes("two-factor") ||
              text.includes("authenticator")
            ) {
              return true;
            }
          }
        }
      }

      return false;
    };

    // Find OTP fields on the page
    const findOTPFields = (): HTMLInputElement[] => {
      const fields: HTMLInputElement[] = [];
      const seen = new Set<HTMLInputElement>();

      for (const selector of OTP_FIELD_SELECTORS) {
        try {
          const matches = document.querySelectorAll<HTMLInputElement>(selector);
          for (const input of matches) {
            if (!seen.has(input) && input.type !== "hidden") {
              seen.add(input);
              fields.push(input);
            }
          }
        } catch {
          // Ignore invalid selectors
        }
      }

      const textInputs = document.querySelectorAll<HTMLInputElement>(
        'input[type="text"], input[type="number"], input[type="tel"], input:not([type])'
      );
      for (const input of textInputs) {
        if (!seen.has(input) && input.type !== "hidden" && isLikelyOTPField(input)) {
          seen.add(input);
          fields.push(input);
        }
      }

      return fields;
    };

    // State
    let autofillContainer: HTMLDivElement | null = null;
    let currentInput: HTMLInputElement | null = null;
    let matches: SiteMatch[] = [];

    // Inject styles
    const injectStyles = () => {
      if (document.getElementById("ente-auth-styles")) return;

      const style = document.createElement("style");
      style.id = "ente-auth-styles";
      style.textContent = AUTOFILL_STYLES;
      document.head.appendChild(style);
    };

    // Create autofill UI
    const createAutofillUI = (): HTMLDivElement => {
      const container = document.createElement("div");
      container.className = "ente-auth-autofill-container";
      container.innerHTML = `
        <div class="ente-auth-autofill-header">
          <span class="ente-auth-autofill-logo">ente</span>
          <span class="ente-auth-autofill-title">Auth</span>
        </div>
        <div class="ente-auth-autofill-list"></div>
      `;
      return container;
    };

    // Position autofill UI near input
    const positionAutofillUI = (input: HTMLInputElement) => {
      if (!autofillContainer) return;

      const rect = input.getBoundingClientRect();
      const scrollX = window.scrollX;
      const scrollY = window.scrollY;

      autofillContainer.style.left = `${rect.left + scrollX}px`;
      autofillContainer.style.top = `${rect.bottom + scrollY + 4}px`;
      autofillContainer.style.minWidth = `${Math.max(rect.width, 200)}px`;
    };

    // Generate OTP for a code
    const generateOTP = async (codeId: string): Promise<string> => {
      try {
        const response = await chrome.runtime.sendMessage({
          type: "GENERATE_OTP",
          codeId,
        });
        return response.otp;
      } catch {
        console.error("Failed to generate OTP");
        return "";
      }
    };

    // Escape HTML
    const escapeHtml = (text: string): string => {
      const div = document.createElement("div");
      div.textContent = text;
      return div.innerHTML;
    };

    // Fill OTP into input
    const fillOTP = (input: HTMLInputElement, otp: string) => {
      input.value = otp;
      const inputEvent = new Event("input", { bubbles: true });
      const changeEvent = new Event("change", { bubbles: true });
      input.dispatchEvent(inputEvent);
      input.dispatchEvent(changeEvent);
      input.focus();
    };

    // Hide autofill UI
    const hideAutofill = () => {
      if (autofillContainer) {
        autofillContainer.remove();
        autofillContainer = null;
      }
      currentInput = null;
    };

    // Update autofill UI with matches
    const updateAutofillUI = async () => {
      if (!autofillContainer || matches.length === 0) {
        hideAutofill();
        return;
      }

      const list = autofillContainer.querySelector(".ente-auth-autofill-list");
      if (!list) return;

      list.innerHTML = matches
        .map(
          (match) => `
        <div class="ente-auth-autofill-item" data-code-id="${match.code.id}">
          <div>
            <div class="ente-auth-autofill-issuer">${escapeHtml(match.code.issuer)}</div>
            ${match.code.account ? `<div class="ente-auth-autofill-account">${escapeHtml(match.code.account)}</div>` : ""}
          </div>
          <div class="ente-auth-autofill-otp">Tap to fill</div>
        </div>
      `
        )
        .join("");

      list.querySelectorAll<HTMLDivElement>(".ente-auth-autofill-item").forEach((item) => {
        item.addEventListener("click", async () => {
          const codeId = item.dataset.codeId;
          if (!codeId || !currentInput) return;
          const otp = await generateOTP(codeId);
          if (otp) {
            fillOTP(currentInput, otp);
          }
          hideAutofill();
        });
      });
    };

    // Show autofill UI
    const showAutofill = async (input: HTMLInputElement) => {
      injectStyles();

      try {
        const response = await chrome.runtime.sendMessage({
          type: "GET_CODES_FOR_SITE",
          url: window.location.href,
        });
        matches = response.matches || [];
      } catch {
        matches = [];
      }

      if (matches.length === 0) {
        hideAutofill();
        return;
      }

      currentInput = input;

      if (!autofillContainer) {
        autofillContainer = createAutofillUI();
        document.body.appendChild(autofillContainer);
      }

      positionAutofillUI(input);
      await updateAutofillUI();
    };

    // Handle focus on input fields
    const handleFocus = (e: FocusEvent) => {
      const target = e.target as HTMLInputElement;
      if (target.tagName !== "INPUT") return;

      const otpFields = findOTPFields();
      if (otpFields.includes(target)) {
        showAutofill(target);
      }
    };

    // Handle blur on input fields
    const handleBlur = () => {
      setTimeout(() => {
        const activeElement = document.activeElement;
        if (
          autofillContainer &&
          !autofillContainer.contains(activeElement) &&
          activeElement !== currentInput
        ) {
          hideAutofill();
        }
      }, 200);
    };

    // Handle scroll
    const handleScroll = () => {
      if (currentInput && autofillContainer) {
        positionAutofillUI(currentInput);
      }
    };

    // Handle click outside
    const handleClickOutside = (e: MouseEvent) => {
      if (
        autofillContainer &&
        !autofillContainer.contains(e.target as Node) &&
        e.target !== currentInput
      ) {
        hideAutofill();
      }
    };

    // Initialize
    document.addEventListener("focus", handleFocus, true);
    document.addEventListener("blur", handleBlur, true);
    document.addEventListener("scroll", handleScroll, true);
    document.addEventListener("click", handleClickOutside, true);

    const observer = new MutationObserver(() => {
      if (currentInput && !document.contains(currentInput)) {
        hideAutofill();
      }
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true,
    });

    console.log("Ente Auth content script initialized");
  },
});
