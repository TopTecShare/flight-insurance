import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';

export default class Contract {
    constructor(network, callback) {

        let config = Config[network];

        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.flightSuretyData = new this.web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.initialize(callback);
        this.owner = null;
        this.airlines = [];
        this.passengers = [];
        this.appAddress = config.appAddress;
        this.firstairline = null;
        this.firstpassenger = null;
        this.flight = 'LY305';
        this.timestamp = Math.floor(Date.now() / 1000) + 1000;



    }

    async initialize(callback) {
       
            // initalize accounts
            let accts = await this.web3.eth.getAccounts();
            this.owner = accts[0];
            this.firstairline = accts[10];
            this.firstpassenger = accts[11];
            await this.flightSuretyData.methods.authorizeContract(this.appAddress).send({ from: this.owner });
            //fund airline
            await this.flightSuretyApp.methods.fund().send({
                from: this.firstairline, value: this.web3.utils.toWei('10', "ether"),
                gas: 1500000
            });

            //register flight


            await this.flightSuretyApp.methods.registerFlight(this.flight, this.timestamp).send({ from: this.firstairline, gas: 3000000 });


            callback();

        
    }

    isOperational(callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner }, callback);
    }

    getFlightKeys(callback) {
        let self = this;
        self.flightSuretyApp.methods.getFlightsKeys().call(callback);
    }

    purchaseInsurance( callback){
        let self = this;

        console.log(self.firstairline,self.flight,self.timestamp);
 
        self.flightSuretyApp.methods.purchaseInsurance(
            self.firstairline,self.flight,self.timestamp).send({ from: self.firstpassenger,value:Web3.utils.toWei('1', 'ether'),gas: 3000000 }, (error, result) => {
                callback(error, result);
            });

            
            
            
    }


    withdrawCredit( callback){
        let self = this;

      
 
        self.flightSuretyApp.methods.withdrawCredit(
            ).call({ from: self.firstpassenger }, (error, result) => {
                callback(error, result);
            });

            
            
            
    }


    fetchFlightStatus(flight, callback) {
        let self = this;
        let payload = {
            airline: self.firstairline,
            flight: flight,
            timestamp: self.timestamp
        }
        self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner }, (error, result) => {
                callback(error, payload);
            });
    }
}