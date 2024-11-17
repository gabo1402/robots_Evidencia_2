using Agents, Random
using StaticArrays: SVector
using JSON3  

function read_list_data(file_path)
    try
        json_string = read(file_path, String)  # Lee el archivo como un string
        data = JSON3.read(json_string)  # Parsea el string como JSON con JSON3
        println("Datos leídos correctamente:")
        return data  # Retorna los datos procesados
    catch e
        println("Error al leer el archivo JSON: ", e)
        return nothing  # Retorna nothing en caso de error
    end
end

@enum BoxStatus waiting taken developed
@enum RobotStatus empty full

normal = 0
left = π/2
down = π
right = 3π/2

@agent struct box(GridAgent{3})  
    identifier::Int  # Nombre alternativo en lugar de id
    status::BoxStatus = waiting
    width::Float64
    height::Float64
    depth::Float64
    weight::Float64
end

@agent struct robot(GridAgent{3})  
    identifier::Int  # Identidad única del robot
    capacity::RobotStatus = empty
    orientation::Float64 = normal
    last_box::Union{Nothing, Tuple{Int64, Float64, Float64, Float64, Float64}} = nothing  # Para recordar la caja eliminada
end

@agent struct angar(GridAgent{3})  
    boxes::Int = 0 
end

function agent_step!(agent::box, model)
end

function agent_step!(agent::angar, model)
end

function closest_box(agent::robot, model, fitted_items)
    for item in fitted_items
        if item["robot"] == agent.identifier  # Verifica que la caja esté asignada al robot
            for neighbor in allagents(model)
                if isa(neighbor, box) && neighbor.status == waiting && neighbor.identifier == item["id"]
                    return neighbor  # Retorna la caja que corresponde
                end
            end
        end
    end
    return nothing  # No se encontró ninguna caja asignada
end


function target_position_nearby(agent::robot, model, fitted_items)
    if agent.last_box !== nothing
        caja_id, _, _, _, _ = agent.last_box  # Extrae el ID de la última caja transportada

        # Busca la posición asociada a la caja en el JSON
        for item in fitted_items
            if item["id"] == caja_id
                return SVector(item["position"]...)  # Devuelve la posición en formato SVector
            end
        end
    end

    return nothing  # Si no encuentra una posición válida
end

function agent_step!(agent::robot, model)
    # Leer los datos del JSON
    fitted_items = read_list_data("C:/Users/gainl/.julia/evidencia 1/cajas1.json")["fitted_items"]
    
    if fitted_items === nothing || isempty(fitted_items)
        println("No hay datos en fitted_items.")
        return
    end

    if agent.capacity == empty
        # Buscar la siguiente caja en la lista del JSON
        closest_box1 = closest_box(agent, model, fitted_items)

        # Si encontramos una caja, procedemos a mover el agente hacia ella
        if closest_box1 !== nothing
            println("El robot está buscando la caja con ID: $(closest_box1.identifier)")
            obj_pos = closest_box1.pos
            actual_pos = agent.pos

            diff_x = obj_pos[1] - actual_pos[1]
            diff_y = obj_pos[2] - actual_pos[2]
            diff_z = obj_pos[3] - actual_pos[3]

            if abs(diff_x) > abs(diff_y) && abs(diff_x) > abs(diff_z)
                posicion_act = (actual_pos[1] + sign(diff_x), actual_pos[2], actual_pos[3])
            elseif abs(diff_y) > abs(diff_z)
                posicion_act = (actual_pos[1], actual_pos[2] + sign(diff_y), actual_pos[3])
            else
                posicion_act = (actual_pos[1], actual_pos[2], actual_pos[3] + sign(diff_z)) 
            end

            move_agent!(agent, posicion_act, model)

            if agent.pos == closest_box1.pos
                agent.last_box = (closest_box1.identifier, closest_box1.width, closest_box1.height, closest_box1.depth, closest_box1.weight)
                closest_box1.status = taken
                agent.capacity = full
                remove_agent!(closest_box1, model)  
                println("El robot ha recogido la caja con ID: $(agent.last_box[1])")
            end
        else
            # Si no se encuentra ninguna caja, mover el robot a (20, 1, 20)
            target_position = (20, 1, 20)
            println("No se encontró una caja disponible. El robot se dirige a la posición de espera $(target_position).")
            obj_pos = SVector{3}(target_position...)
            actual_pos = agent.pos

            diff_x = obj_pos[1] - actual_pos[1]
            diff_y = obj_pos[2] - actual_pos[2]
            diff_z = obj_pos[3] - actual_pos[3]

            if abs(diff_x) > abs(diff_y) && abs(diff_x) > abs(diff_z)
                posicion_act = (actual_pos[1] + sign(diff_x), actual_pos[2], actual_pos[3])
            elseif abs(diff_y) > abs(diff_z)
                posicion_act = (actual_pos[1], actual_pos[2] + sign(diff_y), actual_pos[3])
            else
                posicion_act = (actual_pos[1], actual_pos[2], actual_pos[3] + sign(diff_z)) 
            end

            move_agent!(agent, posicion_act, model)
        end

    elseif agent.capacity == full
        # Buscar la posición objetivo para entregar la caja
        target_position = target_position_nearby(agent, model, fitted_items)

        if target_position !== nothing
            println("El robot está llevando la caja con ID: $(agent.last_box[1]) hacia la posición: $(target_position)")
            obj_pos = SVector{3}(target_position...)
            actual_pos = agent.pos

            diff_x = obj_pos[1] - actual_pos[1]
            diff_y = obj_pos[2] - actual_pos[2]
            diff_z = obj_pos[3] - actual_pos[3] 

            if abs(diff_x) > abs(diff_y) && abs(diff_x) > abs(diff_z)
                posicion_act = (actual_pos[1] + sign(diff_x), actual_pos[2], actual_pos[3])
            elseif abs(diff_y) > abs(diff_z)
                posicion_act = (actual_pos[1], actual_pos[2] + sign(diff_y), actual_pos[3])
            else
                posicion_act = (actual_pos[1], actual_pos[2], actual_pos[3] + sign(diff_z))  # Movimiento en Z
            end

            move_agent!(agent, posicion_act, model)

            if agent.pos == Tuple(target_position)
                # Si ya está en la posición objetivo, coloca la caja
                agent.capacity = empty
                println("El robot ha entregado la caja con ID: $(agent.last_box[1]) en la posición $(target_position)")
                
                if agent.last_box !== nothing
                    identifier, width, height, depth, weight = agent.last_box
                    
                    # Crear y agregar la caja al modelo
                    add_agent!(box, model; 
                        pos = Tuple(target_position), 
                        identifier = identifier, 
                        width = width, 
                        height = height, 
                        depth = depth, 
                        weight = weight, 
                        status = developed
                    )
                    
                    # Imprimir los valores de la caja para verificar
                    println("Caja colocada: ID=$identifier, Posición=$(Tuple(target_position)), Dimensiones=(Width=$width, Height=$height, Depth=$depth), Peso=$weight")

                    agent.last_box = nothing  # El robot ya no recuerda la última caja
                end
            end
        else
            println("No se encontró una posición objetivo para la caja transportada.")
        end
    end
end




function initialize_model(; number = 5, griddims = (40, 40, 40), file_path = "C:/Users/gainl/.julia/evidencia 1/cajas1.json")
    space = GridSpace(griddims; periodic = false, metric = :manhattan)
    model = StandardABM(Union{robot, box, angar}, space; agent_step!, scheduler = Schedulers.fastest)

    list_data = read_list_data(file_path)
    if list_data === nothing
        error("No se pudieron cargar los datos del JSON.")
    end

    caja_dimensiones = [
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0),
        (width=1.2, height=1.2, depth=1.2, weight=15.0),
        (width=1.0, height=1.0, depth=1.0, weight=10.0)
        ]


    all_positions = [(x, 1, z) for x in 1:griddims[1], z in 1:griddims[3]]
    mezcla = shuffle(all_positions)

    num_robots = 2
    bottom_z = 1 
    posicion_ini = div(griddims[1], 10)
    spacing = 2 * posicion_ini
    robot_columns = [posicion_ini + (i - 1) * spacing for i in 1:num_robots]
    robot_positions = [(col, bottom_z, bottom_z) for col in robot_columns] 

    # Crear y añadir robots con identificadores únicos
    for (i, robot_pos) in enumerate(robot_positions)
        add_agent!(robot, model; pos = robot_pos, identifier = i)
        println("Robot añadido: ID=$i, Posición=$robot_pos")
    end

    bloqueadas = []
    for robot_pos in robot_positions
        append!(bloqueadas, [(robot_pos[1] + dx, robot_pos[2] + dy, robot_pos[3] + dz) for dx in -1:1, dy in -1:1, dz in -1:1])
    end

    posicion_co = setdiff(mezcla, bloqueadas)
    if length(posicion_co) < number
        error("No hay suficientes posiciones válidas para las cajas")
    end

    # Asigna identificadores únicos a cada caja
    for i in 1:number
        dims = caja_dimensiones[i]
        pos = posicion_co[i]
        add_agent!(box, model; identifier = i, pos = pos, status = waiting, width = dims.width, height = dims.height, depth = dims.depth, weight = dims.weight)
        
        # Imprime la información de la caja añadida
        println("Caja añadida: ID=$i, Posición=$pos, Dimensiones=(Width=$(dims.width), Height=$(dims.height), Depth=$(dims.depth)), Peso=$(dims.weight)")
    end
    
    

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