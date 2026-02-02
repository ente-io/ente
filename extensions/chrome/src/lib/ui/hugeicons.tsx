import React from "react";

/**
 * Minimal Hugeicons (stroke-rounded) renderer + a small subset of icons.
 *
 * Source: hugeicons Flutter package (MIT License, Copyright (c) 2024 Halal Labs)
 * We vendor only the specific icons we need to avoid adding a new JS dependency.
 */

type HugeIconAttrs = Record<string, string>;
export type HugeIconData = Array<[string, HugeIconAttrs]>;

export function HugeIcon({
  icon,
  size = 16,
  className,
}: {
  icon: HugeIconData;
  size?: number;
  className?: string;
}) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      className={className}
      aria-hidden="true"
      focusable="false"
    >
      {icon.map(([tag, attrs], i) => {
        const { key, ...rest } = attrs;
        return React.createElement(tag as never, { key: key ?? `${String(tag)}-${i}`, ...rest });
      })}
    </svg>
  );
}

export const hugeLock: HugeIconData = [
  [
    "path",
    {
      key: "0",
      d: "M22 12C22 17.5228 17.5228 22 12 22C6.47715 22 2 17.5228 2 12C2 6.47715 6.47715 2 12 2C17.5228 2 22 6.47715 22 12Z",
      stroke: "currentColor",
      strokeWidth: "1.5",
    },
  ],
  [
    "path",
    {
      key: "1",
      d: "M12 13C13.1046 13 14 12.1046 14 11C14 9.89543 13.1046 9 12 9C10.8954 9 10 9.89543 10 11C10 12.1046 10.8954 13 12 13ZM12 13L12 16",
      stroke: "currentColor",
      strokeWidth: "1.5",
      strokeLinecap: "round",
    },
  ],
];

export const hugeLockPassword: HugeIconData = [
  [
    "path",
    {
      key: "0",
      d: "M4.26781 18.8447C4.49269 20.515 5.87613 21.8235 7.55966 21.9009C8.97627 21.966 10.4153 22 12 22C13.5847 22 15.0237 21.966 16.4403 21.9009C18.1239 21.8235 19.5073 20.515 19.7322 18.8447C19.879 17.7547 20 16.6376 20 15.5C20 14.3624 19.879 13.2453 19.7322 12.1553C19.5073 10.485 18.1239 9.17649 16.4403 9.09909C15.0237 9.03397 13.5847 9 12 9C10.4153 9 8.97627 9.03397 7.55966 9.09909C5.87613 9.17649 4.49269 10.485 4.26781 12.1553C4.12105 13.2453 4 14.3624 4 15.5C4 16.6376 4.12105 17.7547 4.26781 18.8447Z",
      stroke: "currentColor",
      strokeWidth: "1.5",
    },
  ],
  [
    "path",
    {
      key: "1",
      d: "M7.5 9V6.5C7.5 4.01472 9.51472 2 12 2C14.4853 2 16.5 4.01472 16.5 6.5V9",
      stroke: "currentColor",
      strokeWidth: "1.5",
      strokeLinecap: "round",
      strokeLinejoin: "round",
    },
  ],
  [
    "path",
    {
      key: "2",
      d: "M16 15.49V15.5",
      stroke: "currentColor",
      strokeWidth: "2",
      strokeLinecap: "round",
      strokeLinejoin: "round",
    },
  ],
  [
    "path",
    {
      key: "3",
      d: "M12 15.49V15.5",
      stroke: "currentColor",
      strokeWidth: "2",
      strokeLinecap: "round",
      strokeLinejoin: "round",
    },
  ],
  [
    "path",
    {
      key: "4",
      d: "M8 15.49V15.5",
      stroke: "currentColor",
      strokeWidth: "2",
      strokeLinecap: "round",
      strokeLinejoin: "round",
    },
  ],
];

export const hugeArrowUp02: HugeIconData = [
  [
    "path",
    {
      key: "0",
      d: "M12 4L12 20",
      stroke: "currentColor",
      strokeWidth: "1.5",
      strokeLinecap: "round",
      strokeLinejoin: "round",
    },
  ],
  [
    "path",
    {
      key: "1",
      d: "M16.9998 8.99996C16.9998 8.99996 13.3174 4.00001 11.9998 4C10.6822 3.99999 6.99982 9 6.99982 9",
      stroke: "currentColor",
      strokeWidth: "1.5",
      strokeLinecap: "round",
      strokeLinejoin: "round",
    },
  ],
];

export const hugeClipboard: HugeIconData = [
  [
    "path",
    {
      key: "0",
      d: "M17.0235 3.03358L16.0689 2.77924C13.369 2.05986 12.019 1.70018 10.9555 2.31074C9.89196 2.9213 9.53023 4.26367 8.80678 6.94841L7.78366 10.7452C7.0602 13.4299 6.69848 14.7723 7.3125 15.8298C7.92652 16.8874 9.27651 17.247 11.9765 17.9664L12.9311 18.2208C15.631 18.9401 16.981 19.2998 18.0445 18.6893C19.108 18.0787 19.4698 16.7363 20.1932 14.0516L21.2163 10.2548C21.9398 7.57005 22.3015 6.22768 21.6875 5.17016C21.0735 4.11264 19.7235 3.75295 17.0235 3.03358Z",
      stroke: "currentColor",
      strokeWidth: "1.5",
    },
  ],
  [
    "path",
    {
      key: "1",
      d: "M16.8538 7.43306C16.8538 8.24714 16.1901 8.90709 15.3714 8.90709C14.5527 8.90709 13.889 8.24714 13.889 7.43306C13.889 6.61898 14.5527 5.95904 15.3714 5.95904C16.1901 5.95904 16.8538 6.61898 16.8538 7.43306Z",
      stroke: "currentColor",
      strokeWidth: "1.5",
    },
  ],
  [
    "path",
    {
      key: "2",
      d: "M12 20.9463L11.0477 21.2056C8.35403 21.9391 7.00722 22.3059 5.94619 21.6833C4.88517 21.0608 4.52429 19.6921 3.80253 16.9547L2.78182 13.0834C2.06006 10.346 1.69918 8.97731 2.31177 7.89904C2.84167 6.96631 4 7.00027 5.5 7.00015",
      stroke: "currentColor",
      strokeWidth: "1.5",
      strokeLinecap: "round",
    },
  ],
];

export const hugeLogout01: HugeIconData = [
  [
    "path",
    {
      key: "0",
      d: "M15.5 8.04045C15.4588 6.87972 15.3216 6.15451 14.8645 5.58671C14.2114 4.77536 13.0944 4.52064 10.8605 4.01121L9.85915 3.78286C6.4649 3.00882 4.76777 2.6218 3.63388 3.51317C2.5 4.40454 2.5 6.1257 2.5 9.56803V14.432C2.5 17.8743 2.5 19.5955 3.63388 20.4868C4.76777 21.3782 6.4649 20.9912 9.85915 20.2171L10.8605 19.9888C13.0944 19.4794 14.2114 19.2246 14.8645 18.4133C15.3216 17.8455 15.4588 17.1203 15.5 15.9595",
      stroke: "currentColor",
      strokeWidth: "1.5",
      strokeLinecap: "round",
      strokeLinejoin: "round",
    },
  ],
  [
    "path",
    {
      key: "1",
      d: "M18.5 9.01172C18.5 9.01172 21.5 11.2212 21.5 12.0117C21.5 12.8023 18.5 15.0117 18.5 15.0117M21 12.0117H8.49998",
      stroke: "currentColor",
      strokeWidth: "1.5",
      strokeLinecap: "round",
      strokeLinejoin: "round",
    },
  ],
];

export const hugeSun01: HugeIconData = [
  [
    "path",
    {
      key: "0",
      d: "M17 12C17 14.7614 14.7614 17 12 17C9.23858 17 7 14.7614 7 12C7 9.23858 9.23858 7 12 7C14.7614 7 17 9.23858 17 12Z",
      stroke: "currentColor",
      strokeWidth: "1.5",
    },
  ],
  [
    "path",
    {
      key: "1",
      d: "M11.9955 3H12.0045M11.9961 21H12.0051M18.3588 5.63599H18.3678M5.63409 18.364H5.64307M5.63409 5.63647H5.64307M18.3582 18.3645H18.3672M20.991 12.0006H21M3 12.0006H3.00898",
      stroke: "currentColor",
      strokeWidth: "2",
      strokeLinecap: "round",
      strokeLinejoin: "round",
    },
  ],
];

export const hugeMoon: HugeIconData = [
  [
    "path",
    {
      key: "0",
      d: "M22 12C22 17.5228 17.5228 22 12 22C6.47715 22 2 17.5228 2 12C2 6.47715 6.47715 2 12 2C17.5228 2 22 6.47715 22 12Z",
      stroke: "currentColor",
      strokeWidth: "1.5",
      strokeLinecap: "round",
    },
  ],
  [
    "path",
    {
      key: "1",
      d: "M12 22C15.3137 22 18 17.5228 18 12C18 6.47715 15.3137 2 12 2",
      stroke: "currentColor",
      strokeWidth: "1.5",
      strokeLinecap: "round",
    },
  ],
  [
    "path",
    {
      key: "2",
      d: "M10.9998 7H11.0088",
      stroke: "currentColor",
      strokeWidth: "2",
      strokeLinecap: "round",
      strokeLinejoin: "round",
    },
  ],
  [
    "path",
    {
      key: "3",
      d: "M10 14.5C10 15.3284 9.32843 16 8.5 16C7.67157 16 7 15.3284 7 14.5C7 13.6716 7.67157 13 8.5 13C9.32843 13 10 13.6716 10 14.5Z",
      stroke: "currentColor",
      strokeWidth: "1.5",
      strokeLinecap: "round",
    },
  ],
];
