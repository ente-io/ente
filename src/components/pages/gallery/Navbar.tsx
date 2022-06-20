import React from 'react';
import NavbarBase from 'components/Navbar/base';
import SidebarToggler from 'components/Navbar/SidebarToggler';
import UploadButton from './UploadButton';
import { getNonTrashedUniqueUserFiles } from 'utils/file';
import SearchBar from 'components/Search/SearchBar';
import { FluidContainer } from 'components/Container';
import { EnteLogo } from 'components/EnteLogo';
import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';
import { Search, SearchResultSummary } from 'types/search';

interface Iprops {
    openSidebar: () => void;
    isFirstFetch: boolean;
    openUploader: () => void;
    isInSearchMode: boolean;
    setIsInSearchMode: (value: boolean) => void;
    collections: Collection[];
    files: EnteFile[];
    setActiveCollection: (id: number) => void;
    updateSearch: (search: Search) => void;
    setSearchResultSummary: (info: SearchResultSummary) => void;
}
export function GalleryNavbar({
    openSidebar,
    isFirstFetch,
    openUploader,
    isInSearchMode,
    setIsInSearchMode,
    collections,
    files,
    setActiveCollection,
    updateSearch,
    setSearchResultSummary,
}: Iprops) {
    return (
        <NavbarBase>
            {!isInSearchMode && <SidebarToggler openSidebar={openSidebar} />}

            {isFirstFetch ? (
                <FluidContainer style={{ justifyContent: 'center' }}>
                    <EnteLogo />
                </FluidContainer>
            ) : (
                <SearchBar
                    isOpen={isInSearchMode}
                    setOpen={setIsInSearchMode}
                    isFirstFetch={isFirstFetch}
                    collections={collections}
                    files={getNonTrashedUniqueUserFiles(files)}
                    setActiveCollection={setActiveCollection}
                    setSearch={updateSearch}
                    setSearchResultSummary={setSearchResultSummary}
                />
            )}
            {!isInSearchMode && (
                <UploadButton
                    isFirstFetch={isFirstFetch}
                    openUploader={openUploader}
                />
            )}
        </NavbarBase>
    );
}
