import LinkButton from "@ente/shared/components/LinkButton";
import ElectronAPIs from "@ente/shared/electron";
import { logError } from "@ente/shared/sentry";
import { Tooltip } from "@mui/material";
import { styled } from "@mui/material/styles";

const DirectoryPathContainer = styled(LinkButton)(
    ({ width }) => `
    width: ${width}px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    /* Beginning of string */
    direction: rtl;
    text-align: left;
`,
);

export const DirectoryPath = ({ width, path }) => {
    const handleClick = async () => {
        try {
            await ElectronAPIs.openDirectory(path);
        } catch (e) {
            logError(e, "openDirectory failed");
        }
    };
    return (
        <DirectoryPathContainer width={width} onClick={handleClick}>
            <Tooltip title={path}>
                <span>{path}</span>
            </Tooltip>
        </DirectoryPathContainer>
    );
};
