import { FluidContainer } from "@ente/shared/components/Container";
import { EnteLinkLogo } from "@ente/shared/components/Navbar/EnteLinkLogo";
import NavbarBase from "@ente/shared/components/Navbar/base";
import AddPhotoAlternateOutlined from "@mui/icons-material/AddPhotoAlternateOutlined";
import UploadButton from "components/Upload/UploadButton";
import { t } from "i18next";
import { AppContext } from "pages/_app";
import { useContext } from "react";
import GoToEnte from "./GoToEnte";

export default function SharedAlbumNavbar({ showUploadButton, openUploader }) {
    const { isMobile } = useContext(AppContext);
    return (
        <NavbarBase isMobile={isMobile}>
            <FluidContainer>
                <EnteLinkLogo />
            </FluidContainer>
            {showUploadButton ? (
                <UploadButton
                    openUploader={openUploader}
                    icon={<AddPhotoAlternateOutlined />}
                    text={t("ADD_PHOTOS")}
                />
            ) : (
                <GoToEnte />
            )}
        </NavbarBase>
    );
}
