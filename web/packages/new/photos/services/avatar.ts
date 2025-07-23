/**
 * The CSS color for the uploader indicator on a file that was uploaded to a
 * public "collect" link that the user has created.
 *
 * Such files belong to the user, even if they were uploaded by someone on their
 * behalf, and are thus marked differently (in this case, colorlessly) than
 * other shared files.
 *
 * This is a hex string, suitable for being used in CSS.
 */
export const avatarBackgroundColorPublicCollectedFile = "#000000";

/**
 * Foreground / text color for the avatars.
 *
 * All avatar background colors are chosen to work with this.
 */
export const avatarTextColor = "#fff";

/**
 * The ordered list of CSS colors for the owner indicator avatar background on
 * files that the user does not own in shared albums.
 *
 * Each entry is a hex string, suitable for being used in CSS.
 */
const avatarBackgroundColors = [
    "#76549A",
    "#DF7861",
    "#94B49F",
    "#87A2FB",
    "#C689C6",
    "#937DC2",
    "#325288",
    "#85B4E0",
    "#C1A3A3",
    "#E1A059",
    "#426165",
    "#6B77B2",
    "#957FEF",
    "#DD9DE2",
    "#82AB8B",
    "#9BBBE8",
    "#8FBEBE",
    "#8AC3A1",
    "#A8B0F2",
    "#B0C695",
    "#E99AAD",
    "#D18484",
    "#78B5A7",
];

/**
 * Return the CSS color to use as the background of the avatar indicating the
 * owner of a shared file.
 *
 * @param ownerID The user ID of the user who owns that file.
 *
 * Note that for the files in shared albums uploaded via collect links, while we
 * do show an avatar / uploader indicator, but these should use
 * {@link avatarBackgroundColorPublicCollectedFile}.
 *
 * @returns A a hex string, suitable for being used in CSS as the color of the
 * owner avatar indicator atop item thumbnails.
 */
export const avatarBackgroundColor = (ownerID: number) =>
    avatarBackgroundColors[ownerID % avatarBackgroundColors.length]!;
