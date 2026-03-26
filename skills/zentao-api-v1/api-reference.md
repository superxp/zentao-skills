# 禅道 API v1.0 接口参考文档

## 基础信息

- **Base URL**: `{zentao_url}/api.php/v1`
- **认证方式**: Token（在 Header 中携带 `Token: {token}`）
- **数据格式**: JSON

---

## 认证

### 获取 Token

**POST** `/tokens`

**请求体**:
```json
{
  "account": "admin",
  "password": "Admin1234"
}
```

**响应**:
```json
{
  "token": "xxxx-xxxx-xxxx-xxxx"
}
```

---

## 产品管理

### 获取产品列表

**GET** `/products`

**参数**:
| 参数 | 类型 | 说明 |
|------|------|------|
| page | int | 页码，默认 1 |
| limit | int | 每页数量，默认 30 |

### 获取产品详情

**GET** `/products/{id}`

### 创建产品

**POST** `/products`

**请求体**:
```json
{
  "name": "产品名称",
  "code": "product-code",
  "desc": "产品描述"
}
```

### 获取产品 Bug 列表

**GET** `/products/{id}/bugs`

### 获取产品需求列表

**GET** `/products/{id}/stories`

---

## 项目管理

### 获取项目列表

**GET** `/projects`

### 获取项目详情

**GET** `/projects/{id}`

### 创建项目

**POST** `/projects`

**请求体**:
```json
{
  "name": "项目名称",
  "code": "project-code",
  "begin": "2024-01-01",
  "end": "2024-12-31"
}
```

### 获取项目任务列表

**GET** `/projects/{id}/tasks`

### 获取项目成员列表

**GET** `/projects/{id}/members`

---

## 执行管理

### 获取执行列表

**GET** `/executions`

### 获取执行详情

**GET** `/executions/{id}`

### 创建执行

**POST** `/executions`

**请求体**:
```json
{
  "project": 1,
  "name": "执行名称",
  "begin": "2024-01-01",
  "end": "2024-03-31"
}
```

---

## 需求管理

### 获取需求列表

**GET** `/stories`

### 获取需求详情

**GET** `/stories/{id}`

### 创建需求

**POST** `/stories`

**请求体**:
```json
{
  "product": 1,
  "title": "需求标题",
  "pri": 2,
  "estimate": 8
}
```

### 更新需求状态

**PUT** `/stories/{id}`

---

## 任务管理

### 获取任务列表

**GET** `/tasks`

### 获取任务详情

**GET** `/tasks/{id}`

### 创建任务

**POST** `/tasks`

**请求体**:
```json
{
  "execution": 1,
  "name": "任务名称",
  "assignedTo": "user01",
  "estimate": 8,
  "pri": 2
}
```

### 更新任务状态

**PUT** `/tasks/{id}`

### 指派任务

**PUT** `/tasks/{id}/assignTo/{account}`

---

## Bug 管理

### 获取 Bug 列表

**GET** `/bugs`

### 获取 Bug 详情

**GET** `/bugs/{id}`

### 创建 Bug

**POST** `/bugs`

**请求体**:
```json
{
  "product": 1,
  "title": "Bug 标题",
  "severity": 3,
  "pri": 2,
  "assignedTo": "user01"
}
```

### 更新 Bug 状态

**PUT** `/bugs/{id}`

### 指派 Bug

**PUT** `/bugs/{id}/assignTo/{account}`

---

## 测试用例管理

### 获取测试用例列表

**GET** `/testcases`

### 获取测试用例详情

**GET** `/testcases/{id}`

### 创建测试用例

**POST** `/testcases`

**请求体**:
```json
{
  "product": 1,
  "title": "测试用例标题",
  "pri": 2,
  "type": "function"
}
```

---

## 用户管理

### 获取用户列表

**GET** `/users`

### 获取当前用户信息

**GET** `/user`

---

## 错误码

| 错误码 | 说明 |
|--------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未授权，Token 无效或已过期 |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |
