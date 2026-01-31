import SvgIcon, { type SvgIconProps } from "@mui/material/SvgIcon";
import React from "react";

// Custom icon because Shape01 is not available in Hugeicons.
export const ShapeIcon: React.FC<SvgIconProps> = (props) => (
    <SvgIcon {...props} viewBox="0 0 24 24">
        <path
            d="M13.3382 10H10.6618C9.1273 10 8.36006 10 8.08543 9.49297C7.8108 8.98594 8.21743 8.32019 9.0307 6.9887L10.3689 4.79773C11.101 3.59924 11.467 3 12 3C12.533 3 12.899 3.59924 13.6311 4.79773L14.9693 6.9887C15.7826 8.32019 16.1892 8.98594 15.9146 9.49297C15.6399 10 14.8727 10 13.3382 10Z"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinejoin="round"
        />
        <circle
            cx="17.5"
            cy="17.5"
            r="3.5"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
        />
        <path
            d="M9.66294 20.1111C10 19.6067 10 18.9045 10 17.5C10 16.0955 10 15.3933 9.66294 14.8889C9.51702 14.6705 9.32952 14.483 9.11114 14.3371C8.60669 14 7.90446 14 6.5 14C5.09554 14 4.39331 14 3.88886 14.3371C3.67048 14.483 3.48298 14.6705 3.33706 14.8889C3 15.3933 3 16.0955 3 17.5C3 18.9045 3 19.6067 3.33706 20.1111C3.48298 20.3295 3.67048 20.517 3.88886 20.6629C4.39331 21 5.09554 21 6.5 21C7.90446 21 8.60669 21 9.11114 20.6629C9.32952 20.517 9.51702 20.3295 9.66294 20.1111Z"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinejoin="round"
        />
    </SvgIcon>
);
