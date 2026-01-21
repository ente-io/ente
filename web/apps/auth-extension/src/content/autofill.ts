/**
 * Auto-fill functionality for MFA codes.
 */
import type { MFAFieldDetection } from "@shared/types";

/**
 * Fill an MFA code into the detected field(s) and optionally submit.
 */
export const fillCode = (detection: MFAFieldDetection, code: string, autoSubmit = true): void => {
    if (detection.type === "split" && detection.splitInputs) {
        fillSplitInputs(detection.splitInputs, code);
    } else {
        fillSingleInput(detection.element, code);
    }

    // Auto-submit after a short delay to let frameworks process the input
    if (autoSubmit) {
        setTimeout(() => {
            clickSubmitButton(detection.element);
        }, 100);
    }
};

/**
 * Fill a single input field.
 */
const fillSingleInput = (input: HTMLInputElement, code: string): void => {
    // Focus the input
    input.focus();

    // Set the value
    input.value = code;

    // Trigger input events to notify frameworks
    triggerInputEvents(input);
};

/**
 * Fill split inputs (one character per field).
 */
const fillSplitInputs = (inputs: HTMLInputElement[], code: string): void => {
    const digits = code.split("");

    inputs.forEach((input, index) => {
        if (index < digits.length) {
            input.focus();
            input.value = digits[index]!;
            triggerInputEvents(input);
        }
    });

    // Focus the last filled input
    if (inputs.length > 0) {
        const lastIndex = Math.min(digits.length - 1, inputs.length - 1);
        inputs[lastIndex]?.focus();
    }
};

/**
 * Trigger input events to notify frameworks (React, Vue, Angular, etc.).
 */
const triggerInputEvents = (input: HTMLInputElement): void => {
    // Create and dispatch events
    const inputEvent = new Event("input", { bubbles: true, cancelable: true });
    const changeEvent = new Event("change", { bubbles: true, cancelable: true });

    // For React synthetic events
    const nativeInputValueSetter = Object.getOwnPropertyDescriptor(
        window.HTMLInputElement.prototype,
        "value"
    )?.set;

    if (nativeInputValueSetter) {
        nativeInputValueSetter.call(input, input.value);
    }

    input.dispatchEvent(inputEvent);
    input.dispatchEvent(changeEvent);

    // Also trigger keydown/keyup for some frameworks
    input.dispatchEvent(
        new KeyboardEvent("keydown", { bubbles: true, cancelable: true })
    );
    input.dispatchEvent(
        new KeyboardEvent("keyup", { bubbles: true, cancelable: true })
    );
};

/**
 * Clear an MFA field.
 */
export const clearField = (detection: MFAFieldDetection): void => {
    if (detection.type === "split" && detection.splitInputs) {
        detection.splitInputs.forEach((input) => {
            input.value = "";
            triggerInputEvents(input);
        });
    } else {
        detection.element.value = "";
        triggerInputEvents(detection.element);
    }
};

/**
 * Find and click the submit button associated with an MFA input.
 */
const clickSubmitButton = (input: HTMLInputElement): void => {
    // Strategy 1: Find submit button in the same form
    const form = input.closest("form");
    if (form) {
        const submitButton = form.querySelector<HTMLButtonElement | HTMLInputElement>(
            'button[type="submit"], input[type="submit"], button:not([type])'
        );
        if (submitButton) {
            console.log("[Ente Auth] Clicking submit button in form");
            submitButton.click();
            return;
        }
    }

    // Strategy 2: Find a button near the input (within a common container)
    const container = input.closest("div, section, article, main") || document.body;
    const buttons = container.querySelectorAll<HTMLButtonElement>("button");

    for (const button of buttons) {
        const text = button.textContent?.toLowerCase() || "";
        const ariaLabel = button.getAttribute("aria-label")?.toLowerCase() || "";

        // Look for common submit button text
        if (
            text.includes("submit") ||
            text.includes("verify") ||
            text.includes("confirm") ||
            text.includes("continue") ||
            text.includes("sign in") ||
            text.includes("login") ||
            text.includes("log in") ||
            ariaLabel.includes("submit") ||
            ariaLabel.includes("verify")
        ) {
            console.log("[Ente Auth] Clicking button with text:", text.trim());
            button.click();
            return;
        }
    }

    // Strategy 3: Submit the form directly if we found one
    if (form) {
        console.log("[Ente Auth] Submitting form directly");
        form.requestSubmit();
        return;
    }

    console.log("[Ente Auth] No submit button found");
};
