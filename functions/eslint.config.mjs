import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  {
    ignores: ['lib/**', 'node_modules/**', 'eslint.config.mjs'],
  },
  {
    files: ['**/*.ts'],
    extends: [eslint.configs.recommended, ...tseslint.configs.recommended],
    languageOptions: { parserOptions: { project: './tsconfig.json' } },
    rules: {
      '@typescript-eslint/explicit-function-return-type': 'error',
    },
  },
);
