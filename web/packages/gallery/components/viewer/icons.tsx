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
 * 1. import { renderToString } from "react-dom/server";
 *
 * 2. console.log(renderToString(<InfoOutlinedIcon />));
 */

// const html =
// console.log(renderToString(<InfoOutlinedIcon />));
// const path =
//     '<path d="M11 7h2v2h-2zm0 4h2v6h-2zm1-9C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2m0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8"></path>';
