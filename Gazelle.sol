// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Gazelle is Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    bool mintAllowed = true;
    uint256 public totalSupply;
    uint256 decimalfactor;
    uint256 public Max_Token;
    uint256 public welcomeAmount;
    uint256 public lockTime;
    uint256 public lockTimeFestive;
    uint256 public festivePersentageAmount; 

    mapping(address => locked) users;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => mapping(address => uint256)) public stakedForWelcome;
    mapping(address => mapping(address => uint256)) public stakedForFestive; 

    struct locked{
        uint256 expire;
        uint256 expireTimeForFestive;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor(
    ) {
        symbol = "GZLT";
        name = "Gazelle";
        decimals = 18;
        decimalfactor = 10**uint256(decimals);
        Max_Token = 600_000_000_000_000 * decimalfactor;

        mint(
            0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,
            23_000_000_000 * decimalfactor
        ); //IO
        mint(
            0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,
            36_000_000 * decimalfactor
        ); 
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
        require(msg.sender == owner, "Only Owner Can Mint");
        balanceOf[_to] += _value;
        totalSupply += _value;
        require(balanceOf[_to] >= _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }
    function finalFestivalGift(address _to) public onlyOwner returns (bool) {
        uint256 userBalance = balanceOf[_to];
        uint256 cda = userBalance * 195 / 10000 ;
         //require((userBalance / 10000) * 10000 == userBalance, "amount is low");
        _transfer(msg.sender, _to, cda);
        return true;
    }

    function send10(address _to, uint256 _value) public returns (bool) {
        uint256 userBalance = balanceOf[msg.sender];
        uint256 finalPercentageAmount = userBalance * 500 / 10000;
        require(finalPercentageAmount >= _value , "you can't send more then 5%" );
         _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function setAllValueByAdmin(uint256 setWelcomeAmount ,  uint256 lockTimeForWelcomeGift,uint256 lockTimeForFestiveGift ,uint256 persentageForFestiveGift ) public onlyOwner returns(bool) {
      welcomeAmount = setWelcomeAmount;
      lockTime = lockTimeForWelcomeGift ;
      lockTimeFestive = lockTimeForFestiveGift;
      festivePersentageAmount = persentageForFestiveGift;
      return true ;

}
    function setWelcomeAmountAdmin(uint256 setWelcomeAmount  ) public onlyOwner returns(bool) {
      welcomeAmount = setWelcomeAmount;
      return true ;
}
    function setWelcomeTimeAdmin(uint256 lockTimeForWelcomeGift  ) public onlyOwner returns(bool) {
      lockTime = lockTimeForWelcomeGift;
      return true ;
}
    function setfestiveTimeAdmin(uint256 lockTimeForFestiveGift  ) public onlyOwner returns(bool) {
      lockTimeFestive = lockTimeForFestiveGift;
      return true ;
}
    function setfestivePersentageAdmin(uint256 persentageForFestiveGift  ) public onlyOwner returns(bool) {
      festivePersentageAmount = persentageForFestiveGift;
      return true ;
}

    function lockTokenForWelcome( ) public  {
        locked storage userInfo = users[msg.sender];
        userInfo.expire = block.timestamp + lockTime;
        stakedForWelcome[owner][msg.sender] = welcomeAmount;
    } 

    function withdrawTokenForWelcome() public payable {
        require(block.timestamp>=users[msg.sender].expire , "Your Welcome Gift tokens was in stake Please wait for some time !");
        locked storage userInfo = users[msg.sender];
        uint256 value;
        userInfo.expire = 0;
        require( value <= stakedForWelcome[owner][msg.sender], "Please LockTime First then withdraw");
         stakedForWelcome[owner][msg.sender] -= welcomeAmount;
        _transfer(owner, msg.sender, welcomeAmount);
    }

    function lockForFestiveGift( ) public  {
        locked storage userInfo = users[msg.sender];
        userInfo.expireTimeForFestive = block.timestamp + lockTimeFestive;
        uint256 userBalance = balanceOf[msg.sender];
        require (userBalance != 0 ,"Please fill Your Balance");
        uint256 fixTokenAmountFestive = userBalance * festivePersentageAmount / 10000 ;
        stakedForFestive[owner][msg.sender] = fixTokenAmountFestive;
    } 
    
    function withdrawForFestive() public payable {
        require(block.timestamp>=users[msg.sender].expireTimeForFestive , "Your Festival Gift tokens was in stake Please wait for some time !");
        locked storage userInfo = users[msg.sender];
        userInfo.expireTimeForFestive = 0;
        uint256 userBalance = balanceOf[msg.sender];
        require (userBalance != 0 ," Please fill Your Balance ");
        uint256 value = userBalance * festivePersentageAmount / 10000 ;
        require( value <= stakedForFestive[owner][msg.sender], "Please LockTime First then withdraw");
         stakedForFestive[owner][msg.sender] -= value;
        _transfer(owner, msg.sender, value);
    }

 }
