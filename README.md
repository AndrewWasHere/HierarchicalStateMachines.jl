# HierarchicalStateMachines.jl

[![docs-dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://andrewwashere.github.io/HSM.jl/dev)
[![Tests](https://github.com/AndrewWasHere/HSM.jl/actions/workflows/tests.yml/badge.svg)](https://github.com/AndrewWasHere/HSM.jl/actions/workflows/tests.yml)

Hierarchical State Machine (HSM) library for complex, stateful, event-driven 
applications written in Julia.

HSM is based on Unified Modeling Language (UML) state machines (also called
state charts).

## Examples

`test/test_temperature.jl` is a sample state machine demonstrating how to use
HierarchicalStateMachines.jl. To see a graphical representation of the 
thermometer state machine described in the file's docstring, pass it through 
[PlantUML](https://plantuml.com).

Unlike `test_temperature.jl`, you will probably want to slap an event queue in 
front of your state machine.

`example/thermometer-notebook.jl` is an interactive thermometer state machine in
a Pluto notebook. It will show the state transitions and HSM function calls when
handling events.

Finally, check out my blog post titled 
**[State Machines and Their Implementation (in Julia)](https://andrewwashere.github.io/2022/05/21/state-machines.html)**
for an in-depth explanation of how this library works.

## Honorable Mentions

Thanks to [G Gundam](https://github.com/g-gundam) for encouraging me to 
actually publish HierarchicalStateMachines.jl on JuliaHub, the proofreading, and 
the pull requests.

## License

Copyright 2022 - 2024, Andrew Lin. All rights reserved.

This library is licensed under the MIT License. See LICENSE.txt or
https://opensource.org/licenses/MIT.
