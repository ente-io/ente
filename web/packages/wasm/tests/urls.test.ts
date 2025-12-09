import { expect, test } from "vitest";
import { file_download_url } from "../pkg/ente_wasm.js";

test("generates CDN URL for production", () => {
    const url = file_download_url("https://api.ente.io", BigInt(12345));
    expect(url).toBe("https://files.ente.io/?fileID=12345");
});

test("generates direct URL for custom server", () => {
    const url = file_download_url("https://my-server.example.com", BigInt(99));
    expect(url).toBe("https://my-server.example.com/files/download/99");
});
