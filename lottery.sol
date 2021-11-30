pragma solidity >= 0.8.0;

// SPDX-License-Identifier: UNLICENSED

import "./SafeMath.sol";
import "./ERC20.sol";



contract lottery {

    using SafeMath for uint;

    // -------------------------------------------- Instanciation -------------------------------------------- //

    // Token Creation
    ERC20Basic private token;

    // Addresses
    address public owner;
    address public contractAddress;

    // Tokens Number
    uint public tokenSupply = 10000;


    // Constructor
    constructor () {

        token = new ERC20Basic(tokenSupply);
        owner = msg.sender;
        contractAddress = address(this);

    }

    // Events
    event tokensBought(uint, address);
    event tokensSold(uint, address);

    
    // -------------------------------------------- Tokens Management -------------------------------------------- //

    // Set Tokens Price
    function tokenPrice(uint _amount) internal pure returns (uint) {
        return _amount * (1 ether);
    }

    // Generate Tokens
    function mintTokens(uint _amount) public onlyOwner {

        token.increaseTotalSupply(_amount);

    }

    // OnlyOwner Modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    // Buy tokens
    function buyTokens(uint _amount) public payable {
        
        // Check if contract has enough tokens.
        require(balanceOf(address(this)) >= _amount, "Not enough tokens in contract");

        // Get Tokens Price
        uint _cost = tokenPrice(_amount);

        // Check if client sent correct ether amount
        require(msg.value >= _cost, "Did not send enough ether.");

        // Calculate ether to return
        uint etherToReturn = msg.value - _cost;

        // Transfer Ether.
        payable(msg.sender).transfer(etherToReturn);

        // Transfer Tokens.
        token.transferFrom(address(this), msg.sender, _amount); 

        // Trigger Emit
        emit tokensBought(_amount, msg.sender);

    }

    // Sell tokens
    function sellTokens(uint _amount) public payable {

        // Check that user has enough tokens and that amount is valid.
        require(_amount > 0 && balanceOf(msg.sender) >= _amount, "Not enough Tokens.");

        // Get value in ether
        uint _value = tokenPrice(_amount);

        // Transfer to this contract
        token.transferFrom(msg.sender, address(this), _amount);

        // Transfer Ether
        payable(msg.sender).transfer(_value);

        // Trigger Event
        emit tokensSold(_amount, msg.sender);

    }

    // Get balance
    function balanceOf(address _owner) public view returns (uint) {
        return token.balanceOf(_owner);
    }

    // Get amount of tokens accumulated in the rewards pool.
    function rewardsPool() public view returns (uint) {
        return token.balanceOf(owner);
    }

    

    // -------------------------------------------- Lottery -------------------------------------------- //


    // Entry price
    uint public entryPrice = 5;
    
    // buyer => entriesAmount
    mapping (address => uint []) clientToEntries;

    // winner
    mapping (uint => address) entryToClient;

    // Random Number
    uint randNonce = 0;

    // Entries registry
    uint [] boughtEntries;

    // Events.
    event boughtEntryEvent(uint, address);
    event winnerEntryEvent(uint);


    // Buy Entry
    function buyEntry(uint _amountOfEntries) public {

        // Total Price
        uint _totalPrice = _amountOfEntries.mul(entryPrice);

        // Check that client has enough tokens.
        require(balanceOf(msg.sender) >= _totalPrice, "Not Enough Balance");

        // Transfer Tokens to Owner
        token.transferFrom(msg.sender, address(this), _totalPrice);

        for (uint256 i = 0; i < _amountOfEntries; i++) {
            
            // Random Number.
            uint random = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % 10000;
            randNonce ++;

            // Save Entry Data
            clientToEntries[msg.sender].push(random);

            // Entry Number
            boughtEntries.push(random);

            // Entry Owner
            entryToClient[random] = msg.sender;

            // Trigger Event
            emit boughtEntryEvent(random, msg.sender);

        }

    }

    // Get Entries of a Client
    function getEntries(address _client) public view returns (uint[] memory) {
        return clientToEntries[_client];
    }

    // Get Winner.
    function getWinner() public onlyOwner {

        // Check there are bought entries.
        require(boughtEntries.length > 0, "Not enough participants.");

        // Get length
        uint _entriesAmount = boughtEntries.length;

        // Get Random Number
        uint _winnerEntryNum = uint (uint(keccak256(abi.encodePacked(block.timestamp))) % _entriesAmount);

        // Get Winner Entry
        uint _winner = boughtEntries[_winnerEntryNum];

        // Trigger Event
        emit winnerEntryEvent(_winner);

        // Get winner address
        address _winnerAddress = entryToClient[_winner];

        // Transfer rewards to winner
        token.transferFrom(address(this), _winnerAddress, rewardsPool());

    }

}