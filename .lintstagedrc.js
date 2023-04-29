const path = require('path');

const buildEslintCommand = (filenames) =>
    `yarn lint --fix --file ${filenames
        .map((f) => path.relative(process.cwd(), f))
        .join(' --file ')} --`;

const buildPrettierCommand = (filenames) =>
    `yarn prettier --write --ignore-unknown ${filenames.join(' ')}`;

module.exports = {
    'apps/**/*.{js,jsx,ts,tsx}': [buildEslintCommand, buildPrettierCommand],
    'packages/**/*.{js,jsx,ts,tsx}': [buildEslintCommand, buildPrettierCommand],
    '**/*.{json,css,scss,md,html,yml,yaml}': [buildPrettierCommand],
};
