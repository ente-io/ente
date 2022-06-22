import React from 'react';
import { LabelWithDivider } from './LabelWithDivider';
import { components } from 'react-select';

const { Option } = components;

export const OptionWithDivider = (props) => (
    <Option {...props}>
        <LabelWithDivider data={props.data} />
    </Option>
);
