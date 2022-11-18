import React, { useState } from 'react';
import constants from 'utils/strings/constants';

import { RenderInfoItem } from './RenderInfoItem';
import { LegendContainer } from '../styledComponents/LegendContainer';
import { Pre } from '../styledComponents/Pre';
import {
    Checkbox,
    FormControlLabel,
    FormGroup,
    Typography,
} from '@mui/material';

export function ExifData(props: { exif: any }) {
    const { exif } = props;
    const [showAll, setShowAll] = useState(false);

    const changeHandler = (e: React.ChangeEvent<HTMLInputElement>) => {
        setShowAll(e.target.checked);
    };

    const renderAllValues = () => <Pre>{exif.raw}</Pre>;

    const renderSelectedValues = () => (
        <>
            {exif?.Make &&
                exif?.Model &&
                RenderInfoItem(constants.DEVICE, `${exif.Make} ${exif.Model}`)}
            {exif?.ImageWidth &&
                exif?.ImageHeight &&
                RenderInfoItem(
                    constants.IMAGE_SIZE,
                    `${exif.ImageWidth} x ${exif.ImageHeight}`
                )}
            {exif?.Flash && RenderInfoItem(constants.FLASH, exif.Flash)}
            {exif?.FocalLength &&
                RenderInfoItem(
                    constants.FOCAL_LENGTH,
                    exif.FocalLength.toString()
                )}
            {exif?.ApertureValue &&
                RenderInfoItem(
                    constants.APERTURE,
                    exif.ApertureValue.toString()
                )}
            {exif?.ISOSpeedRatings &&
                RenderInfoItem(constants.ISO, exif.ISOSpeedRatings.toString())}
        </>
    );

    return (
        <>
            <LegendContainer>
                <Typography variant="subtitle" mb={1}>
                    {constants.EXIF}
                </Typography>
                <FormGroup>
                    <FormControlLabel
                        control={
                            <Checkbox
                                size="small"
                                onChange={changeHandler}
                                color="accent"
                            />
                        }
                        label={constants.SHOW_ALL}
                    />
                </FormGroup>
            </LegendContainer>
            {showAll ? renderAllValues() : renderSelectedValues()}
        </>
    );
}
