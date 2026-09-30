const js = require("@eslint/js");
const globals = require("globals");
const yml = require("eslint-plugin-yml");

module.exports = [
  {
    // _site/.jekyll-cache are build output; vendor/ is where CI vendors
    // gems (ruby/setup-ruby's bundler-cache) - none of it is our code.
    ignores: ["_site/**", ".jekyll-cache/**", "vendor/**"],
  },
  {
    files: ["assets/js/**/*.js"],
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "script",
      globals: {
        ...globals.browser,
      },
    },
    rules: js.configs.recommended.rules,
  },
  ...yml.configs["flat/standard"],
  {
    files: ["**/*.{yml,yaml}"],
    ignores: ["_site/**"],
  },
  {
    // A bare `pull_request:` (no value) is the standard GitHub Actions
    // syntax for "default event types", not a mistake.
    files: [".github/workflows/**/*.{yml,yaml}"],
    rules: {
      "yml/no-empty-mapping-value": "off",
    },
  },
];
