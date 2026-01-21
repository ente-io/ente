const path = require("path");
const webpack = require("webpack");
const CopyPlugin = require("copy-webpack-plugin");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");

const browser = process.env.BROWSER || "chrome";
const isChrome = browser === "chrome";
const outputPath = path.resolve(__dirname, isChrome ? "dist-chrome" : "dist-firefox");

module.exports = {
    mode: process.env.NODE_ENV === "production" ? "production" : "development",
    devtool: process.env.NODE_ENV === "production" ? false : "inline-source-map",
    entry: {
        "background/index": "./src/background/index.ts",
        "content/index": "./src/content/index.tsx",
        "content/auth-capture": "./src/content/auth-capture.ts",
        "popup/index": "./src/popup/index.tsx",
        "options/index": "./src/options/index.tsx",
    },
    output: {
        path: outputPath,
        filename: "[name].js",
        clean: true,
    },
    module: {
        rules: [
            {
                test: /\.tsx?$/,
                use: "ts-loader",
                exclude: /node_modules/,
            },
            {
                test: /\.css$/,
                use: [MiniCssExtractPlugin.loader, "css-loader"],
            },
        ],
    },
    resolve: {
        extensions: [".tsx", ".ts", ".js"],
        alias: {
            "@shared": path.resolve(__dirname, "src/shared"),
        },
        fallback: {
            fs: false,
            path: false,
            crypto: false,
        },
    },
    plugins: [
        new MiniCssExtractPlugin({
            filename: "[name].css",
        }),
        new CopyPlugin({
            patterns: [
                {
                    from: isChrome
                        ? "manifests/chrome.manifest.json"
                        : "manifests/firefox.manifest.json",
                    to: "manifest.json",
                },
                {
                    from: "assets",
                    to: "assets",
                },
            ],
        }),
        new HtmlWebpackPlugin({
            template: "./src/popup/index.html",
            filename: "popup/index.html",
            chunks: ["popup/index"],
        }),
        new HtmlWebpackPlugin({
            template: "./src/options/index.html",
            filename: "options/index.html",
            chunks: ["options/index"],
        }),
    ],
    optimization: {
        splitChunks: false,
    },
};
