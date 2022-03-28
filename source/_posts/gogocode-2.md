---
title: gogocode AST 抽象语法树修改器使用例子 (二)
date: 2022-03-27 22:04:03
tags:
  - front-end
  - gogocode
categories:
  - Front End
description: 本文主要记录一些 gogocode 的使用例子和遇到的坑 (二)， 这次我们的场景是 Vuex 到 Pinia 的迁移
---

接着上一篇 [gogocode AST 抽象语法树修改器使用例子 (一)](/gogocode-1.html), 这次我们的场景是 Vuex 到 Pinia 的迁移

本文的最终目的是按照 [Pinia 官方的迁移步骤](https://pinia.vuejs.org/introduction.html#comparison-with-vuex-3-x-4-x) 进行将 `Vuex` 转换为 `pinia`

我们最终的目的是将下面的代码

```ts
//  vuex

const state: CounterState = {
  count: 0,
};

const getters = {
  getCount(state: CounterState) {
    return state.count;
  },
};

const mutations = {
  setCount(state: CounterState, payload: number) {
    state.count = payload;
  },
};

const actions = {
  changeCount(ctx: ActionContext<CounterState, any>) {
    ctx.commit("setCount", ctx.state.count + 1);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions,
};
```

转换为

```ts
//  pinia

const state: CounterState = {
  count: 0,
};

const getters = {
  getCount(state: CounterState) {
    return state.count;
  },
};

const actions = {
  setCount(payload: number) {
    this.count = payload;
  },
  changeCount() {
    this.setCount(this.count + 1);
  },
};

export const useCounterStore = defineStore("test", {
  state: (): LocaleState => state,
  getters,
  actions,
});
```

因为转换内容比较多，我们需要拆分成多个步骤进行转换（其实是因为我技术不行，无法一次达到）

实际操作过程并不是那么简单，因为代码规范不统一，不同的 store 经过不同的开发者编写，导致需要做很多兼容的地方

### 预处理部分

因为各个文件里面不一定能完全按照理想的代码转换，我们需要提前将代码进行预处理，以保证后续的代码能按预期的运行

我们同时需要将代码拆封下

```ts
let $source = $(source).root();
$source = preFormat($, $source).root();
$source.root().generate().root();

//  我们来实现下预处理
function preFormat($, $source) {
  return (
    $source
      //  将 {state:{...initState} 替换成 {state:initState}
      .replace(
        "export default {state:{...$_$1}, $$$}",
        `export default {state:$_$1, $$$}`
      )
      //  将 {getters:{}} 提出成 {getters}
      .replace(
        `export default {getters:{$$$},$$$1}`,
        `const getters = {$$$};\n
         export default {getters,$$$1}`
      )
      //  将 {mutations:{}} 提出成 {mutations}
      .replace(
        `export default {mutations:{$$$},$$$1}`,
        `const mutations = {$$$};\n
         export default {mutations,$$$1}`
      )
      //  将 {actions:{}} 提出成 {actions}
      .replace(
        `export default {actions:{$$$},$$$1}`,
        `const actions = {$$$};\n
         export default {actions,$$$1}`
      )
      //  将 { method:(state)=>{return state.name} } 和 { method: (state)=>state.name }
      //  替换成 {method(state){return state.name}}
      .find(`const $_$1 = { $$$ }`)
      .each((item) => {
        item.match["$$$$"].map((_item) => {
          if (_item.type === "ObjectProperty") {
            if (_item.value.type === "ArrowFunctionExpression") {
              let fnBody = $($(_item.value).attr("body")).generate().trim();
              fnBody = fnBody[0] !== "{" ? `{return ${fnBody}}` : fnBody;

              const fnArgs = $(_item.value)
                .attr("params")
                .map((arg) => {
                  return $(arg).generate();
                })
                .join(",");

              const fnName = _item.key.name;

              //  这里不知道为什么 `${fnName}: () => "$_$2"` 能匹配到 () => {}
              $(item.node).replace(`${fnName}: () => "$_$2"`, (match) => {
                if (match[2][0].value[0] === "{") {
                  return `${fnName}(${fnArgs}) $_$2`;
                } else {
                  return `${fnName}(${fnArgs}) {return $_$2}`;
                }
              });
            }
          }
        });
      })
  );
}
```

接着我们来转换下导出引用

```ts
let $source = $(source);
$source = preFormat($, $source).root();
$source = transformExport($, $source).root();
$source.root().generate().root();

function transformExport($, $source) {
  return $source.replace(
    `export default {$$$}`,
    `export const useTestStore = defineStore('test',{$$$})`
  );
}
```

我们首先将导出部分替换成 `defineStore('test',{$$$})` 这样再次使用 find 方法时就能准确的命中需要处理的导出内容

在使用 find 之后，我们在 each 方法中，准备调用才分好的转换方法

先看下转换后的效果

```ts
//  上方代码没变动
export const useTestStore = defineStore("test", {
  namespaced: true,
  state,
  getters,
  mutations,
  actions,
});
```

### 删除 namespaced，mutations 俩参数

```ts
let $source = $(source);
$source = preFormat($, $source).root();
$source = transformExport($, $source).root();
$source = deleteUnusedProp($, $source).root();
$source.root().generate();

function deleteUnusedProp($, $source) {
  return $source.find(`defineStore('test', $$$)`).each((item) => {
    //    删除 namespaced，mutations
    item.replace("mutations:$_$1", "");
    item.replace("namespaced:$_$1", "");
  });
}
```

### 转换 state 部分

```ts
let $source = $(source);
$source = preFormat($, $source).root();
$source = transformExport($, $source).root();
$source = deleteUnusedProp($, $source).root();
$source = transformState($, $source).root();
$source.root().generate();


function transformState($, $source) {
  return $source.find(`defineStore('test', $$$)`).each((item) => {
    item.match["$$$$"][0].properties.map((prop, index) => {
      const key = prop.key.name;
      const value = prop.value;

      //  找到 key 为 state 的进行转换
      if (key === "state") {
        //  转换下 state => state:() => state
        {
          //  找到 state 对应的变量
          let stateNameStr = $(value).generate();
          let stateName = stateNameStr.match(/^[\w_]+$/) ? stateNameStr : null;

          //  命中 state: () :CounterState => ({...initState}) 情况
          if (!!~stateNameStr.indexOf("...")) {
            stateName = stateNameStr.split("...")[1].split("}")[0].trim();
          }

          let type = null;
          //  这里如果是变量的话，我们来尝试获取下它的类型
          $source.find(`const $_$1 = $$$`).each((_item) => {
            if (_item.match[1][0].value === stateName) {
              let stateType = _item.attr(
                "declarations.0.id.typeAnnotation.typeAnnotation.typeName.name"
              );
              if (stateType) {
                type = stateType;
              }
            }
          });

          if (value.type === "Identifier") {
            $(item.match["$$$$"][0]).attr(
              `properties.${index}`,
              `${key}: () ${type ? `:${type}` : ""} => ${$(value).generate()}`
            );
          }

          //  判断 state 的类型为对象表达式
          //  命中这种情况 {state:{}}
          if (value.type === "ObjectExpression") {
            $(item.match["$$$$"][0]).attr(
              `properties.${index}`,
              `${key}: () ${type ? `:${type}` : ""} => (${$(value).generate()})`
            );
          }

          //  判断 state 的类型为 fucntin 或者 箭头函数
          //  命中这种情况 {state:function} | {state:()=>{}}
          if (
            value.type === "FunctionExpression" ||
            value.type === "ArrowFunctionExpression"
          ) {
            $(item.match["$$$$"][0]).attr(
              `properties.${index}`,
              `${key}: ${$(value).generate()}`
            );
          }
        }
      }
    });
  });
}
```

转换后的效果

> 没想到吧，转换个 state 既然那么复杂, 这里我们兼顾了代码中各种写法，
> state, state: initState, state:()=>state, state: function { return state }

```ts
export const useTestStore = defineStore("test", {
  state: (): CounterState => state,
  getters,
  actions,
});
```

### 转换 getters

#### 1 删除与 state 相同名称的 getter

> 删除任何以相同名称（例如 firstName: (state) => state.firstName）返回状态的 getter，这些不是必需的，因为您可以直接从商店实例访问任何状态

```ts
let $source = $(source);
$source = preFormat($, $source).root();
$source = transformExport($, $source).root();
$source = deleteUnusedProp($, $source).root();
$source = transformState($, $source).root();
$source = transformGetters($, $source).root();
$source.root().generate();

function transformGetters($, $source) {
  return $source.find(`defineStore('test', $$$)`).each((item) => {
    item.match["$$$$"][0].properties.map((prop, index) => {
      if (prop.key?.name === "getters") {
        //  转换 getters 与 state 相同的情况
        {
          const value = prop.value;
          let stateName = "";

          //  此时到这里， prop 中有个 state: () :CounterState => state 字符串
          //  获取 state 的变量定义名称
          let stateFnName = item.match["$$$$"][0].properties.find(
            (item) => typeof item === "string"
          );
          if (!!~stateFnName.indexOf("=>")) {
            stateName = stateFnName.split("=>")[1].trim();

            //  命中 state: () :CounterState => ({...initState}) 情况
            if (!!~stateName.indexOf("...")) {
              stateName = stateName.split("...")[1].split("}")[0].trim();
            }
          }

          if (stateName.length === 0)
            throw new Error("无法找到对应的 state 对象名称，gutters 转换失败");

          //  获取 state 的 keys
          let stateKeys = [];
          $source.find(`const $_$1 = {$$$}`).each((_item) => {
            if (_item.match[1][0].value === stateName) {
              _item.match["$$$$"].map((_) => {
                stateKeys.push(_.key.name);
              });
            }
          });

          const gettersName = prop?.value?.name;
          if (!gettersName)
            throw new Error(
              "无法找到对应的 gutters 对象名称，gutters 转换失败"
            );

          //  替换与 state 相同的 getter
          $source.find(`const $_$1 = {$$$}`).each((_item) => {
            if (_item.match[1][0].value === gettersName) {
              stateKeys.map((stateKey) => {
                _item.replace(`${stateKey}(){}`, (match) => {
                  console.log(
                    `检测到 getters.${stateKey} 与 state.${stateKey} 出现重复，执行删除`
                  );
                  return "";
                });
              });
            }
          });
        }
      }
    });
  });
}
```

### 转换 mutations 和 actions

```ts
let $source = $(source);
$source = preFormat($, $source).root();
$source = transformExport($, $source).root();
$source = deleteUnusedProp($, $source).root();
$source = transformState($, $source).root();
$source = transformGetters($, $source).root();
$source = transformActionsAndMutations($, $source).root();
$source.root().generate();

function transformActionsAndMutations($, $source) {
  //  将 mutations 里面的第一个参数 state 删除，然后将所有 state. 修改成 this.
  $source = transformMutations($, $source).root();

  //  将 actions 里面的第一个参数删除，并且所有 ctx 的调用都切换为 this
  $source = transformActions($, $source).root();

  //  将 mutations 和 actions 进行合并
  $source = transformMutationsIntoActions($, $source).root();

  return $source;
}

function transformActions($, $source) {
  return $source.find(`const actions = {$$$}`).each((item) => {
    item.match["$$$$"].map((method) => {
      //  如果 method.params.length === 0 代表着用户的 actions 什么也没接收
      // userLogout() {
      //   ApiLogout().then((res: any) => {
      //     if (res.status == 204) {
      //       // 1. 清除本地缓存的 Token
      //       // 2. 重定向到登录界面
      //       window.$cookies.remove("token");
      //       router.replace({ name: "login" });
      //     }
      //   });
      // },
      if (method.params.length === 0) {
        return;
      }

      const methodName = method.key.name;
      let firstParamName = method.params[0].name;
      //  这里如果是解构写法 {state,commit,dispatch} 的话，将 firstParamName 转换成一个数组
      if (!firstParamName && method.params[0].type === "ObjectPattern") {
        firstParamName = method.params[0].properties.map((_param) =>
          $(_param).generate()
        );
      }

      $(item.node).replace(`${methodName}($$$args){$$$body}`, (match) => {
        const paramsLength = match["$$$args"].length;
        const fnArgs = match["$$$args"]
          .map((arg) => {
            return $(arg).generate();
          })
          .slice(1)
          .join(",");

        if (paramsLength === 1) {
          return `${methodName}(){$$$body}`;
        } else {
          return `${methodName}(${fnArgs}){$$$body}`;
        }
      });

      //  替换 async
      $(item.node).replace(`async ${methodName}($$$args){$$$body}`, (match) => {
        const paramsLength = match["$$$args"].length;
        const fnArgs = match["$$$args"]
          .map((arg) => {
            return $(arg).generate();
          })
          .slice(1)
          .join(",");

        if (paramsLength === 1) {
          return `async ${methodName}(){$$$body}`;
        } else {
          return `async ${methodName}(${fnArgs}){$$$body}`;
        }
      });

      //  处理 firstParamName 为 string 的情况
      //  也就是 ctx
      if (typeof firstParamName === "string") {
        //  替换 ctx.state
        $(item.node).replace(`${firstParamName}.state.$_$1`, `this.$_$1`);

        //  替换
        // return actions.requestUserTasks(ctx, {
        //   type: 'favorite',
        //   page: payload.page,
        //   filterGroup: payload.group,
        // })
        $(item.node).replace(`actions.$_$1`, `this.$_$1`);
        $(item.node).replace(`this.$_$1(ctx, $$$)`, `this.$_$1($$$)`);

        //  替换 ctx.getters
        $(item.node).replace(`${firstParamName}.getters.$_$1`, `this.$_$1`);

        //  替换 const state = ctx.state;
        $(item.node).replace(`const state = ctx.state`, "");
        $(item.node).replace(`state.$_$1`, `this.$_$1`);

        //  替换 ctx.commit
        $(item.node).replace(`${firstParamName}.commit($$$)`, (match) => {
          let actionName = $(match["$$$$"][0])
            .generate()
            .match(/^"([\w_\/]+)"$/)[1];
          const leftParams = match["$$$$"]
            .map((arg) => {
              return $(arg).generate();
            })
            .slice(1)
            .join(",");

          if (!!~actionName.indexOf("/")) {
            console.log(
              "监测到使用本文件以外的 commit",
              actionName,
              "请搜索 __USE_STORE_COMMIT__ 关键字后，自己替换"
            );
            actionName = actionName.replace("/", "__USE_STORE_COMMIT__");
          }

          return `this.${actionName}(${leftParams})`;
        });

        //  替换 ctx.dispatch
        $(item.node).replace(`${firstParamName}.dispatch($$$)`, (match) => {
          let actionName = $(match["$$$$"][0])
            .generate()
            .match(/^"([\w_\/]+)"$/)[1];
          const leftParams = match["$$$$"]
            .map((arg) => {
              return $(arg).generate();
            })
            .slice(1)
            .join(",");

          if (!!~actionName.indexOf("/")) {
            console.log(
              "监测到使用本文件以外的 dispatch",
              actionName,
              "请搜索 __USE_STORE_DISPATCH__ 关键字后，自己替换"
            );
            actionName = actionName.replace("/", "__USE_STORE_DISPATCH__");
          }

          return `this.${actionName}(${leftParams})`;
        });

        //  替换 ctx.rootState
        $(item.node).replace(`${firstParamName}.rootState.$_$1`, (match) => {
          console.log(
            "监测到使用本文件以外的 rootstate",

            "请搜索 __USE_STORE_ROOT_STATE__ 关键字后，自己替换"
          );
          return `this.__USE_STORE_ROOT_STATE__.$_$1`;
        });

        //  替换 ctx.rootGetters
        $(item.node).replace(`${firstParamName}.rootGetters[$_$1]`, (match) => {
          console.log(
            "监测到使用本文件以外的 rootGetters",

            "请搜索 __USE_STORE_ROOT_GETTERS__ 关键字后，自己替换"
          );
          return `this.__USE_STORE_ROOT_GETTERS__[$_$1]`;
        });
      }

      //    处理 firstParamName 为数组的情况，也就是 {state,commit,dispatch}
      if (Array.isArray(firstParamName)) {
        //  替换 state
        $(item.node).replace(`state.$_$1`, `this.$_$1`);

        //  替换 getters
        $(item.node).replace(`getters.$_$1`, `this.$_$1`);

        //  替换 commit
        $(item.node).replace(`commit($$$)`, (match) => {
          let actionName = $(match["$$$$"][0])
            .generate()
            .match(/^"([\w_\/]+)"$/)[1];
          const leftParams = match["$$$$"]
            .map((arg) => {
              return $(arg).generate();
            })
            .slice(1)
            .join(",");

          if (!!~actionName.indexOf("/")) {
            console.log(
              "监测到使用本文件以外的 commit",
              actionName,
              "请搜索 __USE_STORE_COMMIT__ 关键字后，自己替换"
            );
            actionName = actionName.replace("/", "__USE_STORE_COMMIT__");
          }

          return `this.${actionName}(${leftParams})`;
        });

        //  替换 dispatch
        $(item.node).replace(`dispatch($$$)`, (match) => {
          let actionName = $(match["$$$$"][0])
            .generate()
            .match(/^"([\w_\/]+)"$/)[1];
          const leftParams = match["$$$$"]
            .map((arg) => {
              return $(arg).generate();
            })
            .slice(1)
            .join(",");

          if (!!~actionName.indexOf("/")) {
            console.log(
              "监测到使用本文件以外的 dispatch",
              actionName,
              "请搜索 __USE_STORE_DISPATCH__ 关键字后，自己替换"
            );
            actionName = actionName.replace("/", "__USE_STORE_DISPATCH__");
          }

          return `this.${actionName}(${leftParams})`;
        });

        //  替换 rootState
        $(item.node).replace(`rootState.$_$1`, (match) => {
          console.log(
            "监测到使用本文件以外的 rootstate",

            "请搜索 __USE_STORE_ROOT_STATE__ 关键字后，自己替换"
          );
          return `this.__USE_STORE_ROOT_STATE__.$_$1`;
        });

        //  替换 rootGetters
        $(item.node).replace(`rootGetters[$_$1]`, (match) => {
          console.log(
            "监测到使用本文件以外的 rootGetters",

            "请搜索 __USE_STORE_ROOT_GETTERS__ 关键字后，自己替换"
          );
          return `this.__USE_STORE_ROOT_GETTERS__[$_$1]`;
        });
      }
    });
  });
}

function transformMutations($, $source) {
  return $source.find(`const mutations = {$$$}`).each((item) => {
    item.match["$$$$"].map((method) => {
      const methodName = method.key.name;
      const firstParamName = method.params[0].name;

      //  删除第一个参数
      $(item.node).replace(`${methodName}($$$args){$$$body}`, (match) => {
        const paramsLength = match["$$$args"].length;
        const fnArgs = match["$$$args"]
          .map((arg) => {
            return $(arg).generate();
          })
          .slice(1)
          .join(",");

        if (paramsLength === 1) {
          return `${methodName}(){$$$body}`;
        } else {
          return `${methodName}(${fnArgs}){$$$body}`;
        }
      });

      $(item.node)
        .find(`${firstParamName}.$_$1`)
        .each((_item) => {
          _item.replaceBy(`this.${_item.match[1][0].value}`);
        });

      //  替换
      //  mutations.addSubTasks(state, [new TaskModel(task.data)])
      $(item.node).replace(`mutations.$_$1(state,$$$)`, `this.$_$1($$$)`);
    });
  });
}

function transformMutationsIntoActions($, $source) {
  return $source
    .find(`const mutations = {$$$}`)
    .each((item) => {
      item.match["$$$$"].map((method) => {
        $source.find(`const actions = {}`).each((_item) => {
          $(_item.attr("declarations.0.init")).prepend("properties", method);
        });
      });
    })
    .replace("const mutations = {}", "");
}
```

### 添加下引用文件和导出方法

```ts
//  顶部导入这两个文件
import { defineStore } from "pinia";
import { store } from "/@/store";

//  底部导出这个方法
export function useTestStoreWithOut() {
  return useTestStore(store);
}
```

```ts
let $source = $(source);
$source = preFormat($, $source).root();
$source = transformExport($, $source).root();
$source = deleteUnusedProp($, $source).root();
$source = transformState($, $source).root();
$source = transformGetters($, $source).root();
$source = transformActionsAndMutations($, $source).root();
$source = importAndExport($, $source).root();
$source.root().generate();

function importAndExport($, $source) {
  return $source
    .before(
      `import { defineStore } from "pinia";
       import { store } from "/@/store";`
    )
    .after(
      `\n\n export function useTestStoreWithOut() {
        return useTestStore(store);
      }`
    );
}
```

### 修修补补

代码可能会出现这种情况, 我们希望它能够按照 `state`, `getters`, `actions` 这样进行排序

```ts
export const useTestStore = defineStore("test", {
  actions,
  getters,
  state: (): State => state,
});
```

让我们再来写个转换

```ts
let $source = $(source);
$source = preFormat($, $source).root();
$source = transformExport($, $source).root();
$source = deleteUnusedProp($, $source).root();
$source = transformState($, $source).root();
$source = transformGetters($, $source).root();
$source = transformActionsAndMutations($, $source).root();
$source = importAndExport($, $source).root();
$source = sortStoreParamsName($, $source).root();
$source.root().generate();

function sortStoreParamsName($, $source) {
  let sortedCode = "";

  $source.find(`defineStore('test', {$$$})`).each((item) => {
    let match = item.match;
    let newArr = [];
    let sortArr = ["state", "getters", "actions"];

    match["$$$$"].map((param) => {
      if (typeof param === "string") {
        newArr.push({
          key: "state",
          value: param,
        });
        return;
      }

      if (param.type === "ObjectProperty") {
        newArr.push({
          key: param.key.name,
          value: $(param).generate(),
        });
        return;
      }

      newArr.push({
        key: "unknown",
        value: $(param).generate(),
      });
    });

    newArr.sort((left, right) => {
      let letIndex = sortArr.includes(left.key)
        ? sortArr.indexOf(left.key)
        : 999;
      let rightIndex = sortArr.includes(right.key)
        ? sortArr.indexOf(right.key)
        : 999;
      return letIndex - rightIndex;
    });

    sortedCode = `defineStore('test', {${newArr
      .map((arg) => arg.value)
      .join(",")}})`;
  });

  if (sortedCode.length > 0) {
    $source.replace(`defineStore('test', {})`, sortedCode);
  }

  return $source;
}
```
