import React, {useState, useEffect} from 'react';
import Connect from './components/Connect';
import Questions from './components/Questions';
import abi from "./artifacts/LearnToEarn.json";
import {ethers} from "ethers";

function App() {
  const [finalScore, setFinalScore] = useState(0);
  const [isOpen, setIsOpen] = useState(false);
  const [trivia, setTrivia] = useState([]);
  const [answer, setAnswer] = useState({});
  const [checkAns, setCheckAns] = useState(false);
  const [currentAccount, setCurrentAccount] = useState("");
  const [isStudent, setIsStudent] = useState(false);
  const [sessions, setSessions] = useState(0);
  const [tuitionFee, setTuitionFee] = useState(0);
  const [acceptNew, setAcceptNew] = useState(false);
  const contractAdd = "0xadEC25d0c67221Ae483DBD5Bef8Ac90f842dD330";
  const contractABI = abi.abi;

  const checkIfWalletIsConnected = async () => {
    try {
        const { ethereum } = window;
        if (!ethereum) {
            alert("Please install an ethereum compatible wallet!");
            return;
        }
        const accounts = await ethereum.request({method: "eth_accounts"});
        if (accounts.length !== 0) {
            const account = accounts[0];
            setCurrentAccount(account);
        } else {
            console.log("No authorised account found")
        }
    } catch (error) {
        console.log(error);
    }
  }

  const connectWallet = async () => {
      try {
          const { ethereum } = window;
          if (!ethereum) {
              alert("Please install an ethereum wallet");
              return;
          }
          const accounts = await ethereum.request({ method: "eth_requestAccounts" });
          setCurrentAccount(accounts[0]);
      } catch (error) {
          console.log(error)
      }
  }

  const register = async () => {
    const {ethereum} = window;
    try {
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const learn2earnContract = new ethers.Contract(contractAdd, contractABI, signer);
        await learn2earnContract.register({ value: ethers.utils.parseUnits(tuitionFee, "ether") });
        const [check, ] = await learn2earnContract.isStudent(await signer.getAddress());
        setIsStudent(check);
      } else console.log("Ethereum object not present");
    } catch (err) {console.log(err)}
  }

  const tuition = (event) => {
    setTuitionFee(event.target.value);
  }

  const ping = async () => {
    if (checkAns === true && finalScore > trivia.length/2) {
      const {ethereum} = window;
      try {
        if (ethereum) {
          const provider = new ethers.providers.Web3Provider(ethereum);
          const signer = await provider.getSigner();
          const learn2earnContract = new ethers.Contract(contractAdd, contractABI, signer);
          await learn2earnContract.ping();
        } else console.log("Ethereum object not present");
      } catch (err) {console.log(err)}
    }
    if (checkAns === true && finalScore < trivia.length/2) {
      alert("You need to pass the assessment to record your learning - try again!")
    }
  }

  function shuffle(array) {
    let currentIndex = array.length,  randomIndex;
    while (currentIndex !== 0) {
      randomIndex = Math.floor(Math.random() * currentIndex);
      currentIndex--;
      [array[currentIndex], array[randomIndex]] = [
        array[randomIndex], array[currentIndex]];
    }
    return array;
  }

  function processData(obj) {
    let results = obj.results
    for (let i=0; i < results.length; i++) {
      let ans = (results[i].incorrect_answers).concat(results[i].correct_answer)
      shuffle(ans)
      results[i].options = ans
    }
    return results;
  }

  function handleChange(event) {
    const {name, value} = event.target
    setAnswer(prevFormData => {
      return {...prevFormData,
        [name]: value
        }
    })
  }

  function toggle() {
    setIsOpen(prev => !prev);
  }

  function handleSubmit(event) {
    event.preventDefault();
    setCheckAns(true);
    setFinalScore(trivia.reduce((score, triv) => {
      let qstns = Object.keys(answer)
      for (let i = 0; i <qstns.length; i++) {
        if (qstns[i] === triv.question && answer[qstns[i]] === triv.correct_answer) {
          score ++;
        }
      }
      return score;
    }, 0));
  }

  const fetchData = async () => {
    const res = await fetch('https://opentdb.com/api.php?amount=5&category=18');
    const data = await res.json();
    setTrivia(processData(data));
  }

  function resetQuiz() {
    setCheckAns(false);
    setFinalScore(0);
    fetchData().catch(console.error);
  }

  useEffect(function () {
    checkIfWalletIsConnected();
    fetchData().catch(console.error)
  }, [])

  useEffect(() => {
    const contractData = async () => {
      const {ethereum} = window;
      try {
        if (ethereum) {
          const provider = new ethers.providers.Web3Provider(ethereum);
          const signer = provider.getSigner();
          const learn2earnContract = new ethers.Contract(contractAdd, contractABI, signer);
          const lessons = await learn2earnContract.sessions();
          const accepting = await learn2earnContract.open();
          const [check, ] = await learn2earnContract.isStudent(await signer.getAddress());
          setIsStudent(check);
          setSessions(ethers.utils.formatUnits(lessons, 0));
          setAcceptNew(accepting);
        } else console.log("Ethereum object not present");
      } catch (err) {console.log(err)}
    }
    contractData();
  }, [currentAccount])

  useEffect(() => {
    ping();
  }, [finalScore])

  const QnA = trivia.length>0 ? trivia.map(triv => {
    return(<Questions
      key={triv.question}
      question={triv.question}
      options={triv.options}
      correct={triv.correct_answer}
      answer={answer}
      handleChange={handleChange}
      checkAns={checkAns}
    />)}) : <p>Loading...</p>

  return (
    <div className="App">
      {!isOpen &&
        <Connect toggle={toggle} connectWallet={connectWallet}
          currentAccount={currentAccount} isStudent={isStudent}
          register={register} acceptNew={acceptNew}
          sessions={sessions} tuition={tuition}
          tuitionFee={tuitionFee}
          />}
      {isOpen && <div className="quiz">
        <h2 className="title">Here is today's assignment</h2>
        {QnA}
        {checkAns ? <div className='score-reset'>
          <p className='score'>You scored {finalScore}/{trivia.length} correct answers</p>
          <button className='open-btn' onClick={resetQuiz}>Next Test</button>
        </div> : <div className='check-ans'><button className='open-btn' onClick={(e) => handleSubmit(e)}>Check Answers</button></div>}
      </div>}
    </div>
  );
}

export default App;
