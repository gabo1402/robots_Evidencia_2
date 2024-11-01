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

# Function tencontrar caja cercana
function closest_angar_nearby(agent::robot, model)
    closest_angar = nothing
    distanciam = Inf

    # Buscar agentes
    for neighbor in allagents(model)
        if isa(neighbor, angar) && neighbor.boxes < 5  # Verifica que el angar tenga menos de 5 cajas
            d_vecino = abs(neighbor.pos[1] - agent.pos[1]) + abs(neighbor.pos[2] - agent.pos[2])
            if d_vecino < distanciam
                distanciam = d_vecino
                closest_angar = neighbor  # angar cercano e ir
            end
        end
    end

    return closest_angar, distanciam
end


function agent_step!(agent::robot, model)
    if agent.capacity == empty
        # Recorre el mapa en zigzag
        # Decide la dirección de movimiento
        if (agent.pos[2] % 2) == 0  # Par (mover hacia la derecha)
            posicion_act = (agent.pos[1] + 1, agent.pos[2])
        else  # Impar (mover hacia la izquierda)
            posicion_act = (agent.pos[1] - 1, agent.pos[2])
        end

        # Chequear límites del grid
        if posicion_act[1] < 1 || posicion_act[1] > 40  # Supone que el grid es 40x40
            posicion_act = (agent.pos[1], agent.pos[2] + 1)  # Cambiar de fila
        end

        move_agent!(agent, posicion_act, model)

        # Revisa si hay una caja en la nueva posición
        for neighbor in allagents(model)
            if isa(neighbor, box) && neighbor.status == waiting && neighbor.pos == agent.pos
                neighbor.status = taken
                agent.capacity = full
                remove_agent!(neighbor, model) # Elimina la caja del modelo
                break  # Salir del bucle al encontrar una caja
            end
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

                # Verificar si el angar ahora tiene 5 cajas
                if closest_angar.boxes == 5
                    # Crear un nuevo angar cerca
                    new_angar_pos = (closest_angar.pos[1], closest_angar.pos[2] + 1) # Ejemplo: crear arriba
                    add_agent!(angar, model; pos = new_angar_pos)
                     # Reiniciamos las cajas en el angar original
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

    # Generar posiciones aleatorias para los robots
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

    # Bloquear posiciones alrededor de los robots
    bloqueadas = []
    for robot_pos in robot_positions
        append!(bloqueadas, [(robot_pos[1] + dx, robot_pos[2] + dy) for dx in -1:1, dy in -1:1])
    end

    # Filtrar las posiciones para las cajas
    posicion_co = setdiff(mezcla, bloqueadas)

    if length(posicion_co) < number
        error("No hay suficientes posiciones válidas para las cajas")
    end

    # Add boxes to valid positions
    for i in 1:number
        add_agent!(box, model; pos = posicion_co[i])
    end

    num_angar = round(Int, num_robots)

    # Añadir angars a posiciones aleatorias válidas
    angar_positions = []
    for robot_pos in robot_positions
        if !any(agent -> isa(agent, box), agents_in_position(robot_pos, model))
            add_agent!(angar, model; pos = robot_pos)
            push!(angar_positions, robot_pos)
        end
    end

    return model
end
