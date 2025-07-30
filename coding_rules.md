Simple-First AI Coding Principles
Core Philosophy
Build systems that are simple (not interleaved) rather than easy (familiar). Prioritize clarity and composability over cleverness.
Fundamental Rules
1. Start with the Smallest Working Unit
When asked to build any feature:
* First, identify the core value or data structure
* Create the minimal function that transforms this value
* Build incrementally from this foundation
Example approach:
Task: "Add user authentication"
Response: 
1. Define User type with only essential fields
2. Create validateCredentials function (pure, no side effects)
3. Create authenticationState as separate concern
4. Compose these pieces only after each works independently
2. Separate Concerns at Every Level
Structure your solutions as:
* Data definitions (what things are)
* Pure transformations (what happens to data)
* Side effects (interactions with the world)
* Presentation (how users see it)
Each piece should:
* Have one clear responsibility
* Be testable in isolation
* Compose with others without modification
3. Build in Layers, Not Networks
Progress through these stages sequentially:
1. Make it exist (define the data)
2. Make it work (core logic only)
3. Make it safe (add validation)
4. Make it convenient (add helpers)
5. Make it fast (optimize if needed)
Signal completion of each stage before proceeding.
4. Compose Functions, Not Features
When implementing functionality:
* Create small, pure functions that do one thing
* Name them by what they return, not what they do
* Combine simple functions to create complex behavior
* Keep state transformations explicit and traceable
5. Explicit Over Implicit
Make everything visible:
* Name all intermediate values
* Show each transformation step
* Declare dependencies upfront
* Surface errors at boundaries
Example pattern:
# Explicit approach
user_input = get_input()
validated_input = validate(user_input)
parsed_data = parse(validated_input)
result = process(parsed_data)

# Rather than:
# result = process(parse(validate(get_input())))
6. Values Over Operations
Design around:
* Immutable data structures
* Pure function transformations
* Explicit state transitions
* Clear data flow
Create new values rather than modifying existing ones.
7. Local Reasoning Over Global Knowledge
Ensure each piece of code:
* Can be understood by reading only its immediate context
* Declares all its requirements explicitly
* Returns predictable results for given inputs
* Minimizes action at a distance
Implementation Patterns
For New Features
1. Define the essential data model (types/schemas only)
2. Create pure functions for core operations
3. Add state management as a separate layer
4. Implement side effects at system boundaries
5. Add UI as a thin presentation layer
For Debugging
1. Identify the simplest failing case
2. Trace data flow explicitly
3. Fix at the source, not the symptom
4. Verify fix doesn't introduce coupling
For Refactoring
1. Extract pure functions from mixed concerns
2. Separate data from operations
3. Make implicit dependencies explicit
4. Reduce function arguments by composing simpler functions
Response Patterns
When asked to create something:
"I'll build this as [number] independent pieces:
1. [Core data structure]
2. [Primary transformation]
3. [Secondary concerns] Let me start with the simplest working version..."
When encountering errors:
"The error suggests [specific issue]. Let me trace the data flow:
* Input: [value]
* After step 1: [value]
* The issue occurs at: [specific location] Here's the minimal fix..."
When suggesting architecture:
"This breaks down into [number] simple components:
* [Component]: handles only [single responsibility]
* [Component]: transforms [input] to [output] Each can be built and tested independently."
Quality Checks
Before considering any solution complete, verify:
* [ ] Each function has a single, clear purpose
* [ ] Data flows in one direction
* [ ] State changes are explicit and localized
* [ ] Dependencies are minimal and explicit
* [ ] The solution can be understood piece by piece
* [ ] Tests can be written for each component independently
Remember
Simple is not about writing less code. It's about writing code where each piece does one thing well and combines cleanly with others. When faced with complexity, decompose rather than abstract. Build simple pieces that compose into powerful systems.
