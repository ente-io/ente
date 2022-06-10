import React from 'react';
import NavbarBase from 'components/Navbar/base';
import SidebarToggler from 'components/Navbar/SidebarToggler';
import UploadButton from './UploadButton';
import { getNonTrashedUniqueUserFiles } from 'utils/file';
import SearchBar from 'components/Search';
import { FluidContainer } from 'components/Container';
import { EnteLogo } from 'components/EnteLogo';

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
    setSearchResultInfo,
}) {
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
                    setSearchResultInfo={setSearchResultInfo}
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
