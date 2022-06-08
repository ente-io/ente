import React from 'react';
import { Box, Typography, Divider } from '@mui/material';
import { components } from 'react-select';

const { Option } = components;

export const OptionWithDivider = (props) => (
    <Option {...props}>
        <LabelWithDivider data={props.data} />
    </Option>
);
export const LabelWithDivider = ({ data }) => (
    <>
        <Box className="main" px={3} py={1}>
            <Typography>{data.label}</Typography>
        </Box>
        <Divider />
    </>
);
