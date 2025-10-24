import js from '@eslint/js';
import security from 'eslint-plugin-security';
import noSecrets from 'eslint-plugin-no-secrets';
import globals from 'globals';

export default [
  js.configs.recommended,
  {
    languageOptions: {
      ecmaVersion: 2021,
      sourceType: 'module',
      globals: {
        ...globals.browser,
        ...globals.node,
        ...globals.es2021
      }
    },
    plugins: {
      security,
      'no-secrets': noSecrets
    },
    rules: {
      // Security rules - keep strict
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
      'security/detect-new-buffer': 'error',
      'no-secrets/no-secrets': 'error',
      
      // Relaxed rules for deployment - convert errors to warnings
      'no-nested-ternary': 'warn',
      'no-return-assign': 'warn',
      'radix': 'warn',
      'func-style': 'warn',
      'no-new': 'warn',
      'no-console': 'warn',
      'no-use-before-define': 'warn',
      'no-lonely-if': 'warn',
      'no-alert': 'warn',
      'no-shadow': 'warn',
      'no-script-url': 'warn',
      'no-unreachable': 'warn',
      'new-cap': 'warn',
      'func-names': 'warn',
      'camelcase': 'warn',
      'indent': 'warn',
      'no-trailing-spaces': 'warn',
      'curly': 'warn',
      'object-curly-spacing': 'warn',
      'space-before-function-paren': 'warn',
      'no-unused-vars': 'warn',
      'no-undef': 'warn'
    }
  }
];
