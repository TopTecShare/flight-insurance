pragma solidity ^0.4.24;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;
    using SafeMath for uint;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;
    bool private operational = true;// Blocks all state changes throughout the contract if false
    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;
    struct Flight {
        string flight;
        bool isRegistered;
        uint8 statusCode;
        uint256 timestamp;
        address airline;
        mapping(address => uint) insurances;
        }

       struct AirLine {
        bool    isRegistered;
        bool    isFunded;
        string  name;
                   }

    bytes32[] private flights_key;
    mapping(bytes32 => Flight) private flights;
    address[] internal passengers;
    mapping(address => uint256) private authorizedContracts;// Blocks all state changes throughout the contract if false
    mapping(address => AirLine) private airLines;
    mapping   (address => uint256) public withdrawals;
    uint private _AirLinesCount=0;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/

    event Paid(address recipient, uint amount);
    event Funded(address airline);
    event AirlineRegistered(address origin, address newAirline);
    event Credited(address passenger, uint amount);
    event InsuranceBought(address originAddress,uint amount,bytes32 flightKey);
    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (address _airLine,string _airLine_Name) 
                                public 
    {
        contractOwner = msg.sender;
        if (_AirLinesCount==0){
            AirLine memory _AirLine =AirLine(true,false,_airLine_Name);
            airLines[_airLine]=_AirLine; 
             _AirLinesCount=_AirLinesCount.add(1);


        }
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

     modifier requireIsCallerAuthorized()
    {
        require(authorizedContracts[msg.sender] == 1, "Caller is not authorized contract");
        _;
    }

     modifier flightRegistered(bytes32 flightKey) {
        require(flights[flightKey].isRegistered, "This flight does not exist");
        _;
    }

   

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


     function isAirLineRegistred(address _airLine) 
                             
                            external
                            requireIsOperational
                            requireIsCallerAuthorized
                            returns(bool) 
    {
        return airLines[_airLine].isRegistered;
    }


     function isAirLineFunded(address _airLine) 
                             
                            external
                            requireIsOperational
                            requireIsCallerAuthorized
                            returns(bool) 
    {
        return airLines[_airLine].isFunded;
    }

     function isFlighRegistred(bytes32 flightKey) 
                             
                            external
                            requireIsOperational
                            requireIsCallerAuthorized
                            returns(bool) 
    {
        return flights[flightKey].isRegistered;
    }
     function getAirLinesNumber() 
                             
                            external
                            requireIsOperational
                           // requireIsCallerAuthorized
                            returns(uint) 
    {
        return _AirLinesCount;
    }
    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }


     function authorizeContract
                            (
                                address contractAddress
                            )
                            external
                            requireContractOwner
                            requireIsOperational
    {
        authorizedContracts[contractAddress] = 1;
    }

    function deauthorizeContract
                            (
                                address contractAddress
                            )
                            external
                            
                            requireContractOwner
                            requireIsOperational
    {
        delete authorizedContracts[contractAddress];
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   

   function registerFlight
                                (  address airline,
                            string  _flight,
                            uint256 timestamp
                                )
                                external
                                requireIsOperational
                                requireIsCallerAuthorized
                                
    {

       bytes32 Key=getFlightKey(airline,_flight,timestamp);
       require(!flights[Key].isRegistered,"Flight Already Registred") ;
 
       Flight memory flight = Flight(
       _flight,
        true,
        STATUS_CODE_UNKNOWN,
        timestamp,       
         airline);
        
         flights[Key]=flight;
         flights_key.push(Key);
          

    } 


    
   function getFlightsKeys()
                               
                                external
                                requireIsOperational
                                requireIsCallerAuthorized
                                returns(bytes32[])
                                
    {

        return (flights_key);

    } 

    function getFlight(bytes32 FlightKey)
                               
                                external
                                requireIsOperational
                                requireIsCallerAuthorized
                                returns(string,bool,uint8,uint256,address)
                                
    {
        
        Flight memory _flight=flights[FlightKey];
        
        return ( _flight.flight, _flight.isRegistered, _flight.statusCode,_flight.timestamp,_flight.airline);

    } 


     function setFlightStatus(bytes32 FlightKey,uint8 StatusCode)
                               
                                external
                                requireIsOperational
                                requireIsCallerAuthorized
                                 
                                
    {
        
        flights[FlightKey].statusCode=StatusCode;
       
    } 

   
   function registerAirline
    (
        address airlineAddress,
        address originAddress,
        string _name
    )
    external
    requireIsOperational
    requireIsCallerAuthorized
    {
        _AirLinesCount=_AirLinesCount.add(1);
        airLines[airlineAddress].isRegistered = true;
        airLines[airlineAddress].name = _name;
        emit AirlineRegistered(originAddress, airlineAddress);
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
            (bytes32 flightKey, uint amount, address originAddress)
            external
            requireIsOperational
            requireIsCallerAuthorized
            flightRegistered(flightKey)
            payable
            {
                Flight storage flight = flights[flightKey];

                flight.insurances[originAddress] = amount;
                passengers.push(originAddress);
                emit InsuranceBought(originAddress,amount,flightKey);
                
               
            }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (bytes32 flightKey,uint Rate
                                )
                                external
                                requireIsOperational
                                requireIsCallerAuthorized
                                flightRegistered(flightKey)
                                


    {
    
           // get flight
                Flight storage flight = flights[flightKey];
        // loop over passengers and credit them their insurance amount
                 for (uint i = 0; i < passengers.length; i++) {
                    withdrawals[passengers[i]] = flight.insurances[passengers[i]].mul(Rate).div(100);
                    emit Credited(passengers[i], flight.insurances[passengers[i]]);
        }
            
    }

    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (address originAddress
                            )
                            external
                             requireIsOperational
                             requireIsCallerAuthorized
                             
    {
        require( withdrawals[originAddress]>0,"No amount to transfer!");
         uint amount = withdrawals[originAddress];
        withdrawals[originAddress] = 0;
        
        originAddress.transfer(amount);
         emit Paid(originAddress, amount);
    }

  
    function fund
                            (address originAddress    )
                            public
                            payable
                            requireIsOperational
                            requireIsCallerAuthorized
    {
                           // require(!airLines[originAddress].isFunded,"already funded" );
                            airLines[originAddress].isFunded = true;
                             emit Funded(originAddress);
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
                            requireIsCallerAuthorized
    {
         require(msg.data.length == 0,"fallback");
            fund(msg.sender);
    }


}

