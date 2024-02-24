import { runningInBrowser } from ".";

export const getConcurrency = () =>
    runningInBrowser() &&
    Math.max(2, Math.ceil(navigator.hardwareConcurrency / 2));
