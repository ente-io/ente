import FileUploadOutlinedIcon from "@mui/icons-material/FileUploadOutlined";
import { Button, ButtonProps, IconButton, styled } from "@mui/material";
import { type UploadTypeSelectorIntent } from "components/Upload/UploadTypeSelector";
import { t } from "i18next";
import uploadManager from "services/upload/uploadManager";

interface UploadButtonProps {
    openUploader: (intent?: UploadTypeSelectorIntent) => void;
    text?: string;
    color?: ButtonProps["color"];
    disableShrink?: boolean;
    icon?: JSX.Element;
}
export const UploadButton: React.FC<UploadButtonProps> = ({
    openUploader,
    text,
    color,
    disableShrink,
    icon,
}) => {
    const onClickHandler = () => openUploader();

    return (
        <UploadButton_
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
                {text ?? t("upload")}
            </Button>

            <IconButton
                onClick={onClickHandler}
                disabled={!uploadManager.shouldAllowNewUpload()}
                className="mobile-button"
            >
                {icon ?? <FileUploadOutlinedIcon />}
            </IconButton>
        </UploadButton_>
    );
};

const UploadButton_ = styled("div")<{ $disableShrink: boolean }>`
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
            display: inline-flex;
        }
        & .desktop-button {
            display: none;
        }
    }`}
`;
