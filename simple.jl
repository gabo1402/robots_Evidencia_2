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
    width::Float64
    height::Float64
    depth::Float64
    weight::Float64
end

@agent struct robot(GridAgent{2})  
    capacity::RobotStatus = empty
    orientation::Float64 = normal
    last_box::Union{Nothing, Tuple{Float64, Float64, Float64, Float64}} = nothing  # Para recordar la caja eliminada
end

@agent struct angar(GridAgent{2})
    boxes::Int = 0 
end

function agent_step!(agent::box, model)
end

function agent_step!(agent::angar, model)
end

function closest_box(agent::robot, model)
    closest_box1 = nothing
    distanciam = Inf

    for neighbor in allagents(model)
        if isa(neighbor, box) && neighbor.status == waiting 
            d_vecino = abs(neighbor.pos[1] - agent.pos[1]) + abs(neighbor.pos[2] - agent.pos[2])

            if d_vecino < distanciam
                distanciam = d_vecino
                closest_box1 = neighbor #caja cercana
            end
        end
    end

    return closest_box1, distanciam
end

function closest_angar_nearby(agent::robot, model)
    closest_angar = nothing
    distanciam = Inf

    for neighbor in allagents(model)
        if isa(neighbor, angar) && neighbor.boxes < 5  # Verifica que el angar tenga menos de 5 cajas
            d_vecino = abs(neighbor.pos[1] - agent.pos[1]) + abs(neighbor.pos[2] - agent.pos[2])
            if d_vecino < distanciam
                distanciam = d_vecino
                closest_angar = neighbor  # angar cercano
            end
        end
    end

    return closest_angar, distanciam
end

function agent_step!(agent::robot, model)
    if agent.capacity == empty
        closest_box1, _ = closest_box(agent, model)

        if closest_box1 !== nothing
            obj_pos = closest_box1.pos
            actual_pos = agent.pos

            diff_x = obj_pos[1] - actual_pos[1]
            diff_y = obj_pos[2] - actual_pos[2]

            if abs(diff_x) > abs(diff_y)
                posicion_act = (actual_pos[1] + sign(diff_x), actual_pos[2])
            else
                posicion_act = (actual_pos[1], actual_pos[2] + sign(diff_y))
            end

            move_agent!(agent, posicion_act, model)

            if agent.pos == closest_box1.pos
                # Guardar las dimensiones de la caja antes de eliminarla
                agent.last_box = (closest_box1.width, closest_box1.height, closest_box1.depth, closest_box1.weight)
                
                closest_box1.status = taken
                agent.capacity = full
                remove_agent!(closest_box1, model)  # Elimina la caja del modelo
            end
        else
            posicion_act = (agent.pos[1], agent.pos[2] - 1)
            move_agent!(agent, posicion_act, model)
        end

    elseif agent.capacity == full
        closest_angar, _ = closest_angar_nearby(agent, model)

        if closest_angar !== nothing
            obj_pos = closest_angar.pos
            actual_pos = agent.pos

            diff_x = obj_pos[1] - actual_pos[1]
            diff_y = obj_pos[2] - actual_pos[2]

            if abs(diff_x) > abs(diff_y)
                posicion_act = (actual_pos[1] + sign(diff_x), actual_pos[2])
            else
                posicion_act = (actual_pos[1], actual_pos[2] + sign(diff_y))
            end

            move_agent!(agent, posicion_act, model)

            if agent.pos == closest_angar.pos
                agent.capacity = empty
                closest_angar.boxes += 1

                if closest_angar.boxes == 5
                    new_angar_pos = (closest_angar.pos[1], closest_angar.pos[2] + 1) # Ejemplo: crear arriba
                    add_agent!(angar, model; pos = new_angar_pos)
                end

                # Recrear la caja con las dimensiones guardadas
                if agent.last_box !== nothing
                    width, height, depth, weight = agent.last_box
                    add_agent!(box, model; pos = closest_angar.pos, width = width, height = height, depth = depth, weight = weight)
                    
                    # Cambiar el estado de la caja a 'developed'
                    for new_box in allagents(model)
                        if isa(new_box, box) && new_box.pos == closest_angar.pos
                            new_box.status = developed
                        end
                    end
                end
            end
        else
            posicion_act = (agent.pos[1], agent.pos[2] - 1)
            move_agent!(agent, posicion_act, model)
        end
    end
end


function initialize_model(; number = 40, griddims = (40, 40))
    space = GridSpace(griddims; periodic = false, metric = :manhattan)
    model = StandardABM(Union{robot, box, angar}, space; agent_step!, scheduler = Schedulers.fastest)

    caja_dimensiones = [
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=0.8, height=1.1, depth=1.3, weight=12.0)  # Hasta llegar a 40
    ]

    all_positions = [(x, y) for x in 1:griddims[1], y in 1:griddims[2]]
    mezcla = shuffle(all_positions)

    # Agregar robots como antes
    num_robots = 1
    bottom_y = 1  
    posicion_ini = div(griddims[1], 10) 
    spacing = 2 * posicion_ini
    robot_columns = [posicion_ini + (i-1) * spacing for i in 1:num_robots]
    robot_positions = [(col, bottom_y) for col in robot_columns]
    for robot_pos in robot_positions
        add_agent!(robot, model; pos = robot_pos)
    end

    # Calcular posiciones disponibles para las cajas
    bloqueadas = []
    for robot_pos in robot_positions
        append!(bloqueadas, [(robot_pos[1] + dx, robot_pos[2] + dy) for dx in -1:1, dy in -1:1])
    end

    posicion_co = setdiff(mezcla, bloqueadas)
    if length(posicion_co) < number
        error("No hay suficientes posiciones válidas para las cajas")
    end

    # Añadir cajas con dimensiones personalizadas
    # Añadir cada caja con sus dimensiones específicas
    for i in 1:number
        dims = caja_dimensiones[i]
        add_agent!(box, model; pos = posicion_co[i], width = dims.width, height = dims.height, depth = dims.depth, weight = dims.weight)
    end

    # Añadir hangares como antes
    num_angar = round(Int, num_robots)
    angar_positions = []
    for robot_pos in robot_positions
        if !any(agent -> isa(agent, box), agents_in_position(robot_pos, model))
            add_agent!(angar, model; pos = robot_pos)
            push!(angar_positions, robot_pos)
        end
    end

    return model
end