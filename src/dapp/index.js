
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';


(async () => {

    let result = null;

    let contract = new Contract('localhost', async () => {

        // Read transaction
        contract.isOperational((error, result) => {
         
            display('Operational Status', 'Check if contract is operational', [{ label: 'Operational Status', error: error, value: result }]);
        });

        


          // Display last Registred flight ,fixed in the code for easy simulation 
        
        
        display('flights', 'Flight details', [{ label: '', error:'', value: `flight : ${contract.flight}  Time: ${contract.timestamp} AirLineAddress: ${contract.firstairline}` }]);
        // display passenger balnace 

        let balance= await contract.web3.eth.getBalance(contract.firstpassenger); 
        display('Passenger Balance', 'Balance', [{ label: '', error:'', value: `Balance : ${contract.web3.utils.fromWei(balance,'ether')} ETH` }]);
        
         
        // User-submitted transaction (request to verify the flight status)
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flight =contract.flight;// DOM.elid('flight-number').value;
            // Write transaction
            contract.fetchFlightStatus(flight, (error, result) => {
                display('Oracles', 'Trigger oracles', [{ label: 'Fetch Flight Status', error: error, value: result.flight + ' ' + new Date(parseInt(result.timestamp,10)*1000).toUTCString() }]);
            });
        })

 // User-submitted transaction (purchasing insurance )
        DOM.elid('purchase').addEventListener('click', () => {
             
            // Write transaction
            contract.purchaseInsurance( (error, result) => {
                
                display('Purchase', 'Trigger Insuarnce purchase', [{ label: 'submit purchase', error: error, value: `${contract.firstpassenger} ${contract.flight}` }]);
            });
        })

// User-submitted transaction (withdrawcredit)
DOM.elid('withdraw-credit').addEventListener('click', () => {
             
    // Write transaction
    contract.withdrawCredit( (error, result) => {
       
        display('withdraw-credit', 'Trigger widraw credits purchase', [{ label: 'submit widraw-credit', error: error, value: `${contract.firstpassenger} ${contract.flight}` }]);
    });
})

        



    });


})();


function display(title, description, results) {
    let displayDiv = DOM.elid("display-wrapper");
    let section = DOM.section();
    section.appendChild(DOM.h2(title));
    section.appendChild(DOM.h5(description));
    results.map((result) => {
        let row = section.appendChild(DOM.div({ className: 'row' }));
        row.appendChild(DOM.div({ className: 'col-sm-4 field' }, result.label));
        row.appendChild(DOM.div({ className: 'col-sm-8 field-value' }, result.error ? String(result.error) : String(result.value)));
        section.appendChild(row);
    })
    displayDiv.append(section);

}







