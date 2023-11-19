import ChevronRight from '@mui/icons-material/ChevronRight';
import Done from '@mui/icons-material/Done';
import { Box, Button } from '@mui/material';
import { SpaceBetweenFlex } from '@ente/shared/components/Container';
import React from 'react';
import { t } from 'i18next';
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
    return (
        <Button
            color="accent"
            disabled={true}
            sx={(theme) => ({
                '&&': {
                    color: theme.colors.accent.A500,
                    borderColor: theme.colors.accent.A500,
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
    return (
        <Button
            color="accent"
            sx={(theme) => ({
                border: `1px solid ${theme.colors.accent.A500}`,
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
