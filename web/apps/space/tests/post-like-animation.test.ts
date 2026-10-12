import { expect, test } from "vitest";
import { pickLikeVariant } from "../src/components/post-like-animation";

test("a like never plays the same animation twice in a row", () => {
    for (const previous of [0, 2, 4]) {
        for (const random of [0, 0.4, 0.99]) {
            expect(pickLikeVariant(previous, () => random)).not.toBe(previous);
        }
    }
});

test("the first like can play any of the three animations", () => {
    const picked = new Set(
        [0, 0.4, 0.99].map((random) => pickLikeVariant(-1, () => random)),
    );

    expect(picked).toEqual(new Set([0, 2, 4]));
});
