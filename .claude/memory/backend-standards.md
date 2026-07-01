# 后端开发规范

## API设计规范

### RESTful API 设计原则

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/resources | 获取列表 |
| GET | /api/resources/:id | 获取详情 |
| POST | /api/resources | 创建资源 |
| PUT | /api/resources/:id | 更新资源 |
| DELETE | /api/resources/:id | 删除资源 |

### 接口响应格式
```json
{
  "code": 200,
  "message": "success",
  "data": {},
  "timestamp": 1234567890
}
```

## 代码分层规范

### Controller 层
- 职责：接收请求、参数校验、调用Service、返回响应
- 命名：*Controller.java

### Service 层
- 职责：业务逻辑处理
- 命名：*Service.java, *ServiceImpl.java

### DAO/Mapper 层
- 职责：数据访问
- 命名：*Mapper.java, *Mapper.xml

## 数据库规范

### 表命名
- 小写字母 + 下划线：user_profile

### 字段命名
- 小写字母 + 下划线：created_at

### 必备字段
- id: 主键
- created_at: 创建时间
- updated_at: 更新时间
- is_deleted: 逻辑删除标记

## 异常处理规范

### 异常分类
- BusinessException：业务异常
- SystemException：系统异常
- ValidationException：参数校验异常

### 全局异常处理
```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(Exception.class)
    public Result handleException(Exception e) {
        // 处理逻辑
    }
}
```

## 日志规范

### 日志级别
- ERROR：错误信息
- WARN：警告信息
- INFO：关键业务信息
- DEBUG：调试信息

### 日志格式
```[时间] [级别] [类名] - 日志内容```

---

**最后更新:** 2026-05-18
