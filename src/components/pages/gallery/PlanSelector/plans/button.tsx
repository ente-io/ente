import ChevronRight from '@mui/icons-material/ChevronRight';
import Done from '@mui/icons-material/Done';
import { Button } from '@mui/material';
import { SpaceBetweenFlex } from 'components/Container';
import React from 'react';
import constants from 'utils/strings/constants';
export function PlanIconButton({
    current,
    onClick,
}: {
    current: boolean;
    onClick: () => void;
}) {
    return current ? (
        <DisabledPlanTileButton />
    ) : (
        <EnabledPlanTileButton onClick={onClick} />
    );
}

function DisabledPlanTileButton() {
    return (
        <Button
            color="accent"
            disabled={true}
            sx={(theme) => ({
                mt: 6,
                '&&': {
                    color: theme.palette.accent.main,
                    borderColor: theme.palette.accent.main,
                },
            })}
            fullWidth
            onClick={() => null}
            variant={'outlined'}>
            <SpaceBetweenFlex>
                {constants.ACTIVE}
                <Done />
            </SpaceBetweenFlex>
        </Button>
    );
}

function EnabledPlanTileButton({ onClick }) {
    return (
        <Button
            color="accent"
            sx={{
                mt: 6,
            }}
            fullWidth
            onClick={onClick}
            variant={'contained'}>
            <SpaceBetweenFlex>
                {constants.CHOOSE_PLAN_BTN}
                <ChevronRight />
            </SpaceBetweenFlex>
        </Button>
    );
}
