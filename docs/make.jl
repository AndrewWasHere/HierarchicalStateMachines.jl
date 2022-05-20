push!(LOAD_PATH, "../src/")

using Documenter, HSM

makedocs(
    modules = [HSM],
    sitename=  "HSM.jl",
    authors = "Andrew Lin",
    pages = [
        "Home" => "index.md",
        "reference.md"
    ]
)
deploydocs(
    repo = "github.com/AndrewWasHere/HSM.jl.git",
)
