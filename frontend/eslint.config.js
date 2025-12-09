import js from '@eslint/js'
import pluginVue from 'eslint-plugin-vue'
import globals from 'globals'

export default [
  js.configs.recommended,
  ...pluginVue.configs['flat/essential'],
  {
    files: ['**/*.{js,vue}'],
    languageOptions: {
      globals: {
        ...globals.browser
      }
    },
    rules: {
      'no-unused-vars': 'warn',
      'vue/multi-word-component-names': 'off'
    }
  },
  {
    ignores: ['dist/**', 'node_modules/**']
  }
]
