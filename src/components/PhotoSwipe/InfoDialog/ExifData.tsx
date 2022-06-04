import React, { useState } from 'react';
import constants from 'utils/strings/constants';
import { FormCheck } from 'react-bootstrap';

import { RenderInfoItem } from './RenderInfoItem';
import { LegendContainer } from '../styledComponents/LegendContainer';
import { Pre } from '../styledComponents/Pre';
import { Typography } from '@mui/material';

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
                <FormCheck>
                    <FormCheck.Label>
                        <FormCheck.Input onChange={changeHandler} />
                        {constants.SHOW_ALL}
                    </FormCheck.Label>
                </FormCheck>
            </LegendContainer>
            {showAll ? renderAllValues() : renderSelectedValues()}
        </>
    );
}
