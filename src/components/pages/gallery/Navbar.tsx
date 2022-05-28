import React from 'react';
import NavbarBase from 'components/Navbar/base';
import SidebarToggler from 'components/Navbar/SidebarToggler';
import { LogoImage } from 'pages/_app';
import UploadButton from './UploadButton';
import { getNonTrashedUniqueUserFiles } from 'utils/file';
import SearchBar from 'components/Search';

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
    searchStats,
}) {
    return (
        <NavbarBase>
            <SidebarToggler openSidebar={openSidebar} />
            {isFirstFetch ? (
                <LogoImage
                    style={{ height: '24px', padding: '3px' }}
                    alt="logo"
                    src="/icon.svg"
                />
            ) : (
                <SearchBar
                    isOpen={isInSearchMode}
                    setOpen={setIsInSearchMode}
                    isFirstFetch={isFirstFetch}
                    collections={collections}
                    files={getNonTrashedUniqueUserFiles(files)}
                    setActiveCollection={setActiveCollection}
                    setSearch={updateSearch}
                    searchStats={searchStats}
                />
            )}
            <UploadButton
                isFirstFetch={isFirstFetch}
                openUploader={openUploader}
            />
        </NavbarBase>
    );
}
