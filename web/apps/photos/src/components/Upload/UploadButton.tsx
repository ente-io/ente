import FileUploadOutlinedIcon from "@mui/icons-material/FileUploadOutlined";
import { Button, ButtonProps, IconButton, styled } from "@mui/material";
import { type UploadTypeSelectorIntent } from "components/Upload/UploadTypeSelector";
import { t } from "i18next";
import uploadManager from "services/upload/uploadManager";

const Wrapper = styled("div")<{ $disableShrink: boolean }>`
    display: flex;
    align-items: center;
    justify-content: center;
    transition: opacity 1s ease;
    cursor: pointer;
    & .mobile-button {
        display: none;
    }
    ${({ $disableShrink }) =>
        !$disableShrink &&
        `@media (max-width: 624px) {
        & .mobile-button {
            display: block;
        }
        & .desktop-button {
            display: none;
        }
    }`}
`;

interface Iprops {
    openUploader: (intent?: UploadTypeSelectorIntent) => void;
    text?: string;
    color?: ButtonProps["color"];
    disableShrink?: boolean;
    icon?: JSX.Element;
}
function UploadButton({
    openUploader,
    text,
    color,
    disableShrink,
    icon,
}: Iprops) {
    const onClickHandler = () => openUploader();

    return (
        <Wrapper
            $disableShrink={disableShrink}
            style={{
                cursor: !uploadManager.shouldAllowNewUpload() && "not-allowed",
            }}
        >
            <Button
                sx={{ whiteSpace: "nowrap" }}
                onClick={onClickHandler}
                disabled={!uploadManager.shouldAllowNewUpload()}
                className="desktop-button"
                color={color ?? "secondary"}
                startIcon={icon ?? <FileUploadOutlinedIcon />}
            >
                {text ?? t("UPLOAD")}
            </Button>

            <IconButton
                onClick={onClickHandler}
                disabled={!uploadManager.shouldAllowNewUpload()}
                className="mobile-button"
            >
                {icon ?? <FileUploadOutlinedIcon />}
            </IconButton>
        </Wrapper>
    );
}

export default UploadButton;
