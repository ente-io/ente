import { Box, Typography } from '@mui/material';
import { FlexWrapper } from 'components/Container';
import React from 'react';
import { useTranslation } from 'react-i18next';
interface Iprops {
    name: string;
    fileCount: number;
    endIcon?: React.ReactNode;
}

export function CollectionInfo({ name, fileCount, endIcon }: Iprops) {
    const { t } = useTranslation();
    return (
        <div>
            <Typography variant="h3">{name}</Typography>

            <FlexWrapper>
                <Typography variant="body2" color="text.secondary">
                    {t('photos_count', { count: fileCount })}
                </Typography>
                {endIcon && (
                    <Box
                        sx={{
                            svg: {
                                fontSize: '17px',
                                color: 'text.secondary',
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
