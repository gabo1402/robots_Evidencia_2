import json
from py3dbp import Packer, Bin, Item
import time
from decimal import Decimal

start = time.time()

# Cargar datos de las cajas desde el archivo JSON
with open("cajas.json", "r") as file:
    data = json.load(file)

# Dividir las cajas en 5 grupos
total_cajas = data["cajas"]
grupos = [total_cajas[i::5] for i in range(5)]  # Dividir en 5 grupos

# Inicializar los packers y bins para cada grupo
packers = []
for i in range(5):
    packer = Packer()
    box = Bin(
        id=f'group_{i + 1}',
        WHD=(22, 10, 32),  # Medidas del packer
        max_weight=28080,
        put_type=0
    )
    packer.addBin(box)
    packers.append(packer)

# Añadir las cajas a los packers correspondientes
for idx, grupo in enumerate(grupos):
    for caja in grupo:
        packers[idx].addItem(Item(
            id=str(caja["identifier"]),
            name="Caja",
            typeof="cube",
            WHD=(caja["width"], caja["height"], caja["depth"]),
            weight=caja["weight"],
            level=1,
            loadbear=100,
            updown=True,
            color="#FF5733"
        ))

# Calcular el empaquetado para cada packer
output_data = []
for idx, packer in enumerate(packers):
    packer.pack(
        bigger_first=True,
        distribute_items=False,
        fix_point=False,
        check_stable=False,
        support_surface_ratio=0.75,
        number_of_decimals=0
    )

    # Margen y posición inicial del packer en el eje X
    x_inicial = 1 + idx * (22 + 2)

    # Ajustar las posiciones de las cajas
    for box in packer.bins:
        for item in box.items:
            dimensions = item.getDimension()
            rotation_type = item.rotation_type # Obtener el tipo de rotación
            output_data.append({
                "id": int(item.id),
                "position": [
                    float(item.position[0]) + x_inicial,  
                    float(item.position[1]) + 1,         
                    float(item.position[2]) + 2          
                ],
                "dimensions": dimensions,
                "rotation_type": rotation_type,  # Añadir el tipo de rotación
                "robot": int(idx + 1)
            })


# Función personalizada para manejar tipos no serializables
def custom_encoder(obj):
    if isinstance(obj, Decimal):
        return float(obj)  # Convertir Decimal a float
    raise TypeError(f"Object of type {type(obj).__name__} is not JSON serializable")

# Guardar los resultados en un archivo JSON
output_file = "cajas1.json"
with open(output_file, "w") as outfile:
    json.dump({"fitted_items": output_data}, outfile, indent=4, default=custom_encoder)

print(f"Archivo JSON generado: {output_file}")

# Imprimir el tiempo total de ejecución
stop = time.time()
print('Tiempo de ejecución:', stop - start)
