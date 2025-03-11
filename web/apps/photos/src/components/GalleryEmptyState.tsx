import { EnteLogo } from "@/base/components/EnteLogo";
import {
    FlexWrapper,
    VerticallyCentered,
} from "@ente/shared/components/Container";
import AddPhotoAlternateIcon from "@mui/icons-material/AddPhotoAlternateOutlined";
import FolderIcon from "@mui/icons-material/FolderOutlined";
import { Button, Stack, Typography, styled } from "@mui/material";
import { t } from "i18next";
import { Trans } from "react-i18next";
import uploadManager from "services/upload/uploadManager";

export default function GalleryEmptyState({ openUploader }) {
    return (
        <Wrapper>
            <Stack sx={{ flex: "none", paddingBlock: "12px 32px" }}>
                <VerticallyCentered sx={{ flex: "none" }}>
                    <Typography
                        variant="h3"
                        sx={{
                            color: "text.muted",
                            userSelect: "none",
                            marginBlockEnd: 1,
                            svg: {
                                color: "text.base",
                                verticalAlign: "middle",
                                marginBlockEnd: "2px",
                            },
                        }}
                    >
                        <Trans
                            i18nKey="welcome_to_ente_title"
                            components={{ a: <EnteLogo /> }}
                        />
                    </Typography>
                    <Typography variant="h2">
                        {t("welcome_to_ente_subtitle")}
                    </Typography>
                </VerticallyCentered>
            </Stack>
            <NonDraggableImage
                height={287.57}
                alt=""
                src="/images/empty-state/ente_duck.png"
                srcSet="/images/empty-state/ente_duck@2x.png, /images/empty-state/ente_duck@3x.png"
            />
            <VerticallyCentered paddingTop={1.5} paddingBottom={1.5}>
                <Button
                    style={{
                        cursor:
                            !uploadManager.shouldAllowNewUpload() &&
                            "not-allowed",
                    }}
                    color="accent"
                    onClick={() => openUploader("upload")}
                    disabled={!uploadManager.shouldAllowNewUpload()}
                    sx={{ mt: 1.5, p: 1, width: 320, borderRadius: 0.5 }}
                >
                    <FlexWrapper sx={{ gap: 1 }} justifyContent="center">
                        <AddPhotoAlternateIcon />
                        {t("upload_first_photo")}
                    </FlexWrapper>
                </Button>
                <Button
                    style={{
                        cursor:
                            !uploadManager.shouldAllowNewUpload() &&
                            "not-allowed",
                    }}
                    onClick={() => openUploader("import")}
                    disabled={!uploadManager.shouldAllowNewUpload()}
                    sx={{ mt: 1.5, p: 1, width: 320, borderRadius: 0.5 }}
                >
                    <FlexWrapper sx={{ gap: 1 }} justifyContent="center">
                        <FolderIcon />
                        {t("import_your_folders")}
                    </FlexWrapper>
                </Button>
            </VerticallyCentered>
        </Wrapper>
    );
}

const Wrapper = styled("div")`
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
`;

/**
 * Prevent the image from being selected _and_ dragged, since dragging it
 * triggers the our dropdown selector overlay.
 */
const NonDraggableImage = styled("img")`
    pointer-events: none;
    user-select: none;
`;
