# Ansilust Development Guidelines

This document provides comprehensive guidelines for developing the ansilust project, a next-generation text art processing system written in Zig. These guidelines ensure systematic development, type safety, memory safety, and adherence to Zig best practices.

## Project Overview

Ansilust is a modular text art processing system inspired by ansilove, built with Zig for performance, safety, and correctness. The project consists of:

- **ansilust-ir**: Intermediate representation for unified text art formats
- **Parsers**: BBS Art Parser, UTF8ANSI Parser (output IR)
- **Renderers**: UTF8ANSI Renderer, HTML Canvas Renderer (read IR)

## Specifications Directory

All major features and enhancements follow a structured spec-driven development approach documented in the `.specs/` directory.

### Structure

Each feature specification follows a standardized structure within its own directory:

- **`instructions.md`** - Initial requirements capture and user story
- **`requirements.md`** - Detailed functional and non-functional requirements
- **`design.md`** - Technical design and architectural decisions
- **`plan.md`** - Implementation roadmap with progress tracking

### 🚨 CRITICAL FILE DISCIPLINE 🚨

**ONLY create the four standard files above unless explicitly instructed otherwise.**

**FORBIDDEN Files** (do not create unless explicitly requested):
- ❌ `README.md` - Information belongs in the standard phase files
- ❌ `ARCHITECTURE.md` - Architecture details belong in `design.md`
- ❌ `DESIGN_DECISIONS.md` - Design decisions belong in `design.md`
- ❌ `NOTES.md`, `SUMMARY.md`, `OVERVIEW.md` - Content belongs in appropriate phase file
- ❌ Any other non-standard files

**Rationale**: 
- The four standard files provide complete coverage of all specification needs
- Additional files fragment information and make specs harder to navigate
- Standard structure ensures consistency across all features
- All design decisions, architecture, summaries, and notes fit naturally within the standard files

**When to use each standard file**:
- `instructions.md` - User stories, initial requirements, acceptance criteria
- `requirements.md` - Formal EARS requirements, constraints, success criteria
- `design.md` - Architecture, data structures, algorithms, design decisions, API surface
- `plan.md` - Implementation tasks, progress tracking, validation checkpoints

### Workflow

The specification-driven development process follows three key phases:

#### 1. Specification Phase
Document requirements, design architecture, and create detailed implementation plans before beginning development work.

#### 2. Implementation Phase
Execute the planned implementation following Zig best practices and safety standards, with continuous validation against specifications.

#### 3. Validation Phase
Verify that the final implementation meets all specified requirements and maintains Zig standards for memory safety, compile-time correctness, and comprehensive testing.

---

## New Feature Development - Ansilust

### 🚨 MANDATORY SPEC-DRIVEN DEVELOPMENT 🚨

This workflow enforces a rigorous **5-phase development process** for substantial new features in the ansilust project. This process ensures systematic development, comprehensive documentation, and alignment with Zig best practices.

#### ⚠️ IMPORTANT SCOPE LIMITATION
This workflow is **ONLY** for substantial new features. For other types of work:
- **Bug fixes**: Use standard development workflow
- **Refactoring**: Direct implementation with validation
- **Documentation enhancement**: Update doc comments and regenerate docs
- **Test fixes**: Fix and validate immediately

#### 🔒 AUTHORIZATION PROTOCOL
- **MANDATORY USER AUTHORIZATION** required between each phase
- **NEVER proceed** to next phase without explicit user approval
- **PRESENT completed work** from current phase before requesting authorization
- **WAIT for clear user confirmation** before continuing

---

### 📋 PHASE STRUCTURE

#### Phase 1: Instructions Phase
**Objective**: Capture initial requirements and user story

**Deliverables**:
- Create feature branch: `feature/[feature-name]`
- Create `.specs/[feature-name]/` directory
- Create **ONLY** `instructions.md` with:
  - Overview and User Story
  - Core Requirements (written in EARS notation when applicable)
  - Technical Specifications
  - Acceptance Criteria (using EARS patterns)
  - Out of Scope items
  - Success Metrics
  - Future Considerations
  - Testing Requirements

**EARS Notation Introduction**:
Begin using EARS (Easy Approach to Requirements Syntax) patterns for clarity:
- **Ubiquitous**: "The system shall [requirement]"
- **Event-driven**: "WHEN [trigger/event] the system shall [requirement]"
- **State-driven**: "WHILE [in state] the system shall [requirement]"
- **Unwanted**: "IF [condition] THEN the system shall [requirement]"
- **Optional**: "WHERE [feature included] the system shall [requirement]"

**Example EARS Requirements**:
```
The component shall validate all input parameters.
WHEN an error condition occurs the system shall log diagnostic information.
WHILE in processing mode the system shall maintain state consistency.
IF invalid input is detected THEN the component shall return an appropriate error.
WHERE feature X is enabled the system shall apply additional validation.
```

**🚨 FILE DISCIPLINE CHECK**:
- [ ] Only `instructions.md` exists in `.specs/[feature-name]/`
- [ ] No additional files created (README, ARCHITECTURE, NOTES, etc.)
- [ ] All content fits within instructions.md structure

**🔒 AUTHORIZATION GATE**: Present instructions.md and request user approval to proceed to Requirements Phase

---

#### Phase 2: Requirements Phase
**Objective**: Structured analysis and formal specifications using EARS notation

**Deliverables**:
- Create **ONLY** `requirements.md` with hierarchical numbering and EARS notation:
  - **FR1.x**: Functional Requirements (EARS notation MANDATORY)
  - **NFR2.x**: Non-Functional Requirements (performance, memory usage)
  - **TC3.x**: Technical Constraints (Zig version, dependencies)
  - **DR4.x**: Data Requirements (structures, formats)
  - **IR5.x**: Integration Requirements
  - **DEP6.x**: Dependencies
  - **SC7.x**: Success Criteria

**🚨 MANDATORY EARS Notation Guidelines**:

All functional requirements (FR1.x) **MUST** use EARS patterns. Choose the appropriate pattern:

**1. Ubiquitous Requirements** (always active, no preconditions):
```
FR1.1: The component shall validate input parameters before processing.
FR1.2: The system shall provide a public API for all core operations.
FR1.3: The module shall support the required data types and structures.
```

**2. Event-Driven Requirements** (triggered by specific events):
```
FR1.4: WHEN the component detects specific input conditions the system shall handle them appropriately.
FR1.5: WHEN an allocation fails the system shall return error.OutOfMemory.
FR1.6: WHEN processing completes the system shall invoke registered callbacks.
```

**3. State-Driven Requirements** (active during specific states):
```
FR1.7: WHILE in special mode the system shall apply mode-specific behavior.
FR1.8: WHILE processing specific data types the system shall use appropriate algorithms.
FR1.9: WHILE the allocator is active the system shall track all allocations.
```

**4. Unwanted Behavior Requirements** (error/exception handling):
```
FR1.10: IF input contains invalid UTF-8 THEN the parser shall return error.InvalidEncoding.
FR1.11: IF buffer overflow is detected THEN the system shall abort with error.BufferTooSmall.
FR1.12: IF a required dependency is missing THEN initialization shall fail with error.MissingDependency.
```

**5. Optional Feature Requirements** (conditional on feature flags):
```
FR1.13: WHERE feature X is enabled the component shall provide extended functionality.
FR1.14: WHERE advanced mode is supported the system shall maintain required state.
FR1.15: WHERE debug mode is active the system shall emit detailed trace logs.
```

**EARS Anti-Patterns to Avoid**:
- ❌ Vague: "The system should handle errors properly"
- ❌ Ambiguous: "The component may support feature X"
- ❌ Implementation: "The system shall use a HashMap for storage"
- ❌ Combined: "The system shall process and output data"

**EARS Best Practices**:
- ✅ One requirement per statement
- ✅ Use "shall" (mandatory), never "should" or "may"
- ✅ Be specific and measurable
- ✅ Focus on WHAT, not HOW (save implementation for design phase)
- ✅ Make preconditions explicit (WHEN/WHILE/IF/WHERE)
- ✅ Define observable behavior, not internal implementation

**Example Complete Requirements Section**:
```markdown
## FR1: Functional Requirements

### FR1.1: Input Handling
FR1.1.1: The component shall accept required input types.
FR1.1.2: WHEN input size exceeds defined limits the component shall return an appropriate error.
FR1.1.3: The component shall validate input according to specifications.

### FR1.2: Core Processing
FR1.2.1: WHEN specific conditions are met the system shall perform required operations.
FR1.2.2: The component shall validate data integrity during processing.
FR1.2.3: IF validation fails THEN the component shall handle the error gracefully.

### FR1.3: Error Handling
FR1.3.1: IF memory allocation fails THEN the system shall return error.OutOfMemory.
FR1.3.2: The system shall release all resources on error paths.
FR1.3.3: WHEN an error occurs the system shall provide context in the error message.
```

**Non-Functional Requirements** (NFR2.x) should specify measurable criteria:
```markdown
## NFR2: Non-Functional Requirements

NFR2.1: The component shall complete typical operations within defined time constraints.
NFR2.2: The system shall maintain reasonable memory usage relative to input size.
NFR2.3: The component shall produce output within acceptable size bounds.
NFR2.4: All public APIs shall have doc comment coverage of 100%.
```

**Technical Constraints** (TC3.x) should define boundaries:
```markdown
## TC3: Technical Constraints

TC3.1: The system shall compile with Zig version 0.11.0 or later.
TC3.2: The system shall have zero external dependencies beyond Zig std.
TC3.3: The system shall not use global mutable state.
TC3.4: The system shall pass with -Doptimize=ReleaseSafe.
```

**🚨 FILE DISCIPLINE CHECK**:
- [ ] Only `instructions.md` and `requirements.md` exist
- [ ] No supplementary files created
- [ ] All requirements properly structured within requirements.md

**🔒 AUTHORIZATION GATE**: Present requirements.md with EARS notation and request user approval to proceed to Design Phase

---

#### Phase 3: Design Phase
**Objective**: Technical architecture and implementation strategy

**⚠️ CRITICAL**: Design phase focuses on **WHAT** to build and **HOW** it will be structured, **NOT** writing actual implementation code.

**Deliverables**:
- Create **ONLY** `design.md` including:
  - **Architecture Overview**: High-level system structure and component relationships
  - **Module Organization**: How components are organized and interact
  - **Data Structures**: Key data structures and their purposes (description only, not full code)
  - **Algorithm Approaches**: High-level description of algorithms and logic flow
  - **Error Handling Strategy**: Error sets, error propagation patterns
  - **Memory Management Strategy**: Allocator usage patterns, ownership rules
  - **Testing Approach**: Testing strategy and key test scenarios
  - **Integration Points**: How feature integrates with existing codebase
  - **Performance Considerations**: Expected performance characteristics
  - **API Surface**: Public API design (signatures and descriptions, not implementations)

**What to INCLUDE**:
- ✅ Architecture diagrams and component relationships
- ✅ Data structure descriptions and relationships
- ✅ Algorithm pseudocode or flowcharts
- ✅ Interface signatures and contracts
- ✅ Decision rationale for design choices
- ✅ Trade-off analysis

**What to AVOID**:
- ❌ Full implementation code
- ❌ Complete function bodies
- ❌ Line-by-line code examples
- ❌ Actual Zig/JavaScript/TypeScript implementations

**Code Examples** (if needed):
- Keep minimal and illustrative only
- Show interface signatures, not implementations
- Demonstrate patterns, not actual working code
- Use pseudocode or simplified examples

**Example of GOOD design documentation**:
```markdown
### Platform Detection Module

**Purpose**: Detect OS, architecture, and libc variant

**Interface**:
```typescript
interface PlatformInfo {
  os: 'linux' | 'darwin' | 'win32'
  arch: 'x64' | 'arm64' | 'arm' | 'ia32'
  libc?: 'glibc' | 'musl'  // Linux only
}

function detectPlatform(): PlatformInfo
```

**Algorithm**:
1. Read process.platform → OS
2. Read process.arch → architecture
3. If Linux: detect libc using detect-libc package
4. Return structured platform information

**Error Handling**:
- Unsupported platform → throw with helpful message
- Missing libc detection → default to glibc
```

**Example of BAD design documentation** (too much code):
```javascript
// ❌ DON'T DO THIS IN DESIGN PHASE
function detectPlatform() {
  const { platform, arch } = process
  let libc = 'glibc'
  if (platform === 'linux') {
    try {
      const detectLibc = require('detect-libc')
      libc = detectLibc.family || 'glibc'
    } catch (err) {
      // fallback to glibc
    }
  }
  return { os: platform, arch, libc: platform === 'linux' ? libc : undefined }
}
// This belongs in IMPLEMENTATION phase, not DESIGN
```

**🚨 FILE DISCIPLINE CHECK**:
- [ ] Only `instructions.md`, `requirements.md`, and `design.md` exist
- [ ] Architecture details in design.md, not separate ARCHITECTURE.md
- [ ] Design decisions in design.md, not separate DESIGN_DECISIONS.md
- [ ] No README.md or other supplementary files

**🔒 AUTHORIZATION GATE**: Present design.md and request user approval to proceed to Plan Phase

**Remember**: Design documents the architecture and approach. Implementation writes the code. Keep them separate.

---

#### Phase 4: Plan Phase
**Objective**: Implementation roadmap with progress tracking

**Deliverables**:
- Create **ONLY** `plan.md` with:
  - **5-Phase Implementation Structure** with checkboxes
  - **Task Hierarchies** with clear objectives
  - **Validation Checkpoints**: build, test, fmt, docs
  - **Risk Mitigation Strategies**
  - **Success Criteria Validation**
  - **Progress Tracking System**

**🚨 FILE DISCIPLINE CHECK**:
- [ ] All four standard files exist: instructions.md, requirements.md, design.md, plan.md
- [ ] No additional files created
- [ ] Spec directory clean and well-organized

**🔒 AUTHORIZATION GATE**: Present plan.md and request user approval to proceed to Implementation Phase

---

#### Phase 5: Implementation Phase
**Objective**: Execute development with continuous validation

**Implementation Requirements**:

##### 🚨 CRITICAL ZIG REQUIREMENTS 🚨
- **FORBIDDEN**: Undefined behavior (use `-Doptimize=Debug` to catch)
- **FORBIDDEN**: Type coercion that loses information without explicit acknowledgment
- **FORBIDDEN**: Ignoring errors with `catch unreachable` without strong justification
- **MANDATORY**: Explicit error handling with error unions
- **MANDATORY**: `zig fmt` on all modified files before committing
- **MANDATORY**: All tests must pass with `zig build test`
- **MANDATORY**: Memory leak detection in tests (use `std.testing.allocator`)
- **MANDATORY**: Doc comments (`///`) for all public APIs
- **MANDATORY**: No hidden allocations (allocator parameter explicit)

##### Validation Steps (MANDATORY after each implementation step):
```bash
# 1. Format Zig files immediately after editing
zig fmt src/<modified-file>.zig

# 2. Build project with all optimizations and checks
zig build

# 3. Run all tests with leak detection
zig build test

# 4. Run specific test file if needed
zig test src/<test-file>.zig

# 5. Build documentation
zig build docs

# 6. Run with debug checks enabled
zig build -Doptimize=Debug
```

##### Implementation Workflow:

**1. Create Implementation Files**
   - Follow Zig naming conventions (snake_case for files/functions, PascalCase for types)
   - Use proper error unions for fallible operations
   - Add comprehensive doc comments (`///`) with examples
   - Make allocator dependencies explicit
   - Use `defer` and `errdefer` for resource cleanup
   - Prefer comptime where applicable for optimization
   - Use namespaced container pattern for modules

**Example Structure**:
```zig
//! Module description
//! 
//! This module provides...

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Public API struct with comprehensive documentation
pub const Component = struct {
    allocator: Allocator,
    state: State,
    
    /// Initialize a new component
    /// 
    /// # Arguments
    /// - `allocator`: Memory allocator for component operations
    /// 
    /// # Returns
    /// A new Component instance
    pub fn init(allocator: Allocator) Component {
        return .{ .allocator = allocator, .state = .{} };
    }
    
    /// Process input with explicit error handling
    /// 
    /// # Arguments
    /// - `input`: Input data to process
    /// 
    /// # Returns
    /// Processing result or error
    /// 
    /// # Errors
    /// - `InvalidInput`: Input validation failed
    /// - `OutOfMemory`: Allocation failed
    pub fn process(self: *Component, input: []const u8) !Result {
        // Implementation
    }
};
```

**2. Create Test Files**
   - Use `std.testing` for all tests
   - Use `std.testing.allocator` to detect memory leaks
   - Test error conditions explicitly
   - Test edge cases and boundary conditions
   - Use descriptive test names

**Example Test Structure**:
```zig
const std = @import("std");
const testing = std.testing;
const Component = @import("component.zig").Component;

test "Component.process handles valid input" {
    var component = Component.init(testing.allocator);
    const input = "valid data";
    
    const result = try component.process(input);
    defer result.deinit();
    
    try testing.expectEqual(expected_value, result.value);
}

test "Component.process returns error on invalid input" {
    var component = Component.init(testing.allocator);
    const input = "invalid data";
    
    try testing.expectError(error.InvalidInput, component.process(input));
}

test "Component.process does not leak memory" {
    var component = Component.init(testing.allocator);
    const input = "test data";
    
    const result = try component.process(input);
    defer result.deinit();
    
    // testing.allocator will detect leaks automatically
}
```

**3. Continuous Validation**
   - Run validation steps after each change
   - Fix any issues immediately
   - Never accumulate technical debt
   - Check for memory leaks in all code paths

**4. Documentation Enhancement**
   - Ensure all public APIs have doc comments (`///`)
   - Include usage examples in doc comments
   - Document error conditions
   - Document ownership and lifetime expectations
   - Document thread safety if applicable

##### Zig Best Practices Checklist:
- [ ] All allocations use explicit allocator parameter
- [ ] All resources cleaned up with `defer` or `errdefer`
- [ ] All errors handled explicitly (no `catch unreachable` without justification)
- [ ] No undefined behavior (verified with `-Doptimize=Debug`)
- [ ] Memory leaks detected with `std.testing.allocator`
- [ ] All public APIs documented with `///` comments
- [ ] Code formatted with `zig fmt`
- [ ] Comptime used where beneficial for performance/safety
- [ ] No hidden control flow (explicit over implicit)
- [ ] Thread safety documented if relevant

##### Completion Criteria:
- [ ] All implementation files created and tested
- [ ] All validation steps pass consistently
- [ ] Doc comment coverage at 100% for new public APIs
- [ ] Test coverage adequate with memory leak detection
- [ ] Feature works end-to-end as specified
- [ ] No breaking changes to existing functionality
- [ ] Documentation updated appropriately
- [ ] No undefined behavior detected
- [ ] Zero memory leaks in tests

**🔒 AUTHORIZATION GATE**: Present completed implementation with all validation passing and request user approval for completion

---

### 🎯 SUCCESS METRICS
- All 5 phases completed with user authorization
- Zero compilation errors (`zig build`)
- All tests pass (`zig build test`)
- Zero memory leaks detected
- 100% doc comment coverage for new public APIs
- Feature delivers on all acceptance criteria
- Integration with existing codebase seamless

### 🚨 CRITICAL REMINDERS
- **NEVER skip phases** or authorization gates
- **NEVER use forbidden patterns** (undefined behavior, hidden errors, memory leaks)
- **ALWAYS validate immediately** after changes
- **ALWAYS use proper Zig patterns** throughout implementation
- **ALWAYS maintain existing code quality standards**

---

## Feature Completion - Ansilust

### 🎯 OBJECTIVE
Complete feature development with comprehensive validation, documentation updates, and proper git workflow for the ansilust project.

### 📋 COMPLETION WORKFLOW

#### Phase 1: Final Validation (MANDATORY)
Run all quality gates to ensure implementation meets Zig standards:

```bash
# 1. Format all modified Zig files
zig fmt src/<modified-files>.zig

# 2. Build entire project
zig build

# 3. Build with debug checks to catch undefined behavior
zig build -Doptimize=Debug

# 4. Run all tests with leak detection
zig build test

# 5. Run specific test suites if applicable
zig test src/<test-files>.zig

# 6. Build documentation
zig build docs

# 7. Run with sanitizers if configured
zig build -Doptimize=ReleaseSafe

# 8. Check for unused code (manual review)
# Review compiler warnings
```

**🚨 CRITICAL**: All checks must pass with ZERO errors before proceeding.

---

#### Phase 2: Documentation Updates
Update project documentation to reflect completed work:

**Update Specifications**:
- [ ] Mark completed tasks in `.specs/[feature-name]/plan.md` with ✅
- [ ] Capture review feedback and status updates directly in `.specs/[feature-name]/plan.md`
- [ ] Add implementation summary to plan.md
- [ ] Document any architectural decisions made
- [ ] Note any deviations from original design with rationale

**Update Progress Tracking**:
```bash
# Update overall specs progress if applicable
# Update any related documentation files
# Ensure all examples in documentation compile
```

---

#### Phase 3: Git Workflow
Execute proper git workflow with comprehensive commit messages:

**Stage Changes**:
```bash
# Add all implementation files
git add src/<new-files>.zig
git add src/<test-files>.zig

# Add documentation updates
git add .specs/<feature-name>/
git add docs/ # if documentation was generated

# Add build configuration if modified
git add build.zig

# Add any other related files
git add <other-modified-files>
```

**Commit with Structured Message**:
```bash
git commit -m "$(cat <<'EOF'
feat: implement [feature-name]

[Brief description of what the feature does and why it was needed]

Implementation highlights:
- [Key architectural decisions]
- [Important patterns used]
- [Memory management approach]
- [Testing approach]
- [Documentation coverage]

Validation:
- ✅ All Zig files formatted with zig fmt
- ✅ zig build completes with zero errors
- ✅ zig build test passes all tests
- ✅ Zero memory leaks detected (std.testing.allocator)
- ✅ Debug build passes (-Doptimize=Debug)
- ✅ Documentation built successfully
- ✅ Doc comment coverage at 100% for new APIs

Closes: [issue-number if applicable]

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

#### Phase 4: Pull Request Creation (if on feature branch)
Create pull request with comprehensive description:

```bash
# Ensure branch is up to date and pushed
git push -u origin <feature-branch-name>

# Create pull request with structured description
gh pr create --title "feat: [feature-name]" --body "$(cat <<'EOF'
## Summary
[Brief description of the feature and its purpose]

## Implementation Details
- **Architecture**: [Key architectural patterns used]
- **Memory Safety**: [Allocator strategy, ownership model]
- **Error Handling**: [Error set design and propagation]
- **Testing**: [Testing strategy and coverage]
- **Documentation**: [Doc comment coverage and examples]
- **Performance**: [Memory allocations, comptime optimizations]

## Zig Best Practices Compliance
- ✅ No undefined behavior (verified with -Doptimize=Debug)
- ✅ Explicit error handling (no catch unreachable without justification)
- ✅ Explicit allocator parameters for all allocations
- ✅ Proper resource cleanup (defer/errdefer)
- ✅ All Zig files formatted with zig fmt
- ✅ All tests use std.testing.allocator for leak detection
- ✅ Doc comments (///) for all public APIs
- ✅ No hidden control flow

## Validation Results
- ✅ `zig fmt` - All files formatted
- ✅ `zig build` - Build completes successfully
- ✅ `zig build test` - All tests pass
- ✅ `zig build -Doptimize=Debug` - No undefined behavior
- ✅ `zig build docs` - Documentation built
- ✅ Memory leak detection - Zero leaks

## Test Plan
- [ ] Verify feature works as documented
- [ ] Test error conditions and edge cases
- [ ] Validate integration with existing APIs
- [ ] Confirm documentation examples compile
- [ ] Check memory usage and performance
- [ ] Verify no memory leaks in all code paths

## Breaking Changes
[None / List any breaking changes with migration notes]

## Related Issues
[List any related issues or dependencies]

🤖 Generated with [Claude Code](https://claude.ai/code)
EOF
)"
```

---

#### Phase 5: Final Verification
Ensure all completion criteria are met:

**Quality Metrics**:
- [ ] All automated checks pass (`zig fmt`, `zig build`, `zig build test`, `zig build docs`)
- [ ] Feature works end-to-end as specified
- [ ] Test coverage adequate with memory leak detection
- [ ] Doc comment coverage at 100% for new public APIs
- [ ] No breaking changes to existing functionality
- [ ] Documentation updated appropriately
- [ ] No undefined behavior detected
- [ ] Zero memory leaks

**Zig Standards**:
- [ ] No forbidden patterns (undefined behavior, hidden errors)
- [ ] Proper Zig patterns throughout (error unions, explicit allocators)
- [ ] Resource management follows Zig conventions (defer/errdefer)
- [ ] Testing uses std.testing.allocator appropriately
- [ ] All examples compile and demonstrate practical usage
- [ ] No hidden control flow
- [ ] Comptime used appropriately for optimization

**Documentation Quality**:
- [ ] All new APIs have comprehensive doc comments (`///`)
- [ ] Examples demonstrate real-world usage patterns
- [ ] Error conditions documented
- [ ] Ownership and lifetime expectations clear
- [ ] Integration with existing documentation seamless

---

## 🎯 SUCCESS CRITERIA
- ✅ All validation steps pass completely
- ✅ Documentation updated and accurate
- ✅ Git workflow completed with structured commits
- ✅ Pull request created (if applicable) with comprehensive description
- ✅ Feature ready for review and integration
- ✅ Zero technical debt introduced
- ✅ Zero memory leaks
- ✅ No undefined behavior

## 🚨 CRITICAL REMINDERS
- **NEVER skip validation steps** - all checks must pass
- **NEVER commit with failing tests or compilation errors**
- **ALWAYS update documentation** to reflect implementation
- **ALWAYS use structured commit messages** for traceability
- **ALWAYS maintain Zig safety and quality standards** throughout
- **ALWAYS check for memory leaks** with std.testing.allocator
- **ALWAYS verify no undefined behavior** with debug builds

---

## Zig-Specific Development Guidelines

### Memory Management
- **Always** pass allocators explicitly as parameters
- **Never** use hidden global allocators
- Use `defer` for cleanup in success paths
- Use `errdefer` for cleanup in error paths
- Test all code paths with `std.testing.allocator` to detect leaks

### Error Handling
- Define specific error sets for each operation
- Use error unions (`!T`) for fallible operations
- Document all possible errors in doc comments
- Avoid `catch unreachable` unless absolutely justified
- Propagate errors with `try` or handle explicitly

### Type Safety
- Use Zig's strong type system to prevent errors at compile time
- Leverage comptime for compile-time verification
- Avoid type coercion that loses information
- Use explicit casts when necessary with clear reasoning

### Testing
- Write tests alongside implementation
- Use descriptive test names
- Test error conditions explicitly
- Use `std.testing.allocator` for leak detection
- Test edge cases and boundary conditions
- Use fuzz testing for parser code when applicable

### Documentation
- Use `///` for doc comments on public APIs
- Include usage examples in doc comments
- Document parameters, return values, and errors
- Document ownership and lifetime expectations
- Use `//!` for module-level documentation

### Performance
- Profile before optimizing
- Use comptime to move work to compile time
- Minimize allocations in hot paths
- Document performance characteristics
- Use appropriate data structures for the use case

This workflow ensures systematic, high-quality feature development that maintains the ansilust project's standards for memory safety, type safety, and Zig best practices.

---

## EARS Notation Reference

### Overview

EARS (Easy Approach to Requirements Syntax) provides structured patterns for writing clear, unambiguous requirements. All functional requirements in ansilust specifications **MUST** use EARS notation.

### The Five EARS Patterns

#### 1. Ubiquitous Requirements
**Pattern**: "The [subject] shall [requirement]"

**When to use**: Requirements that are always active with no preconditions.

**Examples**:
```
The component shall validate input parameters.
The module shall support required data types.
The system shall provide a public API.
The allocator shall be passed explicitly to all functions.
```

**Key characteristics**:
- No trigger conditions
- Always enforced
- System-wide behavior

---

#### 2. Event-Driven Requirements
**Pattern**: "WHEN [trigger/event] the [subject] shall [requirement]"

**When to use**: Requirements triggered by specific events or conditions.

**Examples**:
```
WHEN specific metadata is detected the component shall extract all relevant fields.
WHEN an allocation fails the system shall return error.OutOfMemory.
WHEN processing completes the system shall invoke the completion callback.
WHEN input exceeds buffer size the component shall return error.BufferTooSmall.
```

**Key characteristics**:
- Specific triggering event
- Clearly defined system response
- Temporal relationship

---

#### 3. State-Driven Requirements
**Pattern**: "WHILE [in state] the [subject] shall [requirement]"

**When to use**: Requirements active during specific system states.

**Examples**:
```
WHILE in special mode the component shall apply mode-specific processing rules.
WHILE handling specific format the component shall use format-appropriate defaults.
WHILE processing legacy data the system shall use appropriate encoding mappings.
WHILE the debug flag is set the system shall emit trace information.
```

**Key characteristics**:
- Duration-based activation
- State-dependent behavior
- Remains active until state changes

---

#### 4. Unwanted Behavior Requirements
**Pattern**: "IF [unwanted condition] THEN the [subject] shall [requirement]"

**When to use**: Error handling, exception cases, and fault tolerance.

**Examples**:
```
IF input contains invalid encoding THEN the component shall return error.InvalidEncoding.
IF buffer overflow is detected THEN the system shall return error.BufferTooSmall.
IF a required dependency is missing THEN initialization shall fail with error.MissingDependency.
IF memory allocation fails THEN the system shall clean up partial state.
```

**Key characteristics**:
- Error conditions
- Exception handling
- Defensive requirements

---

#### 5. Optional Feature Requirements
**Pattern**: "WHERE [feature/configuration] the [subject] shall [requirement]"

**When to use**: Conditional features, build configurations, or optional capabilities.

**Examples**:
```
WHERE feature X is enabled the component shall provide extended functionality.
WHERE advanced mode is supported the component shall maintain required state.
WHERE debug mode is active the system shall emit detailed diagnostics.
WHERE the feature flag is set the system shall enable experimental features.
```

**Key characteristics**:
- Feature flags
- Configuration-dependent
- Optional capabilities

---

### EARS Best Practices

#### Writing Quality Requirements

**DO**:
- ✅ Use "shall" for mandatory requirements (never "should", "may", or "might")
- ✅ Write one requirement per statement
- ✅ Be specific and measurable
- ✅ Focus on observable behavior
- ✅ Make preconditions explicit
- ✅ Use consistent terminology
- ✅ Define clear success criteria

**DON'T**:
- ❌ Mix multiple requirements in one statement
- ❌ Use vague language ("properly", "adequately", "reasonable")
- ❌ Specify implementation details (save for design phase)
- ❌ Use passive voice or unclear subjects
- ❌ Omit error conditions
- ❌ Create untestable requirements

---

### EARS Anti-Patterns

#### Vague Requirements
❌ **Bad**: "The system should handle errors properly"
✅ **Good**: "IF parsing fails THEN the system shall return error.ParseError with context"

#### Ambiguous Modality
❌ **Bad**: "The component may support feature X"
✅ **Good**: "The component shall support required feature X"

#### Implementation Details
❌ **Bad**: "The system shall use a HashMap for symbol storage"
✅ **Good**: "The system shall provide O(1) symbol lookup"

#### Combined Requirements
❌ **Bad**: "The system shall parse and render text art"
✅ **Good**: 
- "The component shall process input and produce output"
- "The system shall convert data from format A to format B"

#### Missing Preconditions
❌ **Bad**: "The system shall use special processing"
✅ **Good**: "WHERE compatibility mode is enabled the component shall apply special processing rules"

---

### EARS Validation Checklist

Use this checklist when reviewing requirements:

#### Structure
- [ ] Every functional requirement uses one of the five EARS patterns
- [ ] Each requirement has a unique identifier (FR1.x format)
- [ ] Requirements are hierarchically organized
- [ ] All requirements use "shall" (not "should" or "may")

#### Clarity
- [ ] Each requirement states exactly one obligation
- [ ] Preconditions are explicit (WHEN/WHILE/IF/WHERE when needed)
- [ ] Subject and action are clearly identified
- [ ] No ambiguous terms ("properly", "reasonable", "adequate")
- [ ] Terminology is consistent throughout

#### Completeness
- [ ] Normal operating conditions covered (Ubiquitous, Event-driven, State-driven)
- [ ] Error conditions covered (Unwanted)
- [ ] Optional features covered (Optional)
- [ ] All inputs have defined handling
- [ ] All outputs have defined format
- [ ] All error cases have defined responses

#### Testability
- [ ] Each requirement is verifiable through testing
- [ ] Success criteria are measurable
- [ ] Expected behavior is observable
- [ ] Test conditions can be created
- [ ] Pass/fail criteria are clear

#### Zig-Specific Requirements
- [ ] Memory allocation requirements explicit
- [ ] Error handling requirements complete
- [ ] Ownership and lifetime requirements clear
- [ ] Thread safety requirements specified (if applicable)
- [ ] Performance requirements measurable

---

### Example: Complete Feature Requirements

```markdown
# Feature: Data Processor

## FR1: Functional Requirements

### FR1.1: Input Handling
FR1.1.1: The component shall accept byte arrays as input.
FR1.1.2: The component shall accept an allocator parameter for all allocations.
FR1.1.3: WHEN input size exceeds configured limits the component shall return error.InputTooLarge.

### FR1.2: Data Validation
FR1.2.1: The component shall validate input format before processing.
FR1.2.2: The component shall check all required fields are present.
FR1.2.3: IF validation fails THEN the component shall return error.InvalidInput with details.

### FR1.3: Metadata Extraction
FR1.3.1: WHEN metadata is present the component shall extract all relevant fields.
FR1.3.2: The component shall validate metadata structure.
FR1.3.3: IF metadata validation fails THEN the component shall use default values.
FR1.3.4: WHEN metadata contains hints the component shall apply them during processing.

### FR1.4: Data Encoding
FR1.4.1: WHILE processing legacy format the component shall use appropriate decoding.
FR1.4.2: WHERE modern encoding is enabled the component shall support extended character sets.
FR1.4.3: IF invalid encoding is detected THEN the component shall return error.InvalidEncoding.

### FR1.5: Output Generation
FR1.5.1: The component shall produce a valid output structure.
FR1.5.2: The component shall preserve all relevant information.
FR1.5.3: WHEN processing completes the component shall return ownership to caller.

### FR1.6: Resource Management
FR1.6.1: The component shall release all allocated resources on success.
FR1.6.2: IF an error occurs THEN the component shall release all allocated resources.
FR1.6.3: The component shall not leak memory under any circumstances.

## NFR2: Non-Functional Requirements

NFR2.1: The component shall process typical workloads within performance targets.
NFR2.2: The component shall use reasonable memory relative to input size.
NFR2.3: The component shall compile with -Doptimize=ReleaseSafe with zero warnings.

## TC3: Technical Constraints

TC3.1: The component shall require Zig 0.11.0 or later.
TC3.2: The parser shall have zero dependencies beyond Zig std library.
TC3.3: The parser shall not use global mutable state.
```

---

## EARS Integration with Development Workflow

### During Instructions Phase (Phase 1)
- Introduce EARS patterns in Core Requirements section
- Use EARS for Acceptance Criteria
- Begin thinking in EARS patterns

### During Requirements Phase (Phase 2)
- **MANDATORY**: All FR1.x requirements use EARS notation
- Apply EARS validation checklist
- Review for completeness using all five patterns
- Ensure error conditions covered (Unwanted pattern)

### During Design Phase (Phase 3)
- Map EARS requirements to implementation approach
- Ensure design addresses all EARS requirements
- Document how each requirement will be verified

### During Implementation Phase (Phase 5)
- Trace code back to specific EARS requirements
- Ensure test coverage for each EARS requirement
- Verify error handling matches Unwanted requirements

### During Completion Validation
- [ ] All