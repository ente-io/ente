import React from 'react';
import { SearchOption } from 'types/search';
import { Box, Divider, Stack, Typography } from '@mui/material';
import { FreeFlowText, SpaceBetweenFlex } from 'components/Container';
import CollectionCard from 'components/Collections/CollectionCard';
import { ResultPreviewTile } from 'components/Collections/styledComponents';
import { t } from 'i18next';

import { components } from 'react-select';

const { Option } = components;

export const OptionWithInfo = (props) => (
    <Option {...props}>
        <LabelWithInfo data={props.data} />
    </Option>
);

const LabelWithInfo = ({ data }: { data: SearchOption }) => {
    return (
        !data.hide && (
            <>
                <Box className="main" px={2} py={1}>
                    <Typography variant="mini" mb={1}>
                        {t(`SEARCH_TYPE.${data.type}`)}
                    </Typography>
                    <SpaceBetweenFlex>
                        <Box mr={1}>
                            <FreeFlowText>
                                <Typography fontWeight={'bold'}>
                                    {data.label}
                                </Typography>
                            </FreeFlowText>
                            <Typography color="text.muted">
                                {t('photos_count', { count: data.fileCount })}
                            </Typography>
                        </Box>

                        <Stack direction={'row'} spacing={1}>
                            {data.previewFiles.map((file) => (
                                <CollectionCard
                                    key={file.id}
                                    coverFile={file}
                                    onClick={() => null}
                                    collectionTile={ResultPreviewTile}
                                />
                            ))}
                        </Stack>
                    </SpaceBetweenFlex>
                </Box>
                <Divider sx={{ mx: 2, my: 1 }} />
            </>
        )
    );
};
