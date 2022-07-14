---
title: Antd Vue Form 组件显示后端接口的错误信息
date: 2022-07-14 13:19:00
tags:
  - antd
description: 在日常开发中，表单填写不仅仅要显示前端未通过的反馈信息，后端接口未通过的地方也需要提示出来，但是官方没有直接的接口支持。
---

# 场景

我们提交表单，但是后端未通过并且返回报错信息，我们如何将下面的信息显示在表单上呢？

```json
{
  "error": {
    "email": ["邮箱已经存在"],
    "password": ["密码过于简单"]
  }
}
```

# 解决方法

我们需要使用到 [Form.Item](https://antdv.com/components/form#Form-Item) 中的 `help` 和 `validateStatus` 俩接口来实现信息显示

> `help` 提示信息
>
> `validateStatus` 校验状态

我们来写个 hook

```ts
//  useFormFeedback.ts

/**
 * 处理 form 提交到后端后，后端返回的错误信息显示在 formItem 上
 * @example
 * <AFormItem name="email" v-bind="getFeedbackBind('email')" />
 *
 * scripts
 * const { setFeedback, getFeedbackBind, resetFeedback} = useFormFeedback()
 *
 * 请求 api 报错后
 * setFeedback(res.errors)
 */
import { ref, unref } from "vue";

type ReturnType = {
  setFeedback(feedbacks: Record<string, string[]>): void;
  getFeedbackBind(fieldName: string): Object;
  resetFeedback(): void;
};
export function useFormFeedback(): ReturnType {
  const feedbacks = ref({});

  function setFeedback(feedbacksData: Record<string, string[]>) {
    feedbacks.value = feedbacksData;
  }

  function getFeedbackBind(fieldName: string) {
    const fieldFeedback = unref(feedbacks)[fieldName];
    if (fieldFeedback && fieldFeedback.length > 0) {
      return {
        help: fieldFeedback[0],
        "validate-status": "error",
      };
    }

    return {};
  }

  function resetFeedback() {
    feedbacks.value = [];
  }

  return {
    setFeedback,
    getFeedbackBind,
    resetFeedback,
  };
}
```

# 使用

我们来看下如何使用

```vue
<AForm ref="formRef" :model="formState">
<AFormItem
    name="email"
    :rules="[{ required: true, message: '请输入邮箱' }]"
    v-bind="getFeedbackBind('email')"
>
    <AInput
        v-model:value="formState.email"
    />
</AFormItem>
</AForm>

<script lang="ts" setup>
const { setFeedback, getFeedbackBind, resetFeedback } = useFormFeedback();

ApiRequest()
  .then(() => {
    //  清空 feedback 信息
    resetFeedback()
  })
  .catch((err) => {
    //  设置 error 信息
    setFeedback(err.data.errors);
  });
</script>
```
