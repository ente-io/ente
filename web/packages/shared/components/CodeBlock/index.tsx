import { ActivityIndicator } from "@/base/components/mui/ActivityIndicator";
import { type BoxProps, styled } from "@mui/material";
import React from "react";
import CopyButton from "./CopyButton";
import { CodeWrapper, CopyButtonWrapper, Wrapper } from "./styledComponents";

type Iprops = React.PropsWithChildren<{
    code: string | null;
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

const FreeFlowText = styled("div")`
    word-break: break-word;
    min-width: 30%;
    text-align: left;
`;
