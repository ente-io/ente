import { components } from "react-select";
import { LabelWithDivider } from "./LabelWithDivider";

const { Option } = components;

export const OptionWithDivider = (props) => (
    <Option {...props}>
        <LabelWithDivider data={props.data} />
    </Option>
);
