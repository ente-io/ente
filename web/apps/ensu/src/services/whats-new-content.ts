export interface WhatsNewEntry {
    readonly title: string;
    readonly description: string;
}

export const whatsNewVersion = 1;

export const whatsNewEntries: readonly WhatsNewEntry[] = [
    {
        title: "In-app release notes",
        description:
            "Ensu can now show a short What's new note after updates, with platform-specific entries and a changelog version independent from the app build version.",
    },
];
