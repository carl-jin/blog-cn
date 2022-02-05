---
title: Typescript 在 Event 对象上的实践 
date: 2022-02-05 12:47:04 
tags:
  - Typescript 
categories:
  - Front End 
description: 如何使用 Typescript 实现一个订阅者模式？
---

> 本文假设你已经有了 typescript 的基础知识

# 需求

我们想要实现一个最简单的订阅者模式，其中在 dispatch 和 subscribe 方法调用时，希望传入的参数都有 types 验证。

先来看个 js 实现的例子（非常简单）

```javascript
//  javascript 代码
class Subscribe {
  private eventList = {}

  public subscribe(eventName, handler) {
    if (this.eventList[eventName]) {
      this.eventList[eventName].push(handler)
    } else {
      this.eventList[eventName] = [handler]
    }
  }

  public unSubscribe(eventName, handler) {
    if (this.eventList[eventName]) {
      let index = this.eventList[eventName].indexOf(handler)
      if (~index) {
        this.eventList[eventName].splice(index, 1)
      }
    }
  }

  public dispatch(eventName, ...payload) {
    if (this.eventList[eventName]) {
      for (let i = 0; i < this.eventList[eventName].length; i++) {
        this.eventList[eventName][i].call(null, payload)
      }
    }
  }
}
```

我们来看下调用的例子

```javascript
class App extends Subscribe {
  constructor() {
    this.bindEvent();
  }

  bindEvent() {
    this.subscribe("loaded", (time) => {
      console.log(time, "loaded");
    });

    this.subscribe("destroy", (isSkip) => {
      if (isSkip) {
        console.log(isSkip);
      }
    });

    document.body.addEventListener("resize", () => {
      this.dispatch("resize", Date.now());
    });
  }
}
```

从调用的代码中我们可以看到这个 `App` 实例中，会监听 `loaded` 与 `destroy` 方法，

并且这两个方法对应使用的 dispatch 应该是这样的

```javascript
this.dispatch("loaded", Date.now());
this.dispatch("destroy", true);
```

在 `App` 实例中当触发 `resize` 事件时还会 dispatch `resize` 传递的参数是 `Date.now()`

那么我们就可以知道订阅 `resize` 这个方法的处理函数一定是长这样的

```javascript
this.subscribe("resize", (time) => {
  todo();
});
```

就如开头提到的，这是一个非常简单的例子，但是实际到我们项目中时，当需要订阅的事件逐渐增多，再加上需要暴露接口给外部，

那么就很容易出现参数填错或者事件名写错的问题。

比如这个例子中，如果仅仅是看文档的话就很墨迹，而且也不能保证代码书写的正确。

```javascript
//  你是怎么知道有 loaded 这个事件？ 为何它又传递了一个 number？
this.subscribe("loaded", this.handleLoaded);
//  你是怎么知道有 destroy 这个事件？ 为何它又传递了一个 bool？
this.subscribe("destroy", this.handleDestroy);
```

因此我们来思考下 🤔， 如果我们使用 typescript 来验证调用 `dispatch` 和 `subscribe` 的参数，这将再好不过了 👍

让我们看看下面通过 typescript 改写调用后的例子。

```typescript
//  typescript
declare type AppEvent = {
  loaded: (time: number) => void;
  destroy: (isSkip: boolean) => void;
  resize: (time: number) => void;
  foo: (bar: string) => string;
};

class App extends Subscribe<AppEvent> {
  constructor() {
    this.bindEvent();
  }

  bindEvent() {
    //
    this.subscribe("foo", (bar: string) => {
      //  type error 未返回 AppEvent 中 foo 类型的闭包形式，缺少返回值 string
    });

    //  type errpr “bar” 不适应 AppEvent 这个类型
    //  原因是我们未在 AppEvent 中定义 bar
    this.subscribe("bar", (isSkip, tiem) => {});

    this.subscribe("loaded", () => {
      //  正常执行
    });

    this.subscribe("destroy", (isSkip, tiem) => {
      //  type error，destory 对应的闭包中，缺少参数 time
    });

    document.body.addEventListener("resize", () => {
      //  type error, 缺少参数 time:number
      this.dispatch("resize");

      //  正常工作
      this.dispatch("resize", Date.new());
    });
  }
}
```

要是能这样调用，那真是太棒了 👍

# 💪 实现

让我们通过 typescript 来实现这个订阅者模式.

下面是实现的所有代码，如果你理解能力非常好的话 👌，可以跳过后面的解释。

```typescript
declare type EventObj<T> = {
  [K in keyof T]: (...args: any) => void;
};
 
class Subscribe<T extends EventObj<T>> {
  private eventList: Partial<Record<keyof T, Array<T[keyof T]>>> = {};

  public subscribe<K extends keyof T>(eventName: K, handler: T[K]) {
    if (this.eventList[eventName]) {
      this.eventList[eventName].push(handler);
    } else {
      this.eventList[eventName] = [handler];
    }
  }

  public unSubscribe<K extends keyof T>(eventName: K, handler: T[K]) {
    if (this.eventList[eventName]) {
      let index = this.eventList[eventName].indexOf(handler);
      if (~index) {
        this.eventList[eventName].splice(index, 1);
      }
    }
  }

  public dispatch<K extends keyof T>(
    eventName: K,
    ...payload: Parameters<T[K]>
  ) {
    if (this.eventList[eventName]) {
      for (let i = 0; i < this.eventList[eventName].length; i++) {
        this.eventList[eventName][i].call(null, payload);
      }
    }
  }
}
```

## 下面我们来一步步分解代码

### 泛型 T 的类型约束

```typescript
declare type EventObj<T> = {
  [K in keyof T]: (...args: any) => void;
};

class Subscribe<T extends EventObj<T>> {
  //  ...
}
```

这里我们针对传入的泛型 `T` 使用了 EventObj 来进行约束，因为我们需要保证，在传递泛型 T 的时候，必须是一个 EventObj 类型的对象

比如下面这样

```typescript
declare type AppEvent = {
  loaded: (time: number) => void;
  destroy: (isSkip: boolean) => void;
  resize: (time: number) => void;
  foo: (bar: string) => string;
};

class App extends Subscribe<AppEvent> {}
```

而不是像下面这样 😂

```typescript
declare type AppEvent = void | null;

class App extends Subscribe<AppEvent> {}
```

所以必须通过 EventObj 进行类型约束

### eventList 的定义

根据我们传入的泛型 T，我们希望 eventList 是长这样的

```typescript
class Subscribe {
  private eventList: eventList = {
    loaded: [(time: number) => {}, (time: number) => {}],
    destroy: [(isSkip: boolean) => {}, (time: boolean) => {}],
  };
}
```

因此我们对其这样定义

```typescript
class Subscribe {
  private eventList: Partial<Record<keyof T, Array<T[keyof T]>>> = {};
}
```

让我们从内往外进行拆解，

首先 Record 类型的第一个泛型为 `keyof T` 这意味着 key 的值只能是传入进来的泛型 T（AppEvent）中的 key，

也就是 `loaded` | `destroy` | `resize` | `foo`

然后它对应的 value 应该是一个 handler 的数组，因此我们定义为 `Array<T[keyof T]>`

接着我们使用 `Partial` 类型来让整个 eventList 中的 key 变成可选的，

因为我们可能只监听了 loaded 或者 destroy，所以整体的 key 都需要变成可选的。

### subscribe 方法定义

```typescript
class Subscribe {
  public subscribe<K extends keyof T>(eventName: K, handler: T[K]) {}
}
```

当用户使用 `this.subscribe` 方法时，我们希望他传入的 eventName 必须是来自于泛型 T（AppEvent）中的 key。

也就是只能为 `loaded` | `destroy` | `resize` | `foo`

所以我们这里用了一个泛型 K 来表示当前用户传入的 eventName，并且将其约束为 `keyof T`，

那么对应的 handler 也就理所应当的为 `T[K]` 了，

注意这里的 T 指的是 `AppEvent` 因此 `T[K]` 就相当于 `AppEvent[loaded]` （假设传入的 eventName 为 `loaded`）

### dispatch 方法定义

```typescript
class Subscribe<T> {
  public dispatch<K extends keyof T>(
    eventName: K,
    ...payload: Parameters<T[K]>
  ) {
    if (this.eventList[eventName]) {
      for (let i = 0; i < this.eventList[eventName].length; i++) {
        this.eventList[eventName][i].call(null, payload);
      }
    }
  }
}
```

这里主要的问题是在用户传入的参数，也就是 handler 回调接收的参数。

首先我们使用 `Parameters` 这个工具类型，来获取 `T[K]` 的参数，比如说 `AppEvent[loaded]` 的参数就是 `[time:number]`

也就是意味着，如果用户这样调用时,参数必须是 `[time:number]`

```typescript
this.dispatch("loaded", [Date.new()]);
```

这个 `Parameters` 这个工具类型就是用来获取 function 的参数的，他会把传入的 `Parameters<Fn>` 中 `Fn` 接受的参数变成一个

元组返回（当然 javascirpt 里面元组就是 [ ] 了）

因此我们这里用 `...` 语法将这个元组进行了解构。

# 总结

到这里我们就解决了需求，这里主要用到的知识点就是以下三个
`keyof` , `extends (类型约束)` 和 `Parameters` 如果你还不是太理解的话，

建议先看官方文档对这三个知识点熟悉后再回来阅读，一定会恍然大悟的 😳
