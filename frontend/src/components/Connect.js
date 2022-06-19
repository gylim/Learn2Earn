import React from 'react';

export default function Connect(props) {
    const Registration = (x) => { return(
        x.isStudent ?
        <>
            <h2 className='sub-title'>Welcome back, {x.shortenAddress(x.currentAccount)}!</h2>
            <p className='open-desc'>
                Click below when you're ready to test your understanding of the material!
            </p>
            <button className="open-btn" onClick={x.toggle}>Take Quiz</button>
        </> :
        <>
            <h2 className='sub-title'>Hi there, {x.shortenAddress(x.currentAccount)}!</h2>
            <p className='open-desc'>You are not registered yet.{"\n"}
                The current cohort has {x.sessions} lessons
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
