import assert from "node:assert/strict";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import { webkit } from "playwright";
import { createServer } from "vite";

await test("an inactive preloaded slide renders its decoded frame when partially revealed", async (t) => {
    const server = await createServer({
        configFile: false,
        root: fileURLToPath(new URL("../..", import.meta.url)),
        oxc: { jsx: { runtime: "automatic" } },
        define: { "process.env": JSON.stringify({ appName: "space" }) },
        resolve: {
            alias: {
                components: fileURLToPath(
                    new URL("../../src/components", import.meta.url),
                ),
                services: fileURLToPath(
                    new URL("../../src/services", import.meta.url),
                ),
            },
        },
        server: { host: "127.0.0.1", port: 0 },
    });
    t.after(() => server.close());
    await server.listen();
    const browser = await webkit.launch();
    t.after(() => browser.close());
    const page = await browser.newPage({
        viewport: { width: 320, height: 480 },
        deviceScaleFactor: 1,
        isMobile: true,
        hasTouch: true,
    });
    const errors: Error[] = [];
    page.on("pageerror", (error) => errors.push(error));
    await page.goto(`${server.resolvedUrls!.local[0]}tests/browser/index.html`);
    await page.waitForFunction(() => {
        const videos = document.querySelectorAll("video");
        return (
            videos.length == 2 &&
            !videos[0]!.paused &&
            videos[1]!.readyState >= HTMLMediaElement.HAVE_CURRENT_DATA
        );
    });
    await page.locator("article").evaluate((element) => {
        element.scrollLeft = 160;
    });
    const next = page.locator("video").nth(1);
    assert.equal(
        await next.evaluate((video: HTMLVideoElement) => video.paused),
        true,
    );
    assert.equal(
        await next.evaluate((video: HTMLVideoElement) => video.currentTime),
        0,
    );
    const screenshot = await page.screenshot({
        clip: { x: 176, y: 16, width: 128, height: 208 },
    });
    const pixels = await page.evaluate(async (base64) => {
        const image = new Image();
        image.src = `data:image/png;base64,${base64}`;
        await image.decode();
        const canvas = document.createElement("canvas");
        canvas.width = image.width;
        canvas.height = image.height;
        const context = canvas.getContext("2d")!;
        context.drawImage(image, 0, 0);
        const { data } = context.getImageData(
            0,
            0,
            canvas.width,
            canvas.height,
        );
        let green = 0;
        let blue = 0;
        for (let i = 0; i < data.length; i += 4) {
            if (
                data[i + 1]! - data[i]! > 100 &&
                data[i + 1]! - data[i + 2]! > 100
            )
                green++;
            if (
                data[i + 2]! - data[i]! > 100 &&
                data[i + 2]! - data[i + 1]! > 100
            )
                blue++;
        }
        return {
            green: green / (data.length / 4),
            blue: blue / (data.length / 4),
        };
    }, screenshot.toString("base64"));
    assert.ok(
        pixels.green > 0.45,
        `Missing green video pixels: ${pixels.green}`,
    );
    assert.ok(pixels.blue > 0.45, `Missing blue video pixels: ${pixels.blue}`);
    assert.equal(
        await next.evaluate((video: HTMLVideoElement) => video.paused),
        true,
    );
    assert.equal(
        await next.evaluate((video: HTMLVideoElement) => video.currentTime),
        0,
    );
    assert.deepEqual(errors, []);
});
