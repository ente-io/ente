export const CONCURRENCY = Math.max(
    2,
    Math.ceil(navigator.hardwareConcurrency / 2)
);
