#!/bin/bash
#
# Claude Code 全栈开发环境自动初始化脚本
# 用法:
#   ./init.sh                  # 自动检测模式
#   ./init.sh --workspace      # 强制工作区模式
#   ./init.sh --project <dir>  # 初始化指定子项目
#   ./init.sh --scan           # 只扫描不创建
#

set -e

# ===== 颜色定义 =====
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
fail()  { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }
step()  { echo -e "${CYAN}==>${NC} $1"; }

# ===== 参数解析 =====
MODE="auto"
PROJECT_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --workspace)  MODE="workspace";  shift ;;
        --project)    MODE="project";    PROJECT_DIR="${2:-.}"; shift 2 ;;
        --scan)       MODE="scan";       shift ;;
        -h|--help)
            echo "用法: init.sh [选项]"
            echo ""
            echo "选项:"
            echo "  (无参数)          自动检测：单项目 or 多项目工作区"
            echo "  --workspace       强制工作区模式（扫描子目录）"
            echo "  --project <dir>   只初始化指定子项目"
            echo "  --scan            只扫描报告，不创建文件"
            echo "  -h, --help        显示帮助"
            exit 0
            ;;
        *)
            # 兼容旧用法：init.sh [项目目录]
            if [ -d "$1" ]; then
                PROJECT_DIR="$1"
            else
                fail "未知参数: $1"
            fi
            shift
            ;;
    esac
done

TARGET="${PROJECT_DIR:-.}"
cd "$TARGET"
TARGET_DIR=$(pwd)
WORKSPACE_NAME=$(basename "$TARGET_DIR")

# =====================================================================
#  项目检测函数
# =====================================================================

# 检测单个目录的项目类型
detect_project() {
    local dir="$1"
    local ptype="unknown"
    local lang="unknown"
    local backend=""
    local frontend=""
    local database=""
    local build=""
    local category="unknown"  # backend / frontend / fullstack / unknown

    # 检测后端
    if [ -f "$dir/pom.xml" ]; then
        ptype="java-maven"; lang="Java"; backend="Spring Boot"; build="Maven"; category="backend"
    elif [ -f "$dir/build.gradle" ] || [ -f "$dir/build.gradle.kts" ]; then
        ptype="java-gradle"; lang="Java"; backend="Spring Boot"; build="Gradle"; category="backend"
    elif [ -f "$dir/go.mod" ]; then
        ptype="go"; lang="Go"; backend="Gin"; build="Go Modules"; category="backend"
    elif [ -f "$dir/requirements.txt" ] || [ -f "$dir/pyproject.toml" ] || [ -f "$dir/setup.py" ]; then
        ptype="python"; lang="Python"; build="pip"; category="backend"
        # 区分 FastAPI / Django
        if [ -f "$dir/pyproject.toml" ] && grep -q "django" "$dir/pyproject.toml" 2>/dev/null; then
            backend="Django"
        elif [ -f "$dir/requirements.txt" ] && grep -q "django" "$dir/requirements.txt" 2>/dev/null; then
            backend="Django"
        else
            backend="FastAPI"
        fi
    fi

    # 检测前端
    if [ -f "$dir/package.json" ]; then
        local fe="未知"
        if grep -q '"vue"' "$dir/package.json" 2>/dev/null; then
            fe="Vue"
        elif grep -q '"react"' "$dir/package.json" 2>/dev/null; then
            fe="React"
        elif grep -q '"@angular/core"' "$dir/package.json" 2>/dev/null; then
            fe="Angular"
        fi

        if [ "$ptype" = "unknown" ]; then
            ptype="frontend"; lang="JavaScript/TypeScript"; build="npm"
            frontend="$fe"; category="frontend"
        else
            ptype="${ptype}-frontend"
            frontend="$fe"; category="fullstack"
        fi
    fi

    # 检测数据库
    local app_yml=$(find "$dir" -maxdepth 4 -name "application.yml" -o -name "application.yaml" 2>/dev/null | head -1)
    if [ -n "$app_yml" ]; then
        if grep -q "mysql" "$app_yml" 2>/dev/null; then
            database="MySQL"
        elif grep -q "postgresql" "$app_yml" 2>/dev/null; then
            database="PostgreSQL"
        elif grep -q "oracle" "$app_yml" 2>/dev/null; then
            database="Oracle"
        fi
    fi
    if [ -z "$database" ] && [ -f "$dir/docker-compose.yml" ]; then
        if grep -q "mysql" "$dir/docker-compose.yml" 2>/dev/null; then
            database="MySQL"
        elif grep -q "postgres" "$dir/docker-compose.yml" 2>/dev/null; then
            database="PostgreSQL"
        elif grep -q "redis" "$dir/docker-compose.yml" 2>/dev/null; then
            database="Redis"
        fi
    fi

    # 没检测到任何项目标记
    if [ "$ptype" = "unknown" ]; then
        return 1
    fi

    # 输出结果（通过全局变量）
    DET_PTYPE="$ptype"
    DET_LANG="$lang"
    DET_BACKEND="$backend"
    DET_FRONTEND="$frontend"
    DET_DATABASE="$database"
    DET_BUILD="$build"
    DET_CATEGORY="$category"
    return 0
}

# =====================================================================
#  项目深度检测：扫描依赖、工具链、目录结构
# =====================================================================

detect_project_details() {
    local dir="$1"
    local ptype="$2"

    DET_JAVA_VERSION=""
    DET_SPRING_VERSION=""
    DET_ORM=""
    DET_TEST_FRAMEWORK=""
    DET_API_DOC=""
    DET_UI_LIB=""
    DET_STATE_MGMT=""
    DET_CSS_FRAMEWORK=""
    DET_LINT_TOOL=""
    DET_PYTHON_VERSION=""
    DET_GO_VERSION=""
    DET_CACHE=""
    DET_MQ=""
    DET_DIR_TREE=""

    # 实际目录结构（排除无关目录，最多 60 行）
    DET_DIR_TREE=$(find "$dir" -maxdepth 4 -type d \
        -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/target/*' \
        -not -path '*/__pycache__/*' -not -path '*/.claude/*' -not -path '*/dist/*' \
        -not -path '*/.idea/*' -not -path '*/.vscode/*' -not -path '*/venv/*' \
        -not -path '*/.gradle/*' -not -path '*/build/*' \
        2>/dev/null | head -60 | sort | sed "s|^$dir||" | sed 's|^/||' | grep -v '^\.$')

    # ---------- Java 深度检测 ----------
    if echo "$ptype" | grep -q "java"; then
        # Java 版本
        if [ -f "$dir/pom.xml" ]; then
            DET_JAVA_VERSION=$(grep -oP '(?<=<java.version>)[^<]+' "$dir/pom.xml" 2>/dev/null || echo "")
            DET_SPRING_VERSION=$(grep -oP '(?<=<spring-boot.version>)[^<]+' "$dir/pom.xml" 2>/dev/null \
                || grep -oP 'spring-boot-starter-parent.*<version>\K[^<]+' "$dir/pom.xml" 2>/dev/null || echo "")
            # ORM
            if grep -q "mybatis-plus" "$dir/pom.xml" 2>/dev/null; then
                DET_ORM="MyBatis-Plus"
            elif grep -q "mybatis" "$dir/pom.xml" 2>/dev/null; then
                DET_ORM="MyBatis"
            elif grep -q "spring-boot-starter-data-jpa" "$dir/pom.xml" 2>/dev/null; then
                DET_ORM="JPA/Hibernate"
            fi
            # 测试
            if grep -q "junit" "$dir/pom.xml" 2>/dev/null; then
                DET_TEST_FRAMEWORK="JUnit 5"
            fi
            if grep -q "mockito" "$dir/pom.xml" 2>/dev/null; then
                DET_TEST_FRAMEWORK="${DET_TEST_FRAMEWORK:+$DET_TEST_FRAMEWORK + }Mockito"
            fi
            # API 文档
            if grep -q "springdoc" "$dir/pom.xml" 2>/dev/null; then
                DET_API_DOC="SpringDoc (OpenAPI 3)"
            elif grep -q "swagger" "$dir/pom.xml" 2>/dev/null; then
                DET_API_DOC="Swagger 2"
            elif grep -q "knife4j" "$dir/pom.xml" 2>/dev/null; then
                DET_API_DOC="Knife4j"
            fi
            # 缓存
            if grep -q "spring-boot-starter-data-redis" "$dir/pom.xml" 2>/dev/null; then
                DET_CACHE="Redis"
            fi
            # MQ
            if grep -q "rabbitmq" "$dir/pom.xml" 2>/dev/null; then
                DET_MQ="RabbitMQ"
            elif grep -q "kafka" "$dir/pom.xml" 2>/dev/null; then
                DET_MQ="Kafka"
            elif grep -q "rocketmq" "$dir/pom.xml" 2>/dev/null; then
                DET_MQ="RocketMQ"
            fi
        elif [ -f "$dir/build.gradle" ] || [ -f "$dir/build.gradle.kts" ]; then
            local gradle_file=$(ls "$dir"/build.gradle* 2>/dev/null | head -1)
            DET_JAVA_VERSION=$(grep -oP '(?<=sourceCompatibility.*=.*")[^"]+' "$gradle_file" 2>/dev/null \
                || grep -oP '(?<=javaVersion.*=.*")[^"]+' "$gradle_file" 2>/dev/null || echo "")
            if grep -q "mybatis" "$gradle_file" 2>/dev/null; then
                DET_ORM="MyBatis"
            elif grep -q "jpa" "$gradle_file" 2>/dev/null; then
                DET_ORM="JPA/Hibernate"
            fi
            if grep -q "springdoc" "$gradle_file" 2>/dev/null; then
                DET_API_DOC="SpringDoc (OpenAPI 3)"
            elif grep -q "swagger" "$gradle_file" 2>/dev/null; then
                DET_API_DOC="Swagger 2"
            fi
        fi
    fi

    # ---------- Python 深度检测 ----------
    if echo "$ptype" | grep -q "python"; then
        # Python 版本
        if [ -f "$dir/pyproject.toml" ]; then
            DET_PYTHON_VERSION=$(grep -oP '(?<=python-requires.*=.*">=)[^"]+' "$dir/pyproject.toml" 2>/dev/null \
                || grep -oP '(?<=python_requires.*=.*">=)[^"]+' "$dir/pyproject.toml" 2>/dev/null || echo "")
        fi
        local req_file=""
        [ -f "$dir/requirements.txt" ] && req_file="$dir/requirements.txt"
        [ -f "$dir/pyproject.toml" ] && req_file="$dir/pyproject.toml"
        if [ -n "$req_file" ]; then
            # ORM
            if grep -q "sqlalchemy" "$req_file" 2>/dev/null; then
                DET_ORM="SQLAlchemy"
            elif grep -q "tortoise" "$req_file" 2>/dev/null; then
                DET_ORM="Tortoise ORM"
            elif grep -q "django-orm" "$req_file" 2>/dev/null || grep -q "Django" "$req_file" 2>/dev/null; then
                DET_ORM="Django ORM"
            fi
            # 测试
            if grep -q "pytest" "$req_file" 2>/dev/null; then
                DET_TEST_FRAMEWORK="pytest"
            fi
            # 缓存
            if grep -q "redis" "$req_file" 2>/dev/null; then
                DET_CACHE="Redis"
            fi
            # MQ
            if grep -q "celery" "$req_file" 2>/dev/null; then
                DET_MQ="Celery"
            elif grep -q "rabbitmq" "$req_file" 2>/dev/null; then
                DET_MQ="RabbitMQ"
            fi
        fi
    fi

    # ---------- Go 深度检测 ----------
    if echo "$ptype" | grep -q "^go"; then
        if [ -f "$dir/go.mod" ]; then
            DET_GO_VERSION=$(head -1 "$dir/go.mod" | grep -oP 'go \K[0-9.]+' 2>/dev/null || echo "")
            if grep -q "gin-gonic" "$dir/go.mod" 2>/dev/null; then
                : # 已在 detect_project 中设置
            elif grep -q "labstack/echo" "$dir/go.mod" 2>/dev/null; then
                DET_BACKEND="Echo"
            elif grep -q "fiber" "$dir/go.mod" 2>/dev/null; then
                DET_BACKEND="Fiber"
            fi
            if grep -q "gorm.io" "$dir/go.mod" 2>/dev/null; then
                DET_ORM="GORM"
            elif grep -q "sqlx" "$dir/go.mod" 2>/dev/null; then
                DET_ORM="sqlx"
            fi
            if grep -q "swaggo/swag" "$dir/go.mod" 2>/dev/null; then
                DET_API_DOC="Swag (OpenAPI)"
            fi
            if grep -q "go-redis" "$dir/go.mod" 2>/dev/null; then
                DET_CACHE="Redis"
            fi
        fi
    fi

    # ---------- 前端深度检测 ----------
    if echo "$ptype" | grep -q "frontend" && [ -f "$dir/package.json" ]; then
        # UI 组件库
        if grep -q '"element-plus"' "$dir/package.json" 2>/dev/null; then
            DET_UI_LIB="Element Plus"
        elif grep -q '"ant-design-vue"' "$dir/package.json" 2>/dev/null; then
            DET_UI_LIB="Ant Design Vue"
        elif grep -q '"vuetify"' "$dir/package.json" 2>/dev/null; then
            DET_UI_LIB="Vuetify"
        elif grep -q '"@arco-design/web-vue"' "$dir/package.json" 2>/dev/null; then
            DET_UI_LIB="Arco Design Vue"
        elif grep -q '"antd"' "$dir/package.json" 2>/dev/null; then
            DET_UI_LIB="Ant Design"
        elif grep -q '"@mui/material"' "$dir/package.json" 2>/dev/null; then
            DET_UI_LIB="Material UI"
        elif grep -q '"@chakra-ui"' "$dir/package.json" 2>/dev/null; then
            DET_UI_LIB="Chakra UI"
        fi

        # 状态管理
        if grep -q '"pinia"' "$dir/package.json" 2>/dev/null; then
            DET_STATE_MGMT="Pinia"
        elif grep -q '"vuex"' "$dir/package.json" 2>/dev/null; then
            DET_STATE_MGMT="Vuex"
        elif grep -q '"@reduxjs/toolkit"' "$dir/package.json" 2>/dev/null; then
            DET_STATE_MGMT="Redux Toolkit"
        elif grep -q '"zustand"' "$dir/package.json" 2>/dev/null; then
            DET_STATE_MGMT="Zustand"
        elif grep -q '"mobx"' "$dir/package.json" 2>/dev/null; then
            DET_STATE_MGMT="MobX"
        fi

        # CSS 框架
        if grep -q '"tailwindcss"' "$dir/package.json" 2>/dev/null; then
            DET_CSS_FRAMEWORK="Tailwind CSS"
        elif grep -q '"sass"' "$dir/package.json" 2>/dev/null; then
            DET_CSS_FRAMEWORK="SCSS/Sass"
        elif grep -q '"less"' "$dir/package.json" 2>/dev/null; then
            DET_CSS_FRAMEWORK="Less"
        fi

        # 测试
        if grep -q '"vitest"' "$dir/package.json" 2>/dev/null; then
            DET_TEST_FRAMEWORK="Vitest"
        elif grep -q '"jest"' "$dir/package.json" 2>/dev/null; then
            DET_TEST_FRAMEWORK="Jest"
        fi
        if grep -q '"cypress"' "$dir/package.json" 2>/dev/null; then
            DET_TEST_FRAMEWORK="${DET_TEST_FRAMEWORK:+$DET_TEST_FRAMEWORK + }Cypress"
        elif grep -q '"@playwright/test"' "$dir/package.json" 2>/dev/null; then
            DET_TEST_FRAMEWORK="${DET_TEST_FRAMEWORK:+$DET_TEST_FRAMEWORK + }Playwright"
        fi

        # Lint
        if grep -q '"eslint"' "$dir/package.json" 2>/dev/null; then
            DET_LINT_TOOL="ESLint"
        fi
        if grep -q '"prettier"' "$dir/package.json" 2>/dev/null; then
            DET_LINT_TOOL="${DET_LINT_TOOL:+$DET_LINT_TOOL + }Prettier"
        fi
    fi

    return 0
}

# 扫描所有子项目
scan_subprojects() {
    SUBPROJECTS=()
    BACKEND_PROJECTS=()
    FRONTEND_PROJECTS=()

    local root_has_project=false
    if detect_project "."; then
        root_has_project=true
        SUBPROJECTS+=(".|${WORKSPACE_NAME}|${DET_PTYPE}|${DET_LANG}|${DET_BACKEND}|${DET_FRONTEND}|${DET_DATABASE}|${DET_BUILD}|${DET_CATEGORY}")
        if [ "$DET_CATEGORY" = "backend" ] || [ "$DET_CATEGORY" = "fullstack" ]; then
            BACKEND_PROJECTS+=(".|${WORKSPACE_NAME}|${DET_PTYPE}|${DET_BACKEND}")
        fi
        if [ "$DET_CATEGORY" = "frontend" ] || [ "$DET_CATEGORY" = "fullstack" ]; then
            FRONTEND_PROJECTS+=(".|${WORKSPACE_NAME}|${DET_PTYPE}|${DET_FRONTEND}")
        fi
    fi

    # 扫描一级子目录
    for subdir in */; do
        [ "$subdir" = "node_modules/" ] && continue
        [ "$subdir" = ".claude/" ] && continue
        [ "$subdir" = "docs/" ] && continue
        [ ! -d "$subdir" ] && continue

        local subdir_name="${subdir%/}"
        if detect_project "$subdir_name"; then
            SUBPROJECTS+=("${subdir_name}|${subdir_name}|${DET_PTYPE}|${DET_LANG}|${DET_BACKEND}|${DET_FRONTEND}|${DET_DATABASE}|${DET_BUILD}|${DET_CATEGORY}")
            if [ "$DET_CATEGORY" = "backend" ] || [ "$DET_CATEGORY" = "fullstack" ]; then
                BACKEND_PROJECTS+=("${subdir_name}|${subdir_name}|${DET_PTYPE}|${DET_BACKEND}")
            fi
            if [ "$DET_CATEGORY" = "frontend" ] || [ "$DET_CATEGORY" = "fullstack" ]; then
                FRONTEND_PROJECTS+=("${subdir_name}|${subdir_name}|${DET_PTYPE}|${DET_FRONTEND}")
            fi
        fi
    done
}

# 打印扫描结果
print_scan_results() {
    echo ""
    echo "========================================"
    echo -e "${CYAN}  项目扫描结果${NC}"
    echo "========================================"
    echo ""

    if [ ${#SUBPROJECTS[@]} -eq 0 ]; then
        warn "未检测到任何项目"
        return
    fi

    printf "  %-20s %-12s %-20s %-15s %-10s\n" "项目" "类型" "技术栈" "框架" "分类"
    printf "  %-20s %-12s %-20s %-15s %-10s\n" "----" "----" "-------" "----" "----"

    for proj in "${SUBPROJECTS[@]}"; do
        IFS='|' read -r path name ptype lang backend frontend database build category <<< "$proj"
        local tech="$lang"
        local framework=""
        [ -n "$backend" ] && framework="$backend"
        [ -n "$frontend" ] && framework="${framework:+$framework / }$frontend"
        printf "  %-20s %-12s %-20s %-15s %-10s\n" "$name" "$category" "$tech" "$framework" "$ptype"
    done

    echo ""
    info "后端项目: ${#BACKEND_PROJECTS[@]} 个"
    info "前端项目: ${#FRONTEND_PROJECTS[@]} 个"
    info "总计: ${#SUBPROJECTS[@]} 个项目"
    echo ""
}

# =====================================================================
#  生成函数：settings.json
# =====================================================================

generate_settings() {
    local target_dir="$1"
    local is_workspace="$2"  # "true" or "false"

    if [ -f "$target_dir/.claude/settings.json" ]; then
        info "settings.json 已存在，跳过"
        return
    fi

    if [ "$is_workspace" = "true" ]; then
        cat > "$target_dir/.claude/settings.json" << 'SETTINGEOF'
{
  "language": "chinese",
  "theme": "auto",
  "permissions": {
    "allow": [
      "Bash(npm *)",
      "Bash(mvn *)",
      "Bash(gradle *)",
      "Bash(go *)",
      "Bash(python *)",
      "Bash(pip *)",
      "Bash(node *)",
      "Bash(git show *)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(git diff-tree *)",
      "Read(*)",
      "Edit(*)",
      "Write(*)"
    ],
    "deny": [
      "Bash(git push --force)",
      "Bash(rm -rf *)"
    ]
  },
  "enabledPlugins": {
    "superpowers@superpowers-marketplace": true,
    "document-skills@anthropic-agent-skills": true
  }
}
SETTINGEOF
    else
        # 单项目配置 — 根据技术栈定制权限
        local extra_perms=""
        if echo "$1" | grep -q "java" 2>/dev/null || [ -f "$target_dir/pom.xml" ]; then
            extra_perms="\"Bash(mvn *)\", \"Bash(gradle *)\","
        elif [ -f "$target_dir/go.mod" ]; then
            extra_perms="\"Bash(go *)\","
        elif [ -f "$target_dir/requirements.txt" ] || [ -f "$target_dir/pyproject.toml" ]; then
            extra_perms="\"Bash(python *)\", \"Bash(pip *)\","
        fi

        if [ -f "$target_dir/package.json" ]; then
            extra_perms="${extra_perms}\"Bash(npm *)\", \"Bash(node *)\","
        fi

        cat > "$target_dir/.claude/settings.json" << SETTINGEOF
{
  "language": "chinese",
  "theme": "auto",
  "permissions": {
    "allow": [
      ${extra_perms}
      "Bash(git show *)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(git diff-tree *)",
      "Read(*)",
      "Edit(*)",
      "Write(*)"
    ],
    "deny": [
      "Bash(git push --force)",
      "Bash(rm -rf *)"
    ]
  },
  "enabledPlugins": {
    "superpowers@superpowers-marketplace": true,
    "document-skills@anthropic-agent-skills": true
  }
}
SETTINGEOF
    fi
    ok "settings.json 已创建"
}

# =====================================================================
#  生成函数：共享 rules
# =====================================================================

generate_shared_rules() {
    local target_dir="$1"
    local rules_dir="$target_dir/.claude/rules"
    mkdir -p "$rules_dir"

    # Git 安全规则
    if [ ! -f "$rules_dir/git-safety.md" ]; then
    cat > "$rules_dir/git-safety.md" << 'EOF'
<important if="running git commands or creating commits">
Git 安全规则：

- 不执行 `git push --force`
- 不执行 `rm -rf`
- 不跳过 hooks（不使用 --no-verify）
- 创建新 commit 而非 amend（除非明确要求）
- 不提交含密钥的文件（.env、credentials 等）
</important>
EOF
    fi

    # 开发铁律 + 调试规则
    if [ ! -f "$rules_dir/superpowers-workflow.md" ]; then
    cat > "$rules_dir/superpowers-workflow.md" << 'EOF'
<important if="executing any workflow skill">
Workflow 执行规则：

1. 没设计不写代码 — 先确认文件、范围、方案
2. 没测试不写代码 — 先写失败测试，再写实现
3. 没验证不说完成 — 运行验证命令并贴结果
</important>

<important if="encountering a bug or test failure">
调试规则：

- 先找根因再修，不靠猜
- 读堆栈 → 复现 → 追踪数据流 → 假设 → 最小改动验证
- 连续 3 次失败，停下来审视架构
</important>
EOF
    fi

    # 基础编码标准
    if [ ! -f "$rules_dir/coding-standards.md" ]; then
    cat > "$rules_dir/coding-standards.md" << 'EOF'
<important if="editing any source code file">
编码标准：

- 不引入安全漏洞（SQL 注入、XSS、命令注入等 OWASP Top 10）
- 不添加超出任务需求的抽象或功能
- 不写多余注释，只在 WHY 不明显时注释
- 命名清晰即可，不写解释 WHAT 的注释
</important>
EOF
    fi

    ok "共享 rules 已创建"
}

# =====================================================================
#  生成函数：技术栈专属 rules
# =====================================================================

generate_tech_rules() {
    local target_dir="$1"
    local ptype="$2"
    local rules_dir="$target_dir/.claude/rules"
    mkdir -p "$rules_dir"

    # Java / Spring Boot
    if echo "$ptype" | grep -q "java"; then
        if [ ! -f "$rules_dir/spring-boot.md" ]; then
        cat > "$rules_dir/spring-boot.md" << 'EOF'
<important if="creating or modifying Java/Spring Boot code">
Spring Boot 开发规范：

- Controller 层：只接收请求、参数校验（@Valid），不写业务逻辑
- Service 层：业务逻辑、事务管理（@Transactional），可调用 Mapper 或其他 Service
- Mapper/DAO 层：数据访问，只写 SQL 映射，不含业务逻辑
- 禁止跨层调用（Controller 不能直接调 Mapper）
- 统一响应格式：{ code, message, data, timestamp }
- 全局异常处理：@RestControllerAdvice
- 表名小写下划线，必备字段 id, created_at, updated_at
- 使用 MyBatis-Plus 时，复杂查询手写 XML，简单 CRUD 用注解
</important>
EOF
        ok "Java/Spring Boot rules 已创建"
        fi
    fi

    # Python / FastAPI
    if echo "$ptype" | grep -q "python"; then
        if [ ! -f "$rules_dir/python-api.md" ]; then
        cat > "$rules_dir/python-api.md" << 'EOF'
<important if="creating or modifying Python code">
Python 后端开发规范：

- Router 层：路由定义、请求参数校验（Pydantic Model）
- Service 层：业务逻辑，可调用 Model 或其他 Service
- Model 层：数据模型定义（SQLAlchemy / Tortoise ORM）
- 禁止跨层调用
- 异步优先：async/await，数据库 IO 不阻塞
- 使用 Pydantic 做请求/响应校验，不手动 if-else 校验
- 统一响应格式：{ code, message, data, timestamp }
- 类型注解全覆盖，不使用 Any
</important>
EOF
        ok "Python/FastAPI rules 已创建"
        fi
    fi

    # Vue
    if echo "$ptype" | grep -q "frontend"; then
        if grep -q '"vue"' "$target_dir/package.json" 2>/dev/null; then
            if [ ! -f "$rules_dir/vue-standards.md" ]; then
            cat > "$rules_dir/vue-standards.md" << 'EOF'
<important if="creating or modifying Vue code">
Vue 开发规范：

- 使用 Composition API + <script setup>，不使用 Options API
- 组件文件名 PascalCase（如 UserList.vue），新增前先搜索已有组件
- 状态管理使用 Pinia，不使用 Vuex
- API 调用统一通过 api/ 目录模块，不直接写 axios/fetch
- 处理 loading / error / empty 三种 UI 状态
- Props 定义使用 withDefaults + defineProps<T>()
- 组件内逻辑拆分：useXxx() composable，保持组件简洁
- CSS 使用 scoped，不使用全局样式污染
</important>
EOF
            ok "Vue rules 已创建"
            fi
        elif grep -q '"react"' "$target_dir/package.json" 2>/dev/null; then
            if [ ! -f "$rules_dir/react-standards.md" ]; then
            cat > "$rules_dir/react-standards.md" << 'EOF'
<important if="creating or modifying React code">
React 开发规范：

- 使用函数组件 + Hooks，不使用类组件
- 组件文件名 PascalCase（如 UserList.tsx），新增前先搜索已有组件
- 状态管理：简单用 useState/useReducer，复杂用 Zustand 或 Redux Toolkit
- API 调用统一通过 api/ 目录模块，不直接写 fetch/axios
- 处理 loading / error / empty 三种 UI 状态
- 自定义 Hook 以 use 前缀命名（如 useUserInfo）
- Props 使用 TypeScript interface 定义
- 避免 useEffect 副作用地狱，依赖数组必须完整
</important>
EOF
            ok "React rules 已创建"
            fi
        else
            # 通用前端
            if [ ! -f "$rules_dir/frontend-base.md" ]; then
            cat > "$rules_dir/frontend-base.md" << 'EOF'
<important if="creating or modifying frontend code">
前端规范：

- 组件文件名 PascalCase，新增前先搜索已有组件
- API 调用统一通过 api/ 目录模块，不直接写 fetch/axios
- 处理 loading / error / empty 三种状态
- ESLint + Prettier 规则不可绕过
</important>
EOF
            ok "前端通用 rules 已创建"
            fi
        fi
    fi

    # Go
    if echo "$ptype" | grep -q "^go"; then
        if [ ! -f "$rules_dir/go-standards.md" ]; then
        cat > "$rules_dir/go-standards.md" << 'EOF'
<important if="creating or modifying Go code">
Go 开发规范：

- Handler 层：接收请求、参数绑定（ShouldBind），不写业务逻辑
- Service 层：业务逻辑，可调用 Repository 或其他 Service
- Repository 层：数据访问，不含业务逻辑
- 禁止跨层调用
- 错误处理：不忽略 error，必须处理或向上传递
- 使用标准 layout：cmd/、internal/、pkg/ 结构
- 统一响应格式：{ code, message, data, timestamp }
- Context 传递：所有函数第一参数接收 ctx context.Context
- 数据库操作使用事务确保一致性
</important>
EOF
        ok "Go rules 已创建"
        fi
    fi
}

# =====================================================================
#  生成函数：commands
# =====================================================================

generate_commands() {
    local target_dir="$1"
    local mode="$2"  # "single" / "workspace"
    local backend_list="$3"
    local frontend_list="$4"
    local cmds_dir="$target_dir/.claude/commands"
    mkdir -p "$cmds_dir"

    if [ "$mode" = "workspace" ]; then
        # 工作区命令 — 带子项目感知

        # /frontend
        if [ ! -f "$cmds_dir/frontend.md" ]; then
            local fe_hint=""
            if [ ${#FRONTEND_PROJECTS[@]} -gt 0 ]; then
                fe_hint=$'\n## 前端子项目\n'
                for p in "${FRONTEND_PROJECTS[@]}"; do
                    IFS='|' read -r path name ptype framework <<< "$p"
                    fe_hint+="- \`$name\` ($framework) — cd $name 后使用\n"
                done
            fi
            cat > "$cmds_dir/frontend.md" << EOF
切换到前端开发模式。从现在起，你的工作重点是 UI 组件开发、样式调整、状态管理、前端性能优化。
${fe_hint}
## 约束

- 代码风格遵循当前项目的 \`.claude/memory/frontend-standards.md\`
- API 调用统一走 \`api/\` 目录模块，不直接写 HTTP 请求
- 组件保持单一职责，PascalCase 命名，新增前先搜索已有组件
- 处理好加载/错误/空状态三种 UI 反馈
- ESLint + Prettier 规则不可绕过

## 下一步

- **简单任务**（改样式/改文案）：直接描述需求即可
- **中等任务**（新组件/新页面）：说"帮我设计一下"，会触发 brainstorming
- **复杂任务**（新功能模块）：说"帮我规划"，会走完整流程

\$ARGUMENTS
EOF
        fi

        # /backend
        if [ ! -f "$cmds_dir/backend.md" ]; then
            local be_hint=""
            if [ ${#BACKEND_PROJECTS[@]} -gt 0 ]; then
                be_hint=$'\n## 后端子项目\n'
                for p in "${BACKEND_PROJECTS[@]}"; do
                    IFS='|' read -r path name ptype framework <<< "$p"
                    be_hint+="- \`$name\` ($framework) — cd $name 后使用\n"
                done
            fi
            cat > "$cmds_dir/backend.md" << EOF
切换到后端开发模式。从现在起，你的工作重点是 API 接口设计、数据库操作、业务逻辑、服务治理。
${be_hint}
## 约束

- 代码风格遵循当前项目的 \`.claude/memory/backend-standards.md\`
- 严格分层架构，禁止跨层调用
- API 使用 RESTful 风格，统一响应格式 \`{ code, message, data, timestamp }\`
- 所有外部输入必须校验，防止 SQL 注入和 XSS

## 下一步

- **简单任务**（修接口/加字段）：直接描述需求即可
- **中等任务**（新接口/新表）：说"帮我设计一下"，会触发 brainstorming
- **复杂任务**（新模块/重构）：说"帮我规划"，会走完整流程

\$ARGUMENTS
EOF
        fi

        # /fullstack
        if [ ! -f "$cmds_dir/fullstack.md" ]; then
        cat > "$cmds_dir/fullstack.md" << 'EOF'
切换到全栈协调模式。从现在起，你需要同时关注前后端一致性和完整数据流。

## 多项目工作区

本工作区包含多个子项目，全栈模式需要协调跨项目的数据流。

## 约束

- 前后端数据格式必须统一，接口契约必须一致
- 开发顺序：数据库 → 后端 API → 前端页面，自底向上
- 前端 API 调用必须与后端接口定义匹配（字段名、类型、路径）
- 错误处理链路完整：数据库异常 → 后端异常处理 → 前端错误展示

## 下一步

- **简单任务**（改字段/修 bug）：直接描述需求即可
- **中等任务**（新页面+新接口）：说"帮我设计一下"，会触发 brainstorming
- **复杂任务**（新功能模块）：说"帮我规划"，会走完整流程

$ARGUMENTS
EOF
        fi

    else
        # 单项目命令 — 同当前逻辑
        if [ ! -f "$cmds_dir/frontend.md" ]; then
        cat > "$cmds_dir/frontend.md" << 'EOF'
切换到前端开发模式。从现在起，你的工作重点是 UI 组件开发、样式调整、状态管理、前端性能优化。

## 约束

- 代码风格遵循 `.claude/memory/frontend-standards.md`
- API 调用统一走 `api/` 目录模块，不直接写 HTTP 请求
- 组件保持单一职责，PascalCase 命名，新增前先搜索已有组件
- 处理好加载/错误/空状态三种 UI 反馈
- ESLint + Prettier 规则不可绕过

## 下一步

- **简单任务**（改样式/改文案）：直接描述需求即可
- **中等任务**（新组件/新页面）：说"帮我设计一下"，会触发 brainstorming
- **复杂任务**（新功能模块）：说"帮我规划"，会走完整流程
- **完整流程**：调用 `/frontend-workflow` 走结构化开发流水线

$ARGUMENTS
EOF
        fi

        if [ ! -f "$cmds_dir/backend.md" ]; then
        cat > "$cmds_dir/backend.md" << 'EOF'
切换到后端开发模式。从现在起，你的工作重点是 API 接口设计、数据库操作、业务逻辑、服务治理。

## 约束

- 代码风格遵循 `.claude/memory/backend-standards.md`
- 严格分层架构：Controller → Service → DAO/Mapper，禁止跨层调用
- API 使用 RESTful 风格，统一响应格式 `{ code, message, data, timestamp }`
- 表名小写下划线，必备字段 `id, created_at, updated_at`
- 所有外部输入必须校验，防止 SQL 注入和 XSS

## 下一步

- **简单任务**（修接口/加字段）：直接描述需求即可
- **中等任务**（新接口/新表）：说"帮我设计一下"，会触发 brainstorming
- **复杂任务**（新模块/重构）：说"帮我规划"，会走完整流程
- **完整流程**：调用 `/backend-workflow` 走结构化开发流水线

$ARGUMENTS
EOF
        fi

        if [ ! -f "$cmds_dir/fullstack.md" ]; then
        cat > "$cmds_dir/fullstack.md" << 'EOF'
切换到全栈协调模式。从现在起，你需要同时关注前后端一致性和完整数据流。

## 约束

- 后端遵循 `.claude/memory/backend-standards.md`，前端遵循 `.claude/memory/frontend-standards.md`
- 前后端数据格式必须统一，接口契约必须一致
- 开发顺序：数据库 → 后端 API → 前端页面，自底向上
- 前端 API 调用必须与后端接口定义匹配（字段名、类型、路径）
- 错误处理链路完整：数据库异常 → 后端异常处理 → 前端错误展示

## 下一步

- **简单任务**（改字段/修 bug）：直接描述需求即可
- **中等任务**（新页面+新接口）：说"帮我设计一下"，会触发 brainstorming
- **复杂任务**（新功能模块）：说"帮我规划"，会走 brainstorming → planning → TDD 完整流程
- **完整流程**：调用 `/fullstack-workflow` 走结构化全栈开发流水线

$ARGUMENTS
EOF
        fi
    fi

    ok "commands 已创建"
}

# =====================================================================
#  生成函数：skills
# =====================================================================

generate_skills() {
    local target_dir="$1"
    local skills_dir="$target_dir/.claude/skills"
    mkdir -p "$skills_dir"

    # 前端 Skill
    if [ ! -f "$skills_dir/frontend-workflow.md" ]; then
    cat > "$skills_dir/frontend-workflow.md" << 'SKILLEOF'
---
name: frontend-workflow
description: 当需要开发或修改前端 UI 组件、页面、样式、状态管理、前端性能优化时使用
context: fork
---

# 前端开发流程编排器

你处于前端开发模式。本技能是完整的前端开发流程编排器，每个步骤关联 Superpowers Skill，根据项目配置决定是否启用。

## 配置读取（流程开始前执行）

读取 `.claude/memory/superpowers-config.md` 中的配置，确定每个 Skill 的启用状态：
- **enabled** → 对应步骤始终执行
- **disabled** → 对应步骤始终跳过
- **conditional** → 根据复杂度判断

复杂度：简单（单文件 < 30 分钟）/ 中等（新组件 30 分钟 - 2 小时）/ 复杂（新模块 > 2 小时）

---

## 流程步骤

### 步骤 0：需求入口 [必选]

- 接收用户需求描述
- 判断复杂度等级
- **简单任务**（改样式/改文案）→ 跳到步骤 3 直接实现
- **中等/复杂任务** → 进入步骤 1

### 步骤 1：需求澄清与方案设计 [中等+复杂]

- 确认涉及的文件、组件、页面
- 检查 `.claude/memory/frontend-standards.md` 了解项目规范
- 搜索项目中是否已有可复用的组件
- 在 `specs/active/` 创建 spec 文件
- 输出设计要点让用户确认

### 步骤 2：任务拆解与计划 [复杂]

- 拆解为 2-5 分钟可完成的小任务
- 输出计划让用户确认

### 步骤 3：实现 [必选]

- 按规范编写代码
- API 调用通过 `api/` 目录模块
- 处理 loading / error / empty 三种状态

### 步骤 4：验证 [必选]

- 运行 lint 和测试（如存在）
- 贴出运行结果作为完成证据
- 已完成的 spec 移入 `specs/archived/`

---

## 完成标准

- lint 无错误 + 测试通过 + 三种状态已处理 + 符合规范 + 验证结果已贴出
SKILLEOF
    fi

    # 后端 Skill
    if [ ! -f "$skills_dir/backend-workflow.md" ]; then
    cat > "$skills_dir/backend-workflow.md" << 'SKILLEOF'
---
name: backend-workflow
description: 当需要开发或修改后端 API 接口、数据库操作、业务逻辑、服务配置时使用
context: fork
---

# 后端开发流程编排器

你处于后端开发模式。本技能是完整的后端开发流程编排器，每个步骤关联 Superpowers Skill，根据项目配置决定是否启用。

## 配置读取（流程开始前执行）

读取 `.claude/memory/superpowers-config.md` 中的配置，确定每个 Skill 的启用状态：
- **enabled** → 对应步骤始终执行
- **disabled** → 对应步骤始终跳过
- **conditional** → 根据复杂度判断

复杂度：简单（单接口/加字段 < 30 分钟）/ 中等（新表+新接口 30 分钟 - 2 小时）/ 复杂（新模块 > 2 小时）

---

## 流程步骤

### 步骤 0：需求入口 [必选]

- 接收用户需求描述
- 判断复杂度等级
- **简单任务**（修接口/加字段）→ 跳到步骤 3 直接实现
- **中等/复杂任务** → 进入步骤 1

### 步骤 1：需求澄清与方案设计 [中等+复杂]

- 确认涉及的业务模块、数据表、接口
- 设计 API 路径、请求参数、响应格式、错误码
- 设计数据库变更（如需建表/改表，先输出 DDL）
- 在 `specs/active/` 创建 spec 文件
- 输出设计要点让用户确认

### 步骤 2：任务拆解与计划 [复杂]

- 拆解为 2-5 分钟可完成的小任务
- 输出计划让用户确认

### 步骤 3：自底向上实现 [必选]

按顺序逐层实现：
1. **DAO/Mapper 层** — 数据访问方法、SQL 映射
2. **Service 层** — 业务逻辑、事务管理
3. **Controller 层** — 接口定义、参数校验、响应封装

### 步骤 4：验证 [必选]

- 运行构建和测试命令
- 贴出运行结果作为完成证据
- 已完成的 spec 移入 `specs/archived/`

---

## 完成标准

- 编译通过 + 测试通过 + 分层正确 + 无安全隐患 + 验证结果已贴出
SKILLEOF
    fi

    # 全栈 Skill
    if [ ! -f "$skills_dir/fullstack-workflow.md" ]; then
    cat > "$skills_dir/fullstack-workflow.md" << 'SKILLEOF'
---
name: fullstack-workflow
description: 当需要开发完整功能模块（从数据库到前端页面）或进行前后端联调时使用
context: fork
---

# 全栈开发流程编排器

你处于全栈协调模式。本技能是完整的开发流程编排器。

## 配置读取（流程开始前执行）

读取 `.claude/memory/superpowers-config.md` 中的配置，确定每个 Skill 的启用状态。

---

## 流程步骤

### 步骤 0：需求入口 [必选]

- 接收用户需求描述
- 判断复杂度等级

### 步骤 1：需求澄清与方案设计 [中等+复杂]

- 确认功能边界：数据表、接口数量、页面数量
- 在 `specs/active/` 创建 spec 文件
- 输出设计要点让用户确认

### 步骤 2：任务拆解与计划 [复杂]

- 拆解为 2-5 分钟可完成的小任务
- 输出计划让用户确认

### 步骤 3：工作空间隔离 [复杂]

- 创建 git worktree 隔离开发环境

### 步骤 4：实现 [必选]

#### 4a. 接口契约设计
- 定义 API 路径、请求/响应 JSON、错误码

#### 4b. 自底向上实现
1. 数据库层 → 2. DAO/Mapper 层 → 3. Service 层 → 4. Controller 层 → 5. 前端 API 模块 → 6. 前端页面

### 步骤 5：联调验证 [必选]

- 运行后端构建和测试
- 运行前端 lint 和测试
- 验证前后端字段名/类型完全一致

### 步骤 6：代码审查 [中等+复杂]

- 按严重度分级审查

### 步骤 7：收尾 [必选]

- 更新知识库
- 清理工作空间

---

## 完成标准

- 后端编译通过 + 测试通过 + 前端 lint 无错误 + 端到端数据流通畅 + 验证结果已贴出
SKILLEOF
    fi

    # 代码评审 Skill
    mkdir -p "$skills_dir/code-review"
    if [ ! -f "$skills_dir/code-review/SKILL.md" ]; then
    cat > "$skills_dir/code-review/SKILL.md" << 'SKILLEOF'
---
name: code-review
description: Use when reviewing code changes, pull requests, or performing code quality audits. Triggers include mentions of "code review", "review PR", "check code quality", "代码评审", "代码审查", "评审代码", or when examining code for security vulnerabilities, correctness issues, performance problems, or maintainability concerns.
---

# 代码评审

基于 6 维度 31 项评审标准体系，对代码变更进行系统性评审，输出结构化评审报告。

## 评审流程

```dot
digraph review_flow {
    "确定评审范围" [shape=box];
    "读取变更内容" [shape=box];
    "按维度逐项检查" [shape=box];
    "发现高危/严重问题?" [shape=diamond];
    "记录问题到报告" [shape=box];
    "汇总评审结论" [shape=box];
    "输出评审报告" [shape=doublecircle];

    "确定评审范围" -> "读取变更内容";
    "读取变更内容" -> "按维度逐项检查";
    "按维度逐项检查" -> "发现高危/严重问题?" ;
    "发现高危/严重问题?" -> "记录问题到报告" [label="是"];
    "发现高危/严重问题?" -> "汇总评审结论" [label="否，检查完毕"];
    "记录问题到报告" -> "按维度逐项检查";
    "汇总评审结论" -> "输出评审报告";
}
```

## 执行步骤

### 1. 确定评审范围

根据用户输入确定评审对象：

**模式 A：基于 git 提交记录（推荐）**

询问用户选择评审方式：
- **最近一次提交** → 直接使用最新 commit
- **选择历史提交** → 列出最近 10 次提交，让用户选择

用户选择后，获取该提交涉及的文件列表，然后进入步骤 2。

**模式 B：指定文件或目录**

- 指定文件路径 → 评审该文件
- 指定目录 → 评审目录下所有代码文件

### 2. 获取文件内容（纯读取）

> **重要：从本步骤开始，整个评审过程中禁止执行任何 git 命令。**

使用 `Read` 工具逐一读取步骤 1 中确定的文件列表。只能使用 `Read`、`Glob` 等只读工具获取文件内容。

### 3. 按维度逐项检查

严格按以下 6 个维度顺序检查，每项给出判定结果：

**维度优先级**：安全性 > 正确性 > 性能 > 设计与架构 > 可维护性 > 规范与一致性

对每个维度，逐项检查并标记：
- **通过** — 符合标准
- **不通过** — 不符合标准，记录具体问题和严重等级
- **不适用** — 当前变更不涉及此项

### 4. 输出评审报告

评审报告格式如下：

```markdown
# 代码评审报告

**评审范围**：[文件/目录/变更范围]
**评审日期**：[日期]
**评审结果**：[通过 | 有条件通过 | 不通过]

## 评审汇总

| 维度 | 通过 | 不通过 | 不适用 | 最高等级 |
|------|------|--------|--------|---------|
| 正确性与功能 | X | X | X | - |
| 安全性 | X | X | X | - |
| 可维护性 | X | X | X | - |
| 性能 | X | X | X | - |
| 设计与架构 | X | X | X | - |
| 规范与一致性 | X | X | X | - |

## 问题清单

| # | 维度 | 评审项 | 问题描述 | 严重等级 | 修复建议 |
|---|------|--------|---------|---------|---------|
| 1 | 安全性 | SQL 注入 | ... | 高危 | ... |

## 评审结论

[总结性说明，包括必须修复的问题和建议改进项]
```

## 评审标准速查

### 维度一：正确性与功能（5 项）

| # | 评审项 | 等级 | 检查要点 |
|---|--------|------|---------|
| 1.1 | 功能逻辑 | 严重 | 实现与需求一致，路径覆盖完整 |
| 1.2 | 边界与异常处理 | 严重 | 空值、越界、并发、极端输入处理 |
| 1.3 | 数据一致性 | 严重 | 事务正确，无竞态条件 |
| 1.4 | API 契约 | 严重 | 接口约定一致，向后兼容 |
| 1.5 | 测试覆盖 | 一般 | 核心逻辑有有效测试 |

### 维度二：安全性（18 项）

**业务数据篡改**：必填项/负值/一致性/选择框/置灰项/空值/边界值校验

**未授权访问**：登录校验、权限校验

**越权防护**：水平越权、ID 遍历、垂直越权

**信息泄露**：敏感数据脱敏、组件版本号、异常信息、密钥泄露

**注入攻击**：SQL 注入、CSRF、会话固定、URL 跳转、用户名枚举

**前端安全**：安全配置、静态文件泄露

> 详细标准见 standards.md

### 维度三：可维护性（6 项）

命名规范、方法长度、代码复杂度、重复代码、注释质量、依赖管理

### 维度四：性能（4 项）

数据库查询、资源管理、缓存使用、批量与循环

### 维度五：设计与架构（4 项）

职责划分、接口设计、扩展性、日志规范

### 维度六：规范与一致性（3 项）

编码规范、提交规范、配置管理

## 问题等级定义

| 等级 | 处理方式 |
|------|---------|
| **高危/严重** | 必须修复，阻塞合并 |
| **中危** | 强烈建议修复，本轮处理 |
| **一般** | 建议改进，记录跟踪 |
| **低危/建议** | 供参考，酌情处理 |

## 评审结论判定规则

- **不通过**：存在任何高危/严重级别问题
- **有条件通过**：存在中危级别问题，已确认修复计划
- **通过**：仅有一般/建议级别问题或无问题
SKILLEOF
    fi

    if [ ! -f "$skills_dir/code-review/standards.md" ]; then
    cat > "$skills_dir/code-review/standards.md" << 'SKILLEOF'
# 代码评审标准详细参考

## 维度一：正确性与功能

| # | 评审项 | 评审标准 | 等级 |
|---|--------|---------|------|
| 1.1 | 功能逻辑 | 代码实现与需求/设计文档一致，核心路径和分支路径均覆盖 | 严重 |
| 1.2 | 边界与异常处理 | 空值、越界、并发、极端输入有合理处理 | 严重 |
| 1.3 | 数据一致性 | 数据读写一致，事务使用正确，无竞态条件 | 严重 |
| 1.4 | API 契约 | 接口入参/出参/错误码符合约定，向后兼容 | 严重 |
| 1.5 | 测试覆盖 | 核心逻辑有对应的单元测试/集成测试，测试有效（非凑覆盖率） | 一般 |

---

## 维度二：安全性

### 2.1 业务数据篡改防护

| # | 评审项 | 等级 | 评审标准 |
|---|--------|------|---------|
| 2.1.1 | 必填项校验 | 高危 | 后端需校验是否接收到有效数值 |
| 2.1.2 | 负值校验 | 高危 | 金额等字段需 >= 0 |
| 2.1.3 | 一致性校验 | 中危 | 输入框前后端长度限制须保持一致 |
| 2.1.4 | 选择框校验 | 高危 | 后端需校验入参是否在选择框可选范围内 |
| 2.1.5 | 置灰项校验 | 中危 | 后端需对置灰项提交的值进行校验；更新类服务不允许修改置灰字段 |
| 2.1.6 | 空值校验 | 高危 | 查询入参 ID 为空时需返回异常 |
| 2.1.7 | 边界值校验 | 中危 | 分页等参数需限制最大值 |

### 2.2 未授权访问防护

| # | 评审项 | 等级 | 评审标准 |
|---|--------|------|---------|
| 2.2.1 | 登录校验 | 高危 | 所有服务使用登录过滤器拦截，校验 sessionId 是否有效 |
| 2.2.2 | 权限校验 | 高危 | 未登录或无权限访问时，页面不可展示、接口无数据返回 |

### 2.3 越权防护

| # | 评审项 | 等级 | 评审标准 |
|---|--------|------|---------|
| 2.3.1 | 水平越权 | 高危 | ID 等参数修改后，返回数据须在当前账号权限范围内 |
| 2.3.2 | ID 遍历风险 | 高危 | 禁止使用自增 ID，避免暴力遍历风险 |
| 2.3.3 | 垂直越权 | 高危 | 接口需有权限校验，低权限账号调用高权限接口需返回异常 |

### 2.4 信息泄露防护

| # | 评审项 | 等级 | 评审标准 |
|---|--------|------|---------|
| 2.4.1 | 敏感数据脱敏 | 高危 | 敏感数据原则上不返回，需展示时脱敏返回 |
| 2.4.2 | 组件版本号泄露 | 低危 | 避免 Nginx 等组件版本号泄露 |
| 2.4.3 | 异常信息泄露 | 高危 | 禁止将 `e.getMessage()` 等异常信息返回前端 |
| 2.4.4 | 密钥泄露 | 中危 | 地图 Key、OSS AccessKeyId 等禁止明文出现在 URL 中，必须加密传输 |

### 2.5 注入与攻击防护

| # | 评审项 | 等级 | 评审标准 |
|---|--------|------|---------|
| 2.5.1 | SQL 注入 | 高危 | 禁止字符串拼接 SQL；MyBatis 中禁止使用 `${}`，用 `#{}` 代替 |
| 2.5.2 | CSRF 跨站请求伪造 | 中危 | 所有请求需添加 Referer/Origin 白名单校验 |
| 2.5.3 | 会话固定攻击 | 中危 | 登录信息不缓存，需实时调用接口，与入口系统同步 |
| 2.5.4 | URL 跳转 | 高危 | 跳转 URL 需做域名白名单限制 |
| 2.5.5 | 用户名枚举 | 高危 | 统一登录异常返回，不区分"账号不存在"和"密码错误" |

### 2.6 前端安全

| # | 评审项 | 等级 | 评审标准 |
|---|--------|------|---------|
| 2.6.1 | 安全配置错误 | 低危 | 前端跳转统一加监听，登录失效时在解析页面前跳转登录页 |
| 2.6.2 | 静态文件信息泄露 | 低危 | 调试 IP、注释 IP 及时删除，编译后 JS 中不得存在明文 IP |

---

## 维度三：可维护性

| # | 评审项 | 评审标准 | 等级 |
|---|--------|---------|------|
| 3.1 | 命名规范 | 变量、函数、类命名语义清晰，符合团队编码规范 | 一般 |
| 3.2 | 方法/函数长度 | 单个方法不超过合理阈值（建议 50 行），职责单一 | 一般 |
| 3.3 | 代码复杂度 | 嵌套层级不超过 3-4 层，圈复杂度合理 | 一般 |
| 3.4 | 重复代码 | 无明显的复制粘贴代码，可复用逻辑已抽取 | 一般 |
| 3.5 | 注释质量 | 关键业务逻辑有必要注释，无冗余/过时注释 | 一般 |
| 3.6 | 依赖管理 | 新增依赖有必要性论证，无冗余/过期依赖 | 一般 |

---

## 维度四：性能

| # | 评审项 | 评审标准 | 等级 |
|---|--------|---------|------|
| 4.1 | 数据库查询 | 无 N+1 查询，大表查询有合理索引和分页 | 严重 |
| 4.2 | 资源管理 | 连接、流、文件句柄等资源正确关闭，无泄露 | 严重 |
| 4.3 | 缓存使用 | 热点数据有合理缓存策略，缓存击穿/雪崩有防护 | 一般 |
| 4.4 | 批量与循环 | 循环内无重复计算/重复查询，批量操作使用批量接口 | 一般 |

---

## 维度五：设计与架构

| # | 评审项 | 评审标准 | 等级 |
|---|--------|---------|------|
| 5.1 | 职责划分 | 类/模块职责单一，不出现上帝类或功能堆砌 | 一般 |
| 5.2 | 接口设计 | 接口粒度合理，遵循最小知识原则 | 一般 |
| 5.3 | 扩展性 | 新功能不破坏现有结构，符合开闭原则 | 一般 |
| 5.4 | 日志规范 | 关键操作有日志记录，日志级别使用恰当，不记录敏感信息 | 一般 |

---

## 维度六：规范与一致性

| # | 评审项 | 评审标准 | 等级 |
|---|--------|---------|------|
| 6.1 | 编码规范 | 缩进、命名、格式等符合团队编码规范 | 一般 |
| 6.2 | 提交规范 | Commit 信息清晰，单次提交改动范围合理 | 一般 |
| 6.3 | 配置管理 | 无硬编码配置值，敏感配置使用环境变量/配置中心 | 严重 |
SKILLEOF
    fi

    ok "skills 已创建"
}

# =====================================================================
#  生成函数：memory 知识库
# =====================================================================

generate_memory() {
    local target_dir="$1"
    local ptype="$2"
    local lang="$3"
    local backend="$4"
    local frontend="$5"
    local database="$6"
    local project_name="$7"
    local mode="$8"  # "single" / "workspace" / "subproject"

    local mem_dir="$target_dir/.claude/memory"
    mkdir -p "$mem_dir"

    # architecture.md
    if [ ! -f "$mem_dir/architecture.md" ]; then
        if [ "$mode" = "workspace" ]; then
            local proj_table=""
            for proj in "${SUBPROJECTS[@]}"; do
                IFS='|' read -r path name ptype2 lang2 backend2 frontend2 database2 build2 category2 <<< "$proj"
                local tech_desc="$lang2"
                [ -n "$backend2" ] && tech_desc+=" + $backend2"
                [ -n "$frontend2" ] && tech_desc+=" + $frontend2"
                proj_table+="- **$name** ($path): $tech_desc, 数据库: ${database2:-待填写}\n"
            done
            cat > "$mem_dir/architecture.md" << EOF
# 工作区架构文档

## 系统概述

$project_name 工作区，包含多个子项目。

## 子项目清单

$(echo -e "$proj_table")

## 架构关系

[待填写：子项目之间的调用关系、共享中间件、数据流向]

## 部署架构

[待填写：各子项目的部署方式、环境配置]

---

**最后更新:** $(date +%Y-%m-%d)
EOF
        else
            # 构建技术栈详情
            local tech_details=""
            if [ -n "$lang" ]; then tech_details+="  - 语言：$lang\n"; fi
            if [ -n "$backend" ]; then tech_details+="  - 框架：$backend\n"; fi
            if [ -n "$frontend" ]; then tech_details+="  - 前端框架：$frontend\n"; fi
            if [ -n "$DET_BUILD" ]; then tech_details+="  - 构建工具：$DET_BUILD\n"; fi
            if [ -n "$DET_JAVA_VERSION" ]; then tech_details+="  - Java 版本：$DET_JAVA_VERSION\n"; fi
            if [ -n "$DET_SPRING_VERSION" ]; then tech_details+="  - Spring Boot 版本：$DET_SPRING_VERSION\n"; fi
            if [ -n "$DET_GO_VERSION" ]; then tech_details+="  - Go 版本：$DET_GO_VERSION\n"; fi
            if [ -n "$DET_PYTHON_VERSION" ]; then tech_details+="  - Python 版本：$DET_PYTHON_VERSION\n"; fi
            if [ -n "$database" ]; then tech_details+="  - 数据库：$database\n"; fi
            if [ -n "$DET_ORM" ]; then tech_details+="  - ORM：$DET_ORM\n"; fi
            if [ -n "$DET_CACHE" ]; then tech_details+="  - 缓存：$DET_CACHE\n"; fi
            if [ -n "$DET_MQ" ]; then tech_details+="  - 消息队列：$DET_MQ\n"; fi

            local fe_details=""
            if [ -n "$DET_UI_LIB" ]; then fe_details+="  - UI 组件库：$DET_UI_LIB\n"; fi
            if [ -n "$DET_STATE_MGMT" ]; then fe_details+="  - 状态管理：$DET_STATE_MGMT\n"; fi
            if [ -n "$DET_CSS_FRAMEWORK" ]; then fe_details+="  - CSS 框架：$DET_CSS_FRAMEWORK\n"; fi
            if [ -n "$DET_LINT_TOOL" ]; then fe_details+="  - 代码检查：$DET_LINT_TOOL\n"; fi

            local test_info=""
            if [ -n "$DET_TEST_FRAMEWORK" ]; then test_info="  - 测试框架：$DET_TEST_FRAMEWORK\n"; fi
            if [ -n "$DET_API_DOC" ]; then test_info+="  - API 文档：$DET_API_DOC\n"; fi

            local dir_tree="${DET_DIR_TREE:-$(find "$target_dir" -maxdepth 3 -type d -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/target/*' -not -path '*/__pycache__/*' -not -path '*/.claude/*' 2>/dev/null | head -50 | sort)}"

            cat > "$mem_dir/architecture.md" << EOF
# 项目架构文档

## 系统概述

$project_name 项目

## 技术栈

$(if [ -n "$tech_details" ]; then echo -e "$tech_details"; else echo "[待填写]"; fi)
$(if [ -n "$fe_details" ]; then echo -e "### 前端工具链\n$fe_details"; fi)
$(if [ -n "$test_info" ]; then echo -e "### 开发工具\n$test_info"; fi)

## 目录结构

$(echo "$dir_tree" | sed 's/^/    /')

---

**最后更新:** $(date +%Y-%m-%d)
EOF
        fi
    fi

    # frontend-standards.md — 前端子项目或单项目
    if [ "$mode" != "workspace" ] && [ -n "$frontend" ] && [ ! -f "$mem_dir/frontend-standards.md" ]; then
        local fe_tool_info=""
        if [ -n "$DET_UI_LIB" ]; then fe_tool_info+="- UI 组件库：$DET_UI_LIB\n"; fi
        if [ -n "$DET_STATE_MGMT" ]; then fe_tool_info+="- 状态管理：$DET_STATE_MGMT\n"; fi
        if [ -n "$DET_CSS_FRAMEWORK" ]; then fe_tool_info+="- CSS 框架：$DET_CSS_FRAMEWORK\n"; fi
        if [ -n "$DET_LINT_TOOL" ]; then fe_tool_info+="- 代码检查：$DET_LINT_TOOL\n"; fi
        if [ -n "$DET_TEST_FRAMEWORK" ]; then fe_tool_info+="- 测试框架：$DET_TEST_FRAMEWORK\n"; fi

        cat > "$mem_dir/frontend-standards.md" << EOF
# 前端开发规范

## 技术工具链

$(if [ -n "$fe_tool_info" ]; then echo -e "$fe_tool_info"; else echo "[待填写]"; fi)

## 组件规范
- 组件文件名：PascalCase（如 UserList.vue / UserList.tsx）
- 组件内变量：camelCase
- 常量：UPPER_SNAKE_CASE

## 样式规范
- 使用 BEM 命名规范或 Scoped CSS
- 响应式断点：768px / 1024px

## API 调用规范
- 统一通过 api/ 目录下的模块调用
- 统一错误处理

---

**最后更新:** $(date +%Y-%m-%d)
EOF
    fi

    # backend-standards.md — 后端子项目或单项目
    if [ "$mode" != "workspace" ] && [ -n "$backend" ] && [ ! -f "$mem_dir/backend-standards.md" ]; then
        local layer_desc=""
        if echo "$ptype" | grep -q "java"; then
            layer_desc="- Controller 层：接收请求、参数校验
- Service 层：业务逻辑
- Mapper/DAO 层：数据访问"
        elif echo "$ptype" | grep -q "go"; then
            layer_desc="- Handler 层：接收请求
- Service 层：业务逻辑
- Repository 层：数据访问"
        elif echo "$ptype" | grep -q "python"; then
            layer_desc="- Router 层：路由定义
- Service 层：业务逻辑
- Model 层：数据模型"
        else
            layer_desc="- 接口层：接收请求
- 业务层：业务逻辑
- 数据层：数据访问"
        fi

        local be_tool_info=""
        if [ -n "$DET_ORM" ]; then be_tool_info+="- ORM：$DET_ORM\n"; fi
        if [ -n "$DET_TEST_FRAMEWORK" ]; then be_tool_info+="- 测试框架：$DET_TEST_FRAMEWORK\n"; fi
        if [ -n "$DET_API_DOC" ]; then be_tool_info+="- API 文档：$DET_API_DOC\n"; fi
        if [ -n "$DET_CACHE" ]; then be_tool_info+="- 缓存：$DET_CACHE\n"; fi
        if [ -n "$DET_MQ" ]; then be_tool_info+="- 消息队列：$DET_MQ\n"; fi

        cat > "$mem_dir/backend-standards.md" << EOF
# 后端开发规范

## 技术工具链

$(if [ -n "$be_tool_info" ]; then echo -e "$be_tool_info"; else echo "[待填写]"; fi)

## API 设计规范
- RESTful 风格
- 统一响应格式：{ code, message, data, timestamp }

## 代码分层规范

$layer_desc

## 数据库规范
- 表名：小写 + 下划线（如 user_profile）
- 必备字段：id, created_at, updated_at

## 异常处理
- 统一异常处理机制
- 日志规范：ERROR / WARN / INFO / DEBUG

---

**最后更新:** $(date +%Y-%m-%d)
EOF
    fi

    # business-logic.md — 非工作区级别
    if [ "$mode" != "workspace" ] && [ ! -f "$mem_dir/business-logic.md" ]; then
        cat > "$mem_dir/business-logic.md" << 'EOF'
# 业务逻辑说明

## 核心业务流程

[待填写：描述主要业务流程]

## 数据流向

前端页面 → API → Controller → Service → DAO → 数据库

## 权限控制

[待填写：角色和权限矩阵]

---

**最后更新:** 待填写
EOF
    fi

    # shared memory files for all modes
    if [ ! -f "$mem_dir/superpowers-config.md" ]; then
        cat > "$mem_dir/superpowers-config.md" << 'EOF'
# Superpowers 配置

## Skill 启用状态

| 阶段 | Skill | 状态 | 说明 |
|------|-------|------|------|
| 入口 | using-superpowers | enabled | 自动判断流程 |
| 设计 | brainstorming | conditional | 中等+复杂 |
| 规划 | writing-plans | conditional | 复杂任务 |
| 隔离 | using-git-worktrees | conditional | 复杂任务 |
| 执行 | subagent-driven-development | conditional | 复杂任务 |
| 测试 | test-driven-development | conditional | 中等+复杂 |
| 调试 | systematic-debugging | enabled | 遇到 bug 自动触发 |
| 审查 | requesting/receiving-code-review | conditional | 复杂任务 |
| 验证 | verification-before-completion | enabled | 完成前必验证 |
| 收尾 | finishing-a-development-branch | conditional | 中等+复杂 |

## 配置值

- enabled: 始终执行
- disabled: 始终跳过
- conditional: 按复杂度判断
- manual: 用户明确调用
EOF
    fi

    if [ ! -f "$mem_dir/learned-lessons.md" ]; then
        cat > "$mem_dir/learned-lessons.md" << 'EOF'
# 错误驱动的知识积累

> 每一条规则对应一个过去 AI 犯过的错误。Agent 犯错 → 加一条规则 → 以后不再犯同类错误。

## 编码错误

[待积累]

## 流程错误

[待积累]

## 架构错误

[待积累]

---

## 记录规则

- **触发条件：** AI 犯了一个新的、有代表性的错误（非偶然失误）
- **记录内容：** 错误现象 + 根因 + 规避规则 + 日期
- **后续动作：** 编码层面 → 更新 rules/；流程层面 → 更新 workflow 步骤
EOF
    fi

    if [ ! -f "$mem_dir/issues.md" ]; then
        cat > "$mem_dir/issues.md" << 'EOF'
# 问题记录

## 已解决问题

[待积累]

## 待解决问题

[待积累]

## 技术债务

[待积累]

---

**最后更新:** 待填写
EOF
    fi

    ok "memory 知识库已创建"
}

# =====================================================================
#  生成函数：MEMORY.md 索引
# =====================================================================

generate_memory_index() {
    local target_dir="$1"
    local mode="$2"

    if [ ! -f "$target_dir/.claude/MEMORY.md" ]; then
    if [ "$mode" = "workspace" ]; then
        cat > "$target_dir/.claude/MEMORY.md" << EOF
# 工作区知识库索引

## 工作区文档

- [工作区架构](memory/architecture.md) - 子项目清单和架构关系
- [Superpowers 配置](memory/superpowers-config.md) - Superpowers Skill 启用状态
- [错误积累](memory/learned-lessons.md) - AI 常犯错误和规避规则
- [问题记录](memory/issues.md) - 已解决和待解决问题

## 子项目文档

各子项目有独立的 memory/ 目录，cd 到对应子项目后可查看。

## 快速开始

1. 在工作区根目录：查看全局架构和规范
2. cd 到子项目：查看项目专属规范和业务逻辑
3. 跨项目开发：使用 \`/fullstack\` 协调

## 更新日志

- $(date +%Y-%m-%d): 初始化工作区知识库
EOF
    else
        cat > "$target_dir/.claude/MEMORY.md" << EOF
# 项目知识库索引

## 核心文档

- [项目架构](memory/architecture.md) - 系统架构和技术选型
- [前端规范](memory/frontend-standards.md) - 前端开发规范
- [后端规范](memory/backend-standards.md) - 后端开发规范和 API 设计标准
- [业务逻辑](memory/business-logic.md) - 核心业务流程和规则
- [Superpowers 配置](memory/superpowers-config.md) - Superpowers Skill 启用状态
- [错误积累](memory/learned-lessons.md) - AI 常犯错误和规避规则
- [问题记录](memory/issues.md) - 已解决和待解决问题

## 快速开始

1. 新成员：读 architecture.md → 读对应规范 → 读 business-logic.md
2. AI 助手：前端优先看 frontend-standards.md，后端优先看 backend-standards.md
3. Superpowers 配置：见 memory/superpowers-config.md

## 更新日志

- $(date +%Y-%m-%d): 初始化知识库
EOF
    fi
    fi
}

# =====================================================================
#  生成函数：辅助脚本
# =====================================================================
#  生成函数：流程定义文件
# =====================================================================

generate_workflow() {
    local target_dir="$1"
    local workflow_dir="$target_dir/.claude/workflow"

    mkdir -p "$workflow_dir"

    if [ ! -f "$workflow_dir/WORKFLOW-GUIDE.md" ]; then
    cat > "$workflow_dir/WORKFLOW-GUIDE.md" << 'WORKFLOWEOF'
# 流程定义指南

本文件定义了各工作流的标准阶段、角色分工、输入输出和流转规则。

## 后端标准流程

| 阶段 | 触发 Skill | 输入 | 输出 | 前进条件 | 可回退到 |
|------|-----------|------|------|---------|---------|
| 需求入口 | using-superpowers | 用户描述 | 复杂度判断 | 自动判定 | - |
| 需求澄清 | brainstorming | 复杂度 ≥ 中等 | specs/active/*.md | 用户确认 spec | 需求入口 |
| 方案设计 | writing-plans | 复杂度 = 复杂 | 任务计划 | 用户确认 | 需求澄清 |
| 实现 | executing-plans | spec + 计划 | DAO → Service → Controller | 构建+测试通过 | 方案设计 |
| 代码评审 | code-review | 复杂度 ≥ 中等 | 评审报告 | 无高危问题 | 实现 |
| 收尾 | finishing-branch | 验证通过 | spec 归档 | - | - |

## 通用规则

1. 下游不能修改上游产出（实现不能改 spec，只能打回）
2. 每个阶段必须有明确的"完成"定义
3. 连续 3 次回退到同一阶段，暂停由人决策
4. 验证是硬门禁 — 构建失败、测试失败、评审有高危，必须回退
5. spec 是唯一真相来源 — AI 从文件读约束，不靠聊天记录
WORKFLOWEOF
        ok "生成 workflow/WORKFLOW-GUIDE.md"
    fi
}

# =====================================================================

generate_scripts() {
    local target_dir="$1"
    local scripts_dir="$target_dir/.claude/scripts"
    mkdir -p "$scripts_dir"

    ok "scripts 已创建"
}

# =====================================================================
#  生成函数：CLAUDE.md
# =====================================================================

generate_claude_md_single() {
    local target_dir="$1"
    local ptype="$2"
    local lang="$3"
    local backend="$4"
    local frontend="$5"
    local database="$6"

    if [ -f "$target_dir/CLAUDE.md" ]; then
        info "CLAUDE.md 已存在，跳过"
        return
    fi

    cat > "$target_dir/CLAUDE.md" << CLAUDEEOF
# CLAUDE.md

## 技术栈

- 前端：${frontend:-待填写}
- 后端：${lang:-待填写} + ${backend:-待填写}
- 数据库：${database:-待填写}

## 核心原则：原生优先

简单任务（改变量、修 bug、写工具函数）直接说需求，不走 workflow。
复杂任务（新功能模块、多文件变更）才上 workflow 和 Spec。

> 90% 的场景用原生 Claude Code 就够了。过度工程化是最大的浪费。

## 开发铁律

1. **没设计不写代码** — 动手前先确认文件、范围、方案
2. **没测试不写代码** — 先写失败测试，再写实现
3. **没验证不说完成** — 必须运行验证命令并贴出结果

## 模式切换

| 命令 | 用途 |
|------|------|
| \`/frontend\` | 前端开发 |
| \`/backend\` | 后端开发 |
| \`/fullstack\` | 全栈协调 |

## 核心约束

- 后端分层：Controller → Service → DAO，禁止跨层
- 前端 API 调用走 \`api/\` 模块
- RESTful 统一响应：\`{ code, message, data, timestamp }\`
- 所有外部输入必须校验，不引入安全漏洞

## 文档地图

| 目录 | 用途 | 何时读 |
|------|------|--------|
| \`.claude/rules/\` | 自动触发的编码规则 | 编辑代码时自动生效 |
| \`.claude/skills/\` | 完整工作流编排 | 走 workflow 时按需加载 |
| \`.claude/memory/\` | 项目知识库（架构、规范、业务） | 需要项目上下文时引用 |
| \`.claude/specs/\` | 功能规格文档 | 中等+复杂任务时创建和引用 |
| \`.claude/scripts/\` | 初始化和验证脚本 | 新项目接入时使用 |

## 复杂度分级

| 级别 | 定义 | 策略 |
|------|------|------|
| 简单 | 单文件修改，< 30 分钟 | 原生，不走 workflow |
| 中等 | 新组件/新接口，30 分钟 - 2 小时 | brainstorming + spec + TDD |
| 复杂 | 新功能模块，> 2 小时 | 完整 workflow + spec + worktree + review |
CLAUDEEOF
    ok "CLAUDE.md 已创建"
}

generate_claude_md_workspace() {
    local target_dir="$1"

    if [ -f "$target_dir/CLAUDE.md" ]; then
        info "CLAUDE.md 已存在，跳过"
        return
    fi

    # 构建子项目表格
    local proj_table=""
    for proj in "${SUBPROJECTS[@]}"; do
        IFS='|' read -r path name ptype lang backend frontend database build category <<< "$proj"
        local tech_desc="${lang}"
        local framework=""
        [ -n "$backend" ] && framework="$backend"
        [ -n "$frontend" ] && framework="${framework:+$framework / }$frontend"
        proj_table+="| $name | \`$path\` | $tech_desc + $framework | $category |\n"
    done

    cat > "$target_dir/CLAUDE.md" << CLAUDEEOF
# CLAUDE.md — 工作区

## 工作区概览

本工作区包含多个子项目：

| 子项目 | 路径 | 技术栈 | 类型 |
|--------|------|--------|------|
$(echo -e "$proj_table")

## 核心原则：原生优先

简单任务（改变量、修 bug、写工具函数）直接说需求，不走 workflow。
复杂任务（新功能模块、多文件变更）才上 workflow 和 Spec。

> 90% 的场景用原生 Claude Code 就够了。过度工程化是最大的浪费。

## 开发铁律

1. **没设计不写代码** — 动手前先确认文件、范围、方案
2. **没测试不写代码** — 先写失败测试，再写实现
3. **没验证不说完成** — 必须运行验证命令并贴出结果

## 工作方式

- **单项目开发**: \`cd <子项目目录>\` 后直接说需求，加载该项目的专属配置
- **跨项目开发**: 在工作区根目录使用 \`/fullstack\` 协调
- 每个子项目有自己的 \`.claude/rules/\` 和 \`.claude/memory/\`

## 模式切换

| 命令 | 用途 |
|------|------|
| \`/frontend\` | 前端开发（显示前端子项目列表） |
| \`/backend\` | 后端开发（显示后端子项目列表） |
| \`/fullstack\` | 全栈协调 |

## 文档地图

| 目录 | 用途 | 何时读 |
|------|------|--------|
| \`.claude/rules/\` | 工作区级共享规则 | 全局生效 |
| \`.claude/commands/\` | 工作区级共享命令 | 全局可用 |
| \`.claude/memory/\` | 工作区级知识库 | 全局架构 |
| \`<子项目>/.claude/\` | 子项目专属配置 | cd 到子项目时生效 |

## 复杂度分级

| 级别 | 定义 | 策略 |
|------|------|------|
| 简单 | 单文件修改，< 30 分钟 | 原生，不走 workflow |
| 中等 | 新组件/新接口，30 分钟 - 2 小时 | brainstorming + spec + TDD |
| 复杂 | 新功能模块，> 2 小时 | 完整 workflow + spec + worktree + review |
CLAUDEEOF
    ok "工作区 CLAUDE.md 已创建"
}

generate_claude_md_subproject() {
    local target_dir="$1"
    local proj_name="$2"
    local lang="$3"
    local backend="$4"
    local frontend="$5"
    local database="$6"

    if [ -f "$target_dir/CLAUDE.md" ]; then
        info "子项目 $proj_name 的 CLAUDE.md 已存在，跳过"
        return
    fi

    cat > "$target_dir/CLAUDE.md" << CLAUDEEOF
# CLAUDE.md — $proj_name

## 技术栈

- 语言：${lang}
- 框架：${backend}${frontend:+ / }${frontend}
- 数据库：${database:-待填写}

## 本项目规范

- 详见 \`.claude/rules/\` 下的技术栈专属规则
- 详见 \`.claude/memory/\` 下的项目知识库

## 核心约束

- 严格分层，禁止跨层调用
- 统一响应格式：\`{ code, message, data, timestamp }\`
- 所有外部输入必须校验，不引入安全漏洞

## 所属工作区

- 本项目属于上层工作区，全局配置见上层 \`.claude/\`
CLAUDEEOF
    ok "子项目 $proj_name CLAUDE.md 已创建"
}

# =====================================================================
#  生成函数：README
# =====================================================================

generate_readme() {
    local target_dir="$1"
    local mode="$2"
    local ptype="$3"
    local lang="$4"

    if [ -f "$target_dir/.claude/README.md" ]; then
        return
    fi

    cat > "$target_dir/.claude/README.md" << EOF
# Claude Code AI 辅助开发配置

## 模式
$([ "$mode" = "workspace" ] && echo "工作区模式（多项目）" || echo "单项目模式")

## 项目信息
- 名称：${WORKSPACE_NAME}
- 类型：${ptype:-generic}
- 语言：${lang:-通用}

## 架构说明

| 目录 | 用途 | 触发方式 |
|------|------|----------|
| \`CLAUDE.md\` | 项目最高优先级指令 | 自动加载 |
| \`commands/\` | 斜杠命令（模式切换） | 用户输入 \`/\` 前缀 |
| \`rules/\` | 条件规则（自动触发） | 编辑代码时自动生效 |
| \`skills/\` | 工作流技能 | 用户 \`/skill-name\` 调用 |
| \`memory/\` | 项目知识库 | 被规则和命令引用 |

$([ "$mode" = "workspace" ] && echo "各子项目有自己的 \`.claude/\` 目录，cd 到子项目后自动加载专属配置。" || echo "")

## 使用方式

| 命令 | 说明 |
|------|------|
| \`/frontend\` | 前端开发模式 |
| \`/backend\` | 后端开发模式 |
| \`/fullstack\` | 全栈协调模式 |

## 验证配置

\`\`\`bash
apprentice doctor
\`\`\`

---

**初始化日期:** $(date +%Y-%m-%d)
EOF
}

# =====================================================================
#  生成函数：spec 目录和指南
# =====================================================================

generate_spec_structure() {
    local target_dir="$1"
    mkdir -p "$target_dir/.claude/specs/active"
    mkdir -p "$target_dir/.claude/specs/archived"
    mkdir -p "$target_dir/.claude/reports"

    if [ ! -f "$target_dir/.claude/specs/SPEC-GUIDE.md" ]; then
        cat > "$target_dir/.claude/specs/SPEC-GUIDE.md" << 'EOF'
# Spec 使用指南

## 生命周期

Propose（提案）→ Apply（实施）→ Archive（归档）

## 文件模板

```markdown
# [功能名称] 规格

## 状态
Proposed | Applied | Completed

## 需求概述
[一句话描述]

## 涉及文件
- 新增：[文件路径]
- 修改：[文件路径]

## 接口定义（如涉及 API）
- 路径、方法、请求参数、响应格式

## 约束条件
- [硬性约束]

## 验收标准
- [ ] 标准 1
- [ ] 标准 2

## 变更记录
| 日期 | 变更内容 |
|------|---------|
| YYYY-MM-DD | 初始提案 |
```

## 目录说明

- `active/` — 进行中的 spec
- `archived/` — 已完成的 spec（活文档，不删除）
EOF
    fi
}

# =====================================================================
#  主流程：单项目模式（向后兼容）
# =====================================================================

init_single_project() {
    step "单项目模式初始化"
    echo ""

    # 步骤1: 检测项目类型
    info "检测项目类型..."
    if ! detect_project "."; then
        warn "未检测到已知项目类型，将创建通用模板"
        DET_PTYPE="generic"
        DET_LANG="通用"
        DET_BACKEND=""
        DET_FRONTEND=""
        DET_DATABASE=""
        DET_BUILD=""
    else
        detect_project_details "." "$DET_PTYPE"
    fi

    PROJECT_NAME="$WORKSPACE_NAME"
    echo "  名称: $PROJECT_NAME"
    echo "  类型: $DET_PTYPE"
    echo "  语言: $DET_LANG"
    [ -n "$DET_BACKEND" ] && echo "  后端: $DET_BACKEND"
    [ -n "$DET_FRONTEND" ] && echo "  前端: $DET_FRONTEND"
    [ -n "$DET_DATABASE" ] && echo "  数据库: $DET_DATABASE"
    [ -n "$DET_ORM" ] && echo "  ORM: $DET_ORM"
    [ -n "$DET_UI_LIB" ] && echo "  UI 组件库: $DET_UI_LIB"
    [ -n "$DET_STATE_MGMT" ] && echo "  状态管理: $DET_STATE_MGMT"
    [ -n "$DET_TEST_FRAMEWORK" ] && echo "  测试: $DET_TEST_FRAMEWORK"
    [ -n "$DET_CACHE" ] && echo "  缓存: $DET_CACHE"
    [ -n "$DET_MQ" ] && echo "  消息队列: $DET_MQ"
    echo ""

    # 步骤2: 检查已有配置
    if [ -d ".claude" ]; then
        info "检测到已有 .claude/ 目录，增量更新（补全缺失项）"
    fi

    # 步骤3: 创建目录
    step "创建目录结构..."
    mkdir -p .claude/{skills,memory,scripts,commands,rules,specs/active,specs/archived,reports}
    ok "目录创建完成"

    # 步骤4: 生成配置
    step "生成配置文件..."
    generate_settings "." "false"

    # 步骤5: 生成 CLAUDE.md
    step "生成 CLAUDE.md..."
    generate_claude_md_single "." "$DET_PTYPE" "$DET_LANG" "$DET_BACKEND" "$DET_FRONTEND" "$DET_DATABASE"

    # 步骤6: 生成命令
    step "生成 commands..."
    generate_commands "." "single" "" ""

    # 步骤7: 生成 rules
    step "生成 rules..."
    generate_shared_rules "."
    generate_tech_rules "." "$DET_PTYPE"

    # 步骤8: 生成 skills
    step "生成 skills..."
    generate_skills "."

    # 步骤9: 生成知识库
    step "生成知识库..."
    generate_memory "." "$DET_PTYPE" "$DET_LANG" "$DET_BACKEND" "$DET_FRONTEND" "$DET_DATABASE" "$PROJECT_NAME" "single"
    generate_memory_index "." "single"

    # 步骤10: 生成辅助
    step "生成辅助脚本..."
    generate_scripts "."
    generate_spec_structure "."
    generate_workflow "."
    generate_readme "." "single" "$DET_PTYPE" "$DET_LANG"

    # 完成
    echo ""
    echo "========================================"
    ok "初始化完成！"
    echo "========================================"
    echo ""
    echo "已创建："
    echo "  [OK] CLAUDE.md           — 项目指令"
    echo "  [OK] .claude/commands/   — 3 个斜杠命令"
    echo "  [OK] .claude/rules/      — 共享 + 技术栈专属规则"
    echo "  [OK] .claude/skills/     — 3 个工作流技能"
    echo "  [OK] .claude/memory/     — 知识库模板"
    echo ""
    echo "下一步："
    echo "  1. 根据项目实际情况填写 memory/ 下的模板内容"
    echo "  2. 运行 apprentice doctor 验证健康状态"
    echo "  3. 在 Claude Code 中试试 /frontend 或 /backend"
    echo ""
    echo "项目类型: $DET_PTYPE | 语言: $DET_LANG"
}

# =====================================================================
#  主流程：工作区模式
# =====================================================================

init_workspace() {
    step "工作区模式初始化"
    echo ""

    # 扫描子项目
    scan_subprojects
    print_scan_results

    if [ ${#SUBPROJECTS[@]} -eq 0 ]; then
        fail "未检测到任何项目，无法初始化工作区"
    fi

    if [ ${#SUBPROJECTS[@]} -eq 1 ]; then
        # 只有一个项目且在根目录，走单项目模式
        local root_only=true
        for proj in "${SUBPROJECTS[@]}"; do
            IFS='|' read -r path _ _ _ _ _ _ _ _ <<< "$proj"
            if [ "$path" != "." ]; then
                root_only=false
                break
            fi
        done
        if $root_only; then
            info "只检测到根目录一个项目，切换到单项目模式"
            echo ""
            init_single_project
            return
        fi
    fi

    # 确认
    echo "将为工作区创建全局配置，并为每个子项目创建专属配置。"
    read -p "确认继续？[Y/n] " confirm
    [[ "${confirm:-Y}" =~ ^[Nn] ]] && { info "已取消"; exit 0; }

    # 检查已有配置
    if [ -d ".claude" ]; then
        info "检测到已有 .claude/ 目录，增量更新（补全缺失项）"
    fi

    # ===== 工作区级配置 =====
    echo ""
    step "创建工作区级配置..."
    echo ""

    mkdir -p .claude/{skills,memory,scripts,commands,rules,specs/active,specs/archived,reports}

    # 工作区 settings
    generate_settings "." "true"

    # 工作区 CLAUDE.md
    generate_claude_md_workspace "."

    # 工作区 commands
    generate_commands "." "workspace" "" ""

    # 工作区 rules（共享规则）
    generate_shared_rules "."

    # 工作区 skills
    generate_skills "."

    # 工作区 memory
    generate_memory "." "" "" "" "" "" "$WORKSPACE_NAME" "workspace"
    generate_memory_index "." "workspace"

    # 工作区 scripts
    generate_scripts "."
    generate_spec_structure "."
    generate_workflow "."
    generate_readme "." "workspace" "workspace" "multi"

    ok "工作区级配置完成"

    # ===== 子项目配置 =====
    echo ""
    step "创建子项目专属配置..."
    echo ""

    local sub_count=0
    for proj in "${SUBPROJECTS[@]}"; do
        IFS='|' read -r path name ptype lang backend frontend database build category <<< "$proj"

        # 跳过根目录本身（如果根目录也是一个项目，它的配置已在工作区级处理）
        if [ "$path" = "." ]; then
            info "根目录 $name 作为工作区根，跳过独立初始化"
            continue
        fi

        step "初始化子项目: $name ($category)"
        mkdir -p "$path/.claude/rules" "$path/.claude/memory" "$path/.claude/specs/active" "$path/.claude/specs/archived"

        # 深度检测子项目
        detect_project_details "$path" "$ptype"

        # 子项目 CLAUDE.md
        generate_claude_md_subproject "$path" "$name" "$lang" "$backend" "$frontend" "$database"

        # 子项目 settings（轻量版）
        if [ ! -f "$path/.claude/settings.json" ]; then
            local proj_perms=""
            if echo "$ptype" | grep -q "java"; then
                proj_perms="\"Bash(mvn *)\", \"Bash(gradle *)\","
            elif echo "$ptype" | grep -q "^go"; then
                proj_perms="\"Bash(go *)\","
            elif echo "$ptype" | grep -q "python"; then
                proj_perms="\"Bash(python *)\", \"Bash(pip *)\","
            fi
            if [ -f "$path/package.json" ]; then
                proj_perms="${proj_perms}\"Bash(npm *)\", \"Bash(node *)\","
            fi
            cat > "$path/.claude/settings.json" << SUBSETTINGEOF
{
  "language": "chinese",
  "permissions": {
    "allow": [
      ${proj_perms}
      "Bash(git show *)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(git diff-tree *)",
      "Read(*)",
      "Edit(*)",
      "Write(*)"
    ],
    "deny": [
      "Bash(git push --force)",
      "Bash(rm -rf *)"
    ]
  }
}
SUBSETTINGEOF
        fi

        # 子项目 rules（技术栈专属）
        generate_tech_rules "$path" "$ptype"

        # 子项目 memory
        generate_memory "$path" "$ptype" "$lang" "$backend" "$frontend" "$database" "$name" "subproject"

        # 子项目 specs
        generate_spec_structure "$path"

        sub_count=$((sub_count + 1))
        ok "子项目 $name 配置完成"
        echo ""
    done

    # ===== 完成 =====
    echo "========================================"
    ok "工作区初始化完成！"
    echo "========================================"
    echo ""
    echo "已创建："
    echo "  [OK] 工作区全局 .claude/  — 共享规则、命令、知识库"
    echo "  [OK] ${sub_count} 个子项目专属 .claude/ — 技术栈专属规则和知识库"
    echo ""
    echo "工作方式："
    echo "  1. cd <子项目目录> → 直接说需求（加载项目专属配置）"
    echo "  2. 在工作区根目录 → 使用 /frontend 或 /backend 查看子项目列表"
    echo "  3. 跨项目开发 → 在工作区根目录使用 /fullstack"
    echo ""
    echo "下一步："
    echo "  1. 填写各子项目 memory/ 下的模板内容"
    echo "  2. 运行 apprentice doctor 验证健康状态"
}

# =====================================================================
#  主流程：子项目单独初始化
# =====================================================================

init_single_subproject() {
    local dir="$1"

    if [ ! -d "$dir" ]; then
        fail "目录不存在: $dir"
    fi

    cd "$dir"
    local proj_name=$(basename "$(pwd)")

    step "子项目初始化: $proj_name"
    echo ""

    if ! detect_project "."; then
        fail "未在 $proj_name 中检测到项目标记文件"
    fi

    detect_project_details "." "$DET_PTYPE"

    echo "  名称: $proj_name"
    echo "  类型: $DET_PTYPE"
    echo "  语言: $DET_LANG"
    [ -n "$DET_BACKEND" ] && echo "  后端: $DET_BACKEND"
    [ -n "$DET_FRONTEND" ] && echo "  前端: $DET_FRONTEND"
    [ -n "$DET_DATABASE" ] && echo "  数据库: $DET_DATABASE"
    echo ""

    mkdir -p .claude/{rules,memory,specs/active,specs/archived}

    generate_claude_md_subproject "." "$proj_name" "$DET_LANG" "$DET_BACKEND" "$DET_FRONTEND" "$DET_DATABASE"
    generate_tech_rules "." "$DET_PTYPE"
    generate_memory "." "$DET_PTYPE" "$DET_LANG" "$DET_BACKEND" "$DET_FRONTEND" "$DET_DATABASE" "$proj_name" "subproject"
    generate_spec_structure "."

    echo ""
    ok "子项目 $proj_name 初始化完成"
}

# =====================================================================
#  主入口
# =====================================================================

info "目标目录: $TARGET_DIR"
echo ""

case "$MODE" in
    scan)
        scan_subprojects
        print_scan_results
        ;;
    workspace)
        init_workspace
        ;;
    project)
        init_single_subproject "$PROJECT_DIR"
        ;;
    auto)
        # 自动检测模式
        scan_subprojects

        # 判断：单项目 or 多项目
        AUTO_ROOT_ONLY=false
        if [ ${#SUBPROJECTS[@]} -eq 1 ]; then
            IFS='|' read -r path _ _ _ _ _ _ _ _ <<< "${SUBPROJECTS[0]}"
            [ "$path" = "." ] && AUTO_ROOT_ONLY=true
        fi

        if $AUTO_ROOT_ONLY || [ ${#SUBPROJECTS[@]} -eq 0 ]; then
            # 单项目或无项目 — 走原有单项目流程
            init_single_project
        else
            # 多项目 — 走工作区流程
            print_scan_results
            echo "检测到多个子项目，进入工作区模式。"
            echo "如需单项目模式，请使用: init.sh --project <目录>"
            echo ""
            init_workspace
        fi
        ;;
esac
