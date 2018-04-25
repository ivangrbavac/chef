  pragma solidity 0.4.23;
  import "github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol";
  
contract Ownable{
   address public chefOwner; 
   
   event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
   function Ownable() public {
        chefOwner = msg.sender;
    }
   
    modifier onlyOwner() {
        require(msg.sender == chefOwner);
        _;
    }
      
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(chefOwner, newOwner);
        chefOwner = newOwner;
    }

}  

// ----------------------------------------------------------------------------
// interface for the token
// ----------------------------------------------------------------------------

contract ChefTokenInterface {
    
    function totalSupply() public view returns (uint256 supply);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 value) public returns (bool success);
    function servicePaymentWithCharityPercentage(address to, uint256 value, address charity, uint256 charityValue) public returns  (bool success);
    function approve(address spender, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);
    function approveAndCall(address spender, uint256 value, bytes extraData) public returns (bool success);
    function burn(uint256 value) public returns (bool success);
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PaymentWithCharityPercentage (address indexed from, address indexed to, address indexed charity, uint256 value, uint256 charityValue);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
   
}

interface tokenRecipient { 
    function receiveApproval(address from, uint256 value, address token, bytes extraData) external; 
}

// ----------------------------------------------------------------------------
// ChefToken contract
//-----------------------------------------------------------------------------

contract ChefToken  is Ownable, ChefTokenInterface {
    
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf; 
    mapping (address => mapping (address => uint256)) public allowance;
    
    
	function ChefToken () public {
	totalSupply = 630*(10**6)*(10**18);   //total supply of CHEF tokens is 630 milions
    balanceOf[msg.sender] = totalSupply;  
    name = "CHEF";                  
    symbol = "CHEF";                    
	}


	function totalSupply() public view returns (uint256 supply) {
        return totalSupply;
    }
	

    function balanceOf(address _tokenOwner) public view returns (uint256 balance) {
        return balanceOf[_tokenOwner];
    }
	

	function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
		require(balanceOf[_from] >= _value); 
        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]); 
        balanceOf[_from] =balanceOf[_from].sub(_value); 
        balanceOf[_to] = balanceOf[_to].add(_value); 
        emit Transfer(_from, _to, _value); 
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances); 
    }
	

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
	
// ----------------------------------------------------------------------------
// public function for paying for services which includes charity donation. 
//-----------------------------------------------------------------------------
    function servicePaymentWithCharityPercentage(address _to, uint256 _value, address _charity, uint256 _charityValue)  public onlyOwner returns  (bool success) {
        _transfer(msg.sender, _to, _value);
        _transfer(msg.sender, _charity, _charityValue);
        emit PaymentWithCharityPercentage (msg.sender, _to, _charity, _value, _charityValue);
        return true;
    }
		

    function allowance(address _tokenOwner, address _spender) public view returns (uint256 remaining) {
        return allowance[_tokenOwner][_spender];
    }
    

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
        return true;
    }
	

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
	

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
	    if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }


    function burn(uint256 _value) public onlyOwner returns (bool success) {
        require(balanceOf[msg.sender] >= _value);  
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);  
        totalSupply =totalSupply.sub(_value);  
        emit Burn(msg.sender, _value);
        return true;
    }


}
