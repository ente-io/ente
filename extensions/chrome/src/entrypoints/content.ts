/**
 * Content script for OTP field detection and autofill.
 *
 * This script runs on all pages and:
 * 1. Detects OTP input fields
 * 2. Shows autofill suggestions
 * 3. Injects OTP values when selected
 */
import { defineContentScript } from "wxt/sandbox";
import type { SiteMatchPreview } from "@/lib/types/messages";
import { getDomain } from "tldts";
import { checkPhishing } from "@/lib/services/site-matcher";

type OTPFieldSingleDetection = {
  type: "single";
  element: HTMLInputElement;
  confidence: number;
};

type OTPFieldSplitDetection = {
  type: "split";
  element: HTMLInputElement;
  splitInputs: HTMLInputElement[];
  confidence: number;
};

type OTPFieldDetection = OTPFieldSingleDetection | OTPFieldSplitDetection;

export default defineContentScript({
  matches: ["https://*/*", "http://localhost/*"],
  runAt: "document_idle",
  main() {
    // Skip iframes and non-HTTPS pages (except localhost for dev)
    if (window.top !== window) return;
    if (location.protocol !== "https:" && location.hostname !== "localhost") {
      return;
    }

    const MAX_MATCHES = 8;
    const ICON_SIZE = 24;
    const ICON_PADDING = 4;
    const PREFILL_SINGLE_MATCH_STORAGE_KEY = "prefillSingleMatch";
    const DEFAULT_PREFILL_SINGLE_MATCH = true;
    let prefillSingleMatchEnabled = DEFAULT_PREFILL_SINGLE_MATCH;
    const AUTO_SUBMIT_STORAGE_KEY = "autoSubmitEnabled";
    let autoSubmitEnabled = true;
    const SHOW_PHISHING_WARNINGS_KEY = "showPhishingWarnings";
    let showPhishingWarnings = true;
    const DISABLED_SITES_KEY = "disabledSites";
    let disabledSites: string[] = [];

    chrome.storage.local.get(PREFILL_SINGLE_MATCH_STORAGE_KEY, (result) => {
      const value = result[PREFILL_SINGLE_MATCH_STORAGE_KEY] as boolean | undefined;
      if (typeof value === "boolean") prefillSingleMatchEnabled = value;
    });

    chrome.storage.local.get(AUTO_SUBMIT_STORAGE_KEY, (result) => {
      const value = result[AUTO_SUBMIT_STORAGE_KEY] as boolean | undefined;
      if (typeof value === "boolean") autoSubmitEnabled = value;
    });

    chrome.storage.local.get(SHOW_PHISHING_WARNINGS_KEY, (result) => {
      const value = result[SHOW_PHISHING_WARNINGS_KEY] as boolean | undefined;
      if (typeof value === "boolean") showPhishingWarnings = value;
    });

    chrome.storage.local.get(DISABLED_SITES_KEY, (result) => {
      const value = result[DISABLED_SITES_KEY] as string[] | undefined;
      if (Array.isArray(value)) disabledSites = value.filter((v) => typeof v === "string");
    });

    chrome.storage.onChanged.addListener((changes, areaName) => {
      if (areaName !== "local") return;
      const change = changes[PREFILL_SINGLE_MATCH_STORAGE_KEY];
      if (!change) return;
      if (typeof change.newValue === "boolean") {
        prefillSingleMatchEnabled = change.newValue;
      } else {
        prefillSingleMatchEnabled = DEFAULT_PREFILL_SINGLE_MATCH;
      }
    });

    chrome.storage.onChanged.addListener((changes, areaName) => {
      if (areaName !== "local") return;

      if (changes[AUTO_SUBMIT_STORAGE_KEY]) {
        const v = changes[AUTO_SUBMIT_STORAGE_KEY]!.newValue;
        autoSubmitEnabled = typeof v === "boolean" ? v : true;
      }

      if (changes[SHOW_PHISHING_WARNINGS_KEY]) {
        const v = changes[SHOW_PHISHING_WARNINGS_KEY]!.newValue;
        showPhishingWarnings = typeof v === "boolean" ? v : true;
      }

      if (changes[DISABLED_SITES_KEY]) {
        const v = changes[DISABLED_SITES_KEY]!.newValue;
        disabledSites = Array.isArray(v) ? v.filter((x) => typeof x === "string") : [];
      }
    });

    // --- OTP field detection (single + split) ---

    const OTP_ATTRIBUTE_PATTERNS = [
      "otp",
      "totp",
      "hotp",
      "mfa",
      "2fa",
      "twofa",
      "two-factor",
      "twofactor",
      "verification",
      "verify",
      "code",
      "token",
      "authenticator",
      "security",
      "pin",
      "passcode",
      "one-time",
      "onetime",
    ];

    const OTP_LABEL_PATTERNS = [
      "verification code",
      "authentication code",
      "security code",
      "2-factor",
      "two-factor",
      "6-digit",
      "6 digit",
      "one-time",
      "one time",
      "otp",
      "mfa",
      "authenticator",
      "enter code",
      "enter the code",
      "passcode",
      "confirm code",
      "access code",
    ];

    const matchesPattern = (value: string | null, patterns: string[]): boolean => {
      if (!value) return false;
      const lower = value.toLowerCase();
      return patterns.some((pattern) => lower.includes(pattern));
    };

    const findLabelForInput = (input: HTMLInputElement): HTMLLabelElement | null => {
      if (input.id) {
        const label = document.querySelector(`label[for="${CSS.escape(input.id)}"]`);
        if (label) return label as HTMLLabelElement;
      }
      const parentLabel = input.closest("label");
      if (parentLabel) return parentLabel as HTMLLabelElement;
      return null;
    };

    const isVisibleInput = (input: HTMLInputElement): boolean => {
      if (input.type === "hidden") return false;
      // `offsetParent` is `null` for some visible elements (ex: `position: fixed`), so rely on layout rects.
      if (input.getClientRects().length === 0) return false;
      const style = window.getComputedStyle(input);
      return style.display !== "none" && style.visibility !== "hidden";
    };

    const calculateConfidence = (input: HTMLInputElement): number => {
      let confidence = 0;

      if (input.autocomplete === "one-time-code") confidence += 0.7;

      if (input.inputMode === "numeric" && input.maxLength === 6) confidence += 0.5;

      const pattern = input.pattern;
      if (pattern && (/\[0-9\]\{6\}/.test(pattern) || /\\d\{6\}/.test(pattern))) {
        confidence += 0.4;
      }

      if (input.maxLength === 6) confidence += 0.2;
      if (input.maxLength === 4 || input.maxLength === 8) confidence += 0.1;

      if (input.inputMode === "numeric" && input.maxLength !== 6) confidence += 0.15;

      if (input.type === "tel" || input.type === "number") confidence += 0.15;

      const nameIdClass = `${input.name || ""} ${input.id || ""} ${input.className || ""}`;
      if (matchesPattern(nameIdClass, OTP_ATTRIBUTE_PATTERNS)) confidence += 0.3;

      const dataAttrs = Array.from(input.attributes)
        .filter((attr) => attr.name.startsWith("data-"))
        .map((attr) => `${attr.name} ${attr.value}`)
        .join(" ");
      if (matchesPattern(dataAttrs, OTP_ATTRIBUTE_PATTERNS)) confidence += 0.2;

      if (matchesPattern(input.placeholder, OTP_LABEL_PATTERNS)) confidence += 0.25;

      const label = findLabelForInput(input);
      if (label && matchesPattern(label.textContent, OTP_LABEL_PATTERNS)) confidence += 0.25;

      if (matchesPattern(input.getAttribute("aria-label"), OTP_LABEL_PATTERNS)) confidence += 0.2;

      const describedById = input.getAttribute("aria-describedby");
      if (describedById) {
        const describedBy = document.getElementById(describedById);
        if (describedBy && matchesPattern(describedBy.textContent, OTP_LABEL_PATTERNS)) {
          confidence += 0.15;
        }
      }

      const container = input.closest("form, fieldset, [role='group']") || input.parentElement?.parentElement;
      if (container) {
        const containerIdClass = `${container.id || ""} ${container.className || ""}`;
        if (matchesPattern(containerIdClass, OTP_ATTRIBUTE_PATTERNS)) confidence += 0.2;
      }

      return Math.min(confidence, 1);
    };

    const detectSplitInputs = (): OTPFieldSplitDetection | null => {
      const allInputs = document.querySelectorAll<HTMLInputElement>(
        'input[maxlength="1"][type="text"], input[maxlength="1"][type="tel"], input[maxlength="1"][type="number"], input[maxlength="1"]:not([type])'
      );

      const groups: HTMLInputElement[][] = [];
      let currentGroup: HTMLInputElement[] = [];

      allInputs.forEach((input) => {
        if (!isVisibleInput(input)) return;

        if (currentGroup.length === 0) {
          currentGroup.push(input);
          return;
        }

        const lastInput = currentGroup[currentGroup.length - 1]!;
        const isSibling =
          lastInput.nextElementSibling === input || lastInput.parentElement === input.parentElement;
        const isClose = lastInput.parentElement?.parentElement === input.parentElement?.parentElement;

        if (isSibling || isClose) {
          currentGroup.push(input);
        } else {
          if (currentGroup.length >= 6) groups.push(currentGroup);
          currentGroup = [input];
        }
      });

      if (currentGroup.length >= 6) groups.push(currentGroup);

      for (const group of groups) {
        if (group.length === 6) {
          return {
            type: "split",
            element: group[0]!,
            splitInputs: group,
            confidence: 0.85,
          };
        }
      }

      return null;
    };

    const getDetectionForFocusedInput = (input: HTMLInputElement): OTPFieldDetection | null => {
      if (!isVisibleInput(input)) return null;
      if (input.type === "password") return null;

      const split = detectSplitInputs();
      if (split && split.splitInputs.includes(input)) {
        return { ...split, element: input };
      }

      const confidence = calculateConfidence(input);
      if (confidence >= 0.3) {
        return { type: "single", element: input, confidence };
      }

      return null;
    };

    type OtpInfo = { otp: string; nextOtp: string; validFor: number };

    // State
    let currentInput: HTMLInputElement | null = null;
    let currentDetection: OTPFieldDetection | null = null;
    let matches: SiteMatchPreview[] = [];
    let otpById: Record<string, OtpInfo> = {};
    let phishingWarning: string | null = null;

    // Shadow DOM UI elements (icon inside input + dropdown)
    let shadowHost: HTMLDivElement | null = null;
    let shadowRoot: ShadowRoot | null = null;
    let dropdownEl: HTMLDivElement | null = null;
    let dropdownOpen = false;
    let otpRefreshInterval: number | null = null;
    let restorePaddingRight: (() => void) | null = null;

    const ICON_CSS = `
      :host {
        all: initial;
        /* Mirror the Ente Auth app dark palette (mobile/apps/auth/lib/theme/colors.dart). */
        --ente-background: #000000;
        --ente-paper: #1b1b1b;
        --ente-paper-2: #252525;
        --ente-text: #ffffff;
        --ente-text-muted: rgba(255, 255, 255, 0.7);
        --ente-text-faint: rgba(255, 255, 255, 0.5);
        --ente-stroke: rgba(255, 255, 255, 0.12);
        --ente-accent: #8f33d6;
        --ente-accent-700: #722ed1;
        --ente-warning: #ffc247;
        --ente-warning-bg: rgba(255, 194, 71, 0.12);
        color-scheme: dark;
      }

      .ente-container {
        position: relative;
        display: inline-flex;
        align-items: center;
        z-index: 2147483647;
      }

      .ente-icon-btn {
        width: ${ICON_SIZE}px;
        height: ${ICON_SIZE}px;
        border-radius: 8px;
        background: transparent;
        border: none;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 0;
        transition: transform 0.15s ease;
        box-shadow: 0 2px 6px rgba(0, 0, 0, 0.25);
        overflow: hidden;
      }

      .ente-icon-btn:hover { transform: scale(1.05); }
      .ente-icon-btn:active { transform: scale(0.98); }

      .ente-dropdown {
        position: absolute;
        top: calc(100% + 4px);
        right: 0;
        min-width: 300px;
        max-width: 340px;
        background: var(--ente-paper);
        border-radius: 8px;
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
        border: 1px solid var(--ente-stroke);
        overflow: hidden;
        z-index: 2147483647;
        font-family: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      }

      .ente-header {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 12px 16px;
        border-bottom: 1px solid var(--ente-stroke);
      }

      .ente-header-title {
        font-size: 14px;
        font-weight: 600;
        color: var(--ente-text);
      }

      .ente-header-actions {
        margin-left: auto;
        display: inline-flex;
        gap: 8px;
        align-items: center;
      }

      .ente-header-action {
        border: none;
        background: transparent;
        color: var(--ente-text-muted);
        cursor: pointer;
        font-size: 12px;
        font-weight: 600;
        padding: 4px 6px;
        border-radius: 6px;
      }

      .ente-header-action:hover {
        background: rgba(255, 255, 255, 0.08);
        color: var(--ente-text);
      }

      .ente-warning {
        padding: 10px 16px;
        font-size: 12px;
        line-height: 1.4;
        color: rgba(255, 255, 255, 0.85);
        background: var(--ente-warning-bg);
        border-bottom: 1px solid var(--ente-stroke);
      }

      .ente-list {
        max-height: 280px;
        overflow-y: auto;
        padding: 8px;
      }

      .ente-item {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 12px 16px;
        cursor: pointer;
        transition: background-color 0.15s;
        border-radius: 8px;
        margin-bottom: 4px;
        background: transparent;
      }

      .ente-item:hover { background: var(--ente-paper-2); }

      .ente-item-info { flex: 1; min-width: 0; margin-right: 16px; }
      .ente-issuer {
        font-size: 15px;
        font-weight: 600;
        color: var(--ente-text);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        margin-bottom: 2px;
      }

      .ente-account {
        font-size: 13px;
        font-weight: 500;
        color: var(--ente-text-faint);
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
      }

      .ente-otp-wrap { display: flex; flex-direction: column; align-items: flex-end; gap: 4px; }
      .ente-otp {
        font-size: 18px;
        font-weight: 600;
        color: var(--ente-text);
        letter-spacing: 0.02em;
      }

      .ente-progress-track {
        width: 50px;
        height: 3px;
        background: var(--ente-stroke);
        border-radius: 2px;
        overflow: hidden;
      }

      .ente-progress-bar {
        height: 100%;
        background: var(--ente-accent);
        transition: width 1s linear;
      }

      .ente-progress-bar.warning { background: var(--ente-warning); }

      .ente-empty {
        padding: 24px 16px;
        text-align: center;
        color: var(--ente-text-faint);
        font-size: 14px;
        font-weight: 500;
      }
    `;

    const formatOtp = (raw: string): string => {
      const otp = raw || "";
      if (otp.length === 6) return `${otp.slice(0, 3)} ${otp.slice(3)}`;
      if (otp.length === 8) return `${otp.slice(0, 4)} ${otp.slice(4)}`;
      return otp;
    };

    const applyInputRightPadding = (input: HTMLInputElement): void => {
      if (restorePaddingRight) restorePaddingRight();
      const inlineBefore = input.style.paddingRight;
      const computed = window.getComputedStyle(input).paddingRight;
      const computedPx = Number.parseFloat(computed || "0");
      const extra = ICON_SIZE + ICON_PADDING + 4;
      input.style.paddingRight = `${computedPx + extra}px`;
      restorePaddingRight = () => {
        input.style.paddingRight = inlineBefore;
        restorePaddingRight = null;
      };
    };

    const getSiteKey = (): string => {
      const hostname = window.location.hostname.toLowerCase();
      return getDomain(hostname) ?? hostname;
    };

    const isAutofillDisabledOnSite = (): boolean => {
      const key = getSiteKey();
      return disabledSites.includes(key);
    };

    const disableAutofillOnSite = (): void => {
      const key = getSiteKey();
      const next = Array.from(new Set([...(disabledSites || []), key]));
      disabledSites = next;
      chrome.storage.local.set({ [DISABLED_SITES_KEY]: next }, () => {});
    };

    const positionIcon = (input: HTMLInputElement): void => {
      if (!shadowHost) return;
      const rect = input.getBoundingClientRect();
      const scrollX = window.scrollX;
      const scrollY = window.scrollY;

      const top = rect.top + scrollY + (rect.height - ICON_SIZE) / 2;
      const left = rect.right + scrollX - ICON_SIZE - ICON_PADDING;

      shadowHost.style.position = "absolute";
      shadowHost.style.top = `${top}px`;
      shadowHost.style.left = `${left}px`;
      shadowHost.style.zIndex = "2147483647";
    };

    const stopOtpRefresh = (): void => {
      if (otpRefreshInterval) {
        window.clearInterval(otpRefreshInterval);
        otpRefreshInterval = null;
      }
    };

    const closeDropdown = (): void => {
      dropdownOpen = false;
      stopOtpRefresh();
      if (dropdownEl) dropdownEl.style.display = "none";
    };

    const unmountIconUi = (): void => {
      closeDropdown();
      if (restorePaddingRight) restorePaddingRight();
      if (shadowHost) {
        shadowHost.remove();
        shadowHost = null;
      }
      shadowRoot = null;
      dropdownEl = null;
    };

    const hideAutofill = (): void => {
      unmountIconUi();
      currentInput = null;
      currentDetection = null;
      matches = [];
      otpById = {};
    };

    const generateOTP = async (codeId: string): Promise<OtpInfo | null> => {
      try {
        const response = await chrome.runtime.sendMessage({ type: "GENERATE_OTP", codeId });
        if (!response?.otp) return null;
        return { otp: response.otp, nextOtp: response.nextOtp, validFor: response.validFor };
      } catch {
        return null;
      }
    };

    const generateOTPs = async (codeIds: string[]): Promise<Record<string, OtpInfo | null>> => {
      try {
        const response = await chrome.runtime.sendMessage({ type: "GENERATE_OTPS", codeIds });
        return response?.otps || {};
      } catch {
        return {};
      }
    };

    const renderDropdown = (): void => {
      if (!dropdownEl) return;
      dropdownEl.innerHTML = "";

      const header = document.createElement("div");
      header.className = "ente-header";

      const logo = document.createElement("svg");
      logo.setAttribute("width", "16");
      logo.setAttribute("height", "16");
      logo.setAttribute("viewBox", "0 0 24 24");
      logo.innerHTML =
        '<path d="M12 2L3 7V12C3 16.97 6.84 21.66 12 23C17.16 21.66 21 16.97 21 12V7L12 2Z" fill="#8F33D6"/>' +
        '<path d="M10 17L6 13L7.41 11.59L10 14.17L16.59 7.58L18 9L10 17Z" fill="white"/>';

      const title = document.createElement("span");
      title.className = "ente-header-title";
      title.textContent = "Ente Auth";

      header.appendChild(logo);
      header.appendChild(title);

      const actions = document.createElement("div");
      actions.className = "ente-header-actions";
      const disableBtn = document.createElement("button");
      disableBtn.className = "ente-header-action";
      disableBtn.type = "button";
      disableBtn.textContent = "Disable";
      disableBtn.title = "Disable autofill on this site";
      disableBtn.addEventListener("mousedown", (e) => {
        e.preventDefault();
        e.stopPropagation();
        disableAutofillOnSite();
        hideAutofill();
      });
      actions.appendChild(disableBtn);
      header.appendChild(actions);

      dropdownEl.appendChild(header);

      if (phishingWarning) {
        const warning = document.createElement("div");
        warning.className = "ente-warning";
        warning.textContent = phishingWarning;
        dropdownEl.appendChild(warning);
      }

      const list = document.createElement("div");
      list.className = "ente-list";

      if (matches.length === 0) {
        const empty = document.createElement("div");
        empty.className = "ente-empty";
        empty.textContent = "No matching codes found";
        list.appendChild(empty);
        dropdownEl.appendChild(list);
        return;
      }

      for (const match of matches) {
        const code = match.code;
        const otpInfo = otpById[code.id];

        const item = document.createElement("div");
        item.className = "ente-item";
        item.addEventListener("mousedown", async (e) => {
          e.preventDefault();
          e.stopPropagation();
          if (!currentDetection) return;

          // Only explicit user action should extend the unlock session.
          chrome.runtime.sendMessage({ type: "USER_ACTIVITY" }).catch(() => {});

          let otp = otpInfo?.otp || "";
          if (!otp) {
            const one = await generateOTP(code.id);
            otp = one?.otp || "";
          }
          if (!otp) return;

          // Avoid accidental submission on potentially suspicious pages.
          fillCode(currentDetection, otp, autoSubmitEnabled && !phishingWarning);
          hideAutofill();
        });

        const info = document.createElement("div");
        info.className = "ente-item-info";

        const issuer = document.createElement("div");
        issuer.className = "ente-issuer";
        issuer.textContent = code.issuer;
        info.appendChild(issuer);

        if (code.account) {
          const account = document.createElement("div");
          account.className = "ente-account";
          account.textContent = code.account;
          info.appendChild(account);
        }

        const right = document.createElement("div");
        right.className = "ente-otp-wrap";

        const otpEl = document.createElement("div");
        otpEl.className = "ente-otp";
        otpEl.textContent = otpInfo?.otp ? formatOtp(otpInfo.otp) : "Tap to fill";
        right.appendChild(otpEl);

        const track = document.createElement("div");
        track.className = "ente-progress-track";
        const bar = document.createElement("div");
        bar.className = "ente-progress-bar";

        if (otpInfo?.validFor != null && code.period) {
          const progress = Math.max(0, Math.min(1, otpInfo.validFor / code.period));
          bar.style.width = `${progress * 100}%`;
          if (progress < 0.4) bar.classList.add("warning");
        } else {
          bar.style.width = "0%";
        }

        track.appendChild(bar);
        right.appendChild(track);

        item.appendChild(info);
        item.appendChild(right);
        list.appendChild(item);
      }

      dropdownEl.appendChild(list);
    };

    const openDropdown = (): void => {
      if (!dropdownEl) return;
      dropdownOpen = true;
      dropdownEl.style.display = "block";

      const refresh = async () => {
        const codeIds = matches.map((m) => m.code.id);
        if (codeIds.length === 0) return;
        const results = await generateOTPs(codeIds);
        const next: Record<string, OtpInfo> = {};
        for (const [id, otpInfo] of Object.entries(results)) {
          if (!otpInfo) continue;
          next[id] = otpInfo;
        }
        otpById = next;
        renderDropdown();
      };

      refresh();
      stopOtpRefresh();
      otpRefreshInterval = window.setInterval(refresh, 1000);
    };

    const ensureIconUi = (input: HTMLInputElement): void => {
      if (shadowHost && currentInput === input) {
        positionIcon(input);
        return;
      }

      unmountIconUi();

      shadowHost = document.createElement("div");
      shadowHost.id = "ente-auth-icon-host";
      shadowHost.style.cssText = "all: initial; position: absolute; z-index: 2147483647;";
      shadowRoot = shadowHost.attachShadow({ mode: "closed" });

      const style = document.createElement("style");
      style.textContent = ICON_CSS;

      const container = document.createElement("div");
      container.className = "ente-container";

      const button = document.createElement("button");
      button.type = "button";
      button.className = "ente-icon-btn";
      button.title = "Ente Auth - Click to autofill";
      button.addEventListener("mousedown", (e) => {
        e.preventDefault();
        e.stopPropagation();
        if (!dropdownEl) return;
        if (dropdownOpen) {
          closeDropdown();
        } else {
          openDropdown();
        }
      });

      const img = document.createElement("img");
      img.src = chrome.runtime.getURL("icon/16.png");
      img.alt = "Ente Auth";
      img.width = 20;
      img.height = 20;
      img.style.borderRadius = "4px";

      button.appendChild(img);

      dropdownEl = document.createElement("div");
      dropdownEl.className = "ente-dropdown";
      dropdownEl.style.display = "none";

      container.appendChild(button);
      container.appendChild(dropdownEl);

      shadowRoot.appendChild(style);
      shadowRoot.appendChild(container);

      document.body.appendChild(shadowHost);

      applyInputRightPadding(input);
      positionIcon(input);
    };

    const normalizeOtp = (otp: string): string => otp.replace(/[\s-]/g, "");

    const triggerInputEvents = (input: HTMLInputElement): void => {
      const nativeValueSetter = Object.getOwnPropertyDescriptor(
        window.HTMLInputElement.prototype,
        "value"
      )?.set;

      if (nativeValueSetter) {
        nativeValueSetter.call(input, input.value);
      }

      input.dispatchEvent(new Event("input", { bubbles: true, cancelable: true }));
      input.dispatchEvent(new Event("change", { bubbles: true, cancelable: true }));
      input.dispatchEvent(new KeyboardEvent("keydown", { bubbles: true, cancelable: true }));
      input.dispatchEvent(new KeyboardEvent("keyup", { bubbles: true, cancelable: true }));
    };

    const fillSingleInput = (input: HTMLInputElement, otp: string): void => {
      input.focus();
      input.value = otp;
      triggerInputEvents(input);
    };

    const fillSplitInputs = (inputs: HTMLInputElement[], otp: string): void => {
      const chars = otp.split("");
      inputs.forEach((input, index) => {
        if (index >= chars.length) return;
        input.focus();
        input.value = chars[index]!;
        triggerInputEvents(input);
      });

      const lastIndex = Math.min(chars.length - 1, inputs.length - 1);
      if (lastIndex >= 0) inputs[lastIndex]?.focus();
    };

    const isLikelySubmitButton = (element: HTMLElement): boolean => {
      const text = element.textContent?.toLowerCase().trim() || "";
      const ariaLabel = element.getAttribute("aria-label")?.toLowerCase() || "";
      const title = element.getAttribute("title")?.toLowerCase() || "";
      const className = element.className?.toLowerCase() || "";
      const id = element.id?.toLowerCase() || "";

      const submitKeywords = [
        "submit",
        "verify",
        "confirm",
        "continue",
        "next",
        "sign in",
        "signin",
        "login",
        "log in",
        "authenticate",
        "done",
        "ok",
      ];

      for (const keyword of submitKeywords) {
        if (text.includes(keyword) || ariaLabel.includes(keyword) || title.includes(keyword)) {
          return true;
        }
      }

      const primaryClassPatterns = ["submit", "primary", "btn-primary", "cta", "action", "continue", "next", "confirm"];
      for (const pattern of primaryClassPatterns) {
        if (className.includes(pattern) || id.includes(pattern)) {
          return true;
        }
      }

      return false;
    };

    const clickSubmitButton = (input: HTMLInputElement): void => {
      const form = input.closest("form");
      if (!form) return;

      const submitButton = form.querySelector<HTMLButtonElement | HTMLInputElement>(
        'button[type="submit"], input[type="submit"]'
      );
      if (submitButton && !submitButton.disabled) {
        submitButton.click();
        return;
      }

      const defaultButton = form.querySelector<HTMLButtonElement>('button:not([type])');
      if (defaultButton && !defaultButton.disabled) {
        defaultButton.click();
        return;
      }

      const formButtons = form.querySelectorAll<HTMLButtonElement>("button");
      for (const button of formButtons) {
        if (!button.disabled && isLikelySubmitButton(button)) {
          button.click();
          return;
        }
      }

      try {
        form.requestSubmit();
      } catch {
        // Ignore.
      }
    };

    const fillCode = (detection: OTPFieldDetection, otpRaw: string, autoSubmit = true): void => {
      const otp = normalizeOtp(otpRaw);
      if (detection.type === "split") {
        fillSplitInputs(detection.splitInputs, otp);
      } else {
        fillSingleInput(detection.element, otp);
      }

      if (autoSubmit) {
        setTimeout(() => {
          clickSubmitButton(detection.element);
        }, 100);
      }
    };

    const showAutofill = async (input: HTMLInputElement, detection: OTPFieldDetection) => {
      // Switching between different OTP inputs should behave like "one active session".
      if (currentInput && currentInput !== input) {
        hideAutofill();
      }

      if (isAutofillDisabledOnSite()) {
        hideAutofill();
        return;
      }

      currentInput = input;
      currentDetection = detection;
      closeDropdown();
      phishingWarning = null;

      try {
        const response = await chrome.runtime.sendMessage({
          type: "GET_CODES_FOR_SITE",
          url: window.location.href,
        });
        matches = (response?.matches || []).slice(0, MAX_MATCHES);
      } catch {
        matches = [];
      }

      if (matches.length === 0) {
        hideAutofill();
        return;
      }

      if (showPhishingWarnings) {
        for (const m of matches) {
          const check = checkPhishing(window.location.href, m.code.issuer);
          if (check.isPhishing) {
            phishingWarning = check.warning || "This site does not match known domains for this issuer.";
            break;
          }
        }
      }

      ensureIconUi(input);

      // Nice UX: if there's exactly one strong match and the field is empty, prefill (no autosubmit).
      // Never prefill for low-confidence ("fuzzy") matches.
      if (
        !phishingWarning &&
        prefillSingleMatchEnabled &&
        matches.length === 1 &&
        matches[0]?.matchType !== "fuzzy" &&
        !input.value.trim()
      ) {
        const one = await generateOTP(matches[0]!.code.id);
        if (one?.otp) {
          fillCode(detection, one.otp, false);
        }
      }
    };

    // Handle focus on input fields
    const handleFocus = (e: FocusEvent) => {
      const target = e.target as HTMLInputElement;
      if (target.tagName !== "INPUT") return;

      const detection = getDetectionForFocusedInput(target);
      if (detection) showAutofill(target, detection);
    };

    // Handle blur on input fields
    const handleBlur = (e: FocusEvent) => {
      if (e.target !== currentInput) return;
      setTimeout(() => {
        if (document.activeElement !== currentInput) {
          hideAutofill();
        }
      }, 200);
    };

    // Handle scroll
    const handleScroll = () => {
      if (currentInput && shadowHost) {
        positionIcon(currentInput);
      }
    };

    // Close/hide on outside interactions
    const handleMouseDown = (e: MouseEvent) => {
      if (!shadowHost) return;
      const path = e.composedPath();
      const inHost = path.includes(shadowHost);

      // If the user is switching between OTP fields, avoid hiding to prevent flicker.
      if (!inHost && e.target instanceof HTMLInputElement) {
        const nextDetection = getDetectionForFocusedInput(e.target);
        if (nextDetection) {
          closeDropdown();
          return;
        }
      }

      if (!inHost && e.target !== currentInput) {
        hideAutofill();
        return;
      }

      if (!inHost && dropdownOpen) {
        closeDropdown();
      }
    };

    // Initialize
    document.addEventListener("focus", handleFocus, true);
    document.addEventListener("blur", handleBlur, true);
    document.addEventListener("scroll", handleScroll, true);
    document.addEventListener("mousedown", handleMouseDown, true);

    const observer = new MutationObserver(() => {
      if (currentInput && !document.contains(currentInput)) {
        hideAutofill();
      }
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true,
    });
  },
});
