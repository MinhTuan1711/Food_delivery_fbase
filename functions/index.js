/**
 * Firebase Cloud Functions entrypoint.
 * Re-export separated modules for clarity and maintainability.
 */
module.exports = {
  ...require("./notifications"),
  ...require("./payments"),
};
