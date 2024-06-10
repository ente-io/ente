import React from "react";
import "../App.css";
interface SidebarProps {
    onOptionSelect: (option: string) => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ onOptionSelect }) => {
    return (
        <div className="sidebar">
            <ul>
                <li onClick={() => onOptionSelect("Disable2FA")}>Disable2FA</li>
                <li onClick={() => onOptionSelect("Closefamily")}>
                    Closefamily
                </li>
                <li onClick={() => onOptionSelect("Passkeys")}>
                    DisablePasskeys
                </li>
            </ul>
        </div>
    );
};
