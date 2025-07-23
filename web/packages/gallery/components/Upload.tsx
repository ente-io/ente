/**
 * The upload can be triggered by different buttons and flows in the UI, each of
 * which is referred to as an "intent".
 *
 * The "intent" does not change the eventual upload outcome, only the UX flow.
 */
export type UploadTypeSelectorIntent = "upload" | "import" | "collect";
