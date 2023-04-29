const path = require('path');

const buildEslintCommand = (filenames) =>
    `yarn run lint --fix --file ${filenames
        .map((f) => path.relative(process.cwd(), f))
        .join(' --file ')}`;

const buildPrettierCommand = (filenames) =>
    `yarn prettier --write --ignore-unknown ${filenames.join(' ')}`;

module.exports = {
    'src/**/*.{js,jsx,ts,tsx}': [buildEslintCommand, buildPrettierCommand],
};
