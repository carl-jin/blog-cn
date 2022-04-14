---
title: gogocode AST 抽象语法树修改器使用例子 (五)
date: 2022-04-14 15:04:03
tags:
  - front-end
  - gogocode 
categories:
  - Front End 
description: 本文主要记录一些 gogocode 的使用例子和遇到的坑 (五)， 这次我们的场景是对 eslint-plugin-vue 包无法自动修复 cmp 中 options api 自动排序的问题
---

接着上一篇 [gogocode AST 抽象语法树修改器使用例子 (四)](/gogocode-4.html)

# 背景

由于项目中大量使用了 vue 的 options api，并且由不同的开发者维护，导致 options api 的顺序非常混乱。

具体请查看 [#1841](https://github.com/vuejs/eslint-plugin-vue/issues/1841)

# 解决方案

我们使用 gogocode 来转换下 options api 的排序

```typescript
function transform(fileInfo, api, options) {
  const $ = api.gogocode
  const source = fileInfo.source
  const ast = $(source, {
    parseOptions: { language: 'vue', sourceType: 'module' },
  })
  const script = ast.find('<script></script>')
  script
    .replace('export default defineComponent({$$$})', (match) => {
      match['$$$$'].sort((left, right) => {
        const orders = propsOrder()
        let leftName = left.key.name
        let rightName = right.key.name
        let leftIndex = orders.indexOf(leftName)
        let rightIndex = orders.indexOf(rightName)

        return leftIndex - rightIndex
      })

      let propsCode = match['$$$$'].map((prop) => $(prop).generate())

      return `export default defineComponent({${propsCode.join(
        ','
      )}})`
    })
    .generate()
  // return your transformed code here
  return ast.generate()
}

function propsOrder() {
  //  https://github.com/vuejs/eslint-plugin-vue/blob/124cc371645dbb56a80ddcbc8bf37af6efccd044/lib/rules/order-in-components.js#L14
  return [
    // Side Effects (triggers effects outside the component)
    'el',

    // Global Awareness (requires knowledge beyond the component)
    'name',
    'key', // for Nuxt
    'parent',

    // Component Type (changes the type of the component)
    'functional',

    // Template Modifiers (changes the way templates are compiled)
    ['delimiters', 'comments'],

    // Template Dependencies (assets used in the template)
    ['components', 'directives', 'filters'],

    // Composition (merges properties into the options)
    'extends',
    'mixins',
    ['provide', 'inject'], // for Vue.js 2.2.0+

    // Page Options (component rendered as a router page)
    'ROUTER_GUARDS', // for Vue Router
    'layout', // for Nuxt
    'middleware', // for Nuxt
    'validate', // for Nuxt
    'scrollToTop', // for Nuxt
    'transition', // for Nuxt
    'loading', // for Nuxt

    // Interface (the interface to the component)
    'inheritAttrs',
    'model',
    ['props', 'propsData'],
    'emits', // for Vue.js 3.x

    // Note:
    // The `setup` option is included in the "Composition" category,
    // but the behavior of the `setup` option requires the definition of "Interface",
    // so we prefer to put the `setup` option after the "Interface".
    'setup', // for Vue 3.x

    // Local State (local reactive properties)
    'asyncData', // for Nuxt
    'data',
    'fetch', // for Nuxt
    'head', // for Nuxt
    'computed',

    // Events (callbacks triggered by reactive events)
    'watch',
    'watchQuery', // for Nuxt
    [
      'beforeCreate',
      'created',
      'beforeMount',
      'mounted',
      'beforeUpdate',
      'updated',
      'activated',
      'deactivated',
      'beforeUnmount', // for Vue.js 3.x
      'unmounted', // for Vue.js 3.x
      'beforeDestroy',
      'destroyed',
      'renderTracked', // for Vue.js 3.x
      'renderTriggered', // for Vue.js 3.x
      'errorCaptured', // for Vue.js 2.5.0+
    ],

    // Non-Reactive Properties (instance properties independent of the reactivity system)
    'methods',

    // Rendering (the declarative description of the component output)
    ['template', 'render'],
    'renderError',
  ].flat()
}
```
