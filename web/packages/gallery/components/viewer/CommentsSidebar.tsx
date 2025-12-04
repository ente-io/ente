import CloseIcon from "@mui/icons-material/Close";
import {
    Avatar,
    Box,
    Drawer,
    IconButton,
    Stack,
    styled,
    TextField,
    Typography,
} from "@mui/material";
import { type ModalVisibilityProps } from "ente-base/components/utils/modal";
import { t } from "i18next";
import React, { useState } from "react";

// =============================================================================
// Icons
// =============================================================================

const SendIcon: React.FC = () => (
    <svg
        width="18"
        height="16"
        viewBox="0 0 15 13"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
    >
        <path
            d="M2.03872 4.50697L2.47372 5.26697C2.75072 5.75197 2.88872 5.99397 2.88872 6.25997C2.88872 6.52597 2.75072 6.76797 2.47372 7.25197L2.03872 8.01297C0.800717 10.18 0.181717 11.263 0.663717 11.801C1.14672 12.338 2.29072 11.838 4.57672 10.838L10.8527 8.09197C12.6477 7.30697 13.5457 6.91397 13.5457 6.25997C13.5457 5.60597 12.6477 5.21297 10.8527 4.42797L4.57672 1.68197C2.29072 0.681968 1.14672 0.181968 0.663717 0.718968C0.181717 1.25597 0.800717 2.33897 2.03872 4.50697Z"
            stroke="black"
            strokeOpacity="0.8"
        />
    </svg>
);

const ReplyIcon: React.FC = () => (
    <svg
        width="12"
        height="9"
        viewBox="0 0 12 9"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
    >
        <path
            fillRule="evenodd"
            clipRule="evenodd"
            d="M4.5241 0.242677C4.62341 0.34442 4.67919 0.482337 4.67919 0.626134C4.67919 0.76993 4.62341 0.907847 4.5241 1.00959L1.89369 3.70102H7.68483C8.3587 3.70102 9.35854 3.9036 10.2042 4.52653C11.0775 5.17045 11.7507 6.23762 11.7507 7.86116C11.7507 8.00507 11.6948 8.14309 11.5953 8.24485C11.4959 8.34661 11.361 8.40378 11.2203 8.40378C11.0797 8.40378 10.9448 8.34661 10.8453 8.24485C10.7459 8.14309 10.69 8.00507 10.69 7.86116C10.69 6.59069 10.1844 5.84982 9.58481 5.40776C8.95761 4.94544 8.18899 4.78627 7.68483 4.78627H1.89369L4.5241 7.4777C4.5762 7.52738 4.61799 7.58728 4.64698 7.65384C4.67597 7.72041 4.69155 7.79226 4.69281 7.86512C4.69406 7.93798 4.68096 8.01035 4.65429 8.07791C4.62762 8.14548 4.58792 8.20686 4.53756 8.25839C4.4872 8.30991 4.42722 8.35053 4.36118 8.37782C4.29515 8.40512 4.22442 8.41852 4.15321 8.41723C4.082 8.41595 4.01178 8.4 3.94673 8.37034C3.88167 8.34068 3.82313 8.29792 3.77457 8.24461L0.23908 4.6271C0.139767 4.52536 0.0839844 4.38744 0.0839844 4.24364C0.0839844 4.09985 0.139767 3.96193 0.23908 3.86019L3.77457 0.242677C3.87401 0.141061 4.0088 0.0839844 4.14934 0.0839844C4.28987 0.0839844 4.42466 0.141061 4.5241 0.242677Z"
            fill="#131313"
            stroke="#131313"
            strokeWidth="0.166667"
        />
    </svg>
);

const HeartIcon: React.FC = () => (
    <svg
        width="16"
        height="14"
        viewBox="0 0 16 14"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
    >
        <path
            d="M6.63749 12.3742C4.66259 10.885 0.75 7.4804 0.75 4.41664C0.75 2.39161 2.22368 0.75 4.25 0.75C5.3 0.75 6.35 1.10294 7.75 2.51469C9.15 1.10294 10.2 0.75 11.25 0.75C13.2763 0.75 14.75 2.39161 14.75 4.41664C14.75 7.4804 10.8374 10.885 8.86251 12.3742C8.19793 12.8753 7.30207 12.8753 6.63749 12.3742Z"
            stroke="#131313"
            strokeWidth="1.5"
            strokeLinecap="round"
            strokeLinejoin="round"
        />
    </svg>
);

// =============================================================================
// Types
// =============================================================================

interface Comment {
    id: string;
    collectionID: number;
    fileID?: number;
    encData: {
        text: string;
        userName: string;
        userAvatar?: string;
    };
    parentCommentID?: string;
    isDeleted: boolean;
    userID: number;
    anonUserID?: string;
    createdAt: number;
    updatedAt: number;
}

// =============================================================================
// Constants
// =============================================================================

// Mock current user ID (for determining if comment is from current user)
const CURRENT_USER_ID = 2;

// Mock data - realistic discussion between 4 friends about a Goa trip photo
const mockComments: Comment[] = [
    {
        id: "1",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Omg this photo is amazing! The sunset colors are unreal",
            userName: "Vishnu",
        },
        isDeleted: false,
        userID: 1,
        createdAt: Date.now() - 2 * 24 * 60 * 60 * 1000,
        updatedAt: Date.now() - 2 * 24 * 60 * 60 * 1000,
    },
    {
        id: "2",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "I know right! Took me forever to get the timing right",
            userName: "Anand",
        },
        parentCommentID: "1",
        isDeleted: false,
        userID: CURRENT_USER_ID,
        createdAt: Date.now() - 2 * 24 * 60 * 60 * 1000 + 30000,
        updatedAt: Date.now() - 2 * 24 * 60 * 60 * 1000 + 30000,
    },
    {
        id: "3",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Remember how we almost missed this because Priya couldn't find her sandals",
            userName: "Vishnu",
        },
        isDeleted: false,
        userID: 1,
        createdAt: Date.now() - 2 * 24 * 60 * 60 * 1000 + 60000,
        updatedAt: Date.now() - 2 * 24 * 60 * 60 * 1000 + 60000,
    },
    {
        id: "4",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "HEY those sandals were expensive okay! I wasn't leaving them behind",
            userName: "Priya",
        },
        parentCommentID: "3",
        isDeleted: false,
        userID: 4,
        createdAt: Date.now() - 2 * 24 * 60 * 60 * 1000 + 120000,
        updatedAt: Date.now() - 2 * 24 * 60 * 60 * 1000 + 120000,
    },
    {
        id: "5",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "They were like 200 rupees from the beach stall lmao",
            userName: "Shanthy",
        },
        parentCommentID: "3",
        isDeleted: false,
        userID: 3,
        createdAt: Date.now() - 2 * 24 * 60 * 60 * 1000 + 180000,
        updatedAt: Date.now() - 2 * 24 * 60 * 60 * 1000 + 180000,
    },
    {
        id: "6",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Lol I remember that! We were literally running to the beach",
            userName: "Anand",
        },
        parentCommentID: "3",
        isDeleted: false,
        userID: CURRENT_USER_ID,
        createdAt: Date.now() - 2 * 24 * 60 * 60 * 1000 + 240000,
        updatedAt: Date.now() - 2 * 24 * 60 * 60 * 1000 + 240000,
    },
    {
        id: "7",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Still expensive!! And they were cute",
            userName: "Priya",
        },
        parentCommentID: "5",
        isDeleted: false,
        userID: 4,
        createdAt: Date.now() - 2 * 24 * 60 * 60 * 1000 + 300000,
        updatedAt: Date.now() - 2 * 24 * 60 * 60 * 1000 + 300000,
    },
    {
        id: "8",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Worth it though, look at this shot! Best photo from the whole trip imo",
            userName: "Anand",
        },
        isDeleted: false,
        userID: CURRENT_USER_ID,
        createdAt: Date.now() - 2 * 24 * 60 * 60 * 1000 + 360000,
        updatedAt: Date.now() - 2 * 24 * 60 * 60 * 1000 + 360000,
    },
    {
        id: "9",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Agreed! Can you send me the full res version? Want to print it",
            userName: "Shanthy",
        },
        parentCommentID: "8",
        isDeleted: false,
        userID: 3,
        createdAt: Date.now() - 2 * 24 * 60 * 60 * 1000 + 420000,
        updatedAt: Date.now() - 2 * 24 * 60 * 60 * 1000 + 420000,
    },
    {
        id: "10",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Yeah I'll share the album link with everyone later today",
            userName: "Anand",
        },
        parentCommentID: "9",
        isDeleted: false,
        userID: CURRENT_USER_ID,
        createdAt: Date.now() - 2 * 24 * 60 * 60 * 1000 + 480000,
        updatedAt: Date.now() - 2 * 24 * 60 * 60 * 1000 + 480000,
    },
    {
        id: "11",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Who took this btw? The composition is so good",
            userName: "Priya",
        },
        isDeleted: false,
        userID: 4,
        createdAt: Date.now() - 1 * 24 * 60 * 60 * 1000,
        updatedAt: Date.now() - 1 * 24 * 60 * 60 * 1000,
    },
    {
        id: "12",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "That would be me actually! Was experimenting with the angles",
            userName: "Anand",
        },
        parentCommentID: "11",
        isDeleted: false,
        userID: CURRENT_USER_ID,
        createdAt: Date.now() - 1 * 24 * 60 * 60 * 1000 + 60000,
        updatedAt: Date.now() - 1 * 24 * 60 * 60 * 1000 + 60000,
    },
    {
        id: "13",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Don't let it go to your head, you also took 47 blurry photos that day",
            userName: "Shanthy",
        },
        parentCommentID: "12",
        isDeleted: true,
        userID: 3,
        createdAt: Date.now() - 1 * 24 * 60 * 60 * 1000 + 120000,
        updatedAt: Date.now() - 1 * 24 * 60 * 60 * 1000 + 120000,
    },
    {
        id: "14",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "HAHAHA okay fair point",
            userName: "Anand",
        },
        parentCommentID: "13",
        isDeleted: false,
        userID: CURRENT_USER_ID,
        createdAt: Date.now() - 1 * 24 * 60 * 60 * 1000 + 180000,
        updatedAt: Date.now() - 1 * 24 * 60 * 60 * 1000 + 180000,
    },
    {
        id: "15",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Quality over quantity right?",
            userName: "Vishnu",
        },
        parentCommentID: "13",
        isDeleted: false,
        userID: 1,
        createdAt: Date.now() - 1 * 24 * 60 * 60 * 1000 + 240000,
        updatedAt: Date.now() - 1 * 24 * 60 * 60 * 1000 + 240000,
    },
    {
        id: "16",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Exactly! At least I got this one perfect",
            userName: "Anand",
        },
        parentCommentID: "15",
        isDeleted: false,
        userID: CURRENT_USER_ID,
        createdAt: Date.now() - 1 * 24 * 60 * 60 * 1000 + 300000,
        updatedAt: Date.now() - 1 * 24 * 60 * 60 * 1000 + 300000,
    },
    {
        id: "17",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "We need to plan another trip soon. I miss Goa already",
            userName: "Priya",
        },
        isDeleted: false,
        userID: 4,
        createdAt: Date.now() - 23 * 60 * 60 * 1000,
        updatedAt: Date.now() - 23 * 60 * 60 * 1000,
    },
    {
        id: "18",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Same! Maybe December? End of year trip?",
            userName: "Shanthy",
        },
        parentCommentID: "17",
        isDeleted: false,
        userID: 3,
        createdAt: Date.now() - 22 * 60 * 60 * 1000,
        updatedAt: Date.now() - 22 * 60 * 60 * 1000,
    },
    {
        id: "19",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "December works for me! But not Goa again, somewhere new?",
            userName: "Anand",
        },
        parentCommentID: "18",
        isDeleted: false,
        userID: CURRENT_USER_ID,
        createdAt: Date.now() - 21 * 60 * 60 * 1000,
        updatedAt: Date.now() - 21 * 60 * 60 * 1000,
    },
    {
        id: "20",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Ooh how about Kerala? Always wanted to go there",
            userName: "Vishnu",
        },
        parentCommentID: "19",
        isDeleted: false,
        userID: 1,
        createdAt: Date.now() - 20 * 60 * 60 * 1000,
        updatedAt: Date.now() - 20 * 60 * 60 * 1000,
    },
    {
        id: "21",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "YES Kerala! Backwaters and houseboats!",
            userName: "Priya",
        },
        parentCommentID: "20",
        isDeleted: false,
        userID: 4,
        createdAt: Date.now() - 19 * 60 * 60 * 1000,
        updatedAt: Date.now() - 19 * 60 * 60 * 1000,
    },
    {
        id: "22",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "I've been wanting to try the houseboat thing for ages",
            userName: "Anand",
        },
        parentCommentID: "20",
        isDeleted: false,
        userID: CURRENT_USER_ID,
        createdAt: Date.now() - 18 * 60 * 60 * 1000 + 30000,
        updatedAt: Date.now() - 18 * 60 * 60 * 1000 + 30000,
    },
    {
        id: "23",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "I'm in! Let's make a group to plan this properly",
            userName: "Shanthy",
        },
        parentCommentID: "20",
        isDeleted: false,
        userID: 3,
        createdAt: Date.now() - 18 * 60 * 60 * 1000,
        updatedAt: Date.now() - 18 * 60 * 60 * 1000,
    },
    {
        id: "24",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "I'll create one tonight",
            userName: "Anand",
        },
        parentCommentID: "23",
        isDeleted: false,
        userID: CURRENT_USER_ID,
        createdAt: Date.now() - 17 * 60 * 60 * 1000,
        updatedAt: Date.now() - 17 * 60 * 60 * 1000,
    },
    {
        id: "25",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Wait can we go back to how good this photo is though",
            userName: "Priya",
        },
        isDeleted: false,
        userID: 4,
        createdAt: Date.now() - 12 * 60 * 60 * 1000,
        updatedAt: Date.now() - 12 * 60 * 60 * 1000,
    },
    {
        id: "26",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "The way the light hits the water is so pretty",
            userName: "Priya",
        },
        isDeleted: false,
        userID: 4,
        createdAt: Date.now() - 12 * 60 * 60 * 1000 + 30000,
        updatedAt: Date.now() - 12 * 60 * 60 * 1000 + 30000,
    },
    {
        id: "27",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Priya sending 3 messages in a row as usual",
            userName: "Shanthy",
        },
        parentCommentID: "26",
        isDeleted: false,
        userID: 3,
        createdAt: Date.now() - 11 * 60 * 60 * 1000,
        updatedAt: Date.now() - 11 * 60 * 60 * 1000,
    },
    {
        id: "28",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "I have a lot of thoughts okay!!",
            userName: "Priya",
        },
        parentCommentID: "27",
        isDeleted: false,
        userID: 4,
        createdAt: Date.now() - 10 * 60 * 60 * 1000,
        updatedAt: Date.now() - 10 * 60 * 60 * 1000,
    },
    {
        id: "29",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "That's what we love about you",
            userName: "Anand",
        },
        parentCommentID: "28",
        isDeleted: false,
        userID: CURRENT_USER_ID,
        createdAt: Date.now() - 9 * 60 * 60 * 1000,
        updatedAt: Date.now() - 9 * 60 * 60 * 1000,
    },
    {
        id: "30",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Aww thanks! See Shanthy, some people appreciate me",
            userName: "Priya",
        },
        parentCommentID: "29",
        isDeleted: false,
        userID: 4,
        createdAt: Date.now() - 8 * 60 * 60 * 1000,
        updatedAt: Date.now() - 8 * 60 * 60 * 1000,
    },
    {
        id: "31",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "I appreciate you too, just in a bullying way",
            userName: "Shanthy",
        },
        parentCommentID: "30",
        isDeleted: false,
        userID: 3,
        createdAt: Date.now() - 7 * 60 * 60 * 1000,
        updatedAt: Date.now() - 7 * 60 * 60 * 1000,
    },
    {
        id: "32",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "This is why our friend group works lol",
            userName: "Anand",
        },
        parentCommentID: "31",
        isDeleted: false,
        userID: CURRENT_USER_ID,
        createdAt: Date.now() - 6 * 60 * 60 * 1000,
        updatedAt: Date.now() - 6 * 60 * 60 * 1000,
    },
    {
        id: "33",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "The chaos is what makes it fun",
            userName: "Vishnu",
        },
        parentCommentID: "32",
        isDeleted: false,
        userID: 1,
        createdAt: Date.now() - 5 * 60 * 60 * 1000,
        updatedAt: Date.now() - 5 * 60 * 60 * 1000,
    },
    {
        id: "34",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Okay but seriously, this should be our group photo",
            userName: "Shanthy",
        },
        isDeleted: false,
        userID: 3,
        createdAt: Date.now() - 3 * 60 * 60 * 1000,
        updatedAt: Date.now() - 3 * 60 * 60 * 1000,
    },
    {
        id: "35",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Wait we're not even in the photo though",
            userName: "Anand",
        },
        parentCommentID: "34",
        isDeleted: false,
        userID: CURRENT_USER_ID,
        createdAt: Date.now() - 2 * 60 * 60 * 1000,
        updatedAt: Date.now() - 2 * 60 * 60 * 1000,
    },
    {
        id: "36",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "That's the best part, no faces just vibes",
            userName: "Shanthy",
        },
        parentCommentID: "35",
        isDeleted: false,
        userID: 3,
        createdAt: Date.now() - 1 * 60 * 60 * 1000,
        updatedAt: Date.now() - 1 * 60 * 60 * 1000,
    },
    {
        id: "37",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "She has a point actually",
            userName: "Vishnu",
        },
        parentCommentID: "36",
        isDeleted: false,
        userID: 1,
        createdAt: Date.now() - 75 * 60 * 1000,
        updatedAt: Date.now() - 75 * 60 * 1000,
    },
    {
        id: "38",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Okay I'm convinced, vibes > faces",
            userName: "Anand",
        },
        parentCommentID: "36",
        isDeleted: false,
        userID: CURRENT_USER_ID,
        createdAt: Date.now() - 70 * 60 * 1000,
        updatedAt: Date.now() - 70 * 60 * 1000,
    },
    {
        id: "39",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Fine fine, approved as official group photo",
            userName: "Priya",
        },
        parentCommentID: "36",
        isDeleted: false,
        userID: 4,
        createdAt: Date.now() - 65 * 60 * 1000,
        updatedAt: Date.now() - 65 * 60 * 1000,
    },
    {
        id: "40",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Motion passed unanimously! I'll set it as the album cover",
            userName: "Anand",
        },
        parentCommentID: "39",
        isDeleted: false,
        userID: CURRENT_USER_ID,
        createdAt: Date.now() - 60 * 60 * 1000,
        updatedAt: Date.now() - 60 * 60 * 1000,
    },
    {
        id: "41",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Occupy Mars",
            userName: "Elon",
        },
        parentCommentID: "35",
        isDeleted: false,
        userID: 5,
        createdAt: Date.now() - 45 * 60 * 1000,
        updatedAt: Date.now() - 45 * 60 * 1000,
    },
    {
        id: "42",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "You want to wake up in the morning and think the future is going to be great - and that's what being a spacefaring civilization is all about.\n\nIt's about believing in the future and thinking that the future will be better than the past.\n\nAnd I can't think of anything more exciting than going out there and being among the stars.",
            userName: "Elon",
        },
        isDeleted: false,
        userID: 5,
        createdAt: Date.now() - 43 * 60 * 1000,
        updatedAt: Date.now() - 43 * 60 * 1000,
    },
    {
        id: "43",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "The stars await.",
            userName: "Elon",
        },
        isDeleted: false,
        userID: 5,
        createdAt: Date.now() - 30 * 60 * 1000,
        updatedAt: Date.now() - 30 * 60 * 1000,
    },
    {
        id: "44",
        collectionID: 1,
        fileID: 1,
        encData: {
            text: "Haha.",
            userName: "Anand",
        },
        parentCommentID: "42",
        isDeleted: false,
        userID: CURRENT_USER_ID,
        createdAt: Date.now() - 5 * 60 * 1000,
        updatedAt: Date.now() - 5 * 60 * 1000,
    },
];

// =============================================================================
// Utility Functions
// =============================================================================

const formatTimeAgo = (timestamp: number): string => {
    const diff = Date.now() - timestamp;
    const minutes = Math.floor(diff / 60000);
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours}h ago`;
    const days = Math.floor(hours / 24);
    return `${days}d ago`;
};

const getParentComment = (
    parentID: string | undefined,
    comments: Comment[],
): Comment | undefined => {
    if (!parentID) return undefined;
    return comments.find((c) => c.id === parentID);
};

/**
 * Truncates comment text to first 100 characters of the first line.
 * Adds "..." if multiline or if first line exceeds 100 chars.
 */
const truncateCommentText = (text: string): string => {
    const lines = text.split("\n");
    const firstLine = lines[0] ?? text;
    const isMultiline = lines.length > 1;
    if (firstLine.length > 100) {
        return firstLine.slice(0, 100) + "...";
    }
    return isMultiline ? firstLine + "..." : firstLine;
};

// =============================================================================
// Shared Comment Components
// =============================================================================

interface CommentHeaderProps {
    userName: string;
    timestamp: number;
    avatarSize?: number;
}

/**
 * Header component showing avatar, username, and timestamp.
 * Used consistently for both root comments and replies.
 */
const CommentHeader: React.FC<CommentHeaderProps> = ({
    userName,
    timestamp,
    avatarSize = 32,
}) => (
    <CommentHeaderContainer>
        <Avatar
            sx={{
                width: avatarSize,
                height: avatarSize,
                fontSize: 14,
                bgcolor: "#E0E0E0",
                color: "#666",
            }}
        >
            {userName[0]}
        </Avatar>
        <UserName>{userName}</UserName>
        <Separator>•</Separator>
        <Timestamp>{formatTimeAgo(timestamp)}</Timestamp>
    </CommentHeaderContainer>
);

interface QuotedReplyProps {
    parentComment: Comment;
    isOwn: boolean;
}

/**
 * Shows the quoted parent comment inside a reply bubble.
 */
const QuotedReply: React.FC<QuotedReplyProps> = ({ parentComment, isOwn }) => (
    <QuotedReplyContainer isOwn={isOwn}>
        {parentComment.isDeleted ? (
            <Typography
                sx={{
                    fontSize: 12,
                    fontStyle: "italic",
                    color: isOwn ? "rgba(255,255,255,0.8)" : "#888",
                }}
            >
                (deleted)
            </Typography>
        ) : (
            <>
                <Typography
                    sx={{
                        fontWeight: 600,
                        fontSize: 12,
                        color: isOwn ? "rgba(255,255,255,0.9)" : "#666",
                    }}
                >
                    {parentComment.encData.userName}
                </Typography>
                <Typography
                    sx={{
                        fontSize: 12,
                        color: isOwn ? "rgba(255,255,255,0.8)" : "#888",
                    }}
                >
                    {truncateCommentText(parentComment.encData.text)}
                </Typography>
            </>
        )}
    </QuotedReplyContainer>
);

interface CommentActionsProps {
    onReply: () => void;
}

/**
 * Action buttons (like, reply) shown below comment bubbles.
 */
const CommentActions: React.FC<CommentActionsProps> = ({ onReply }) => (
    <ActionsContainer>
        <ActionButton>
            <HeartIcon />
        </ActionButton>
        <ActionButton onClick={onReply}>
            <ReplyIcon />
        </ActionButton>
    </ActionsContainer>
);

// =============================================================================
// Main Component
// =============================================================================

export type CommentsSidebarProps = ModalVisibilityProps;

/**
 * A sidebar panel for displaying and managing comments on a file.
 */
export const CommentsSidebar: React.FC<CommentsSidebarProps> = ({
    open,
    onClose,
}) => {
    const [comment, setComment] = useState("");
    const [replyingTo, setReplyingTo] = useState<Comment | null>(null);

    const handleSend = () => {
        if (!comment.trim()) return;
        // TODO: Call API to store comment
        setComment("");
        setReplyingTo(null);
    };

    const handleReply = (commentToReply: Comment) => {
        setReplyingTo(commentToReply);
    };

    // Filter out deleted comments and sort by timestamp
    const sortedComments = [...mockComments]
        .filter((c) => !c.isDeleted)
        .sort((a, b) => a.createdAt - b.createdAt);

    return (
        <SidebarDrawer open={open} onClose={onClose} anchor="right">
            <Header>
                <Typography sx={{ color: "#000", fontWeight: 600 }}>
                    {`${sortedComments.length} ${t("comments")}`}
                </Typography>
                <CloseButton onClick={onClose}>
                    <CloseIcon sx={{ fontSize: 22 }} />
                </CloseButton>
            </Header>

            <CommentsContainer>
                {sortedComments.map((comment, index) => {
                    const commentIsOwn = comment.userID === CURRENT_USER_ID;
                    const prevComment = sortedComments[index - 1];
                    const nextComment = sortedComments[index + 1];

                    // 10 minutes in milliseconds
                    const GROUP_TIME_THRESHOLD = 10 * 60 * 1000;

                    // Comments are in same sequence if same user AND within 10 minutes
                    const isSameSequenceAsPrev =
                        prevComment &&
                        prevComment.userID === comment.userID &&
                        comment.createdAt - prevComment.createdAt <=
                            GROUP_TIME_THRESHOLD;
                    const isSameSequenceAsNext =
                        nextComment &&
                        nextComment.userID === comment.userID &&
                        nextComment.createdAt - comment.createdAt <=
                            GROUP_TIME_THRESHOLD;

                    const isFirstInSequence = !isSameSequenceAsPrev;
                    const isLastInSequence = !isSameSequenceAsNext;
                    const showHeader = isFirstInSequence && !commentIsOwn;
                    const parentComment = comment.parentCommentID
                        ? getParentComment(comment.parentCommentID, mockComments)
                        : undefined;

                    const showOwnTimestamp =
                        commentIsOwn &&
                        !!prevComment &&
                        prevComment.userID !== CURRENT_USER_ID;

                    return (
                        <React.Fragment key={comment.id}>
                            {showHeader && (
                                <CommentHeader
                                    userName={comment.encData.userName}
                                    timestamp={comment.createdAt}
                                />
                            )}
                            {showOwnTimestamp && (
                                <OwnTimestamp>
                                    {formatTimeAgo(comment.createdAt)}
                                </OwnTimestamp>
                            )}
                            <CommentBubbleWrapper
                                isOwn={commentIsOwn}
                                isFirstOwn={
                                    !showOwnTimestamp &&
                                    commentIsOwn &&
                                    !!prevComment &&
                                    prevComment.userID !== CURRENT_USER_ID
                                }
                                isLastOwn={isLastInSequence}
                            >
                                <CommentBubbleInner>
                                    <CommentBubble isOwn={commentIsOwn}>
                                        {parentComment && (
                                            <QuotedReply
                                                parentComment={parentComment}
                                                isOwn={commentIsOwn}
                                            />
                                        )}
                                        <CommentText isOwn={commentIsOwn}>
                                            {comment.encData.text}
                                        </CommentText>
                                    </CommentBubble>
                                    <CommentActions
                                        onReply={() => handleReply(comment)}
                                    />
                                </CommentBubbleInner>
                            </CommentBubbleWrapper>
                        </React.Fragment>
                    );
                })}
            </CommentsContainer>

            <InputContainer>
                {replyingTo && (
                    <ReplyingToBar>
                        <Box
                            sx={{
                                borderLeft: "3px solid #ccc",
                                paddingLeft: "10px",
                                paddingRight: "24px",
                            }}
                        >
                            <Typography sx={{ fontSize: 12, color: "#666" }}>
                                Replying to{" "}
                                {replyingTo.userID === CURRENT_USER_ID
                                    ? "me"
                                    : replyingTo.encData.userName}
                                ...
                            </Typography>
                            <Typography
                                sx={{
                                    fontSize: 14,
                                    color: "#000",
                                    overflow: "hidden",
                                    textOverflow: "ellipsis",
                                    whiteSpace: "nowrap",
                                }}
                            >
                                {truncateCommentText(replyingTo.encData.text)}
                            </Typography>
                        </Box>
                        <IconButton
                            size="small"
                            onClick={() => setReplyingTo(null)}
                            sx={{
                                position: "absolute",
                                top: 8,
                                right: 8,
                                color: "#666",
                                p: 0.5,
                            }}
                        >
                            <CloseIcon sx={{ fontSize: 16 }} />
                        </IconButton>
                    </ReplyingToBar>
                )}
                <InputWrapper>
                    <StyledTextField
                        fullWidth
                        multiline
                        minRows={1}
                        autoFocus
                        placeholder="Say something nice!"
                        variant="standard"
                        value={comment}
                        onChange={(e) => setComment(e.target.value)}
                    />
                </InputWrapper>
                <SendButton onClick={handleSend}>
                    <SendIcon />
                </SendButton>
            </InputContainer>
        </SidebarDrawer>
    );
};

// =============================================================================
// Styled Components
// =============================================================================

// Drawer & Layout
const SidebarDrawer = styled(Drawer)(() => ({
    "& .MuiDrawer-paper": {
        width: "23vw",
        minWidth: "520px",
        maxWidth: "calc(100% - 32px)",
        height: "calc(100% - 32px)",
        margin: "16px",
        borderRadius: "36px",
        backgroundColor: "#fff",
        padding: "24px 24px 32px 24px",
        boxShadow: "none",
        display: "flex",
        flexDirection: "column",
        "@media (max-width: 450px)": {
            width: "100%",
            minWidth: "unset",
            maxWidth: "100%",
            height: "100%",
            margin: 0,
            borderRadius: 0,
        },
    },
    "& .MuiBackdrop-root": {
        backgroundColor: "transparent",
    },
}));

const Header = styled(Stack)(() => ({
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 48,
}));

const CloseButton = styled(IconButton)(() => ({
    backgroundColor: "#F5F5F7",
    color: "#000",
    padding: "8px",
    "&:hover": {
        backgroundColor: "#E5E5E7",
    },
}));

const CommentsContainer = styled(Box)(() => ({
    flex: 1,
    overflow: "auto",
    marginBottom: 16,
    marginRight: -24,
    "&::-webkit-scrollbar": {
        width: "6px",
    },
    "&::-webkit-scrollbar-track": {
        background: "transparent",
    },
    "&::-webkit-scrollbar-thumb": {
        background: "rgba(0, 0, 0, 0.2)",
        borderRadius: "3px",
    },
    scrollbarWidth: "thin",
    scrollbarColor: "rgba(0, 0, 0, 0.2) transparent",
}));

// Comment Header
const CommentHeaderContainer = styled(Box)(() => ({
    display: "flex",
    alignItems: "center",
    gap: 8,
    marginBottom: 12,
}));

const UserName = styled(Typography)(() => ({
    fontWeight: 600,
    color: "#000",
    fontSize: 14,
}));

const Separator = styled(Typography)(() => ({
    color: "#666",
    fontSize: 12,
    marginLeft: -4,
}));

const Timestamp = styled(Typography)(() => ({
    color: "#666",
    fontSize: 12,
}));

const OwnTimestamp = styled(Typography)(() => ({
    color: "#666",
    fontSize: 12,
    textAlign: "right",
    marginBottom: 4,
    paddingRight: 52,
}));

// Comment Bubbles
const CommentBubbleWrapper = styled(Box)<{
    isOwn: boolean;
    isFirstOwn?: boolean;
    isLastOwn?: boolean;
}>(({ isOwn, isFirstOwn, isLastOwn }) => ({
    display: "flex",
    justifyContent: isOwn ? "flex-end" : "flex-start",
    width: "100%",
    marginTop: isFirstOwn ? 64 : 0,
    marginBottom: isOwn ? 24 : isLastOwn ? 48 : 24,
    paddingRight: isOwn ? 52 : 0,
    paddingLeft: isOwn ? 0 : 28,
}));

const CommentBubbleInner = styled(Box)(() => ({
    position: "relative",
    maxWidth: 320,
}));

const CommentBubble = styled(Box)<{ isOwn: boolean }>(({ isOwn }) => ({
    backgroundColor: isOwn ? "#0DAF35" : "#F0F0F0",
    borderRadius: isOwn ? "20px 6px 20px 20px" : "6px 20px 20px 20px",
    padding: "20px 40px 20px 20px",
    width: "fit-content",
}));

const CommentText = styled(Typography)<{ isOwn: boolean }>(({ isOwn }) => ({
    color: isOwn ? "#fff" : "#000",
    fontSize: 14,
    whiteSpace: "pre-wrap",
}));

const QuotedReplyContainer = styled(Box)<{ isOwn: boolean }>(({ isOwn }) => ({
    borderLeft: `3px solid ${isOwn ? "rgba(255,255,255,0.5)" : "#ccc"}`,
    paddingLeft: 10,
    marginBottom: 16,
}));

// Actions
const ActionsContainer = styled(Box)(() => ({
    display: "flex",
    alignItems: "center",
    gap: 14,
    backgroundColor: "#F0F0F0",
    borderRadius: 9999,
    padding: "10px 14px",
    border: "2px solid #fff",
    position: "absolute",
    bottom: 0,
    right: 0,
    transform: "translate(50%, 50%)",
}));

const ActionButton = styled(Box)(() => ({
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    cursor: "pointer",
}));

// Input Area
const InputContainer = styled(Box)(() => ({
    position: "relative",
    backgroundColor: "#F3F3F3",
    borderRadius: "20px",
    margin: "0 -8px -16px -8px",
}));

const ReplyingToBar = styled(Box)(() => ({
    position: "relative",
    padding: "20px 16px 8px 16px",
}));

const InputWrapper = styled(Box)(() => ({
    padding: "8px 48px 8px 16px",
    maxHeight: "300px",
    overflow: "auto",
    "&::-webkit-scrollbar": {
        width: "8px",
    },
    "&::-webkit-scrollbar-track": {
        background: "transparent",
    },
    "&::-webkit-scrollbar-thumb": {
        background: "rgba(0, 0, 0, 0.3)",
        borderRadius: "4px",
    },
    "&::-webkit-scrollbar-thumb:hover": {
        background: "rgba(0, 0, 0, 0.5)",
    },
    scrollbarWidth: "thin",
    scrollbarColor: "rgba(0, 0, 0, 0.3) transparent",
}));

const StyledTextField = styled(TextField)(() => ({
    "& .MuiInput-root": {
        "&::before, &::after": {
            display: "none",
        },
    },
    "& .MuiInputBase-input": {
        padding: 0,
        color: "#000",
        "&::placeholder": {
            color: "#666",
            opacity: 1,
        },
    },
}));

const SendButton = styled(IconButton)(() => ({
    position: "absolute",
    right: 12,
    bottom: 8.5,
    color: "#000",
    width: 42,
    height: 42,
    "&:hover": {
        backgroundColor: "rgba(0, 0, 0, 0.1)",
    },
}));
