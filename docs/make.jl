push!(LOAD_PATH, "../src/")

using Documenter, HierarchicalStateMachines

makedocs(
    modules = [HierarchicalStateMachines],
    sitename=  "HierarchicalStateMachines.jl",
    authors = "Andrew Lin",
    pages = [
        "Home" => "index.md",
        "reference.md"
    ],
    checkdocs=:exports
)
deploydocs(
    repo = "github.com/AndrewWasHere/HSM.jl.git",
)
