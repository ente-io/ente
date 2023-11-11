import { StyledMenu } from '@ente/shared/components/OverflowMenu/menu';
import { CollectionActions } from '.';
import { OverflowMenuOption } from '@ente/shared/components/OverflowMenu/option';
import { t } from 'i18next';

interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean
    ) => (...args: any[]) => Promise<void>;
    overFlowMenuIconRef: React.MutableRefObject<SVGSVGElement>;
    collectionSortOrderMenuView: boolean;
    closeCollectionSortOrderMenu: () => void;
}

const CollectionSortOrderMenu = ({
    handleCollectionAction,
    collectionSortOrderMenuView,
    closeCollectionSortOrderMenu,
    overFlowMenuIconRef,
}: Iprops) => {
    const setCollectionSortOrderToAsc = () => {
        closeCollectionSortOrderMenu();
        handleCollectionAction(CollectionActions.UPDATE_COLLECTION_SORT_ORDER)({
            asc: true,
        });
    };

    const setCollectionSortOrderToDesc = () => {
        closeCollectionSortOrderMenu();
        handleCollectionAction(CollectionActions.UPDATE_COLLECTION_SORT_ORDER)({
            asc: false,
        });
    };
    return (
        <StyledMenu
            id={'collection-files-sort'}
            anchorEl={overFlowMenuIconRef.current}
            open={collectionSortOrderMenuView}
            onClose={closeCollectionSortOrderMenu}
            MenuListProps={{
                disablePadding: true,
                'aria-labelledby': 'collection-files-sort',
            }}
            anchorOrigin={{
                vertical: 'bottom',
                horizontal: 'right',
            }}
            transformOrigin={{
                vertical: 'top',
                horizontal: 'right',
            }}>
            <OverflowMenuOption onClick={setCollectionSortOrderToDesc}>
                {t('NEWEST_FIRST')}
            </OverflowMenuOption>
            <OverflowMenuOption onClick={setCollectionSortOrderToAsc}>
                {t('OLDEST_FIRST')}
            </OverflowMenuOption>
        </StyledMenu>
    );
};

export default CollectionSortOrderMenu;
