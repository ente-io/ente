import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { CenteredFlex } from "@ente/shared/components/Container";
import { type BoxProps, styled } from "@mui/material";
import React from "react";
import CopyButton from "./CopyButton";

type Iprops = React.PropsWithChildren<{
    code: string | null | undefined;
}>;

export default function CodeBlock({ code, ...props }: BoxProps<"div", Iprops>) {
    if (!code) {
        return (
            <Wrapper>
                <ActivityIndicator />
            </Wrapper>
        );
    }

    return (
        <Wrapper {...props}>
            <CodeWrapper>
                <FreeFlowText>{code}</FreeFlowText>
            </CodeWrapper>
            <CopyButtonWrapper>
                <CopyButton code={code} />
            </CopyButtonWrapper>
        </Wrapper>
    );
}

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
`,
);

const FreeFlowText = styled("div")`
    word-break: break-word;
    min-width: 30%;
    text-align: left;
`;

const CopyButtonWrapper = styled("div")(
    ({ theme }) => `
    position: absolute;
    top: 0px;
    right: 0px;
    margin-top: ${theme.spacing(1)};
`,
);
