import React from 'react';

export default function Connect(props) {
    const Registration = ({status}) => status ?
            <button className="open-btn" onClick={props.toggle}>Take Quiz</button>
            : <>
                <p className='open-desc'>The current cohort has {props.sessions} lessons</p>
                <h2 className='sub-title'>How much do you want to deposit?</h2>
                <label>
                    <input type='text' className='input' onChange={(e) => props.tuition(e)} />
                    ETH
                </label>
                <button className="open-btn" onClick={props.register}>Register</button>
            </>
    return(
        <div className="open-container">
            <h1 className="open-title">Learn 2 Earn!</h1>
            <p className="open-desc">Earn boosted yield from DeFi as you learn!</p>
            {props.currentAccount ?
            <>
                <h2 className='sub-title'>Welcome back {props.currentAccount}!</h2>
                <Registration status={props.isStudent}/>
            </>
            : <button className="open-btn" onClick={props.connectWallet}>Login with Metamask</button>}
        </div>
    )
}
