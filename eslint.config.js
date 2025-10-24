import js from '@eslint/js';
import security from 'eslint-plugin-security';

export default [
  js.configs.recommended,
  {
    files: ['**/*.js'],
    plugins: {
      security
    },
    rules: {
      'security/detect-object-injection': 'error',
      'no-unused-vars': 'warn',
      'camelcase': 'warn',
      'quotes': ['error', 'single'],
      'object-curly-spacing': ['error', 'never']
    }
  }
];
