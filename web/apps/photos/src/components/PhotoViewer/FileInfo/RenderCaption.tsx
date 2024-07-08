import { EnteFile } from "@/new/photos/types/file";
import log from "@/next/log";
import { FlexWrapper } from "@ente/shared/components/Container";
import Close from "@mui/icons-material/Close";
import Done from "@mui/icons-material/Done";
import { Box, IconButton, TextField } from "@mui/material";
import { Formik } from "formik";
import { t } from "i18next";
import { useState } from "react";
import { changeCaption, updateExistingFilePubMetadata } from "utils/file";
import * as Yup from "yup";
import { SmallLoadingSpinner } from "../styledComponents/SmallLoadingSpinner";

export const MAX_CAPTION_SIZE = 5000;

interface formValues {
    caption: string;
}

export function RenderCaption({
    file,
    scheduleUpdate,
    refreshPhotoswipe,
    shouldDisableEdits,
}: {
    shouldDisableEdits: boolean;
    file: EnteFile;
    scheduleUpdate: () => void;
    refreshPhotoswipe: () => void;
}) {
    const [caption, setCaption] = useState(
        file?.pubMagicMetadata?.data.caption,
    );

    const [loading, setLoading] = useState(false);

    const saveEdits = async (newCaption: string) => {
        try {
            if (file) {
                if (caption === newCaption) {
                    return;
                }
                setCaption(newCaption);

                const updatedFile = await changeCaption(file, newCaption);
                updateExistingFilePubMetadata(file, updatedFile);
                file.title = file.pubMagicMetadata.data.caption;
                refreshPhotoswipe();
                scheduleUpdate();
            }
        } catch (e) {
            log.error("failed to update caption", e);
        }
    };

    const onSubmit = async (values: formValues) => {
        try {
            setLoading(true);
            await saveEdits(values.caption);
        } finally {
            setLoading(false);
        }
    };
    if (!caption?.length && shouldDisableEdits) {
        return <></>;
    }
    return (
        <Box p={1}>
            <Formik<formValues>
                initialValues={{ caption }}
                validationSchema={Yup.object().shape({
                    caption: Yup.string().max(
                        MAX_CAPTION_SIZE,
                        t("CAPTION_CHARACTER_LIMIT"),
                    ),
                })}
                validateOnBlur={false}
                onSubmit={onSubmit}
            >
                {({
                    values,
                    errors,
                    handleChange,
                    handleSubmit,
                    resetForm,
                }) => (
                    <form noValidate onSubmit={handleSubmit}>
                        <TextField
                            hiddenLabel
                            fullWidth
                            id="caption"
                            name="caption"
                            type="text"
                            multiline
                            placeholder={t("CAPTION_PLACEHOLDER")}
                            value={values.caption}
                            onChange={handleChange("caption")}
                            error={Boolean(errors.caption)}
                            helperText={errors.caption}
                            disabled={loading || shouldDisableEdits}
                        />
                        {values.caption !== caption && (
                            <FlexWrapper justifyContent={"flex-end"}>
                                <IconButton type="submit" disabled={loading}>
                                    {loading ? (
                                        <SmallLoadingSpinner />
                                    ) : (
                                        <Done />
                                    )}
                                </IconButton>
                                <IconButton
                                    onClick={() =>
                                        resetForm({
                                            values: { caption: caption ?? "" },
                                            touched: { caption: false },
                                        })
                                    }
                                    disabled={loading}
                                >
                                    <Close />
                                </IconButton>
                            </FlexWrapper>
                        )}
                    </form>
                )}
            </Formik>
        </Box>
    );
}
