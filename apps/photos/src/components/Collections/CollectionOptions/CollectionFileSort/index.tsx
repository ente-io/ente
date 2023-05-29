import { StyledMenu } from 'components/OverflowMenu/menu';
import { CollectionActions } from '..';
import { OverflowMenuOption } from 'components/OverflowMenu/option';
import { t } from 'i18next';

interface Iprops {
    handleCollectionAction: (
        action: CollectionActions,
        loader?: boolean
    ) => (...args: any[]) => Promise<void>;
    overFlowMenuIconRef: React.MutableRefObject<SVGSVGElement>;
    collectionFileSortOptionView: boolean;
    closeCollectionFileSortOptionView: () => void;
}

export const CollectionFileSortOrderMenu = ({
    handleCollectionAction,
    collectionFileSortOptionView,
    closeCollectionFileSortOptionView,
    overFlowMenuIconRef,
}: Iprops) => {
    const setCollectionFileOrderToAsc = () => {
        closeCollectionFileSortOptionView();
        handleCollectionAction(CollectionActions.UPDATE_COLLECTION_FILES_ORDER)(
            true
        );
    };

    const setCollectionFileOrderToDesc = () => {
        closeCollectionFileSortOptionView();
        handleCollectionAction(CollectionActions.UPDATE_COLLECTION_FILES_ORDER)(
            false
        );
    };
    return (
        <StyledMenu
            id={'collection-files-sort'}
            anchorEl={overFlowMenuIconRef.current}
            open={collectionFileSortOptionView}
            onClose={closeCollectionFileSortOptionView}
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
            <OverflowMenuOption onClick={setCollectionFileOrderToAsc}>
                {t('NEWEST_FIRST')}
            </OverflowMenuOption>
            <OverflowMenuOption onClick={setCollectionFileOrderToDesc}>
                {t('OLDEST_FIRST')}
            </OverflowMenuOption>
        </StyledMenu>
    );
};
