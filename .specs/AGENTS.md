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
- Create `instructions.md` with:
  - Overview and User Story
  - Core Requirements
  - Technical Specifications
  - Acceptance Criteria
  - Out of Scope items
  - Success Metrics
  - Future Considerations
  - Testing Requirements

**🔒 AUTHORIZATION GATE**: Present instructions.md and request user approval to proceed to Requirements Phase

---

#### Phase 2: Requirements Phase
**Objective**: Structured analysis and formal specifications

**Deliverables**:
- Create `requirements.md` with hierarchical numbering:
  - **FR1.x**: Functional Requirements
  - **NFR2.x**: Non-Functional Requirements (performance, memory usage)
  - **TC3.x**: Technical Constraints (Zig version, dependencies)
  - **DR4.x**: Data Requirements (structures, formats)
  - **IR5.x**: Integration Requirements
  - **DEP6.x**: Dependencies
  - **SC7.x**: Success Criteria

**🔒 AUTHORIZATION GATE**: Present requirements.md and request user approval to proceed to Design Phase

---

#### Phase 3: Design Phase
**Objective**: Technical architecture and implementation strategy

**Deliverables**:
- Create `design.md` including:
  - **Zig Patterns**: Struct methods, comptime, error unions
  - **Memory Safety Approach**: Allocator strategy, ownership model
  - **Module Architecture**: Namespace organization, public API design
  - **Error Handling Strategy**: Error sets, error union patterns
  - **Testing Strategy**: Unit tests, integration tests, fuzz testing
  - **Documentation Plan**: Doc comments (`///`), examples, API coverage
  - **Code Examples**: Demonstrating key implementations
  - **Integration Points**: How feature fits with existing codebase
  - **Performance Considerations**: Allocations, compile-time optimization

**🔒 AUTHORIZATION GATE**: Present design.md and request user approval to proceed to Plan Phase

---

#### Phase 4: Plan Phase
**Objective**: Implementation roadmap with progress tracking

**Deliverables**:
- Create `plan.md` with:
  - **5-Phase Implementation Structure** with checkboxes
  - **Task Hierarchies** with clear objectives
  - **Validation Checkpoints**: build, test, fmt, docs
  - **Risk Mitigation Strategies**
  - **Success Criteria Validation**
  - **Progress Tracking System**

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
pub const Parser = struct {
    allocator: Allocator,
    
    /// Initialize a new parser
    /// 
    /// # Arguments
    /// - `allocator`: Memory allocator for parser operations
    /// 
    /// # Returns
    /// A new Parser instance
    pub fn init(allocator: Allocator) Parser {
        return .{ .allocator = allocator };
    }
    
    /// Parse input with explicit error handling
    /// 
    /// # Arguments
    /// - `input`: Input data to parse
    /// 
    /// # Returns
    /// Parsed result or error
    /// 
    /// # Errors
    /// - `InvalidFormat`: Input format is invalid
    /// - `OutOfMemory`: Allocation failed
    pub fn parse(self: *Parser, input: []const u8) !Result {
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
const Parser = @import("parser.zig").Parser;

test "Parser.parse handles valid input" {
    var parser = Parser.init(testing.allocator);
    const input = "valid data";
    
    const result = try parser.parse(input);
    defer result.deinit();
    
    try testing.expectEqual(expected_value, result.value);
}

test "Parser.parse returns error on invalid input" {
    var parser = Parser.init(testing.allocator);
    const input = "invalid data";
    
    try testing.expectError(error.InvalidFormat, parser.parse(input));
}

test "Parser.parse does not leak memory" {
    var parser = Parser.init(testing.allocator);
    const input = "test data";
    
    const result = try parser.parse(input);
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