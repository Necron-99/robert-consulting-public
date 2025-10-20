module.exports = {
  env: {
    browser: true,
    node: true,
    es2021: true
  },
  extends: [
    'eslint:recommended',
    'plugin:security/recommended'
  ],
  plugins: [
    'security',
    'no-secrets'
  ],
  rules: {
    'security/detect-object-injection': 'error',
    'security/detect-non-literal-regexp': 'error',
    'security/detect-unsafe-regex': 'error',
    'security/detect-buffer-noassert': 'error',
    'security/detect-child-process': 'error',
    'security/detect-disable-mustache-escape': 'error',
    'security/detect-eval-with-expression': 'error',
    'security/detect-no-csrf-before-method-override': 'error',
    'security/detect-non-literal-fs-filename': 'error',
    'security/detect-non-literal-require': 'error',
    'security/detect-possible-timing-attacks': 'error',
    'security/detect-pseudoRandomBytes': 'error',
    'no-secrets/no-secrets': 'error',
    'no-console': 'off',
    indent: 'off',
    'no-trailing-spaces': 'off',
    'linebreak-style': 'off',
    'no-new': 'off',
    'operator-linebreak': 'off',
    curly: 'off',
    'no-use-before-define': 'off',
    'prefer-arrow-callback': 'off'
  }
};
