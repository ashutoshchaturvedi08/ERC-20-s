// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


contract StableCoin {
    string public name;
    string public symbol;
    uint8 public decimals;
    bool mintAllowed = true;
    uint256 public totalSupply;
    uint256 decimalfactor;
    uint256 public Max_Token;
    address public owner;
    // ETH to nUSD exchange rate
    uint256 public ethToNusdRate;


    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    // Event emitted when a deposit is made
    event Deposit(address indexed user, uint256 ethAmount, uint256 nusdAmount);
    
    // Event emitted when a redemption occurs
    event Redeem(address indexed user, uint256 nusdAmount, uint256 ethAmount);

    constructor( uint256 _ethToNusdRate
    ) {
        symbol = "nUSD";
        name = "nUSD";
        decimals = 18;
        decimalfactor = 10**uint256(decimals);
        Max_Token = 600_000_000 * decimalfactor;
        owner = msg.sender;
        ethToNusdRate = _ethToNusdRate;
     

    }
        modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }




    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
 
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "Allowance error");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    // Function to deposit ETH and receive nUSD
    function deposit() external payable {
        // Ensure the user has sent some ETH
        require(msg.value > 0, "Must send ETH");
        
        // Calculate the amount of nUSD to be minted (50% of the deposited ETH value)
        uint256 nusdAmount = msg.value / 2;
        
        
        // Mint new nUSD tokens and transfer them to the user
        mint(msg.sender, nusdAmount);
        
        // Emit the Deposit event
        emit Deposit(msg.sender, msg.value, nusdAmount);
    }
    
    // Function to redeem nUSD and receive ETH
    function redeem(uint256 nusdAmount) external {

        
        // Calculate the amount of ETH to be redeemed (double the nUSD value)
        uint256 ethAmount = nusdAmount * 2 * ethToNusdRate;
        
        // Ensure the contract has enough nUSD tokens
        require(balanceOf[msg.sender] >= nusdAmount, "Insufficient nUSD balance");
        
        // Burn the nUSD tokens from the user's address
        burn(nusdAmount);
        
        // Transfer the corresponding ETH amount to the user
        payable(msg.sender).transfer(ethAmount);
        
        // Emit the Redeem event
        emit Redeem(msg.sender, nusdAmount, ethAmount);
    }

    // Function to update the ETH to nUSD exchange rate
    function updateExchangeRate(uint256 newRate) external onlyOwner{
       // require(msg.sender == ethReserve, "Only the ETH reserve can update the exchange rate");
        ethToNusdRate = newRate;
    }


    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function mint(address _to, uint256 _value) public returns (bool success) {
        require(Max_Token >= (totalSupply + _value));
        require(mintAllowed, "Max supply reached");
        if (Max_Token == (totalSupply + _value)) {
            mintAllowed = false;
        }
      //  require(msg.sender == owner, "Only Owner Can Mint");
        balanceOf[_to] += _value;
        totalSupply += _value;
        require(balanceOf[_to] >= _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }    
 }