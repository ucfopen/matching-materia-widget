//Commenting out because we are bulding CARDS directly in this file
//import { populateTable } from './scoreTableComponents.js';

// Hide default system table
Materia.ScoreCore.hideResultsTable();

const cardListElement = document.getElementById('score-card-list');
const template = document.getElementById('card-template');

const screenReaderTbodyElement = document.getElementById('screenReaderTbody');


const start = (instance, qset, scoreTable, isPreview, qsetVersion) => {
	update(qset, scoreTable)
}

// calculates height so the widget fits
const getRenderedHeight = () => {
    return Math.ceil(parseFloat(window.getComputedStyle(document.querySelector('html')).height)) + 10
}

const update = (qset, scoreTable) => {
	//check if instructor hid answers
	const showAnswers = qset && qset.options ? !qset.options.hide_correct : true;
    const items = qset.items[0].items
    console.log(items)

    const findAudio = (text) => {
        const foundQ = items.find((v)=>(v.questions[0].text == text))
        const foundA = items.find((v)=>(v.answers[0].text == text))
        if(!foundQ && !foundA) return false

        if(foundQ && foundQ.questions[0].text == text) {
            return foundQ.assets[0] != 0
        }

        if(foundA && foundA.answers[0].text == text) {
            return foundA.assets[1] != 0
        }

        return false
    }

	// erase old cards
	if (cardListElement) {
		cardListElement.innerHTML = '';
	}

	if (scoreTable && scoreTable.length > 0) {
		scoreTable.forEach((row, index) => {
			const termText = row.data[0]; 
            const userResponse = row.data[1]; 
            const correctAnswer = showAnswers ? row.data[2] : "Hidden"; 
            const isCorrect = row.score === 100;

            const qIsAudio = findAudio(termText);
            const answerIsAudio = findAudio(userResponse);
            const correctIsAudio = showAnswers ? findAudio(correctAnswer) : false;

            const clone = template.content.cloneNode(true);
            
            const rowContainer = clone.querySelector('.match-row');

            const termPill = clone.querySelector('.term-pill');
            const userPill = clone.querySelector('.user-pill');
            const correctPill = clone.querySelector('.correct-pill');

            const iconBadge = clone.querySelector('.icon-badge');
            const correctionContainer = clone.querySelector('.correction-container');

            if (qIsAudio){ 
                termPill.innerHTML = `<span class="audio-indicator" aria-hidden="true"></span> ${termText || "Term"}`;
            } else { 
                termPill.innerHTML = `${termText || "Term"}`;
            }

            if (answerIsAudio){ 
                userPill.innerHTML = `<span class="audio-indicator" aria-hidden="true"></span> ${userResponse || "No Match"}`;
            } else { 
                userPill.innerHTML = `${userResponse || "No Match"}`;
            }

            if (correctIsAudio){ 
                correctPill.innerHTML = `<span class="audio-indicator" aria-hidden="true"></span> ${correctAnswer || "Term"}`;
            } else { 
                correctPill.innerHTML = `${correctAnswer}`;
            }

            // userPill.textContent = userResponse || "No Match";
            // correctPill.textContent = correctAnswer;

            if (isCorrect) {
                rowContainer.classList.add('state-correct');
                iconBadge.textContent = '✓';
    
                correctionContainer.style.display = 'none';
            } else {
                rowContainer.classList.add('state-incorrect');
                iconBadge.textContent = '✕';
                
                if (showAnswers) {
                    correctionContainer.style.display = 'flex';
                }
            }

            cardListElement.appendChild(clone); 
        });
    }

    const h = getRenderedHeight();
    Materia.ScoreCore.setHeight(h);
}

Materia.ScoreCore.start({
    start: start,
    update: update,
    handleScoreDistribution: (distribution) => {},
});
