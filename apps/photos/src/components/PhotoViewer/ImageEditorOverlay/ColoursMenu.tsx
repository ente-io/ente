import { Dispatch, SetStateAction } from 'react';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import { Box, Slider, Switch, Typography } from '@mui/material';
import { SpaceBetweenFlex } from 'components/Container';
import { t } from 'i18next';

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
            <MenuSectionTitle title={t('BRIGHTNESS')} />
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
                        label: '100%',
                    },
                ]}
                onChange={(_, value) => {
                    props.setBrightness(value as number);
                }}
            />
            <MenuSectionTitle title={t('CONTRAST')} />
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
                        label: '100%',
                    },
                ]}
            />
            <MenuSectionTitle title={t('BLUR')} />
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
            <MenuSectionTitle title={t('SATURATION')} />
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
                        label: '100%',
                    },
                ]}
            />
            <SpaceBetweenFlex minHeight={'48px'}>
                <Typography color="text.muted">{t('INVERT_COLORS')}</Typography>
                <Box>
                    <Switch
                        value={props.invert}
                        onChange={(e) => {
                            props.setInvert(e.target.checked);
                        }}
                    />
                </Box>
            </SpaceBetweenFlex>
        </>
    );
};

export default ColoursMenu;
