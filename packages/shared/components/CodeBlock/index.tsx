import { FreeFlowText } from "@ente/shared/components/Container";
import EnteSpinner from "@ente/shared/components/EnteSpinner";
import { BoxProps } from "@mui/material";
import React from "react";
import CopyButton from "./CopyButton";
import { CodeWrapper, CopyButtonWrapper, Wrapper } from "./styledComponents";

type Iprops = React.PropsWithChildren<{
    code: string;
    wordBreak?: "normal" | "break-all" | "keep-all" | "break-word";
}>;

export default function CodeBlock({
    code,
    wordBreak,
    ...props
}: BoxProps<"div", Iprops>) {
    if (!code) {
        return (
            <Wrapper>
                <EnteSpinner />
            </Wrapper>
        );
    }
    return (
        <Wrapper {...props}>
            <CodeWrapper>
                <FreeFlowText style={{ wordBreak: wordBreak }}>
                    {code}
                </FreeFlowText>
            </CodeWrapper>
            <CopyButtonWrapper>
                <CopyButton code={code} />
            </CopyButtonWrapper>
        </Wrapper>
    );
}
