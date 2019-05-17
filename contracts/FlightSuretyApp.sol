pragma solidity ^0.4.24;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)
    using SafeMath for uint;
    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;
    

    address private contractOwner;          // Account used to deploy contract
    FlightSuretyData flightSuretyData ;
    bool public operational=true;

    // Multi-party consensus - part of app logic
    // mapping instead of an array I want to count not only multicalls but multicalls per to-be-added airline
    mapping(address => address[]) internal votes;

 

    // airline fee fund
    uint256 public constant AIRLINE_REGISTRATION_FEE = 10 ether;


 
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
         // Modify to call data contract's status
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
     modifier enoughFund() {
        require(msg.value >= AIRLINE_REGISTRATION_FEE, "Minimun funding amount is 10 ETH");
        _;
    }


    modifier requireAirlineRegistered(){
        require(isAirLineRegistred(msg.sender),"Airline must be registered first");
        _;
    }
    modifier requireAirlineFunded(){
         require(isAirLineFunded(msg.sender),"Airline must be Funded first");
         _;
    }


    /********************************************************************************************/
    /*                                       Events                                             */
    /********************************************************************************************/
    
    
    event FlightRegistered(string flight,  uint256 timestamp, address airline);
    event WithdrawRequest(address recipient);
    event FlightProcessed(string flight, address airline, uint timestamp, uint8 statusCode);
    /********************************************************************************************/
     /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/


    /**
    * @dev Contract constructor
    *
    */
    constructor
                                (
                                      address dataContract
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        flightSuretyData=FlightSuretyData(dataContract) ; //  datacontract reference
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/
    
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;  
    }

    function isAirLineRegistred(address _airLine) 
                             
                            public 
                            view 
                            returns(bool) 
    {
        return flightSuretyData.isAirLineRegistred( _airLine);
    }


     function isAirLineFunded(address _airLine) 
                             
                            public 
                            view 
                            returns(bool) 
    {
        return flightSuretyData.isAirLineFunded( _airLine);
    }

    
     function isFlighRegistred(bytes32 flightKey)  public 
                            view returns(bool) {

        return flightSuretyData.isFlighRegistred(flightKey);

    }

    function remainingVotes(address airlineToBeAdded)
    public
    view
    returns (uint )
    {
        uint registeredVotes = votes[airlineToBeAdded].length;
        uint criteria  = flightSuretyData.getAirLinesNumber().div(2);
        uint result = criteria.sub(registeredVotes);
        return result;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

  function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
       require(operational!=mode,"nothing to change");
               
        operational = mode;
    }
   /**
    * @dev Add an airline to the registration queue
    *
    */   


    function registerAirline
                           (address airlineAddress,string _name)
    external
    requireIsOperational
    requireAirlineRegistered
    requireAirlineFunded
    {
        //only Airlines  can register a new airline when less than 4 airlines are registered
        if (flightSuretyData.getAirLinesNumber() < 4) {
            
            flightSuretyData.registerAirline(airlineAddress, msg.sender,_name);
        } else {
            // multi party consensus
            bool isDuplicate = false;
            for (uint i=0; i < votes[airlineAddress].length; i++) {
                if (votes[airlineAddress][i] == msg.sender) {
                    isDuplicate = true;
                    break;
                }
            }
            require(!isDuplicate, "Caller cannot call this function twice");
            votes[airlineAddress].push(msg.sender);

            if (remainingVotes(airlineAddress) == 0) {
                votes[airlineAddress] = new address[](0);
                flightSuretyData.registerAirline(airlineAddress, msg.sender,_name);
            }
        }
    }


   /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight
                                ( string  _flight, uint256 timestamp
                                )
                                external
                                requireIsOperational
                                requireAirlineRegistered
                                requireAirlineFunded
    {
        flightSuretyData.registerFlight(msg.sender,_flight,timestamp);
                
        emit FlightRegistered(_flight,timestamp,msg.sender);
    }


    function fund()
    external
    requireIsOperational
    requireAirlineRegistered
    enoughFund
    
    payable
    {
        flightSuretyData.fund.value(msg.value)(msg.sender);
    }




    function purchaseInsurance
    (
        address airline,
        string  flight,
        
        uint256 timestamp
    )
        external
        payable
        requireIsOperational
    {
        require(msg.value > 0, "Insurance can accept more than 0 ether");
        require(msg.value <= 1 ether, "Insurance can accept up to 1 ether");

        bytes32 flightKey = getFlightKey(airline,flight,timestamp);

        
        flightSuretyData.buy.value(msg.value)(flightKey,msg.value,msg.sender);

       
    }

    function getFlightsKeys()  external
        requireIsOperational
         returns(bytes32[]) {
            return  flightSuretyData.getFlightsKeys();
        }

    function withdrawCredit
    (
        
    )
        external
        requireIsOperational
    {
         

        
           flightSuretyData.pay(msg.sender);
             emit WithdrawRequest(msg.sender);
    }
    
   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus
                                (
                                    address airline,
                                    string memory flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                
                                 
                                internal
                                
    {
           bytes32 flightKey=getFlightKey(airline,flight,timestamp);

          flightSuretyData.setFlightStatus(flightKey,statusCode);
        if (statusCode == STATUS_CODE_LATE_AIRLINE) {
             
             flightSuretyData.creditInsurees(flightKey,150);
             emit FlightProcessed( flight,  airline,  timestamp,  statusCode);
        }else{
            flightSuretyData.creditInsurees(flightKey,0);
            emit FlightProcessed( flight,  airline,  timestamp,  statusCode);
        }
    }


    // Generate a request for oracles to fetch flight information
    function fetchFlightStatus
                        (
                            address airline,
                            string flight,
                            uint256 timestamp                            
                        )
                        external
    {
        uint8 index = getRandomIndex(msg.sender);

        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });

        emit OracleRequest(index, airline, flight, timestamp);
    } 


// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant ORACLE_REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= ORACLE_REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3])
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {
            oracleResponses[key].isOpen = false;

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            internal
                            returns(uint8[3])
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

} 

contract FlightSuretyData {

     function isOperational() external view returns(bool) ;
     function isAirLineRegistred(address _airLine)  external  returns(bool) ;
     function isAirLineFunded(address _airLine)  external returns(bool) ;
     function registerFlight (address airline,  string  _flight, uint256 timestamp ) external;
     function getFlightsKeys() external returns(bytes32[]);
     function getFlight(bytes32 FlightKey) external returns(string,bool,uint8,uint256,address);
     function registerAirline  ( address airlineAddress, address originAddress, string _name ) external;
     function buy (bytes32 flightKey, uint amount, address originAddress) external  payable;
     function creditInsurees (bytes32 flightKey,uint Rate)  external;
     function pay(address originAddress) external ;
     function fund (address originAddress ) external payable;
     function isFlighRegistred(bytes32 flightKey)  external returns(bool) ;
     function getAirLinesNumber() external returns(uint);
     function setFlightStatus(bytes32 flightKey ,uint8 statusCode) external;
     




} 
