import { Button, ButtonGroup, SliderField } from '@aws-amplify/ui-react';
import { useRef, useState } from 'react';
import { Canvas } from '@react-three/fiber';
import { OrbitControls } from '@react-three/drei';
import '@aws-amplify/ui-react/styles.css';
import * as THREE from 'three';

function App() {
  let [location, setLocation] = useState("");
  let [gridSize, setGridSize] = useState(150); // Cambiar el tamaño de la cuadrícula a 40
  let [simSpeed, setSimSpeed] = useState(2);
  const running = useRef(null);
  let [pasos, setPasos] = useState(0);
  let [number, setNumber] = useState(40);
  let [boxes, setBoxes] = useState([]);
  let [robots, setRobots] = useState([]);
  let [angars, setAngars] = useState([]);

  let setup = () => {
    setGridSize(100); // Asegurarse de que el tamaño de la cuadrícula sea 40
    fetch("http://localhost:8000/simulations", {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        dim: [150, 50, 100], // Establecer dimensiones fijas
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
    <mesh
      position={[
        position[0] + width / 2,
        position[1] + height / 2,
        position[2] + depth / 2
      ]}
      scale={[width, height, depth]}
    >
      <boxGeometry args={[1, 1, 1]} />
      <meshStandardMaterial color="orange" />
    </mesh>
  );
  

  const Robot = ({ position }) => (
    <mesh position={[position[0], position[1] +0.5, position[2]]} scale={[1, 1, 1]}>
      <boxGeometry args={[1, 1, 1]} />
      <meshStandardMaterial map={new THREE.TextureLoader().load("./dron1.png")} />
    </mesh>
  );
  
  

  const Angar = ({ position }) => {
    // Ajuste para mover el hangar desde su esquina a su centro
    const adjustedPosition = [
      position[0] + 22 / 2, // Desplaza la mitad de la escala en X
      position[1] + 10 / 2, // Desplaza la mitad de la escala en Y
      position[2] + 32 / 2  // Desplaza la mitad de la escala en Z
    ];
  
    return (
      <mesh position={adjustedPosition} scale={[22, 10, 32]}>
        <boxGeometry args={[1, 1, 1]} />
        <meshStandardMaterial 
          color="lightgray" 
          transparent={true} 
          opacity={0.7} 
        />
      </mesh>
    );
  };
  
  

  const Ground = () => (
    <mesh rotation={[-Math.PI / 2, 0, 0]} position={[75, 1, 50]}>
      <planeGeometry args={[170, 120]} />
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

      <Canvas camera={{ position: [25, 20, 70], fov: 50 }}>
        <ambientLight intensity={0.6} />
        <pointLight position={[10, 20, 10]} />
        <OrbitControls />

        <Ground /> {/* Plano de fondo */}
        {boxes.map((box, index) => (
          <Box key={index} position={box.pos} width={box.width} height={box.height} depth={box.depth} />
        ))}
        {robots.map((robot, index) => (
          <Robot key={index} position={robot.pos} />
        ))}
        {angars.map((angar, index) => (
          <Angar key={index} position={angar.pos} />
        ))}
      </Canvas>
    </>
  );
}

export default App;
