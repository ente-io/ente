import { FlexWrapper, Overlay } from "@ente/shared/components/Container";
import ChevronRightIcon from "@mui/icons-material/ChevronRight";
export function ClickOverlay({ onClick }) {
    return (
        <Overlay display="flex">
            <FlexWrapper
                onClick={onClick}
                justifyContent={"flex-end"}
                sx={{ cursor: "pointer" }}
            >
                <ChevronRightIcon />
            </FlexWrapper>
        </Overlay>
    );
}
