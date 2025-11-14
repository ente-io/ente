import {
    CallIcon,
    CollectionsBookmarkIcon,
    File02Icon,
    Image01Icon,
    MailAccount01Icon,
    StickyNote02Icon,
    Video02Icon,
} from "hugeicons-react";
import React from "react";

export enum LockerInfoType {
    Note = "note",
    PhysicalRecord = "physicalRecord",
    AccountCredential = "accountCredential",
    EmergencyContact = "emergencyContact",
}

interface LockerIconInfo {
    icon: React.ReactElement;
    backgroundColor: string;
}

/**
 * Extract the file extension from a filename
 * Returns lowercase extension without the dot, or empty string if no extension
 */
const getFileExtension = (fileName: string): string => {
    const lastDot = fileName.lastIndexOf(".");
    if (lastDot === -1 || lastDot === fileName.length - 1) {
        return "";
    }
    return fileName.slice(lastDot + 1).toLowerCase();
};

/**
 * Check if file extension is an image
 */
const isImageExtension = (extension: string): boolean => {
    const imageExtensions = [
        "jpg",
        "jpeg",
        "png",
        "gif",
        "webp",
        "bmp",
        "svg",
        "heic",
        "heif",
        "ico",
        "tiff",
        "tif",
    ];
    return imageExtensions.includes(extension);
};

/**
 * Check if file extension is a video
 */
const isVideoExtension = (extension: string): boolean => {
    const videoExtensions = [
        "mp4",
        "mov",
        "avi",
        "mkv",
        "webm",
        "wmv",
        "flv",
        "m4v",
        "3gp",
        "3g2",
        "ogv",
        "mpg",
        "mpeg",
    ];
    return videoExtensions.includes(extension);
};

/**
 * Check if file extension is a document/text file
 */
const isDocumentExtension = (extension: string): boolean => {
    const documentExtensions = [
        "pdf",
        "doc",
        "docx",
        "xls",
        "xlsx",
        "ppt",
        "pptx",
        "txt",
        "rtf",
        "odt",
        "ods",
        "odp",
        "md",
        "csv",
    ];
    return documentExtensions.includes(extension);
};

/**
 * Get icon based on locker info type (first priority) or file extension (fallback)
 */
export const getLockerFileIcon = (
    fileName: string,
    lockerType?: string,
): LockerIconInfo => {
    // First priority: Check locker info type
    if (lockerType) {
        switch (lockerType as LockerInfoType) {
            case LockerInfoType.Note:
                return {
                    icon: <StickyNote02Icon size={42} color="#FFA825" />,
                    backgroundColor: "rgba(255, 168, 37, 0.06)",
                };

            case LockerInfoType.EmergencyContact:
                return {
                    icon: <CallIcon size={42} color="#DF61BB" />,
                    backgroundColor: "rgba(223, 97, 187, 0.06)",
                };

            case LockerInfoType.AccountCredential:
                return {
                    icon: <MailAccount01Icon size={42} color="#666666" />,
                    backgroundColor: "rgba(102, 102, 102, 0.06)",
                };

            case LockerInfoType.PhysicalRecord:
                return {
                    icon: <CollectionsBookmarkIcon size={42} color="#5FB7BB" />,
                    backgroundColor: "rgba(95, 183, 187, 0.06)",
                };
        }
    }

    // Second priority: Detect based on file extension
    const extension = getFileExtension(fileName);

    if (isImageExtension(extension)) {
        return {
            icon: <Image01Icon size={42} color="#08C225" />,
            backgroundColor: "rgba(8, 194, 37, 0.06)",
        };
    }

    if (isVideoExtension(extension)) {
        return {
            icon: <Video02Icon size={42} color="#8A38F5" />,
            backgroundColor: "rgba(138, 56, 245, 0.06)",
        };
    }

    if (isDocumentExtension(extension)) {
        return {
            icon: <File02Icon size={42} color="#FF1A53" />,
            backgroundColor: "rgba(255, 26, 83, 0.06)",
        };
    }

    // Default: Generic file icon
    return {
        icon: <File02Icon size={42} color="#FF1A53" />,
        backgroundColor: "rgba(255, 26, 83, 0.06)",
    };
};
