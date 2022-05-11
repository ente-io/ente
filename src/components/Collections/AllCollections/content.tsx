import React from 'react';
import { DialogContent } from '@mui/material';
import { FlexWrapper } from 'components/Container';
import AllCollectionCard from './card';

export default function AllCollectionContent({
    sortedCollectionSummaries,
    onCollectionClick,
}) {
    return (
        <DialogContent>
            <FlexWrapper
                style={{
                    flexWrap: 'wrap',
                }}>
                {sortedCollectionSummaries.map(
                    ({ latestFile, collectionAttributes, fileCount }) => (
                        <AllCollectionCard
                            onCollectionClick={onCollectionClick}
                            collectionAttributes={collectionAttributes}
                            key={collectionAttributes.id}
                            latestFile={latestFile}
                            fileCount={fileCount}
                        />
                    )
                )}
            </FlexWrapper>
        </DialogContent>
    );
}
