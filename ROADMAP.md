# WasmPatch Roadmap

本路线图聚焦两件事：先把**体验 / 易用性**做上去（见效快），再系统性地补齐 **Swift 应用支持**。
每个任务都标注了对应的代码落点，便于逐项推进。状态约定：`[ ]` 待办 / `[~]` 进行中 / `[x]` 完成。

> 进度（feat/usability-and-swift-support 分支）：Track A 的 A1/A2/A3/A4 与 Track B 的 B1/B4/B5 已落地，
> A5 远程下发已端到端验证；B3 已支持回调收到的 block（invoke_block）；B2 以桥接+文档形式覆盖。
> 验证状态见每项 "验收" 与 PR 描述的验证矩阵。

> 现状基线（制定计划时的事实，供后续验证用）：
> - 方法替换走 libffi closure 替换 IMP（`wap_objc_method_bridge.mm`），调用走 `NSInvocation` + 类型编码（`core/runtime/export/wap_objc_export_call.h`）。
> - struct（`'{'`）在签名解析、参数构造、调用三处均为 TODO。
> - block（`@?`）解析了但未处理；可变参数明确不支持。
> - 补丁用 C 编写，靠 `my_instance_<Class>_<sel>` 字符串命名约定手工对齐，无编译期校验；内存需手动 `dealloc_object`。
> - 工具链依赖 `brew llvm` + `wasm-ld` + `wabt`；`WAPDefine.h` 需手动拷贝；仅支持 CocoaPods，无 SPM。

---

## Track A — 体验 / 易用性（优先，先做）

目标：让"写一个补丁 → 编译 → 加载 → 验证"这条链路尽量少踩坑、少手工步骤。

### A1. 补丁作者 API：宏 DSL + 自动释放 — ✅ 完成（已验证）
痛点：手工命名 `my_instance_ReplaceMe_request` 容易写错；`>2` 参数要手搓数组；`dealloc_object` 容易漏。

- [x] 在 `WAPDefine.h` 增加替换声明宏，自动生成规范命名的导出函数：
      `WAP_REPLACE_INSTANCE(ReplaceMe, request, body...)` / `WAP_REPLACE_CLASS(...)`。
- [x] 增加 `call_class_method_3/4` 与可变参便捷宏，避免手工 `alloc_array`/`append_array`。
- [x] 引入 scope/arena 自动释放语义（如 `WAP_AUTORELEASE_SCOPE { ... }`），减少手工 `dealloc_object`。
- [x] 更新 `TestCase/.../objc.c` 与 README 示例使用新宏。
- 验收：用新宏重写现有 testcase，行为与旧版一致（`compile-testcase.sh` + 验证脚本通过）。

### A2. 一键工具链 / CLI — ✅ 完成（已验证）
痛点：依赖分散、`WAPDefine.h` 手抄、产物元数据要手算。

- [x] 把 `Tool/build-patch.sh` 包一层 `wasmpatch` CLI（或增强脚本）：自动定位 LLVM、自动 `-include` SDK 头、自动输出 `.wasm` + 元数据 `JSON`（sha256、字节数、目标 app/OS 版本占位）。
- [x] `WAPDefine.h` 作为 SDK 头随产物分发，作者无需手抄（脚本自动注入 include path）。
- [x] 工具链自检命令：检查 `clang --target=wasm32`、`wasm-ld`、`wasm2wat` 是否就绪，缺失时给出明确修复指引。
- 验收：在干净环境跑通"一条命令从 .c 到带元数据的 .wasm"。

### A3. 加载期校验与可观测性 — ✅ 完成（已验证）
痛点：`__call_objc_method_param` 等失败仅 `std::cout` + `return 0`，宿主侧无感知。

- [x] 加载时预校验：补丁中 `replace_*` 引用的类 / selector 是否存在、签名是否可桥接，提前报错。
- [x] dry-run / inspect 模式：列出补丁将 hook 的方法清单与签名匹配结果（CLI + 运行时各一份）。
- [x] 给 `WAPPatchLoader` 增加日志 / 错误回调钩子，将 runtime 错误透出到宿主（接 APM）。
- [x] 把内部 `std::cout` 错误改为可被 `wap_last_error()` 捕获的结构化错误。
- 验收：故意写错类名/selector，加载阶段即报出明确错误。

### A4. 集成方式现代化（SPM）— ✅ 完成（swift build 通过）
- [x] 增加 Swift Package 支持（与现有 podspec 并存），暴露 `WasmPatch` 模块。
- [x] SPM 集成文档 + 最小示例。
- 验收：一个空 SPM 工程能 `import WasmPatch` 并成功加载一个补丁。
- 备注：此项是 Track B（Swift 接入）的前置条件。

### A5. 远程下发闭环 — ✅ 已验证（HTTP 拉取→sha256 校验→缓存→应用，端到端）
- [ ] 拉取 → 签名校验（非对称，强于当前 sha256）→ 落盘缓存 → 启动按 app 版本/灰度应用 → 失败回滚。
- [ ] 单补丁禁用/回滚（当前 `reset` 为全量重置）。
- 备注：价值高但工作量大，排在体验基础项之后。

---

## Track B — Swift 应用支持

核心约束：当前桥基于 Obj-C 消息派发，**纯 Swift（静态/vtable 派发）方法无法 hook**。需先打通"可 hook 边界 + 值/结构体桥接"，再做接入体验。

### B1. struct 桥接 — ✅ 完成（几何结构体 + 通用任意结构体 alloc_struct/字段读写，已验证往返）
现状：`'{'` 在 `ObjcMethodSignature::parse/ffitypeFromTypeEncoding`、`CreateObjectFromObjcTypeEncoding`、`__call_objc_method_param` 三处全为 TODO。

- [x] 用 libffi 构造 struct 的 `ffi_type`，先覆盖高频结构体：`CGRect/CGPoint/CGSize/NSRange/CGAffineTransform/UIEdgeInsets`。
- [x] 参数方向：wasm → Obj-C 的 struct 入参打包（`__call_objc_method_param` 的 `'{'` 分支）。
- [x] 返回方向：Obj-C → wasm 的 struct 返回（`write_replacement_result` 与调用返回路径）。
- [x] 替换方向：被替换方法签名含 struct 时的 closure 编组（`binding_objc_method`）。
- [x] 新增 struct 往返 testcase。
- 验收：替换/调用一个含 `CGRect` 参数与返回值的方法并断言数值正确。

### B2. Swift 值类型 / 字符串桥接 — 🟢 既有路径覆盖 + 文档（SWIFT.md）
- [ ] 覆盖 `@objc dynamic` 方法签名中常见的 Swift→ObjC 桥接类型：`String`↔`NSString`、`Bool`、`Int`、`Double`、`Optional`（nil 处理）。
- [ ] 在 `CreateObjectFromObjcTypeEncoding` 与调用编组路径补齐相应类型分支与测试。
- 验收：替换一个参数/返回为 Swift `String`、`Bool`、`Int` 的 `@objc dynamic` 方法成功。

### B3. block / 闭包桥接 — 🟢 已支持回调被替换方法收到的 block（invoke_block，已验证）；wasm 侧创建 block 仍未做
现状：`@?` 已解析但未处理。现代 Swift API 大量使用 completion handler。

- [ ] Obj-C block 作为入参传入 wasm（至少支持调用回去的能力）。
- [ ] wasm 侧构造 block 作为参数回传（用于 completion handler 场景）。
- [ ] 新增异步回调 testcase。
- 验收：替换一个带 completion block 的方法并能正确触发回调。

### B4. 可 hook 边界：文档 + 扫描工具 — ✅ 完成（SWIFT.md + Tool/scan-hookable.sh，已验证）
- [x] 文档化规则：仅 `@objc dynamic` 方法可替换；类名需模块限定 `"Module.Class"`；类需 `@objc`/`NSObject` 子类。
- [x] 构建期扫描工具：分析产物，输出"可被 WasmPatch 替换"的方法白名单；对不可 hook 的目标给出明确提示。
- 验收：对一个示例 Swift 工程输出可 hook 方法清单。

### B5. Swift 接入体验 + Demo — ✅ SPM Swift 示例端到端 hook 了 @objc dynamic 方法（已验证）；独立 Xcode GUI app 仍待补
- [ ] 在 SPM（A4）基础上提供 Swift 封装：`async`/`throws` 风格的加载 API。
- [ ] 新增 Swift 宿主 Demo（现有 iOS/macOS Demo 均为 `.mm`）。
- [ ] 新增 Swift TestCase 类（对标现有 `CallMe`/`ReplaceMe`），覆盖 `@objc dynamic` 替换、struct 传参、闭包回调。
- 验收：Swift Demo 中加载补丁并验证三类场景跑通。

---

## 建议推进顺序

1. **A1 → A2 → A3**（体验三件套，快速见效，且为后续 Swift 调试打基础）
2. **A4**（SPM，Swift 接入前置）
3. **B1 struct**（运行时收益最高，Swift / 复杂 ObjC 共同瓶颈）
4. **B2 → B3**（Swift 值类型与闭包桥接）
5. **B4 → B5**（边界文档/扫描 + Swift Demo 与测试）
6. **A5**（远程下发闭环，价值高、工作量大，最后做）

> 每个里程碑保持小步可回归：改运行时必配 testcase，改命令/行为同步更新 README 与 AGENT.md（见 AGENT.md 的 PR Checklist）。
