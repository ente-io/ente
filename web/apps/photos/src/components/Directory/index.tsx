import { ensureElectron } from "@/base/electron";
import log from "@/base/log";
import LinkButton from "@ente/shared/components/LinkButton";
import { Tooltip, styled } from "@mui/material";

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
            await ensureElectron().openDirectory(path);
        } catch (e) {
            log.error("openDirectory failed", e);
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
