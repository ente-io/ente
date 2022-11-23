import React, { useState } from 'react';
import constants from 'utils/strings/constants';
import { Formik } from 'formik';
import * as Yup from 'yup';
import { MAX_CAPTION_SIZE } from 'constants/file';
import { IconButton, TextField } from '@mui/material';
import { SmallLoadingSpinner } from '../styledComponents/SmallLoadingSpinner';
import CloseIcon from '@mui/icons-material/Close';
import TickIcon from '@mui/icons-material/Check';
import { FlexWrapper } from 'components/Container';
export interface formValues {
    caption: string;
}
interface Iprops {
    openEditMode: () => void;
    caption: string;
    isInEditMode: boolean;
    saveEdits: (caption: string) => Promise<void>;
    discardEdits: () => void;
}

export const CaptionEditForm = ({
    openEditMode,
    caption,
    isInEditMode,
    saveEdits,
    discardEdits,
}: Iprops): JSX.Element => {
    const [loading, setLoading] = useState(false);

    const onSubmit = async (values: formValues) => {
        try {
            setLoading(true);
            await saveEdits(values.caption);
        } finally {
            setLoading(false);
        }
    };
    return (
        <Formik<formValues>
            initialValues={{ caption }}
            validationSchema={Yup.object().shape({
                caption: Yup.string().max(
                    MAX_CAPTION_SIZE,
                    constants.CAPTION_CHARACTER_LIMIT
                ),
            })}
            validateOnBlur={false}
            onSubmit={onSubmit}>
            {({ values, errors, handleChange, handleSubmit }) => (
                <form noValidate onSubmit={handleSubmit} onClick={openEditMode}>
                    <TextField
                        fullWidth
                        id="caption"
                        name="caption"
                        type="text"
                        multiline
                        label={constants.CAPTION_PLACEHOLDER}
                        value={values.caption}
                        onChange={handleChange('caption')}
                        error={Boolean(errors.caption)}
                        helperText={errors.caption}
                        disabled={loading || !isInEditMode}
                    />
                    {isInEditMode && (
                        <FlexWrapper justifyContent={'flex-end'}>
                            <IconButton type="submit" disabled={loading}>
                                {loading ? (
                                    <SmallLoadingSpinner />
                                ) : (
                                    <TickIcon />
                                )}
                            </IconButton>
                            <IconButton
                                onClick={discardEdits}
                                disabled={loading}>
                                <CloseIcon />
                            </IconButton>
                        </FlexWrapper>
                    )}
                </form>
            )}
        </Formik>
    );
};
