import React from "react";

export const Container: React.FC<React.PropsWithChildren> = ({ children }) => (
    <div className="container">{children}</div>
);
