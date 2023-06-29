import React, { useMemo, useState } from 'react';
import { Formik, FormikHelpers, FormikState } from 'formik';
import * as Yup from 'yup';
import SubmitButton from './SubmitButton';
import TextField from '@mui/material/TextField';
import { FlexWrapper } from './Container';
import { Button, FormHelperText, Stack } from '@mui/material';
import { t } from 'i18next';
import Autocomplete from '@mui/material/Autocomplete';
import { MenuItemGroup } from './Menu/MenuItemGroup';
import { EnteMenuItem } from './Menu/EnteMenuItem';
import MenuItemDivider from './Menu/MenuItemDivider';
import MenuSectionTitle from './Menu/MenuSectionTitle';
import AvatarCollectionShare from './Collections/CollectionShare/AvatarCollectionShare';

interface formValues {
    inputValue: string;
}
export interface SingleInputAutocompleteProps {
    callback: (
        inputValue: string,
        setFieldError: (errorMessage: string) => void,
        resetForm: (nextState?: Partial<FormikState<formValues>>) => void
    ) => Promise<void>;
    fieldType: 'text' | 'email' | 'password';
    placeholder: string;
    buttonText: string;
    submitButtonProps?: any;
    initialValue?: string;
    secondaryButtonAction?: () => void;
    disableAutoFocus?: boolean;
    hiddenPreInput?: any;
    caption?: any;
    hiddenPostInput?: any;
    autoComplete?: string;
    blockButton?: boolean;
    hiddenLabel?: boolean;
    optionsList?: string[];
}

export default function SingleInputAutocomplete(
    props: SingleInputAutocompleteProps
) {
    const [selectedOptions, setSelectedOptions] = useState([]);

    const { submitButtonProps } = props;
    const { sx: buttonSx, ...restSubmitButtonProps } = submitButtonProps ?? {};

    const [loading, SetLoading] = useState(false);

    const submitForm = async (
        values: formValues,
        { setFieldError, resetForm }: FormikHelpers<formValues>
    ) => {
        SetLoading(true);
        await props.callback(
            values.inputValue,
            (message) => setFieldError('inputValue', message),
            resetForm
        );

        if (props.optionsList && props.optionsList.length > 0) {
            setSelectedOptions([...selectedOptions, values.inputValue]);
        }

        SetLoading(false);
    };

    const validationSchema = useMemo(() => {
        switch (props.fieldType) {
            case 'text':
                return Yup.object().shape({
                    inputValue: Yup.string().required(t('REQUIRED')),
                });
            case 'email':
                return Yup.object().shape({
                    inputValue: Yup.string()
                        .email(t('EMAIL_ERROR'))
                        .required(t('REQUIRED')),
                });
        }
    }, [props.fieldType]);

    return (
        <Formik<formValues>
            initialValues={{ inputValue: props.initialValue ?? '' }}
            onSubmit={submitForm}
            validationSchema={validationSchema}
            validateOnChange={false}
            validateOnBlur={false}>
            {({
                values,
                errors,
                handleChange,
                handleSubmit,
                setFieldValue,
            }) => (
                <form noValidate onSubmit={handleSubmit}>
                    {props.hiddenPreInput}

                    <Autocomplete
                        id="free-solo-demo"
                        filterSelectedOptions
                        freeSolo
                        value={values.inputValue}
                        options={props.optionsList
                            .map((option) => option.toString())
                            .filter(
                                (option) => !selectedOptions.includes(option)
                            )}
                        onChange={(event, newValue) => {
                            setFieldValue('inputValue', newValue);
                        }}
                        renderInput={(params) => (
                            <TextField
                                {...params}
                                hiddenLabel={props.hiddenLabel}
                                fullWidth
                                type={props.fieldType}
                                id={props.fieldType}
                                onChange={handleChange('inputValue')}
                                name={props.fieldType}
                                {...(props.hiddenLabel
                                    ? { placeholder: props.placeholder }
                                    : { label: props.placeholder })}
                                error={Boolean(errors.inputValue)}
                                helperText={errors.inputValue}
                                value={values.inputValue}
                                disabled={loading}
                                autoFocus={!props.disableAutoFocus}
                                autoComplete={props.autoComplete}
                            />
                        )}
                    />
                    <Stack py={'10px'} px={'8px'}>
                        {' '}
                    </Stack>
                    <MenuSectionTitle title={t('or add an existing one')} />

                    <MenuItemGroup>
                        {props.optionsList.map((item, index) => (
                            <>
                                <EnteMenuItem
                                    //
                                    fontWeight="normal"
                                    key={item}
                                    onClick={() => {
                                        setFieldValue('inputValue', item);
                                    }}
                                    label={item}
                                    startIcon={
                                        <AvatarCollectionShare email={item} />
                                    }
                                />
                                {index !== props.optionsList.length - 1 && (
                                    <MenuItemDivider />
                                )}
                            </>
                        ))}
                    </MenuItemGroup>

                    <FormHelperText
                        sx={{
                            position: 'relative',
                            top: errors.inputValue ? '-22px' : '0',
                            float: 'right',
                            padding: '0 8px',
                        }}>
                        {props.caption}
                    </FormHelperText>
                    {props.hiddenPostInput}

                    <Stack py={'20px'} px={'8px'} spacing={'8px'}>
                        {' '}
                    </Stack>

                    <MenuSectionTitle
                        title={t(
                            'Collaborators can add photos and videos to the shared album.'
                        )}
                    />
                    <Stack py={'5px'} px={'8px'}>
                        {' '}
                    </Stack>

                    <FlexWrapper
                        justifyContent={'center'}
                        flexWrap={
                            props.blockButton ? 'wrap-reverse' : 'nowrap'
                        }>
                        {props.secondaryButtonAction && (
                            <Button
                                onClick={props.secondaryButtonAction}
                                size="large"
                                color="secondary"
                                sx={{
                                    '&&&': {
                                        mt: !props.blockButton ? 2 : 0.5,
                                        mb: !props.blockButton ? 4 : 0,
                                        mr: !props.blockButton ? 1 : 0,
                                        ...buttonSx,
                                    },
                                }}
                                {...restSubmitButtonProps}>
                                {t('CANCEL')}
                            </Button>
                        )}

                        <SubmitButton
                            sx={{
                                '&&&': {
                                    mt: 2,
                                    ...buttonSx,
                                },
                            }}
                            buttonText={props.buttonText}
                            loading={loading}
                            {...restSubmitButtonProps}
                        />
                    </FlexWrapper>
                </form>
            )}
        </Formik>
    );
}
