# 前端开发规范

## 组件开发规范

### 命名规范
- 组件文件名：PascalCase（如：UserList.vue / UserList.tsx）
- 组件内变量：camelCase
- 常量：UPPER_SNAKE_CASE

### 组件结构（Vue 3 Composition API）
```vue
<template>
  <!-- 模板内容 -->
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'

// 响应式数据
const list = ref([])

// 计算属性
const total = computed(() => list.value.length)

// 方法
function handleSearch() {}
</script>

<style scoped>
/* 样式 */
</style>
```

### 组件结构（React Hooks）
```tsx
import { useState, useEffect, useMemo } from 'react'

export default function UserList() {
  const [list, setList] = useState([])

  useEffect(() => {}, [])

  return <div>...</div>
}
```

## 状态管理规范

### Vue（Pinia）
```typescript
// stores/user.ts
export const useUserStore = defineStore('user', () => {
  const userInfo = ref(null)
  function setUser(info) { userInfo.value = info }
  return { userInfo, setUser }
})
```

### React（Zustand / Redux Toolkit）
```typescript
// stores/userSlice.ts
const useUserStore = create((set) => ({
  userInfo: null,
  setUser: (info) => set({ userInfo: info }),
}))
```

## API 调用规范

```typescript
// api/user.ts
import request from '@/utils/request'

export const getUserList = (params: object) => {
  return request({ url: '/api/users', method: 'get', params })
}
```

- API 调用统一走 `api/` 目录模块，不直接写 fetch/axios
- 必须处理 loading / error / empty 三种状态

## 代码检查工具

- ESLint + Prettier：代码质量和格式化
- TypeScript：类型安全

---

**最后更新:** 2026-06-01
