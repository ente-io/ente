import { expect, test } from "vitest";
import { itemFormDataForSave } from "../src/components/create-item/item-form-fields-utils";

test("content-only notes derive a title from the first five words", () => {
    expect(
        itemFormDataForSave("note", {
            title: "",
            content: "  Remember where the spare key lives\nMore details  ",
        }),
    ).toEqual({
        title: "Remember where the spare key",
        content: "  Remember where the spare key lives\nMore details  ",
    });
});

test("long generated note titles use mobile's 40-character limit", () => {
    expect(
        itemFormDataForSave("note", {
            content: "Antidisestablishmentarianism and several other details",
        }).title,
    ).toBe("Antidisestablishmentarianism and several...");
});

test("an explicit note title is kept, and clearing it regenerates the title", () => {
    expect(
        itemFormDataForSave("note", {
            title: "  My own title  ",
            content: "New content",
        }).title,
    ).toBe("  My own title  ");
    expect(
        itemFormDataForSave("note", { title: "", content: "New content" })
            .title,
    ).toBe("New content");
});

test("cleared Thing and Secret fields are omitted on save", () => {
    expect(
        itemFormDataForSave("physicalRecord", {
            name: "  Spare key  ",
            location: "  ",
            notes: "",
        }),
    ).toEqual({ name: "  Spare key  ", location: "  " });
    expect(
        itemFormDataForSave("accountCredential", {
            name: "  Netflix  ",
            username: "",
            password: "",
            notes: "",
        }),
    ).toEqual({ name: "  Netflix  " });
});

test.each([" secret", "secret ", " secret ", "   "])(
    "saving a Secret preserves password whitespace: %j",
    (password) => {
        const data = itemFormDataForSave("accountCredential", {
            name: "  Account  ",
            username: "  user  ",
            password,
            notes: "  Notes  ",
        });
        expect(data).toEqual({
            name: "  Account  ",
            username: "  user  ",
            password,
            notes: "  Notes  ",
        });
        expect(
            itemFormDataForSave("accountCredential", {
                ...data,
                name: "Renamed",
            }),
        ).toEqual({
            name: "Renamed",
            username: "  user  ",
            password,
            notes: "  Notes  ",
        });
    },
);

const infoFields = [
    ["note", ["title", "content"]],
    ["accountCredential", ["name", "username", "password", "notes"]],
    ["physicalRecord", ["name", "location", "notes"]],
    ["emergencyContact", ["name", "contactDetails", "notes"]],
] as const;

for (const [type, fields] of infoFields) {
    test.each(["  entered text  ", " \t\u00a0 ", "line one\nline two\n"])(
        `${type} preserves all entered field values: %j`,
        (value) => {
            const data = Object.fromEntries(
                fields.map((field) => [field, value]),
            );
            expect(itemFormDataForSave(type, data)).toEqual(data);
            expect(
                itemFormDataForSave(
                    type,
                    JSON.parse(JSON.stringify(data)) as Record<string, string>,
                ),
            ).toEqual(data);
        },
    );
}

test("generated note titles ignore leading blank lines without changing content", () => {
    const content = "\n\n  one two three four five six\nsecond line\n";
    expect(itemFormDataForSave("note", { title: "", content })).toEqual({
        title: "one two three four five",
        content,
    });
});

test("whitespace-only note titles remain explicit titles", () => {
    expect(
        itemFormDataForSave("note", { title: " \t ", content: "Body" }),
    ).toEqual({ title: " \t ", content: "Body" });
});

test("file forms retain filename trimming", () => {
    expect(itemFormDataForSave("file", { name: "  notes.txt  " })).toEqual({
        name: "notes.txt",
    });
    expect(itemFormDataForSave("file", { name: "   " })).toEqual({});
});
