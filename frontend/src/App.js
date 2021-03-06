import React, {useState, useEffect} from 'react';
import Connect from './components/Connect';
import Questions from './components/Questions';
import abi from "./artifacts/LearnToEarn.json";
import {ethers} from "ethers";
import quizData from "./L2Equiz.json"

function App() {
  const [finalScore, setFinalScore] = useState(0);
  const [isOpen, setIsOpen] = useState(false);
  const [trivia, setTrivia] = useState([]);
  const [answer, setAnswer] = useState({});
  const [checkAns, setCheckAns] = useState(false);
  const [currentAccount, setCurrentAccount] = useState("");
  const [registered, setRegistered] = useState(false);
  const [sessions, setSessions] = useState(0);
  const [tuitionFee, setTuitionFee] = useState(0);
  const [loading, setLoading] = useState(false);
  const [progress, setProgress] = useState("default");
  const contractAdd = "0x9e343Bf7966d851a2987A0fE0e0aF2F3c9759116";
  const contractABI = abi.abi;

  const shortenAddress = (str) => {
    return str.substring(0, 6) + "..." + str.substring(str.length - 4);
  };

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
            await ethereum.request({
              method: "wallet_switchEthereumChain",
              params: [{ chainId: `0x${Number(4).toString(16)}` }],
            })
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
          await ethereum.request({
            method: "wallet_switchEthereumChain",
            params: [{ chainId: `0x${Number(4).toString(16)}` }],
          })
      } catch (error) {
          console.log(error)
      }
  }

  const register = async () => {
    setLoading(true);
    const {ethereum} = window;
    try {
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const learn2earnContract = new ethers.Contract(contractAdd, contractABI, signer);
        const txn = await learn2earnContract.register({ value: ethers.utils.parseUnits(tuitionFee, "ether") });
        await txn.wait();
        if (txn.hash) setLoading(false);
        const check = await learn2earnContract.getStudentStatus(await signer.getAddress());
        setRegistered(check);
        fetchData().catch(console.error)
      } else console.log("Ethereum object not present");
    } catch (err) {console.log(err)}
  }

  const tuition = (event) => {
    setTuitionFee(event.target.value);
  }

  const ping = async () => {
    setLoading(true);
    if (checkAns === true && finalScore > trivia.length/2) {
      const {ethereum} = window;
      try {
        if (ethereum) {
          const provider = new ethers.providers.Web3Provider(ethereum);
          const signer = await provider.getSigner();
          const learn2earnContract = new ethers.Contract(contractAdd, contractABI, signer);
          const txn = await learn2earnContract.ping();
          await txn.wait();
          if (txn.hash) setLoading(false);
        } else console.log("Ethereum object not present");
      } catch (err) {console.log(err)}
    } else if (checkAns === true && finalScore < trivia.length/2) {
      alert("You need to pass the assessment to record your learning - try again!")
      setLoading(false);
    } else {
      setLoading(false);
    }
  }

  const withdrawFunds = async () => {
    setLoading(true);
    const {ethereum} = window;
    try {
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const learn2earnContract = new ethers.Contract(contractAdd, contractABI, signer);
        const txn = await learn2earnContract.payout();
        await txn.wait();
        if (txn.hash) setLoading(false);
        const check = await learn2earnContract.getStudentStatus(await signer.getAddress());
        setRegistered(check);
      } else {
        console.log("Ethereum object not present");
        setLoading(false);
      }
    } catch (err) {
      console.log(err)
      setLoading(false);
    }
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
    const {ethereum} = window;
    try {
      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const learn2earnContract = new ethers.Contract(contractAdd, contractABI, signer);
        const pingCount = await learn2earnContract.getPingCount(await signer.getAddress());
        setProgress("module" + ethers.utils.formatUnits(pingCount, 0).toString());
      } else console.log("Ethereum object not present");
    } catch (err) {console.log(err)}
  }

  function resetQuiz() {
    setCheckAns(false);
    setFinalScore(0);
    fetchData().catch(console.error)
  }

  useEffect(function () {
    checkIfWalletIsConnected();
  }, [])

  useEffect(() => {
    const contractData = async () => {
      const {ethereum} = window;
      try {
        if (ethereum) {
          const provider = new ethers.providers.Web3Provider(ethereum);
          const signer = provider.getSigner();
          const learn2earnContract = new ethers.Contract(contractAdd, contractABI, signer);
          const lessons = await learn2earnContract.interval();
          const check = await learn2earnContract.getStudentStatus(await signer.getAddress());
          setRegistered(check);
          setSessions(ethers.utils.formatUnits(lessons, 0));
        } else console.log("Ethereum object not present");
      } catch (err) {console.log(err)}
    }
    contractData();
    fetchData().catch(console.error)
  }, [currentAccount])

  useEffect(() => {
    ping();
  }, [finalScore])

  useEffect(() => {
    console.log(progress);
    if (progress !== "default" && progress !== "module0") {
      setTrivia(quizData[progress].questions);
    }
  }, [progress])

  const QnA = trivia.length>0 ? trivia.map((triv,idx) => {
    return(<Questions
      question={triv.question}
      options={triv.answers}
      correct={triv.correct_answer}
      answer={answer}
      handleChange={handleChange}
      checkAns={checkAns}
    />)}) : <p>Loading...</p>

  return (
    <div className="App">
      {!isOpen &&
        <Connect toggle={toggle} connectWallet={connectWallet}
          currentAccount={currentAccount} registered={registered}
          register={register} shortenAddress={shortenAddress}
          sessions={sessions} tuition={tuition} loading={loading}
          tuitionFee={tuitionFee} withdrawFunds={withdrawFunds}
          />}
      {isOpen && <div className="quiz">
        <h2 className="title">Here is today's assignment</h2>
        {QnA}
        {checkAns ? <div className='score-reset'>
          <p className='score'>You scored {finalScore}/{trivia.length} correct answers</p>
          <button className='open-btn' onClick={resetQuiz} disabled={loading}>{loading ? "Pinging Contract" : "Next Test"}</button>
        </div> : <div className='check-ans'><button className='open-btn' onClick={(e) => handleSubmit(e)}>Check Answers</button></div>}
      </div>}
    </div>
  );
}

export default App;
