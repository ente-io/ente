import ChevronRight from '@mui/icons-material/ChevronRight';
import Done from '@mui/icons-material/Done';
import { Box, Button } from '@mui/material';
import { SpaceBetweenFlex } from 'components/Container';
import React from 'react';
import { useTranslation } from 'react-i18next';
export function PlanIconButton({
    current,
    onClick,
}: {
    current: boolean;
    onClick: () => void;
}) {
    return (
        <Box mt={6}>
            {current ? (
                <CurrentPlanTileButton />
            ) : (
                <NormalPlanTileButton onClick={onClick} />
            )}
        </Box>
    );
}

function CurrentPlanTileButton() {
    const { t } = useTranslation();
    return (
        <Button
            color="accent"
            disabled={true}
            sx={(theme) => ({
                '&&': {
                    color: theme.palette.accent.main,
                    borderColor: theme.palette.accent.main,
                },
            })}
            fullWidth
            onClick={() => null}
            variant={'outlined'}>
            <SpaceBetweenFlex>
                {t('ACTIVE')}
                <Done />
            </SpaceBetweenFlex>
        </Button>
    );
}

function NormalPlanTileButton({ onClick }) {
    const { t } = useTranslation();
    return (
        <Button
            color="accent"
            sx={(theme) => ({
                border: `1px solid ${theme.palette.accent.main}`,
            })}
            fullWidth
            onClick={onClick}
            variant={'contained'}>
            <SpaceBetweenFlex>
                {t('SUBSCRIBE')}
                <ChevronRight />
            </SpaceBetweenFlex>
        </Button>
    );
}
