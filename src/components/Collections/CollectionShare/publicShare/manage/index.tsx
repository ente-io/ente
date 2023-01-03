import { ManageLinkPassword } from './linkPassword';
import { ManageDeviceLimit } from './deviceLimit';
import { ManageLinkExpiry } from './linkExpiry';
import { Stack, Typography } from '@mui/material';
import { GalleryContext } from 'pages/gallery';
import React, { useContext, useState } from 'react';
import { updateShareableURL } from 'services/collectionService';
import { Collection, PublicURL, UpdatePublicURL } from 'types/collection';
import { sleep } from 'utils/common';
import constants from 'utils/strings/constants';
import {
    ManageSectionLabel,
    ManageSectionOptions,
} from '../../styledComponents';
import { ManageDownloadAccess } from './downloadAccess';
import { handleSharingErrors } from 'utils/error/ui';
import { SetPublicShareProp } from 'types/publicCollection';
import { ManagePublicCollect } from './publicCollect';

interface Iprops {
    publicShareProp: PublicURL;
    collection: Collection;
    setPublicShareProp: SetPublicShareProp;
}

export default function PublicShareManage({
    publicShareProp,
    collection,
    setPublicShareProp,
}: Iprops) {
    const galleryContext = useContext(GalleryContext);

    const [sharableLinkError, setSharableLinkError] = useState(null);

    const updatePublicShareURLHelper = async (req: UpdatePublicURL) => {
        try {
            galleryContext.setBlockingLoad(true);
            const response = await updateShareableURL(req);
            setPublicShareProp(response);
        } catch (e) {
            const errorMessage = handleSharingErrors(e);
            setSharableLinkError(errorMessage);
        } finally {
            galleryContext.setBlockingLoad(false);
        }
    };

    const scrollToEnd = (e) => {
        const lastOptionRow: Element =
            e.currentTarget.nextElementSibling.lastElementChild;
        const main = async (lastOptionRow: Element) => {
            await sleep(0);
            lastOptionRow.scrollIntoView(true);
        };
        main(lastOptionRow);
    };

    return (
        <>
            <details>
                <ManageSectionLabel onClick={scrollToEnd}>
                    {constants.MANAGE_LINK}
                </ManageSectionLabel>
                <ManageSectionOptions>
                    <Stack spacing={1.5}>
                        <ManageLinkExpiry
                            collection={collection}
                            publicShareProp={publicShareProp}
                            updatePublicShareURLHelper={
                                updatePublicShareURLHelper
                            }
                        />
                        <ManageDeviceLimit
                            collection={collection}
                            publicShareProp={publicShareProp}
                            updatePublicShareURLHelper={
                                updatePublicShareURLHelper
                            }
                        />
                        <ManagePublicCollect
                            collection={collection}
                            publicShareProp={publicShareProp}
                            updatePublicShareURLHelper={
                                updatePublicShareURLHelper
                            }
                        />
                        <ManageDownloadAccess
                            collection={collection}
                            publicShareProp={publicShareProp}
                            updatePublicShareURLHelper={
                                updatePublicShareURLHelper
                            }
                        />
                        <ManageLinkPassword
                            collection={collection}
                            publicShareProp={publicShareProp}
                            updatePublicShareURLHelper={
                                updatePublicShareURLHelper
                            }
                        />
                    </Stack>
                    {sharableLinkError && (
                        <Typography
                            textAlign={'center'}
                            variant="body2"
                            sx={{
                                color: (theme) => theme.palette.danger.main,
                                mt: 0.5,
                            }}>
                            {sharableLinkError}
                        </Typography>
                    )}
                </ManageSectionOptions>
            </details>
        </>
    );
}
