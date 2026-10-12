import { expect, test } from "vitest";
import { viewerOriginKey } from "../src/components/viewer-transition";

test("tiles are matched by space and post", () => {
    expect(viewerOriginKey("space", 12)).toBe("space:12");
    expect(viewerOriginKey("space", 0)).toBe("space:0");
    expect(viewerOriginKey(undefined, 12)).toBeUndefined();
    expect(viewerOriginKey("space", undefined)).toBeUndefined();
});
