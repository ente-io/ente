import DocumentPage, {
    EnteDocumentProps,
} from "@ente/shared/next/pages/_document";

export default function Document(props: EnteDocumentProps) {
    return <DocumentPage {...props} />;
}
