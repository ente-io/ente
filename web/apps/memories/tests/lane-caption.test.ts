import { createInstance } from "i18next";
import { afterEach, beforeEach, expect, test, vi } from "vitest";
import german from "../../../packages/base/locales/de-DE/translation.json";
import english from "../../../packages/base/locales/en-US/translation.json";
import type { PublicMemoryShareMetadata } from "../src/services/public-memory";
import {
    buildLaneCaptionModel,
    buildLaneTitle,
    laneCaptionNamePlaceholder,
    laneCaptionTimePlaceholder,
    localizeLaneCaption,
} from "../src/utils/lane";

const i18n = createInstance();
beforeEach(async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 9, 16, 12));
    await i18n.init({
        lng: "en-US",
        fallbackLng: "en-US",
        resources: {
            "en-US": { translation: english },
            "de-DE": { translation: german },
        },
        interpolation: { escapeValue: false },
    });
});
afterEach(() => vi.useRealTimers());

const caption = (
    date: Date,
    metadata: Partial<PublicMemoryShareMetadata> = {},
) =>
    buildLaneCaptionModel({
        frame: { fileID: 1, creationTime: date.getTime() * 1000 },
        metadata: { name: "Memory lane", frames: [], ...metadata },
        fallbackLabel: "Memory lane",
    });

test("uses now until the first completed anniversary, including unnamed people", () => {
    const current = caption(new Date(2025, 9, 17), { personName: "Snow now" });
    expect(localizeLaneCaption(current, i18n.t, "en-US")).toMatchObject({
        label: "Snow now now",
        name: "Snow now",
        isNow: true,
    });
    expect(
        localizeLaneCaption(caption(new Date(2026, 9, 16)), i18n.t, "en-US")
            .label,
    ).toBe("now");
    expect(
        localizeLaneCaption(caption(new Date(2025, 9, 16)), i18n.t, "en-US")
            .label,
    ).toBe("1 year ago");
});

test("preserves age mode, including zero and a leap-day birthday", () => {
    const newborn = caption(new Date(2026, 9, 16), { birthDate: "2026-10-16" });
    expect(localizeLaneCaption(newborn, i18n.t, "en-US")).toMatchObject({
        label: "0 years old",
        isNow: false,
    });
    const birthday = caption(new Date(2025, 1, 28), {
        birthDate: "2024-02-29",
        personName: "Ashil",
    });
    expect(localizeLaneCaption(birthday, i18n.t, "en-US").label).toBe(
        "1 year old",
    );
});

test("keeps translated word order and placeholders separate from names", async () => {
    expect(
        buildLaneTitle({
            memoryName: "Ashils Erinnerungen",
            personName: "Ashil",
        }),
    ).toBe("Ashils Erinnerungen");
    await i18n.changeLanguage("de-DE");
    const before = localizeLaneCaption(
        caption(new Date(2025, 9, 16), { personName: "Jetzt" }),
        i18n.t,
        "de-DE",
    );
    expect(before.template).toBe(
        `${laneCaptionNamePlaceholder} vor ${laneCaptionTimePlaceholder} Jahr`,
    );
    expect(before.label).toBe("Jetzt vor 1 Jahr");
    const after = localizeLaneCaption(
        caption(new Date(2026, 9, 16), { personName: "Jetzt" }),
        i18n.t,
        "de-DE",
    );
    expect(after.template).toBe(
        `${laneCaptionNamePlaceholder} ${laneCaptionTimePlaceholder}`,
    );
    expect(after.label).toBe("Jetzt jetzt");
});

test("uses the English fallback direction with an Arabic name and localized number", async () => {
    await i18n.changeLanguage("ar-SA");
    const result = localizeLaneCaption(
        caption(new Date(2025, 9, 16), { personName: "ليلى" }),
        i18n.t,
        "ar-SA",
    );
    expect(result.language).toBe("en-US");
    expect(i18n.dir(result.language)).toBe("ltr");
    expect(result.label).toBe(
        `ليلى ${new Intl.NumberFormat("ar-SA").format(1)} year ago`,
    );
});

test("uses RTL direction when the caption template has an RTL translation", async () => {
    i18n.addResourceBundle("ar-SA", "translation", {
        memory_lane_caption_years_ago_one: "قبل {{number}} عام {{name}}",
    });
    await i18n.changeLanguage("ar-SA");
    const result = localizeLaneCaption(
        caption(new Date(2025, 9, 16), { personName: "ليلى" }),
        i18n.t,
        "ar-SA",
    );
    expect(result.language).toBe("ar-SA");
    expect(i18n.dir(result.language)).toBe("rtl");
    expect(result.template).toBe(
        `قبل ${laneCaptionTimePlaceholder} عام ${laneCaptionNamePlaceholder}`,
    );
});
