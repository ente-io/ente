import { afterEach, beforeEach, expect, test, vi } from "vitest";
import type { PublicMemoryShareMetadata } from "../src/services/public-memory";
import {
    buildLaneCaptionModel,
    buildLaneTitle,
    laneCaptionNamePlaceholder,
    laneCaptionTimePlaceholder,
} from "../src/utils/lane";

beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(2026, 9, 16, 12));
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

test("uses now until the first completed anniversary, keeping names separate", () => {
    expect(
        caption(new Date(2025, 9, 17), { personName: "Snow now" }),
    ).toMatchObject({
        text: "Snow now now",
        template: `${laneCaptionNamePlaceholder} ${laneCaptionTimePlaceholder}`,
        name: "Snow now",
        time: "now",
        isNow: true,
    });
    expect(caption(new Date(2026, 9, 16))).toMatchObject({
        text: "now",
        template: laneCaptionTimePlaceholder,
        name: "",
        time: "now",
        isNow: true,
    });
    expect(
        caption(new Date(2025, 9, 16), { personName: "ليلى" }),
    ).toMatchObject({
        text: "ليلى 1 year ago",
        template: `${laneCaptionNamePlaceholder} ${laneCaptionTimePlaceholder} year ago`,
        name: "ليلى",
        time: "1",
        value: 1,
        isNow: false,
    });
});

test("preserves age captions, including zero and a leap-day birthday", () => {
    expect(
        caption(new Date(2026, 9, 16), { birthDate: "2026-10-16" }),
    ).toMatchObject({
        text: "0 years old",
        template: `${laneCaptionTimePlaceholder} years old`,
        time: "0",
        value: 0,
        isNow: false,
    });
    expect(
        caption(new Date(2025, 1, 28), {
            birthDate: "2024-02-29",
            personName: "Ashil",
        }),
    ).toMatchObject({
        text: "1 year old",
        template: `${laneCaptionTimePlaceholder} year old`,
        name: "",
        time: "1",
        value: 1,
        isNow: false,
    });
});

test("uses the supplied label when a frame has no capture date", () => {
    expect(
        buildLaneCaptionModel({ fallbackLabel: "Erinnerungen" }),
    ).toMatchObject({
        text: "Erinnerungen",
        template: "Erinnerungen",
        name: "",
        time: "",
        isNow: false,
    });
});

test("personalizes legacy lane titles while preserving translated named titles", () => {
    for (const [memoryName, personName, expected] of [
        ["Memory lane", "Alice", "Alice's memory lane"],
        ["Album", "Al", "Al's memory lane"],
        ["Erinnerungen", "Ashil", "Ashil's memory lane"],
        ["Ashils Erinnerungen", "Ashil", "Ashils Erinnerungen"],
        ["Kỷ niệm của Ashil", "Ashil", "Kỷ niệm của Ashil"],
        ["Ashil님의 추억의 길", "Ashil", "Ashil님의 추억의 길"],
        ["Alex (Dad)s Erinnerungen", "Alex (Dad)", "Alex (Dad)s Erinnerungen"],
        ["Erinnerungen", "", "Erinnerungen"],
    ] as const) {
        expect(buildLaneTitle({ memoryName, personName })).toBe(expected);
    }
});
