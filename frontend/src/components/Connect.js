import React from 'react';

export default function Connect(props) {
    return(
        <div className="open-container">
            <h1 className="open-title">Learn 2 Earn!</h1>
            <p className="open-desc">Earn boosted yield from DeFi as you learn!</p>
            {props.currentAccount ?
                <>
                    <h2 className='sub-title'>Welcome back {props.currentAccount}!</h2>
                    <button className="open-btn" onClick={props.toggle}>Take Quiz</button>
                </>
            : <button className="open-btn" onClick={props.connectWallet}>Login with Metamask</button>}
        </div>
    )
}
