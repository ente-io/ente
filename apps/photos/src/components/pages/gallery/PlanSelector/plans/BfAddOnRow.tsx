import { Box, styled, Typography } from '@mui/material';
import { SpaceBetweenFlex } from '@ente/shared/components/Container';
import React from 'react';

import { Trans } from 'react-i18next';
import { makeHumanReadableStorage } from 'utils/billing';

const RowContainer = styled(SpaceBetweenFlex)(({ theme }) => ({
    // gap: theme.spacing(1.5),
    padding: theme.spacing(1, 0),
    cursor: 'pointer',
    '&:hover .endIcon': {
        backgroundColor: 'rgba(255,255,255,0.08)',
    },
}));
export function BFAddOnRow({ bonusData, closeModal }) {
    return (
        <>
            {bonusData.storageBonuses.map((bonus) => {
                if (bonus.type.startsWith('ADD_ON')) {
                    return (
                        <RowContainer key={bonus.id} onClick={closeModal}>
                            <Box>
                                <Typography color="text.muted">
                                    <Trans
                                        i18nKey={'ADD_ON_AVAILABLE_TILL'}
                                        values={{
                                            storage: makeHumanReadableStorage(
                                                bonus.storage
                                            ),
                                            date: bonus.validTill,
                                        }}
                                    />
                                </Typography>
                            </Box>
                        </RowContainer>
                    );
                }
                return null;
            })}
        </>
    );
}
