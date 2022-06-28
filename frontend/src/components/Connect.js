import React from 'react';
import YoutubeEmbed from "./YoutubeEmbed";

export default function Connect(props) {

    const Registration = (x) => { return(
        x.registered ?
        <>
            <h2 className='sub-title'>Welcome back, {x.shortenAddress(x.currentAccount)}!</h2>
            <p className='open-desc'><b>Day 1:</b><br/>
            Welcome to Learn 2 Earn, today is our first day and we are very happy that you
            are joining us for this exciting journey into the world of Web3 and everything
            that it contains. There is a lot of information to learn so take your time and
            go through each video and reading in order. After acquiring a deeper understanding
            of Web3, don’t forget to take the quiz and submit your answers on-chain.</p>
            <p className='open-desc'>Happy learning!</p>
            <p className='open-desc'><b>Videos:</b></p>
                <div className="youtube"><YoutubeEmbed embedId="nHhAEkG1y2U" />
                <YoutubeEmbed embedId="2uYuWiICCM0" /></div>
            <p className='open-desc'><b>Articles:</b><br/>
                <a href="https://ethereum.org/en/developers/docs/web2-vs-web3" target="_blank" rel="noopener noreferrer">Web2 vs Web3</a> by ethereum.org<br/>
                <a href="https://cobie.substack.com/p/wtf-is-web3?s=r" target="_blank" rel="noopener noreferrer">WTF is web3</a> by Cobie<br/>
                <a href="https://www.freecodecamp.org/news/what-is-web3" target="_blank" rel="noopener noreferrer">What is web3</a>by freeCodeCamp</p>
            <button className="open-btn" onClick={x.toggle}>Take Quiz</button>
        </> :
        <>
            <h2 className='sub-title'>Hi there, {x.shortenAddress(x.currentAccount)}!</h2>
            <p className='open-desc'>You are not registered yet.{"\n"}
                The frequency of check-in is {x.sessions/60} minutes
            </p>
            <p className='open-desc'>How much tuition would you like to deposit?{"\n"}
                The more you put in, the more you get out!
            </p>
            <label>
                <input type='text' className='input' value={x.tuitionFee} onChange={(e) => x.tuition(e)} />
                ETH
            </label>
            <button className="open-btn" onClick={x.register} disabled={x.loading}>{x.loading ? "Wait for Network" : "Register"}</button>
        </>)
    }
    return(
        <div className="open-container">
            <h1 className="open-title">Learn 2 Earn!</h1>
            <p className="open-desc">Earn boosted yield from DeFi as you learn!</p>
            {props.currentAccount ?
            Registration(props) :
            <button className="open-btn" onClick={props.connectWallet}>Login with Metamask</button>}
        </div>
    )
}
