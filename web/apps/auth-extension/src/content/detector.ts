/**
 * MFA field detection algorithm.
 * Detects input fields likely asking for MFA codes.
 */
import type { MFAFieldDetection } from "@shared/types";

/**
 * Attribute patterns that suggest MFA input.
 */
const MFA_ATTRIBUTE_PATTERNS = [
    "otp",
    "totp",
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
];

/**
 * Label/placeholder patterns that suggest MFA input.
 */
const MFA_LABEL_PATTERNS = [
    "verification code",
    "verification-code",
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
];

/**
 * Check if a string matches any MFA pattern.
 */
const matchesPattern = (value: string | null, patterns: string[]): boolean => {
    if (!value) return false;
    const lower = value.toLowerCase();
    return patterns.some((pattern) => lower.includes(pattern));
};

/**
 * Calculate confidence score for a single input element.
 */
const calculateConfidence = (input: HTMLInputElement): number => {
    let confidence = 0;

    // Check autocomplete="one-time-code" (high confidence)
    if (input.autocomplete === "one-time-code") {
        confidence += 0.6;
    }

    // Check name/id attributes
    const nameOrId = `${input.name || ""} ${input.id || ""}`;
    if (matchesPattern(nameOrId, MFA_ATTRIBUTE_PATTERNS)) {
        confidence += 0.3;
    }

    // Check placeholder
    if (matchesPattern(input.placeholder, MFA_LABEL_PATTERNS)) {
        confidence += 0.25;
    }

    // Check pattern attribute for 6 digits
    const pattern = input.pattern;
    if (pattern && (/\[0-9\]\{6\}/.test(pattern) || /\\d\{6\}/.test(pattern))) {
        confidence += 0.3;
    }

    // Check inputmode="numeric" with maxlength="6"
    if (input.inputMode === "numeric" && input.maxLength === 6) {
        confidence += 0.35;
    }

    // Check for maxlength of 6 (common for OTP)
    if (input.maxLength === 6) {
        confidence += 0.15;
    }

    // Check type="tel" or type="number" (common for numeric codes)
    if (input.type === "tel" || input.type === "number") {
        confidence += 0.1;
    }

    // Check for associated label
    const label = findLabelForInput(input);
    if (label && matchesPattern(label.textContent, MFA_LABEL_PATTERNS)) {
        confidence += 0.25;
    }

    // Check aria-label
    if (matchesPattern(input.getAttribute("aria-label"), MFA_LABEL_PATTERNS)) {
        confidence += 0.2;
    }

    // Check if input is within a form/section with MFA-related text
    const container = input.closest("form, section, div[class*='auth'], div[class*='mfa'], div[class*='otp']");
    if (container) {
        const containerText = container.textContent?.toLowerCase() || "";
        if (MFA_LABEL_PATTERNS.some((p) => containerText.includes(p))) {
            confidence += 0.15;
        }
    }

    return Math.min(confidence, 1);
};

/**
 * Find the label element for an input.
 */
const findLabelForInput = (input: HTMLInputElement): HTMLLabelElement | null => {
    // Check for explicit label via for attribute
    if (input.id) {
        const label = document.querySelector(`label[for="${input.id}"]`);
        if (label) return label as HTMLLabelElement;
    }

    // Check for parent label
    const parentLabel = input.closest("label");
    if (parentLabel) return parentLabel as HTMLLabelElement;

    return null;
};

/**
 * Detect split OTP inputs (6 adjacent single-character inputs).
 */
const detectSplitInputs = (): MFAFieldDetection | null => {
    const allInputs = document.querySelectorAll<HTMLInputElement>(
        'input[maxlength="1"][type="text"], input[maxlength="1"][type="tel"], input[maxlength="1"][type="number"], input[maxlength="1"]:not([type])'
    );

    // Find groups of 6 adjacent inputs
    const groups: HTMLInputElement[][] = [];
    let currentGroup: HTMLInputElement[] = [];

    allInputs.forEach((input) => {
        if (!input.offsetParent) return; // Skip hidden inputs

        if (currentGroup.length === 0) {
            currentGroup.push(input);
        } else {
            const lastInput = currentGroup[currentGroup.length - 1]!;
            // Check if inputs are siblings or close in DOM
            const isSibling =
                lastInput.nextElementSibling === input ||
                lastInput.parentElement === input.parentElement;
            const isClose =
                lastInput.parentElement?.parentElement ===
                input.parentElement?.parentElement;

            if (isSibling || isClose) {
                currentGroup.push(input);
            } else {
                if (currentGroup.length >= 6) {
                    groups.push(currentGroup);
                }
                currentGroup = [input];
            }
        }
    });

    if (currentGroup.length >= 6) {
        groups.push(currentGroup);
    }

    // Return the first group of 6 inputs
    for (const group of groups) {
        if (group.length === 6) {
            return {
                element: group[0]!,
                confidence: 0.85,
                type: "split",
                splitInputs: group,
            };
        }
    }

    return null;
};

/**
 * Detect all MFA fields on the page.
 */
export const detectMFAFields = (): MFAFieldDetection[] => {
    const detections: MFAFieldDetection[] = [];

    // First, check for split inputs
    const splitDetection = detectSplitInputs();
    if (splitDetection) {
        detections.push(splitDetection);
    }

    // Then check single inputs
    const inputs = document.querySelectorAll<HTMLInputElement>(
        'input[type="text"], input[type="tel"], input[type="number"], input:not([type])'
    );

    inputs.forEach((input) => {
        // Skip hidden inputs
        if (!input.offsetParent) return;

        // Skip if already part of a split detection
        if (splitDetection?.splitInputs?.includes(input)) return;

        // Skip password fields
        if (input.type === "password") return;

        const confidence = calculateConfidence(input);
        if (confidence >= 0.3) {
            detections.push({
                element: input,
                confidence,
                type: "single",
            });
        }
    });

    // Sort by confidence
    detections.sort((a, b) => b.confidence - a.confidence);

    return detections;
};

/**
 * Check if the page likely has an MFA prompt.
 */
export const hasMFAPrompt = (): boolean => {
    const detections = detectMFAFields();
    return detections.some((d) => d.confidence >= 0.5);
};

/**
 * Get the best MFA field detection.
 */
export const getBestMFAField = (): MFAFieldDetection | null => {
    const detections = detectMFAFields();
    const best = detections.find((d) => d.confidence >= 0.5);
    return best || null;
};
