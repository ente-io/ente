import { SpaceBetweenFlex } from "@ente/shared/components/Container";
import { EnteLogo } from "@ente/shared/components/EnteLogo";
import CloseIcon from "@mui/icons-material/Close";
import { IconButton } from "@mui/material";

interface IProps {
    closeSidebar: () => void;
}

export default function HeaderSection({ closeSidebar }: IProps) {
    return (
        <SpaceBetweenFlex mt={0.5} mb={1} pl={1.5}>
            <EnteLogo />
            <IconButton
                aria-label="close"
                onClick={closeSidebar}
                color="secondary"
            >
                <CloseIcon fontSize="small" />
            </IconButton>
        </SpaceBetweenFlex>
    );
}
