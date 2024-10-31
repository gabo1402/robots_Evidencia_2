import { Button, ButtonGroup, CheckboxField, SliderField, SwitchField } from '@aws-amplify/ui-react';
import { useRef, useState } from 'react'
import '@aws-amplify/ui-react/styles.css';

function App() {
  let [location, setLocation] = useState("");
  let [gridSize, setGridSize] = useState(80);
  let [simSpeed,setSimSpeed] = useState(2);
  const sizing = 12.5;
  const running = useRef(null);
  let [pasos, setPasos] = useState(0);
  let [sliderGridSize, setSliderGridSize] = useState(80);
  let [number, setNumber] = useState(40);
  let [boxes, setBoxes] = useState([]);
  let [robots, setRobots] = useState([]);
  let [angars, setAngars] = useState([]);
  

  let setup = () => {
    setGridSize(sliderGridSize);
    fetch("http://localhost:8000/simulations", {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        dim: [sliderGridSize, sliderGridSize],
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
        setPasos(prev => prev + 1);
      });
    }, 3000 / simSpeed);
  };

  let handleStop = () => {
    clearInterval(running.current);
  };
  let offset = ((sizing * sliderGridSize) - gridSize * 12) / 2;

  return (
    <>
      <ButtonGroup variation="primary">
        <Button onClick={setup}>Setup</Button>
        <Button onClick={handleStart}>Start</Button>
        <Button onClick={handleStop}>Stop</Button>
      </ButtonGroup>

      <SliderField label="Grid size" min={40} max={80} step={10}
        value={sliderGridSize} onChange={setSliderGridSize} />
      <SliderField label="Simulation speed" min={1} max={30}
        value={simSpeed} onChange={setSimSpeed} />
      
      <p>Pasos: {pasos}</p> 

      <svg width={sizing * sliderGridSize} height={sizing * sliderGridSize} xmlns="http://www.w3.org/2000/svg" style={{backgroundColor:"white"}}>
        {boxes.map(box => (
          <image
            key={box["id"]}
            x={(box["pos"][0] - 1) * sizing} 
            y={(box["pos"][1] - 1) * sizing} 
            width={sizing}  
            height={sizing} 
            href={"./boxA.png"} 
          />
        ))}
        {robots.map(robot => (
          <image
            key={robot["id"]}
            x={(robot["pos"][0] - 1) * sizing} 
            y={(robot["pos"][1] - 1) * sizing} 
            width={sizing}  
            height={sizing} 
            href={"./dron1.png"} 
          />
        ))}
        {angars.map(angar => (
          <image
            key={angar["id"]}
            x={(angar["pos"][0] - 1) * sizing} 
            y={(angar["pos"][1] - 1) * sizing} 
            width={sizing}  
            height={sizing} 
            href={"./angar.svg"} 
          />
        ))}
      </svg>
    </>
  )
}

export default App

