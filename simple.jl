using Agents, Random
using StaticArrays: SVector

@enum BoxStatus waiting taken developed
@enum RobotStatus empty full

normal = 0
left = π/2
down = π
right = 3π/2

@agent struct box(GridAgent{2})
    status::BoxStatus = waiting
end

@agent struct robot(GridAgent{2})  
    capacity::RobotStatus = empty
    orientation::Float64 = normal
end

@agent struct angar(GridAgent{2})
    boxes::Int = 5
end

# Funciones de paso de agente sin lógica de movimiento o cambios de estado
function agent_step!(agent::box, model)
end

function agent_step!(agent::angar, model)
end

function agent_step!(agent::robot, model)
end

function initialize_model(; number = 40, griddims = (40, 40))
    space = GridSpace(griddims; periodic = false, metric = :manhattan)
    model = StandardABM(Union{robot, box, angar}, space; agent_step!, scheduler = Schedulers.fastest)
    matrix = fill(1, griddims...)

    all_positions = [(x, y) for x in 1:griddims[1], y in 1:griddims[2]]
    mezcla = shuffle(all_positions)

    num_robots = 5
    bottom_y = 1  # Última fila (abajo)
    posicion_ini = div(griddims[1], 10) 
    spacing = 2 * posicion_ini

    robot_columns = [posicion_ini + (i-1) * spacing for i in 1:num_robots]
    robot_positions = [(col, bottom_y) for col in robot_columns]
    for robot_pos in robot_positions
        add_agent!(robot, model; pos = robot_pos)
    end
    bloqueadas = []
    for robot_pos in robot_positions
        append!(bloqueadas, [(robot_pos[1] + dx, robot_pos[2] + dy) for dx in -1:1, dy in -1:1])
    end

    posicion_co = setdiff(mezcla, bloqueadas)

    if length(posicion_co) < number
        error("No hay suficientes posiciones válidas para las cajas")
    end

    # Agrega las cajas en posiciones válidas
    for i in 1:number
        add_agent!(box, model; pos = posicion_co[i])
    end

    # Agrega los hangares en posiciones de robots
    for robot_pos in robot_positions
        if !any(agent -> isa(agent, box), agents_in_position(robot_pos, model))
            add_agent!(angar, model; pos = robot_pos)
        end
    end

    return model
end