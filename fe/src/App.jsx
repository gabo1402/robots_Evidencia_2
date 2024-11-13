import { Button, ButtonGroup, SliderField } from '@aws-amplify/ui-react';
import { useRef, useState } from 'react';
import { Canvas } from '@react-three/fiber';
import { OrbitControls } from '@react-three/drei';
import '@aws-amplify/ui-react/styles.css';
import * as THREE from 'three';

function App() {
  let [location, setLocation] = useState("");
  let [gridSize, setGridSize] = useState(40); // Cambiar el tamaño de la cuadrícula a 40
  let [simSpeed, setSimSpeed] = useState(2);
  const running = useRef(null);
  let [pasos, setPasos] = useState(0);
  let [number, setNumber] = useState(40);
  let [boxes, setBoxes] = useState([]);
  let [robots, setRobots] = useState([]);
  let [angars, setAngars] = useState([]);

  let setup = () => {
    setGridSize(40); // Asegurarse de que el tamaño de la cuadrícula sea 40
    fetch("http://localhost:8000/simulations", {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        dim: [40, 40], // Establecer dimensiones fijas
        number: number,
      })
    }).then(resp => resp.json())
    .then(data => {
      setLocation(data["Location"]);
      setBoxes(data["boxes"]);
      setRobots(data["robots"]);
      setAngars(data["angars"]);
      setPasos(0);
    });
  }

  let handleStart = () => {
    running.current = setInterval(() => {
      fetch("http://localhost:8000" + location)
      .then(res => res.json())
      .then(data => {
        setBoxes(data["boxes"]);
        setRobots(data["robots"]);
        setAngars(data["angars"]);
        setPasos(prev => prev + 1);
      });
    }, 1000 / simSpeed);
  };

  let handleStop = () => {
    clearInterval(running.current);
  };

  // Componentes 3D para los elementos, escalados para mejor visibilidad
  const Box = ({ position, width, height, depth }) => (
    <mesh position={position} scale={[width, height, depth]}>
      <boxGeometry args={[1, 1, 1]} />
      <meshStandardMaterial color="orange" /> {/* O usar otro material simple */}
    </mesh>
  );

  const Robot = ({ position }) => (
    <mesh position={position} scale={[1.5, 1.5, 1.5]}>
      <boxGeometry args={[1, 1, 1]} />
      <meshStandardMaterial map={new THREE.TextureLoader().load("./dron1.png")} />
    </mesh>
  );

  const Angar = ({ position }) => (
    <mesh position={position} scale={[5, 5, 5]}>
      {/* Geometría para la estructura del angar (caja hueca) */}
      <boxGeometry args={[1, 1, 1]} />
      {/* Usamos un material con transparencia y sin color sólido para el angar */}
      <meshStandardMaterial 
        color="lightgray" 
        transparent={true} 
        opacity={0.5
      } />
    </mesh>
  );
  

  // Fondo gris como plano
  const Ground = () => (
    <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -0.5, 0]}>
      <planeGeometry args={[60, 60]} />
      <meshStandardMaterial color="#b0b0b0" />
    </mesh>
  );

  return (
    <>
      <ButtonGroup variation="primary">
        <Button onClick={setup}>Setup</Button>
        <Button onClick={handleStart}>Start</Button>
        <Button onClick={handleStop}>Stop</Button>
      </ButtonGroup>

      <SliderField label="Simulation speed" min={1} max={30}
        value={simSpeed} onChange={setSimSpeed} />

      <p>Pasos: {pasos}</p>

      <Canvas camera={{ position: [0, 30, 50], fov: 50 }}>
        <ambientLight intensity={0.6} />
        <pointLight position={[10, 20, 10]} />
        <OrbitControls />

        <Ground /> {/* Plano de fondo */}

        {boxes.map((box) => (
  <Box
    key={box.id}
    position={[(box.pos[0] - 1), 0, (box.pos[1] - 1)]}
    width={box.width}
    height={box.height}
    depth={box.depth}
  />
))}
        {robots.map((robot) => (
          <Robot key={robot.id} position={[(robot.pos[0] - 1), 0, (robot.pos[1] - 1)]} />
        ))}
        {angars.map((angar) => (
          <Angar key={angar.id} position={[(angar.pos[0] - 1), 0, (angar.pos[1] - 1)]} />
        ))}
      </Canvas>
    </>
  );
}

export default App;
