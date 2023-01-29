---
title: typescript 对象中的类型约束
date: 2023-01-29 14:52:39
tags:
  - typescript
description: 如何将类型约束运用到对象中？
---


# 类型约束，无解释

```typescript
export enum MessageTypeEnum {
  TEXT = "text",
  IMG = "image",
  AUDIO = "audio",
  DELAY = "delay",
  INPUT = "input",
}

type MessageTypeDataMap = {
  [MessageTypeEnum.TEXT]: {
    text: string;
  };
  [MessageTypeEnum.IMG]: {
    uri: string;
  };
  [MessageTypeEnum.AUDIO]: {
    uri: string;
  };
  [MessageTypeEnum.DELAY]: {
    options: TimeOptionType;
  };
  [MessageTypeEnum.INPUT]: {
    text: any;
  };
};

type MessageType<T extends keyof MessageTypeDataMap, P> = {
  id: string;
  type: T;
  data: P;
};

export type SendMessageNodePayloadType = {
  messages: Array<
    {
      [K in keyof MessageTypeDataMap]: MessageType<K, MessageTypeDataMap[K]>;
    }[keyof MessageTypeDataMap]
  >;
};

//  测试
const a: NodeDataType<AutoMessage.NodeTypeEnum.SEND_MESSAGE> = {
  namespace: NodeNamespaceEnum.AUTO_MESSAGE,
  icon: "123",
  title: "123",
  type: AutoMessage.NodeTypeEnum.SEND_MESSAGE,
  payload: {
    messages: [
      {
        id: "123",
        type: MessageTypeEnum.IMG,
        data: {
          uri: "123",
        },
      },
    ],
  },
};
```
