import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { CenteredFlex } from "@ente/shared/components/Container";
import CopyButton from "@ente/shared/components/CopyButton";
import { styled } from "@mui/material";
import React from "react";

interface CodeBlockProps {
    /**
     * The code (an arbitrary string) to show.
     *
     * If not present, then an activity indicator will be shown.
     */
    code: string | undefined;
}

/**
 * A component that shows a "code" (e.g. the user's recovery key, or a 2FA setup
 * code), alongwith a button to copy it.
 */
export const CodeBlock: React.FC<CodeBlockProps> = ({ code }) => {
    if (!code) {
        return (
            <Wrapper>
                <ActivityIndicator />
            </Wrapper>
        );
    }

    return (
        <Wrapper>
            <CodeWrapper>{code}</CodeWrapper>
            <CopyButtonWrapper>
                <CopyButton code={code} />
            </CopyButtonWrapper>
        </Wrapper>
    );
};

const Wrapper = styled(CenteredFlex)(
    ({ theme }) => `
    position: relative;
    background-color: ${theme.vars.palette.accent.dark};
    border-radius: ${theme.shape.borderRadius}px;
    min-height: 80px;
`,
);

const CodeWrapper = styled("div")(
    ({ theme }) => `
    padding: 16px 36px 16px 16px;
    border-radius: ${theme.shape.borderRadius}px;
    word-break: break-word;
    min-width: 30%;
    text-align: left;
`,
);

const CopyButtonWrapper = styled("div")(
    ({ theme }) => `
    position: absolute;
    top: 0px;
    right: 0px;
    margin-top: ${theme.spacing(1)};
`,
);
