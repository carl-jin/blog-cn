---
title: 如何根据 JSON Schema 自动填充数据？
date: 2023-03-10 09:41:51
description: 平常开发项目时常常会遇到在数据库中新增字段，每次的新增字段都要额外兼容之前的老数据，这样很麻烦，让我来看看如何解决
---

平常开发项目时常常会遇到在数据库中新增字段，每次的新增字段都要额外兼容之前的老数据，这样很麻烦

比如我们有一个 getUserInfo 的方法, 并且这次版本中新增加了一个 rule 字段，来表示用户的权限

```typescript
function getUserInfo(userId): UserInfo {
  return users[userId];
}
```

首先我们会修改 UserInfo 这个类型

```typescript
type UserInfo = {
  name: string;
  //  新增加的 rule
  rule: "admin" | "normal";
};
```

然后在代码里面写兼容

```typescript
const userInfo = getUserInfo(1);

//  假设这样写，会报错，因为老数据中的 rule 是 undefind
userInfo.rule.indexOf("admin");

//  因此必须写兼容
if (userInfo.rule) {
  userInfo.rule.indexOf("admin");
}
```

这时候就很烦人了，明明 `getUserInfo` 返回的 `UserInfo` 中有 rule，为什么还要再判断一遍？

# 场景

假如我们有一个这样的 JSON Schema,

```typescript
const Schema = {
  type: "object",
  properties: {
    rule: {
      type: "string",
      default: "admin",
    },
    name: {
      type: "string",
    },
  },
  required: ["rule", "name"],
};
```

我们希望能根据这个 Schema 的描述自动补齐数据

比如传入是 `{}` 时返回 {name:"carl",rule:"admin"}, 传入 `{name:"carl"}` 时返回的也是 {name:"carl",rule:"admin"}

这样只需要在每次版本变更时执行以下该方法就能保证数据是按照我们理想情况返回的

# 解决方案

# ajv 是最快的方案

> chrome extension background 中无法使用，因为 ajv 的 schema 需要通过 eval 生成

```typescript
import Ajv from "ajv";
const ajv = new Ajv({ usedefaults: true });

const Schema = {
  type: "object",
  properties: {
    rule: {
      type: "string",
      default: "admin",
    },
    name: {
      type: "string",
    },
  },
  required: ["rule", "name"],
};

const validate = ajv.compile(schema);
console.log(validate({}));

//  log: {name:"carl",rule:"admin"}
```

## 造轮子

由于 ajv 的解决方案无法在某些不支持 eval 的环境运行，并且只是用到了 ajv 的一小部分功能，引用整个包确实不太理想，因此我们写个轮子

```typescript
import type { JSONSchemaType } from "ajv";

function forOwn(object, callback) {
  Object.keys(object).map((key) => callback(object[key], key, object));
}

export function JSONSchemaAutoFill<SchemaType>(
  data: Partial<SchemaType>,
  schema: JSONSchemaType<SchemaType>
): SchemaType {
  function processNode(schemaNode, dataNode) {
    switch (schemaNode.type) {
      case "object":
        return processObject(schemaNode, dataNode); // eslint-disable-line no-use-before-define

      case "array":
        return processArray(schemaNode, dataNode); // eslint-disable-line no-use-before-define

      default:
        if (dataNode !== undefined) return dataNode;
        if (schemaNode.default !== undefined) return schemaNode.default;
        return undefined;
    }
  }

  function processObject(schemaNode, dataNode) {
    const result = {};
    const props = schemaNode.properties ?? {};

    forOwn(props, (propertySchema, propertyName) => {
      if (
        schemaNode.required.includes(propertyName) ||
        (dataNode !== undefined && dataNode[propertyName] !== undefined)
      ) {
        let nodeValue =
          dataNode !== undefined ? dataNode[propertyName] : undefined;

        if (
          !propertySchema.properties &&
          propertySchema.default &&
          propertySchema.type === "object" &&
          propertySchema.additionalProperties
        ) {
          nodeValue = propertySchema.default;
        }

        result[propertyName] = processNode(propertySchema, nodeValue);
      }
    });

    if (dataNode) {
      forOwn(dataNode, (propertyValue, propertyName) => {
        if (result[propertyName] === undefined && propertyValue !== undefined) {
          result[propertyName] = propertyValue;
        }
      });
    }

    return result;
  }

  function processArray(schemaNode, dataNode) {
    if (dataNode === undefined) {
      if (schemaNode.default) {
        return schemaNode.default;
      }

      return undefined;
    }

    const result = [];

    for (let i = 0; i < dataNode.length; i++) {
      //  @ts-ignore
      result.push(processNode(schemaNode.items, dataNode[i]));
    }
    return result;
  }

  return processNode(schema, data);
}
```

```typescript
const Schema = {
  type: "object",
  properties: {
    rule: {
      type: "string",
      default: "admin",
    },
    name: {
      type: "string",
    },
  },
  required: ["rule", "name"],
};

console.log(JSONSchemaAutoFill({}, Schema));

//  log: {name:"carl",rule:"admin"}
```
