import en from "ente-base/locales/en-US/translation.json";
import es from "ente-base/locales/es-ES/translation.json";
import fr from "ente-base/locales/fr-FR/translation.json";
import { trashFilesDialogAttributes } from "ente-gallery/components/trash-files-dialog";
import i18n from "i18next";
import { beforeEach, expect, test } from "vitest";

beforeEach(async () => {
    await i18n.init({
        lng: "en-US",
        fallbackLng: "en-US",
        resources: {
            "en-US": { translation: en },
            "fr-FR": {
                translation: {
                    trash_file_title: fr.trash_file_title,
                    trash_file_message: fr.trash_file_message,
                    trash_files_title: fr.trash_files_title,
                    trash_files_message: fr.trash_files_message,
                },
            },
            "es-ES": {
                translation: {
                    trash_file_title: es.trash_file_title,
                    trash_file_message: es.trash_file_message,
                    trash_files_title: es.trash_files_title,
                    trash_files_message: es.trash_files_message,
                },
            },
        },
    });
});

test("keeps singular and plural English confirmations", () => {
    expect(trashFilesDialogAttributes(1)).toMatchObject({
        title: "Delete 1 item?",
        message: en.trash_items_message_one,
    });
    expect(trashFilesDialogAttributes(2)).toMatchObject({
        title: "Delete 2 items?",
        message: en.trash_items_message_other,
    });
});

test.each([
    ["fr-FR", fr],
    ["es-ES", es],
] as const)("retains existing translations in %s", async (locale, strings) => {
    await i18n.changeLanguage(locale);
    for (const count of [1, 2]) {
        expect(trashFilesDialogAttributes(count)).toMatchObject({
            title:
                count === 1
                    ? strings.trash_file_title
                    : strings.trash_files_title,
            message:
                count === 1
                    ? strings.trash_file_message
                    : strings.trash_files_message,
        });
    }
});

test("uses new translated copy independently for each key", async () => {
    i18n.addResourceBundle("fr-FR", "translation", {
        trash_items_title_one: "Supprimer {{count}} fichier ?",
        trash_items_title_other: "Supprimer {{count}} fichiers ?",
    });
    await i18n.changeLanguage("fr-FR");
    expect(trashFilesDialogAttributes(2)).toMatchObject({
        title: "Supprimer 2 fichiers ?",
        message: fr.trash_files_message,
    });
});
