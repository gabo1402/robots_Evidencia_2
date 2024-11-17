import json
from py3dbp import Packer, Bin, Item, Painter
import time
from decimal import Decimal

start = time.time()

# Cargar datos de las cajas desde el archivo JSON
with open("cajas.json", "r") as file:
    data = json.load(file)

# Inicializar la función de empaque
packer = Packer()

# Definir el contenedor (20ft Steel Dry Cargo Container)
box = Bin(
    id='example0',
    WHD=(589.8, 243.8, 259.1),
    max_weight=28080,
    put_type=0
)

packer.addBin(box)

# Añadir las cajas al packer
for caja in data["cajas"]:
    packer.addItem(Item(
        id=str(caja["identifier"]),
        name="Caja",
        typeof="cube",
        WHD=(caja["width"] * 100, caja["height"] * 100, caja["depth"] * 100),  # Convertir de m a cm
        weight=caja["weight"],
        level=1,
        loadbear=100,
        updown=True,
        color="#FF5733"
    ))

# Calcular el empaquetado
packer.pack(
    bigger_first=True,
    distribute_items=False,
    fix_point=False,
    check_stable=False,
    support_surface_ratio=0.75,
    number_of_decimals=0
)

# Preparar los resultados para guardarlos en JSON
output_data = []

for box in packer.bins:
    output_data.append({
        "fitted_items": [{"id": item.id, "position": [float(p) for p in item.position]} for item in box.items]  # Convertimos posiciones a float
    })

# Función personalizada para manejar tipos no serializables
def custom_encoder(obj):
    if isinstance(obj, Decimal):
        return float(obj)  # Convierte Decimal a float
    raise TypeError(f"Object of type {type(obj).__name__} is not JSON serializable")

# Guardar los resultados en un archivo JSON
output_file = "resultados_cajas.json"
with open(output_file, "w") as outfile:
    json.dump(output_data, outfile, indent=4, default=custom_encoder)

print(f"Archivo JSON generado: {output_file}")

# Imprimir el tiempo total de ejecución
stop = time.time()
print('Tiempo de ejecución:', stop - start)
