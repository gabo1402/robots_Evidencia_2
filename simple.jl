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
function guardar_cajas_en_json(model, ruta_archivo)
    cajas = []

    for agente in allagents(model)
        if isa(agente, box)
            push!(cajas, Dict(
                "identifier" => agente.identifier,
                "width" => agente.width,
                "height" => agente.height,
                "depth" => agente.depth,
                "weight" => agente.weight,
            ))
        end
    end

    json_data = Dict("cajas" => cajas)
    open(ruta_archivo, "w") do archivo
        write(archivo, JSON3.write(json_data))
    end

    println("Archivo '$(ruta_archivo)' creado con éxito.")
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
    fitted_items = read_list_data("C:/Users/gainl/.julia/loquesea/cajas1.json")["fitted_items"]

    if agent.capacity == empty
        closest_box1 = closest_box(agent, model, fitted_items)
        
        if closest_box1 !== nothing
            println("El robot está buscando la caja con ID: $(closest_box1.identifier)")
            obj_pos = closest_box1.pos
            actual_pos = agent.pos

            # Movimiento por pasos: primero en Y, luego en Z, y finalmente en X
if actual_pos[2] != obj_pos[2]
    posicion_act = (actual_pos[1], actual_pos[2] + sign(obj_pos[2] - actual_pos[2]), actual_pos[3])
elseif actual_pos[3] != obj_pos[3]
    posicion_act = (actual_pos[1], actual_pos[2], actual_pos[3] + sign(obj_pos[3] - actual_pos[3]))
elseif actual_pos[1] != obj_pos[1]
    posicion_act = (actual_pos[1] + sign(obj_pos[1] - actual_pos[1]), actual_pos[2], actual_pos[3])
else
    posicion_act = (actual_pos[1], actual_pos[2], actual_pos[3])  # Ya en la posición deseada
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
            # Posiciones de espera en hilera
            waiting_positions = [(45, 1, 55), (50, 1, 55), (55, 1, 55), (60, 1, 55), (65, 1, 55)]
            robot_index = agent.identifier
            target_position = waiting_positions[robot_index]
            
            println("No se encontró una caja disponible. El robot $robot_index se dirige a la posición de espera $(target_position).")
            obj_pos = SVector{3}(target_position...)
            actual_pos = agent.pos

            # Movimiento por pasos: primero en Y, luego en Z, y finalmente en X
if actual_pos[2] != obj_pos[2]
    posicion_act = (actual_pos[1], actual_pos[2] + sign(obj_pos[2] - actual_pos[2]), actual_pos[3])
elseif actual_pos[3] != obj_pos[3]
    posicion_act = (actual_pos[1], actual_pos[2], actual_pos[3] + sign(obj_pos[3] - actual_pos[3]))
elseif actual_pos[1] != obj_pos[1]
    posicion_act = (actual_pos[1] + sign(obj_pos[1] - actual_pos[1]), actual_pos[2], actual_pos[3])
else
    posicion_act = (actual_pos[1], actual_pos[2], actual_pos[3])  # Ya en la posición deseada
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

            # Movimiento por pasos: primero en X, luego en Z
            if actual_pos[1] != obj_pos[1]
                posicion_act = (actual_pos[1] + sign(obj_pos[1] - actual_pos[1]), actual_pos[2], actual_pos[3])
            elseif actual_pos[3] != obj_pos[3]
                posicion_act = (actual_pos[1], actual_pos[2], actual_pos[3] + sign(obj_pos[3] - actual_pos[3]))
            elseif actual_pos[2] != obj_pos[2]
                posicion_act = (actual_pos[1], actual_pos[2] + sign(obj_pos[2] - actual_pos[2]), actual_pos[3])
            else
                posicion_act = (actual_pos[1], actual_pos[2], actual_pos[3])  # Ya en la posición objetivo
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
                    
                    println("Caja colocada: ID=$identifier, Posición=$(Tuple(target_position)), Dimensiones=(Width=$width, Height=$height, Depth=$depth), Peso=$weight")
                    agent.last_box = nothing
                end
            end
        else
            println("No se encontró una posición objetivo para la caja transportada.")
        end
    end
end



function initialize_model(; number = 40, griddims = (150, 50, 100))
    space = GridSpace(griddims; periodic = false, metric = :manhattan)
    model = StandardABM(Union{robot, box, angar}, space; agent_step!, scheduler = Schedulers.fastest)
    

    caja_dimensiones = [
        (width=5, height=5, depth=5, weight=10.0),
        (width=7, height=7, depth=7, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=7, height=7, depth=7, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=5, height=5, depth=5, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=5, height=5, depth=5, weight=10.0),
        (width=5, height=5, depth=5, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=7, height=7, depth=7, weight=10.0),
        (width=5, height=5, depth=5, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=5, height=5, depth=5, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=5, height=5, depth=5, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=7, height=7, depth=7, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=5, height=5, depth=5, weight=10.0),
        (width=5, height=5, depth=5, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        (width=7, height=7, depth=7, weight=10.0),
        (width=1, height=1, depth=1, weight=10.0),
        ]


    # Generación de posiciones para las cajas con la restricción de z >= 40
    all_positions = [(x, 1, z) for x in 1:griddims[1], z in 1:griddims[3]]
    # Filtrar posiciones para que x sea uno de los valores permitidos y z >= 40
    allowed_x = [5, 20, 40, 60, 70, 80, 90, 100, 120, 140]
    filtered_positions = filter(pos -> pos[1] in allowed_x && pos[3] >= 40, all_positions)
    mezcla = shuffle(filtered_positions)


    num_robots = 5
robot_positions = [(12, 1, 35), (36, 1, 35), (61, 1, 35), (86, 1, 35), (109, 1, 35)]

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
    # Asigna identificadores únicos a cada caja
    for i in 1:number
        dims = caja_dimensiones[i]
        pos = mezcla[i]
    
        add_agent!(box, model; identifier = i, pos = pos, status = waiting, 
                width = dims.width, height = dims.height, depth = dims.depth, 
                weight = dims.weight)
    
        # Imprime la información de la caja añadida
        println("Caja añadida: ID=$i, Posición=$pos, Dimensiones=(Width=$(dims.width), Height=$(dims.height), Depth=$(dims.depth)), Peso=$(dims.weight)")
    end

    
    
    

    num_angar = 5
angar_positions = [(1, 1, 2), (25, 1, 2), (49, 1, 2), (74, 1, 2), (97, 1, 2)]
#medida de cada angar (22,10,32)

for i in 1:num_angar
    pos = angar_positions[i]
    if !any(agent -> isa(agent, box), agents_in_position(pos, model))
        add_agent!(angar, model; pos = pos)
    end
end

    ruta_archivo = "cajas.json"
    guardar_cajas_en_json(model, ruta_archivo)


    return model
end