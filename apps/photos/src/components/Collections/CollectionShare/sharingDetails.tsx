import { Stack } from '@mui/material';
import { EnteMenuItem } from 'components/Menu/EnteMenuItem';
import MenuItemDivider from 'components/Menu/MenuItemDivider';
import { MenuItemGroup } from 'components/Menu/MenuItemGroup';
import MenuSectionTitle from 'components/Menu/MenuSectionTitle';
import { t } from 'i18next';
import AdminPanelSettingsIcon from '@mui/icons-material/AdminPanelSettings';
import { COLLECTION_ROLE } from 'types/collection';
import { GalleryContext } from 'pages/gallery';
import { useContext } from 'react';
import Avatar from 'components/pages/gallery/Avatar';
import ModeEditIcon from '@mui/icons-material/ModeEdit';
import { CollectionSummaryType } from 'constants/collection';
import Photo from '@mui/icons-material/Photo';

export default function SharingDetails({ collection, type }) {
    const galleryContext = useContext(GalleryContext);

    const ownerEmail =
        galleryContext.user.id === collection.owner?.id
            ? galleryContext.user?.email
            : collection.owner?.email;

    const collaborators = collection.sharees
        ?.filter((sharee) => sharee.role === COLLECTION_ROLE.COLLABORATOR)
        .map((sharee) => sharee.email);

    const viewers =
        collection.sharees
            ?.filter((sharee) => sharee.role === COLLECTION_ROLE.VIEWER)
            .map((sharee) => sharee.email) || [];

    const isOwner = galleryContext.user?.id === collection.owner?.id;

    const isMe = (email: string) => email === galleryContext.user?.email;

    return (
        <>
            <Stack>
                <MenuSectionTitle
                    title={t('OWNER')}
                    icon={<AdminPanelSettingsIcon />}
                />
                <MenuItemGroup>
                    <EnteMenuItem
                        fontWeight="normal"
                        onClick={() => {}}
                        label={isOwner ? t('YOU') : ownerEmail}
                        startIcon={<Avatar email={ownerEmail} />}
                    />
                </MenuItemGroup>
            </Stack>
            {type === CollectionSummaryType.incomingShareCollaborator &&
                collaborators?.length > 0 && (
                    <Stack>
                        <MenuSectionTitle
                            title={t('COLLABORATORS')}
                            icon={<ModeEditIcon />}
                        />
                        <MenuItemGroup>
                            {collaborators.map((item, index) => (
                                <>
                                    <EnteMenuItem
                                        fontWeight="normal"
                                        key={item}
                                        onClick={() => {}}
                                        label={isMe(item) ? t('YOU') : item}
                                        startIcon={<Avatar email={item} />}
                                    />
                                    {index !== collaborators.length - 1 && (
                                        <MenuItemDivider />
                                    )}
                                </>
                            ))}
                        </MenuItemGroup>
                    </Stack>
                )}
            {viewers?.length > 0 && (
                <Stack>
                    <MenuSectionTitle title={t('VIEWERS')} icon={<Photo />} />
                    <MenuItemGroup>
                        {viewers.map((item, index) => (
                            <>
                                <EnteMenuItem
                                    fontWeight="normal"
                                    key={item}
                                    onClick={() => {}}
                                    label={isMe(item) ? t('YOU') : item}
                                    startIcon={<Avatar email={item} />}
                                />
                                {index !== viewers.length - 1 && (
                                    <MenuItemDivider />
                                )}
                            </>
                        ))}
                    </MenuItemGroup>
                </Stack>
            )}
        </>
    );
}
