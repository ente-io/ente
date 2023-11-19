import { Box, Typography } from '@mui/material';
import { FlexWrapper } from '@ente/shared/components/Container';
import React from 'react';
import { t } from 'i18next';
interface Iprops {
    name: string;
    fileCount: number;
    endIcon?: React.ReactNode;
}

export function CollectionInfo({ name, fileCount, endIcon }: Iprops) {
    return (
        <div>
            <Typography variant="h3">{name}</Typography>

            <FlexWrapper>
                <Typography variant="small" color="text.muted">
                    {t('photos_count', { count: fileCount })}
                </Typography>
                {endIcon && (
                    <Box
                        sx={{
                            svg: {
                                fontSize: '17px',
                                color: 'text.muted',
                            },
                        }}
                        ml={1.5}>
                        {endIcon}
                    </Box>
                )}
            </FlexWrapper>
        </div>
    );
}
