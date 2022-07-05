import React from 'react';
import NavbarBase from 'components/Navbar/base';
import SidebarToggler from 'components/Navbar/SidebarToggler';
import { getNonTrashedUniqueUserFiles } from 'utils/file';
import SearchBar from 'components/Search/SearchBar';
import { FluidContainer } from 'components/Container';
import { EnteLogo } from 'components/EnteLogo';
import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';
import { UpdateSearch } from 'types/search';
import UploadButton from 'components/Upload/UploadButton';

interface Iprops {
    openSidebar: () => void;
    isFirstFetch: boolean;
    openUploader: () => void;
    isInSearchMode: boolean;
    setIsInSearchMode: (v: boolean) => void;
    collections: Collection[];
    files: EnteFile[];
    setActiveCollection: (id: number) => void;
    updateSearch: UpdateSearch;
}
export function GalleryNavbar({
    openSidebar,
    isFirstFetch,
    openUploader,
    isInSearchMode,
    collections,
    files,
    setActiveCollection,
    updateSearch,
    setIsInSearchMode,
}: Iprops) {
    return (
        <NavbarBase sx={{ background: 'transparent', position: 'absolute' }}>
            {!isInSearchMode && <SidebarToggler openSidebar={openSidebar} />}

            {isFirstFetch ? (
                <FluidContainer style={{ justifyContent: 'center' }}>
                    <EnteLogo />
                </FluidContainer>
            ) : (
                <SearchBar
                    isInSearchMode={isInSearchMode}
                    setIsInSearchMode={setIsInSearchMode}
                    collections={collections}
                    files={getNonTrashedUniqueUserFiles(files)}
                    setActiveCollection={setActiveCollection}
                    updateSearch={updateSearch}
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
