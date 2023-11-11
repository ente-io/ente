import React, { useState } from 'react';
import { EnteFile } from 'types/file';
import { changeCaption, updateExistingFilePubMetadata } from 'utils/file';
import { logError } from '@ente/shared/sentry';
import { Box, IconButton, TextField } from '@mui/material';
import { FlexWrapper } from '@ente/shared/components/Container';
import { MAX_CAPTION_SIZE } from 'constants/file';
import { Formik } from 'formik';
import { SmallLoadingSpinner } from '../styledComponents/SmallLoadingSpinner';
import * as Yup from 'yup';
import Close from '@mui/icons-material/Close';
import Done from '@mui/icons-material/Done';
import { t } from 'i18next';

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
        file?.pubMagicMetadata?.data.caption
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
            logError(e, 'failed to update caption');
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
                        t('CAPTION_CHARACTER_LIMIT')
                    ),
                })}
                validateOnBlur={false}
                onSubmit={onSubmit}>
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
                            placeholder={t('CAPTION_PLACEHOLDER')}
                            value={values.caption}
                            onChange={handleChange('caption')}
                            error={Boolean(errors.caption)}
                            helperText={errors.caption}
                            disabled={loading || shouldDisableEdits}
                        />
                        {values.caption !== caption && (
                            <FlexWrapper justifyContent={'flex-end'}>
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
                                            values: { caption: caption ?? '' },
                                            touched: { caption: false },
                                        })
                                    }
                                    disabled={loading}>
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
