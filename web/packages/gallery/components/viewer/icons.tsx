/**
 * @file [Note: SVG paths of MUI icons]
 *
 * When creating buttons for use with PhotoSwipe, we need to provide just the
 * contents of the SVG element (e.g. paths) as an HTML string.
 *
 * Since we only need a handful, these strings were created by temporarily
 * adding the following code in some existing React component to render the
 * corresponding MUI icon React component to a string, and retain the path.
 *
 *
 *     import { renderToString } from "react-dom/server";
 *     import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
 *
 *     console.log(renderToString(<InfoOutlinedIcon />));
 */

// The transforms are not part of the originals, they have been applied
// separately to get these icons to align with the ones built into PhotoSwipe.
const paths = {
    // "@mui/icons-material/ErrorOutline"
    error: '<path d="M11 15h2v2h-2zm0-8h2v6h-2zm.99-5C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2M12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8" transform="translate(7, 5.7) scale(0.85)"',
    // "@mui/icons-material/AlbumOutlined"
    live: '<path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2m0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8m0-12.5c-2.49 0-4.5 2.01-4.5 4.5s2.01 4.5 4.5 4.5 4.5-2.01 4.5-4.5-2.01-4.5-4.5-4.5m0 5.5c-.55 0-1-.45-1-1s.45-1 1-1 1 .45 1 1-.45 1-1 1" transform="translate(2, 8.7) scale(0.75)"',
    // "@mui/icons-material/VolumeUp"
    vol: '<path d="M3 9v6h4l5 5V4L7 9zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02M14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77" transform="translate(0, 9) scale(0.75)"',
    // "@mui/icons-material/FavoriteBorderRounded"
    favorite:
        '<path d="M19.66 3.99c-2.64-1.8-5.9-.96-7.66 1.1-1.76-2.06-5.02-2.91-7.66-1.1-1.4.96-2.28 2.58-2.34 4.29-.14 3.88 3.3 6.99 8.55 11.76l.1.09c.76.69 1.93.69 2.69-.01l.11-.1c5.25-4.76 8.68-7.87 8.55-11.75-.06-1.7-.94-3.32-2.34-4.28M12.1 18.55l-.1.1-.1-.1C7.14 14.24 4 11.39 4 8.5 4 6.5 5.5 5 7.5 5c1.54 0 3.04.99 3.57 2.36h1.87C13.46 5.99 14.96 5 16.5 5c2 0 3.5 1.5 3.5 3.5 0 2.89-3.14 5.74-7.9 10.05" transform="translate(0, 5.5) scale(0.95)"',
    // "@mui/icons-material/FavoriteRounded"
    "favorite-fill":
        '<path d="M13.35 20.13c-.76.69-1.93.69-2.69-.01l-.11-.1C5.3 15.27 1.87 12.16 2 8.28c.06-1.7.93-3.33 2.34-4.29 2.64-1.8 5.9-.96 7.66 1.1 1.76-2.06 5.02-2.91 7.66-1.1 1.41.96 2.28 2.59 2.34 4.29.14 3.88-3.3 6.99-8.55 11.76z" transform="translate(0, 5.5) scale(0.95)"',
    // "@mui/icons-material/FileDownloadOutlined"
    download:
        '<path d="M18 15v3H6v-3H4v3c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2v-3zm-1-4-1.41-1.41L13 12.17V4h-2v8.17L8.41 9.59 7 11l5 5z" transform="translate(0, 4)"',
    // "@mui/icons-material/InfoOutlined"
    info: '<path d="M11 7h2v2h-2zm0 4h2v6h-2zm1-9C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2m0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8" transform="translate(1, 4.5) scale(0.95)"',
    // "@mui/icons-material/MoreHoriz"
    more: '<path d="M6 10c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2m12 0c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2m-6 0c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2" transform="translate(0, 4.5)"',
    // "@mui/icons-material/FullscreenOutlined"
    fullscreen:
        '<path d="M7 14H5v5h5v-2H7zm-2-4h2V7h3V5H5zm12 7h-3v2h5v-5h-2zM14 5v2h3v3h2V5z" transform="translate(0, 4.5)"',
    // "@mui/icons-material/FullscreenExitOutlined"
    "fullscreen-exit":
        '<path d="M5 16h3v3h2v-5H5zm3-8H5v2h5V5H8zm6 11h2v-3h3v-2h-5zm2-11V5h-2v5h5V8z" transform="translate(0, 4.5)"',
};

type IconKeys = Exclude<
    keyof typeof paths,
    "favorite-fill" | "fullscreen-exit"
>;

/**
 * Return an object that can be passed verbatim to the "html" option expected by
 * PhotoSwipe's registerElement function.
 *
 * API docs for registerElement:
 * https://photoswipe.com/adding-ui-elements/#uiregisterelement-api
 *
 * Example:
 *
 *     html: {
 *         isCustomSVG: true,
 *         inner: '<path d="M11 7h2v2h-2zm0 4h2v6h-2zm1-9C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2m0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8" transform="translate(3.5, 3.5)" id="pswp__icn-info" />',
 *         outlineID: "pswp__icn-info",
 *     }
 *
 */
export const createPSRegisterElementIconHTML = (name: IconKeys) => ({
    isCustomSVG: true,
    inner:
        name == "favorite"
            ? favoriteInner()
            : name == "fullscreen"
              ? fullscreenInner()
              : `${paths[name]} id="pswp__icn-${name}" />`,
    outlineID: `pswp__icn-${name}`,
});

// Favorite is a special case since it consists of two layers.
const favoriteInner = () =>
    `${paths.favorite} id="pswp__icn-favorite" />${paths["favorite-fill"]} id="pswp__icn-favorite-fill" />`;

// Fullscreen is also a special case since it has two states.
const fullscreenInner = () =>
    `${paths.fullscreen} id="pswp__icn-fullscreen" />${paths["fullscreen-exit"]} id="pswp__icn-fullscreen-exit" />`;

/**
 * The path of "@mui/icons-material/Settings" as as string.
 *
 * Assumes `viewBox="0 0 24 24"`.
 */
export const settingsSVGPath = `<path d="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6"></path>`;
