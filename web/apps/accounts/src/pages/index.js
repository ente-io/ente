"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var react_1 = require("react");
var Page = function () {
    (0, react_1.useEffect)(function () {
        // There are no user navigable pages currently on accounts.ente.io.
        window.location.href = "https://web.ente.io";
    }, []);
    return <></>;
};
exports.default = Page;
