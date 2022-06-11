import React from 'react';

export default function Questions(props) {
    function htmlDecode(input) {
        let doc = new DOMParser().parseFromString(input, "text/html");
        return doc.documentElement.textContent;
    }

    const styles = (opt, question) => {
        if (props.checkAns) {
            if (opt === props.correct) {
                return {background: "#94D7A2", border: "none"}
            } else if (opt !== props.correct && opt === props.answer[question]) {
                return {background: "#F8BCBC", border:"none", opacity: 0.5}
            } else {
                return {opacity: 0.5}
            }
        }
    }

    const multichoice = props.options.map(opt => {
        return(<div className='opt-container'>
        <input
            type="radio"
            id={opt}
            name={props.question}
            value={opt}
            checked={props.answer[props.question] === opt}
            onChange={(e) => props.handleChange(e)}
        />
        <label className='ques-opt' htmlFor={opt} style={styles(opt, props.question)}>{htmlDecode(opt)}</label></div>
        )
    })

    return(
        <div className='ques-container'>
            <h2 className='ques-title'>{htmlDecode(props.question)}</h2>
            {multichoice}
            <br/>
            <hr/>
        </div>
    )
}
