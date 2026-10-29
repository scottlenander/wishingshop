// ESLint flat config for the Playwright suite.
// typescript-eslint uses the local TypeScript (6.0) from node_modules.
import js from '@eslint/js'
import prettier from 'eslint-config-prettier'
import globals from 'globals'
import tseslint from 'typescript-eslint'

export default tseslint.config(
  {
    ignores: [
      'node_modules/',
      'test-results/',
      'playwright-report/',
      'blob-report/',
      'playwright/.cache/',
    ],
  },
  js.configs.recommended,
  ...tseslint.configs.recommendedTypeChecked,
  {
    languageOptions: {
      globals: globals.node,
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      // Forgotten awaits on Playwright calls are the most common e2e bug.
      '@typescript-eslint/no-floating-promises': 'error',
    },
  },
  {
    // This file is plain JS, so skip the type-aware rules.
    files: ['**/*.mjs'],
    ...tseslint.configs.disableTypeChecked,
  },
  // Last: turn off rules that conflict with Prettier's formatting.
  prettier,
)
