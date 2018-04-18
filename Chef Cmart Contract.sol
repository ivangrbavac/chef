  pragma solidity ^0.4.21;

// ----------------------------------------------------------------------------
// functions for safe conductiong of math operations
// ----------------------------------------------------------------------------
contract SafeOperations 
{
    function Add(uint a, uint b) public pure returns (uint c) 
    {
        c = a + b;
        require(c >= a);
    }
    function Sub(uint a, uint b) public pure returns (uint c) 
    {
        require(b <= a);
        c = a - b;
    }
    function Mul(uint a, uint b) public pure returns (uint c) 
    {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function Div(uint a, uint b) public pure returns (uint c) 
    {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// interface for the token
// ----------------------------------------------------------------------------

contract ChefTokenInterface {
    
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint value) public returns (bool success);
    function approve(address spender, uint value) public returns (bool success);
    function transferFrom(address from, address to, uint value) public returns (bool success);
    function approveAndCall(address spender, uint value, bytes extraData) public returns (bool success);
    function addConsumerReview(address consumer, address chef, uint32 position, string review) public returns (bool success);
    function addChefReview(address consumer, address chef, uint32 position, string review) public returns (bool success);
    function readConsumerReview(address consumer, address chef, uint32 position) public returns (string review);
    function readChefReview(address consumer, address chef, uint32 position) public returns (string review);
	function burn(uint value) public returns (bool success);
	function requestService(address chef, uint price, string orderDescription, uint32 position ) public returns (bool success);
	function confirmService(address consumer, uint price, uint32 position, string orderDescription) public returns (bool success);
	function setServiceStatus(address consumer, address chef, uint32 position, uint state, string notice) public returns (bool success);
	function servicePaymentWithCharityPercentage(address _to, uint256 _value, address _charity, uint256 _charityValue) public returns  (bool success);
    function transferFromCroudsale (address receiver, uint value) public returns (bool success) ;

    event Transfer(address indexed from, address indexed to, uint value);
    event PaymentWithCharityPercentage (address indexed from, address indexed to, address indexed charity, uint value, uint charityValue);
    event Approval(address indexed tokenOwner, address indexed spender, uint value);
    event Review(address indexed from, address indexed to, uint indexed position, string review, string reviewer);
    event Agreement(address indexed from, address indexed to, uint indexed position, uint price, string description);
    event ServiceStatus(address indexed from, address indexed to, uint indexed position, uint state, string description);
    event Burn(address indexed from, uint value);
}

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; 
}

// ----------------------------------------------------------------------------
// ChefToken contract
//-----------------------------------------------------------------------------

contract ChefToken  is ChefTokenInterface, SafeOperations {
    
    struct cokingAgreement {
        uint8 consumer; //it is set to 1 if consumer requested meal
        uint8 chef; //it is set to 1 when chef accepts consumer request
        uint256 price; //amount to be paid by consumer
        string orderDescription; //order description
        string consumerReview; //review of the chef given by consumer
        string chefReview; //review of the consumer given by the chef
        uint state;
        }
 
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address ChefICOAddress = 0x000000000000000000000000000; 
    address ChefOwner = 0x9396bB9702c9a19515d9d9b86a3ccC6B3159aeC6; // adress needs to be set
    
     
    mapping (address => uint256) public balanceOf; // This creates an array with all balances
    mapping (address => mapping (address => uint256)) public allowance; // This creates an array with all allowances
    
    // This creates an three-dimensional array used for storing cokingAgreements. One address owner can give several reviews to other address owner. 
    //Concept of array is [address_of_consumer][address_of_chef][review_ordinal_number_for_address_pair]
	mapping (address => mapping (address => mapping (uint32 => cokingAgreement ))) public cokingEvent; 
	
	
	function ChefToken () public {
	totalSupply = 630*(10**6)*(10**18);   //total supply of CHEF tokens is 630 milions
    balanceOf[msg.sender] = totalSupply;  // Give the creator all initial tokens
    name = "Chef Token";                  // Set the name for display purposes
    symbol = "CHEF";                      // Set token symbol
	}
		
// ----------------------------------------------------------------------------
// enable receiving ETH -mislim da je nećemo koristiti
//-----------------------------------------------------------------------------
//function () public payable {
//}
// ----------------------------------------------------------------------------
// Public function that returns total supply of tokens
//-----------------------------------------------------------------------------
	function totalSupply() public constant returns (uint) {
        return totalSupply;
    }
	
// ----------------------------------------------------------------------------
// Public function that returns total token balance of given address 
//-----------------------------------------------------------------------------
    function balanceOf(address _tokenOwner) public constant returns (uint balance) {
        return balanceOf[_tokenOwner];
    }
	
// ----------------------------------------------------------------------------
// internal function for handling transfers
//-----------------------------------------------------------------------------
	function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0); // Prevent transfer to 0x0 address. Use burn() instead
		require(balanceOf[_from] >= _value); // Check if the sender has enough tokens
        uint previousBalances = Add(balanceOf[_from], balanceOf[_to]); // Save this for an assertion in the future
        balanceOf[_from] =Sub(balanceOf[_from], _value); // Subtract from the sender
        balanceOf[_to] = Add(balanceOf[_to] ,_value); // Add the same to the recipient
        emit Transfer(_from, _to, _value); //Call Transfer event
        assert(Add(balanceOf[_from],balanceOf[_to]) == previousBalances); // This should be allway true
    }
	
// ----------------------------------------------------------------------------
// public function for transfering tokens from owner to recipient. First argument is
// addresses recipient and  the second argument determines the amount to send to recipient
//-----------------------------------------------------------------------------
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
	
// ----------------------------------------------------------------------------
// public function for paying for services whinc include charity donation. First argument is
// addresses recipient and the second argument determines the amount to send to recipient
// third arhument receives charity address and fourth charity amount
//-----------------------------------------------------------------------------
    function servicePaymentWithCharityPercentage(address _to, uint256 _value, address _charity, uint256 _charityValue) public returns  (bool success) {
        _transfer(msg.sender, _to, _value);
        _transfer(msg.sender, _charity, _charityValue);
        emit PaymentWithCharityPercentage (msg.sender, _to, _charity, _value, _charityValue);
        return true;
    }
		
// ----------------------------------------------------------------------------
// Public function that returns the amount of tokens approved by the tokenOwner 
// that can be transferred to the spender's account
// ----------------------------------------------------------------------------
    function allowance(address _tokenOwner, address _spender) public constant returns (uint remaining) {
        return allowance[_tokenOwner][_spender];
    }

// -----------------------------------------------------------------------------
// Public function in which tokenOwner allows sender to transferFrom  tokenOwner
// account no more than 'value' tokens. First argument is the spenders address which
//is authorized to transferFrom tokens. Second argument determines token amount.
// -----------------------------------------------------------------------------    
      function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
        return true;
    }
	
// -----------------------------------------------------------------------------
// Public function which enables to transfer certain amount of tokens 
// (third argument) from The address of the sender (first argument)
//  to the address of the recipient (second argument). Transaction is enabled only
// in case that token owner approwed transaction to msg.sender
// -----------------------------------------------------------------------------     

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] = Sub(allowance[_from][msg.sender] , _value);
        _transfer(_from, _to, _value);
        return true;
    }
	
//Allow 'spender' (address authorized to spend - first argument) to spend no more 
//than 'value' (second argument) tokens on tokenOwner behalf, and then ping the 
// contract about it. Third argument may contain some extra information to send 
//to the approved contract
// -----------------------------------------------------------------------------
  
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
	    if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

// -----------------------------------------------------------------------------
// Token owner can remove certain amount of tokens (argument) from 
// the system irreversibly
// -----------------------------------------------------------------------------
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough tokens
        balanceOf[msg.sender] = Sub(balanceOf[msg.sender],_value);     // Subtract from the sender
        totalSupply =Sub(totalSupply , _value);  // Subtract from totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
	
// ------------------------------------------------------------------------
// Add review written by 'consumers address which evaluates 'chef' address. Writing rewiews
// is alowed only to consumer and only if consumer and chef agreed on cokingEvent (state >100). 
// ------------------------------------------------------------------------
   	function addConsumerReview(address _consumer, address _chef, uint32 _position, string _review) public returns (bool success){
		if (msg.sender != _consumer || cokingEvent[_consumer][_chef][_position].consumer!=1 || cokingEvent[_consumer][_chef][_position].chef!=1 || bytes(cokingEvent[_consumer][_chef][_position].consumerReview).length!=0 && cokingEvent[_consumer][msg.sender][_position].state>100){
		    return false;   
		    } 
		else {
		cokingEvent[_consumer][_chef][_position].consumerReview=_review;
		emit Review(_consumer, _chef, _position, _review, "Consumer review");
		    }
		return true;
	}
	
// ------------------------------------------------------------------------
// Add review written by 'chef' address which evaluates 'consumer' address. Writing rewiews
// is alowed only to chef and only if consumer and chef agreed on cokingEvent (state >100).  
// ------------------------------------------------------------------------
   	function addChefReview(address _consumer, address _chef, uint32 _position, string _review) public returns (bool success){
		if (msg.sender != _chef || cokingEvent[_consumer][_chef][_position].consumer!=1 || cokingEvent[_consumer][_chef][_position].chef!=1 || bytes(cokingEvent[_consumer][_chef][_position].chefReview).length!=0 && cokingEvent[_consumer][msg.sender][_position].state>100){
		    return false;   
		    }
		else {   
		cokingEvent[_consumer][_chef][_position].chefReview=_review;
		emit Review(_consumer, _chef, _position, _review, "Chef review");
		     }
		return true;
	}
	
	
// ------------------------------------------------------------------------
// Read review written from '_consumer' address which evaluates '_chef' address. 
// Third argument is ordinal number of review
// ------------------------------------------------------------------------
	function readConsumerReview(address _consumer, address _chef, uint32 _position) public  returns (string consumerReview){
	return  cokingEvent[_consumer][_chef][_position].consumerReview;
	}
	
// ------------------------------------------------------------------------
// Read review written from '_chef' address which evaluates '_consumer' address. 
// Third argument is ordinal number of review
// ------------------------------------------------------------------------
	function readChefReview(address _consumer, address _chef, uint32 _position) public  returns (string chefReview){
	return  cokingEvent[_consumer][_chef][_position].chefReview;
	}
	
// ------------------------------------------------------------------------
// Public function stores consumer request for a service (meal cooked by chef )
// First argument is chef address, second is agreed price, third is description of requested service
// and last argument is ordinal number of agreement between those two addresses
// ------------------------------------------------------------------------
	function requestService(address _chef, uint _price, string _orderDescription, uint32 _position) public returns (bool success){
	    if (cokingEvent[msg.sender][_chef][_position].consumer!=1){
	        cokingEvent[msg.sender][_chef][_position].consumer=1;
	        cokingEvent[msg.sender][_chef][_position].price=_price;
	        cokingEvent[msg.sender][_chef][_position].orderDescription=_orderDescription;
	        cokingEvent[msg.sender][_chef][_position].state=0;
	        return true;
	    }
	    else{
	        return false;
	    }
	}
	
// ------------------------------------------------------------------------
// Public function stores chef's confirmation on a consumer request.
// First argument is consumer address, second is agreed price, third is ordinal number of agreement between those two addresses
// and last argument is description of requested meal
// ------------------------------------------------------------------------	
	function confirmService(address _consumer, uint _price, uint32 _position, string _orderDescription) public returns (bool success){
		if (cokingEvent[_consumer][msg.sender][_position].consumer==1 && cokingEvent[_consumer][msg.sender][_position].price==_price && cokingEvent[_consumer][msg.sender][_position].state==0){
	        cokingEvent[_consumer][msg.sender][_position].chef=1;
	        emit Agreement(_consumer, msg.sender, _position, _price, _orderDescription);
	        return true;
	    }
	    else{
	        return false;
	    }
	}
// ------------------------------------------------------------------------
// Public function that sets statuses of a particular service arranged between consumer and chef.
// First argument is consumer address, second is chef's address, third is  ordinal number of agreement between those two addresses.
// then goes state of service and notice about state.
//------------------------------------------------------------------------
	function setServiceStatus(address _consumer, address _chef, uint32 _position, uint _state, string _notice) public returns (bool success){
	if (cokingEvent[_consumer][_chef][_position].consumer==1 && msg.sender == ChefOwner){
	    cokingEvent[_consumer][_chef][_position].state=_state;
	    emit ServiceStatus(_consumer, msg.sender, _position, _state, _notice);
	    return true;
	}else{
	        return false;
	    }
	
	}
	
// ------------------------------------------------------------------------
// Public function which could be executed only by ChefOwner and which sets 
// the address of crowdsale contract which will be used in next function  
//------------------------------------------------------------------------	
	
function setChefICOAddress (address _ICOAddress) public returns (bool success){
     if (msg.sender == ChefOwner){
         ChefICOAddress = _ICOAddress;
         return true;
     }
     else{
         return false;
     }
}


// ------------------------------------------------------------------------
// Public function which is called from croudsale contract in a case of successful ICO.
// Function should transfer bought amount of ICO ChefTokens to buyer 
//------------------------------------------------------------------------
function  transferFromCroudsale (address _receiver, uint _value) public returns (bool success) {
    	if (msg.sender == ChefICOAddress){
    	     _transfer(ChefOwner, _receiver, _value);
        return true;
    	}
    	else {
    	    return false;
    	}
	
	}


}
