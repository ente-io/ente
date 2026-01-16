/**
 * Avatar colors matching the mobile app's contact colors.
 *
 * These colors are used to give users a consistent colored avatar
 * based on their identifier (email or user ID).
 */
export const avatarColors = [
    "#76549A", // Purple
    "#DF7861", // Coral
    "#94B49F", // Sage green
    "#87A2FB", // Periwinkle blue
    "#C689C6", // Orchid
    "#937DC2", // Soft purple
    "#325288", // Deep blue
    "#85B4E0", // Sky blue
    "#C1A3A3", // Dusty rose
    "#E1A059", // Amber
    "#426165", // Teal
    "#6B77B2", // Slate blue
    "#957FEF", // Violet
    "#DD9DE2", // Pink
    "#82AB8B", // Forest green
    "#9BBBE8", // Light blue
    "#8FBEBE", // Seafoam
    "#8AC3A1", // Mint
    "#A8B0F2", // Lavender
    "#B0C695", // Lime green
    "#E99AAD", // Rose
    "#D18484", // Salmon
    "#78B5A7", // Cyan
];

/**
 * Get a consistent avatar color for a user based on their email or userName.
 *
 * Uses the same algorithm as the mobile app: the string length modulo the
 * number of available colors determines the color index.
 *
 * @param identifier - The user's email or userName (any string)
 * @returns A hex color string from the avatar colors palette
 */
export const getAvatarColor = (identifier: string): string => {
    return avatarColors[identifier.length % avatarColors.length]!;
};
