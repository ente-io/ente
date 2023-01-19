import { CollectionActions } from '.';
import React from 'react';
import PeopleIcon from '@mui/icons-material/People';
import FileDownloadOutlinedIcon from '@mui/icons-material/FileDownloadOutlined';
import { FlexWrapper } from 'components/Container';
import { IconButton } from '@mui/material';
interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean
    ) => (...args: any[]) => Promise<void>;
}

export function QuickOptions({ handleCollectionAction }: Iprops) {
    return (
        <FlexWrapper>
            <IconButton>
                <PeopleIcon
                    onClick={handleCollectionAction(
                        CollectionActions.SHOW_SHARE_DIALOG,
                        false
                    )}
                />
            </IconButton>
            <IconButton>
                <FileDownloadOutlinedIcon
                    onClick={handleCollectionAction(
                        CollectionActions.CONFIRM_DOWNLOAD,
                        false
                    )}
                    aria-haspopup="true"
                />
            </IconButton>
        </FlexWrapper>
    );
}
