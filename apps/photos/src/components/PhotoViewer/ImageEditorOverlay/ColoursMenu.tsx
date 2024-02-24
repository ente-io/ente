import { Box, Slider } from "@mui/material";
import { EnteMenuItem } from "components/Menu/EnteMenuItem";
import { MenuItemGroup } from "components/Menu/MenuItemGroup";
import MenuSectionTitle from "components/Menu/MenuSectionTitle";
import { t } from "i18next";
import { Dispatch, SetStateAction } from "react";

interface IProps {
    brightness: number;
    contrast: number;
    saturation: number;
    blur: number;
    invert: boolean;
    setBrightness: Dispatch<SetStateAction<number>>;
    setContrast: Dispatch<SetStateAction<number>>;
    setSaturation: Dispatch<SetStateAction<number>>;
    setBlur: Dispatch<SetStateAction<number>>;
    setInvert: Dispatch<SetStateAction<boolean>>;
}

const ColoursMenu = (props: IProps) => {
    return (
        <>
            <Box px={"8px"}>
                <MenuSectionTitle title={t("BRIGHTNESS")} />
                <Slider
                    min={0}
                    max={200}
                    defaultValue={100}
                    step={10}
                    valueLabelDisplay="auto"
                    value={props.brightness}
                    marks={[
                        {
                            value: 100,
                            label: "100%",
                        },
                    ]}
                    onChange={(_, value) => {
                        props.setBrightness(value as number);
                    }}
                />
                <MenuSectionTitle title={t("CONTRAST")} />
                <Slider
                    min={0}
                    max={200}
                    defaultValue={100}
                    step={10}
                    valueLabelDisplay="auto"
                    value={props.contrast}
                    onChange={(_, value) => {
                        props.setContrast(value as number);
                    }}
                    marks={[
                        {
                            value: 100,
                            label: "100%",
                        },
                    ]}
                />
                <MenuSectionTitle title={t("BLUR")} />
                <Slider
                    min={0}
                    max={10}
                    defaultValue={0}
                    step={1}
                    valueLabelDisplay="auto"
                    value={props.blur}
                    onChange={(_, value) => {
                        props.setBlur(value as number);
                    }}
                />
                <MenuSectionTitle title={t("SATURATION")} />
                <Slider
                    min={0}
                    max={200}
                    defaultValue={100}
                    step={10}
                    valueLabelDisplay="auto"
                    value={props.saturation}
                    onChange={(_, value) => {
                        props.setSaturation(value as number);
                    }}
                    marks={[
                        {
                            value: 100,
                            label: "100%",
                        },
                    ]}
                />
            </Box>
            <MenuItemGroup
                style={{
                    marginBottom: "0.5rem",
                }}
            >
                <EnteMenuItem
                    variant="toggle"
                    checked={props.invert}
                    label={t("INVERT_COLORS")}
                    onClick={() => {
                        props.setInvert(!props.invert);
                    }}
                />
            </MenuItemGroup>
        </>
    );
};

export default ColoursMenu;
