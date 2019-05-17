import 'babel-polyfill';
import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';
const bodyParser = require('body-parser')


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
let flightSuretyData = new web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);
let orcales = [];
const minFund = Web3.utils.toWei('10', 'ether');

let accounts = [];
(async () => {

  accounts = await web3.eth.getAccounts();
 
  try {
    await flightSuretyData.methods.authorizeContract(config.appAddress).send({ from: accounts[0] });
  } catch (e) {
    console.log(e.message)
  }

  let fee = await flightSuretyApp.methods.ORACLE_REGISTRATION_FEE().call()

  accounts.slice(20, 40).forEach(async (oracleAddress) => {
    // const estimateGas = await flightSuretyApp.methods.registerOracle().estimateGas({from: oracleAddress, value: fee});
    try {
       
      await flightSuretyApp.methods.registerOracle().send({ from: oracleAddress, value: fee, gas: 3000000 });
      let indexesResult = await flightSuretyApp.methods.getMyIndexes().call({ from: oracleAddress });
      orcales.push({
        address: oracleAddress,
        indexes: indexesResult
      });
    } catch (e) {
      console.log(e.message)
    }


 
  const timestamp = Math.floor(Date.now() / 1000) + 1000

  

  const flight = 'LY305'  //new flight
  try {

   
    await flightSuretyApp.methods.fund().send({ from: accounts[10], value: minFund, gas: 3000000 });



  } catch (e) {
   
  }
/*
enabele it for testing only
  try {
    await flightSuretyApp.methods.registerFlight(flight, timestamp).send({ from: accounts[10], gas: 3000000 });
    await flightSuretyApp.methods.fetchFlightStatus(accounts[10], flight, timestamp).send({ from: accounts[11], gas: 3000000 });
  } catch (e) {
    console.log("flight reg", e.message);
  }*/
  });
})();
 
flightSuretyApp.events.OracleRequest({
  fromBlock: 0
}, async function (error, event) {
  if (error) { console.log(error); }
  else {
    let randomStatusCode = Math.floor(Math.random() * 6) * 10;
    let eventValue = event.returnValues;
    console.log(`Got a new oracle request event with randome index: ${eventValue.index} for flight: ${eventValue.flight}`);
   
    for (let i = 0; i < orcales.length; i++) {

      for (let idx = 0; idx < 3; idx++) {
        try {

await flightSuretyApp.methods.submitOracleResponse(
  orcales[i].indexes[idx],
  eventValue.airline,
  eventValue.flight,
  eventValue.timestamp,
  randomStatusCode
).send(
  { from: orcales[i].address, gas: 5555555 }
);
console.log(`accepted ${orcales[i].address} ${orcales[i].indexes[idx]} ${randomStatusCode}`);
        }
        catch (e) {
          console.log(`rejected ${orcales[i].address} ${orcales[i].indexes[idx]}  ${randomStatusCode}`);
        }
      }

    }
  }
});

const app = express();
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

// did not use in this project but maybe use it in future implementation
app.get('/flights', async (req, res) => {
  try{
let FlightsKeys=await flightSuretyApp.methods.getFlightsKeys().call();

if (FlightsKeys.length>0){
  let flight= await flightSuretyData.methods.getFlight(FlightsKeys[0]).call({from:config.appAddress});
  let d=new  Date(parseInt(flight[3],10)*1000).toUTCString();
  
  
  
  
  res.json({flight:flight[0],time:new  Date(parseInt(flight[3],10)*1000).toUTCString(),airline:flight[4]});
}
 
}
  catch(e){
    console.log(e.message);
  }
})

export default app;





