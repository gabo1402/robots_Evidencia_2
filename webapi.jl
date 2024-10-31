include("simple.jl")
using Genie, Genie.Renderer.Json, Genie.Requests, HTTP
using UUIDs

instances = Dict()

route("/simulations", method = POST) do
    payload = jsonpayload()
    x = payload["dim"][1]
    y = payload["dim"][2]
    number = payload["number"]

    model = initialize_model(griddims=(x,y), number=(number))
    id = string(uuid1())
    instances[id] = model

    boxes = []
    robots = []
    angars = []
    for agent in allagents(model)
        if agent isa box
            push!(boxes, agent)
        elseif agent isa robot
            push!(robots, agent)
        elseif agent isa angar
            push!(angars, agent)
        end
    end

    json(Dict(:msg => "Hola", "Location" => "/simulations/$id", "boxes" => boxes, "robots" => robots, "angars" => angars))
end

route("/simulations/:id") do
    model_id = payload(:id)
    model = instances[model_id]
    run!(model, 1)

    boxes = []
    robots = []
    angars = []
    for agent in allagents(model)
        if agent isa box
            push!(boxes, agent)
        elseif agent isa robot
            push!(robots, agent)
        elseif agent isa angar
            push!(angars, agent)
        end
    end

    json(Dict(:msg => "Adios", "boxes" => boxes, "robots" => robots, "angars" => angars))
end

Genie.config.run_as_server = true
Genie.config.cors_headers["Access-Control-Allow-Origin"] = "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]

up()
