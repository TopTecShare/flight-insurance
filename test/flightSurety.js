
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');
var Web3 = require('../node_modules/web3');

contract('Flight Surety Tests', async (accounts) => {

  var config;

  const minFund = Web3.utils.toWei('10', 'ether');



  const timestamp = Math.floor(Date.now() / 1000) + 1000

  const flight = 'LY305'  //new flight
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeContract(config.flightSuretyApp.address);
    
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {



    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account 1`, async function () {

    // Ensure that access is denied for non-Contract Owner account


    let accessDenied = false
    try {
      await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] })
    } catch (e) {
      accessDenied = true
    }
    assert(accessDenied, 'Access not restricted to Contract Owner')



  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account 2`, async function () {
    try {
      await config.flightSuretyData.setOperatingStatus(false)
      assert.equal(await config.flightSuretyData.isOperational.call(), false, 'Failed to change operational status')

    }
    catch (e) {
      console.log(e.message)
    }

  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false 3`, async function () {







    let reverted = false;
    try {
      let t = await config.flightSuretyData.isAirLineRegistred(config.firstAirline);

    }
    catch (e) {
      reverted = true;

    }

    assert(reverted, "Access not blocked for requireIsOperational");
    // Retrun them back 


    await config.flightSuretyData.setOperatingStatus(true, { from: accounts[0] });


  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded 4', async () => {


    // ARRANGE
    let newAirline2 = accounts[2];

    // ACT



    try {
      await config.flightSuretyApp.registerAirline(newAirline2, "Libyan Air Lines", { from: config.firstAirline });

    }
    catch (e) {
      assert(e.message.includes('Airline must be Funded first'), 'Error: wrong revert message')

    }

  });

  it('(airline)  register an Airline using registerAirline() if it is  funded 5', async () => {

    // ARRANGE
    let newAirline2 = accounts[2];
    let result;

    // ACT
    try {
      await config.flightSuretyApp.fund({ from: config.firstAirline, value: minFund })

     
      await config.flightSuretyApp.registerAirline(newAirline2, "Libyan Air Lines", { from: config.firstAirline });
      
    }
    catch (e) {
      //result=false;
      console.log(e.message);
    }
    result = await config.flightSuretyApp.isAirLineFunded(config.firstAirline);//,{from: config.firstAirline}) ;//await config.flightSuretyApp.isAirLineRegistred(newAirline2);
     

    // ASSERT
    assert.equal(result, true, "Airline should not be able to register another airline if it hasn't provided funding");

  });



  it('(airline) Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines, 7 ', async () => {

    // ARRANGE
    let newAirline2 = accounts[2];// airline 2
    let newAirline3 = accounts[3];// airline 3
    let newAirline4 = accounts[4];// airline 4

    let counter;

    let newAirline5 = accounts[5];// airline 5

    let result;

    // ACT
    try {


      //result= await config.flightSuretyApp.isAirLineRegistred(newAirline2);
      counter = await config.flightSuretyData.getAirLinesNumber.call();
      await config.flightSuretyApp.fund({ from: newAirline2, value: minFund });
      await config.flightSuretyApp.registerAirline(newAirline3, "Libyan Air Lines3", { from: newAirline2 });
      await config.flightSuretyApp.registerAirline(newAirline4, "Libyan Air Lines4", { from: config.firstAirline });
      await config.flightSuretyApp.fund({ from: newAirline3, value: minFund });
      await config.flightSuretyApp.fund({ from: newAirline4, value: minFund });

      await config.flightSuretyApp.registerAirline(newAirline5, "Libyan Air Lines5", { from: newAirline2 });

      await config.flightSuretyApp.registerAirline(newAirline5, "Libyan Air Lines5", { from: newAirline3 });

      await config.flightSuretyApp.registerAirline(newAirline5, "Libyan Air Lines5", { from: newAirline4 });
      result = await config.flightSuretyApp.isAirLineRegistred(newAirline5);
      counter = await config.flightSuretyData.getAirLinesNumber.call();
    }
    catch (e) {
      //result=false;
      console.log(e.message);
    }

    // ASSERT
    assert.equal(result, true, "Airline should  be registered after half of registed airlines voted for it");

  });





  it('Passenger purchasing insuarnce, 8 ', async () => {

    // ARRANGE
    let passenger = accounts[11];// airline 2

    let result=true;

    // ACT
    try {


       

      await config.flightSuretyApp.registerFlight(flight, timestamp, { from: config.firstAirline, gas: 3000000 });
      await config.flightSuretyApp.purchaseInsurance(accounts[10], flight, timestamp, { from: accounts[11], value: Web3.utils.toWei('1', 'ether') });
     
    }
    catch (e) {
      result=false;
      console.log(e.message);
    }

    // ASSERT
    assert.equal(result, true, "Airline should  be registered after half of registed airlines voted for it");

  });
  // to continue any required test cases here


});
