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

const paths = {
    // "@mui/icons-material/InfoOutlined"
    // TODO(PS): This transform is temporary, audit later.
    info: '<path d="M11 7h2v2h-2zm0 4h2v6h-2zm1-9C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2m0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8" transform="translate(3.5, 3.5)"',
    // "@mui/icons-material/ErrorOutline"
    error: '<path d="M11 15h2v2h-2zm0-8h2v6h-2zm.99-5C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2M12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8" transform="translate(7, 5.7) scale(0.85)"',
    // "@mui/icons-material/Edit"
    edit: '<path d="M3 17.25V21h3.75L17.81 9.94l-3.75-3.75zM20.71 7.04c.39-.39.39-1.02 0-1.41l-2.34-2.34a.996.996 0 0 0-1.41 0l-1.83 1.83 3.75 3.75z" transform="translate(3, 3) scale(0.97)"',
    // "@mui/icons-material/FavoriteBorderRounded"
    favorite:
        '<path d="M19.66 3.99c-2.64-1.8-5.9-.96-7.66 1.1-1.76-2.06-5.02-2.91-7.66-1.1-1.4.96-2.28 2.58-2.34 4.29-.14 3.88 3.3 6.99 8.55 11.76l.1.09c.76.69 1.93.69 2.69-.01l.11-.1c5.25-4.76 8.68-7.87 8.55-11.75-.06-1.7-.94-3.32-2.34-4.28M12.1 18.55l-.1.1-.1-.1C7.14 14.24 4 11.39 4 8.5 4 6.5 5.5 5 7.5 5c1.54 0 3.04.99 3.57 2.36h1.87C13.46 5.99 14.96 5 16.5 5c2 0 3.5 1.5 3.5 3.5 0 2.89-3.14 5.74-7.9 10.05" transform="translate(3, 3)"',
    // "@mui/icons-material/FavoriteRounded"
    unfavorite:
        '<path d="M13.35 20.13c-.76.69-1.93.69-2.69-.01l-.11-.1C5.3 15.27 1.87 12.16 2 8.28c.06-1.7.93-3.33 2.34-4.29 2.64-1.8 5.9-.96 7.66 1.1 1.76-2.06 5.02-2.91 7.66-1.1 1.41.96 2.28 2.59 2.34 4.29.14 3.88-3.3 6.99-8.55 11.76z" transform="translate(3, 3)"',
};

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
export const createPSRegisterElementIconHTML = (name: "info") => ({
    isCustomSVG: true,
    inner: `${paths[name]} id="pswp__icn-${name}" />`,
    outlineID: `pswp__icn-${name}`,
});
