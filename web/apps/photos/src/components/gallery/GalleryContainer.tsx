import React from 'react';
import { NavbarBase } from 'ente-base/components/Navbar';
import { NormalNavbarContents, HiddenSectionNavbarContents } from './NavbarContents';
import type { EnteFile } from 'ente-media/file';
import type { SelectedState } from 'utils/file';

interface GalleryContainerProps {
    // State props
    filteredFiles: EnteFile[];
    selected: SelectedState;
    barMode: string;
    isInSearchMode: boolean;
    isFirstLoad: boolean;
    activeCollectionID: number | undefined;
    
    // Event handlers
    onSidebar: () => void;
    onUpload: () => void;
    onSelectSearchOption: (option: unknown) => void;
    onSelectPeople: () => void;
    onSelectPerson: (personID: string) => void;
    onClearSelection: () => void;
    onChangeMode: (mode: string) => void;
    
    // Children for flexible rendering
    children: React.ReactNode;
}

/**
 * Simplified gallery container component that handles the basic layout
 */
export const GalleryContainer: React.FC<GalleryContainerProps> = ({
    selected,
    barMode,
    isInSearchMode,
    activeCollectionID,
    onSidebar,
    onUpload,
    onSelectSearchOption,
    onSelectPeople,
    onSelectPerson,
    onChangeMode,
    children,
}) => {
    const showSelectionBar = selected.count > 0 && selected.collectionID === activeCollectionID;

    return (
        <>
            {/* Navigation Bar */}
            <NavbarBase
                sx={[
                    {
                        mb: "12px",
                        px: "24px",
                        "@media (width < 720px)": { px: "4px" },
                    },
                    showSelectionBar && { borderColor: "accent.main" },
                ]}
            >
                {showSelectionBar ? (
                    <div>Selection Bar Placeholder</div>
                ) : barMode === "hidden-albums" ? (
                    <HiddenSectionNavbarContents
                        onBack={() => onChangeMode("albums")}
                    />
                ) : (
                    <NormalNavbarContents
                        isInSearchMode={isInSearchMode}
                        onSidebar={onSidebar}
                        onUpload={onUpload}
                        onShowSearchInput={() => {
                            // TODO: Implement search mode toggle
                        }}
                        onSelectSearchOption={onSelectSearchOption}
                        onSelectPeople={onSelectPeople}
                        onSelectPerson={onSelectPerson}
                    />
                )}
            </NavbarBase>

            {/* Main Content Area */}
            {children}
        </>
    );
};
