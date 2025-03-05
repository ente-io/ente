// TODO(PS): Temporary trampoline
export const resetFileViewerDataSourceOnClose = async () => {
    if (!process.env.NEXT_PUBLIC_ENTE_WIP_PS5) return;
    (
        await import("@/gallery/components/viewer/data-source")
    ).resetFileViewerDataSourceOnClose();
};
