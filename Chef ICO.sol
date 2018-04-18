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
// interface of CHEF smart contract function, used for transfering CHEF tokens 
// to crowdsale contributors in a case of successful ICO
// ----------------------------------------------------------------------------
interface ChefToken {
    function transferFromCroudsale(address receiver, uint value) external;
}



contract ChefICO is SafeOperations {
	ChefToken public Chef;
    uint public softCap;
	uint public hardCap;
	address public recipient;
    uint public totalAmount;
    uint public ICOdeadline;
    uint public hardCapReachedDeadline;
    uint public ChefPrice;
    uint public bonusDeadline; //deadline for additional 5% in ICO
    uint minimumInvestment;
    uint maximumInvestment;
	bool softCapReached = false;
    bool crowdsaleClosed = false;
	bool hardCapReached = false;
	address ChefAddress = 0x000000000000000000000000000; // adress needs to be set
	address ChefOwner  =  0x000000000000000000000000000; // adress needs to be set
	
	mapping(address => uint256) public balanceOf;
	mapping(address => uint256) public ChefBalanceOf;

    event ChefICOSucceed(address indexed recipient, uint totaltotalAmount);
    event ChefICOTransfer(address indexed tokenHolder, uint value, bool isContribution);

 //------------------------------------------
 // initialize ICO parameters
 //------------------------------------------
    function ChefICO() public {
        recipient = ChefAddress;
        softCap = 7000 * 1 ether;
        hardCap = 22500 * 1 ether;
        ICOdeadline = 1530406800; //01.07.2018. 00:00:00 CET
        hardCapReachedDeadline=1530406800;
        bonusDeadline = 1527728400; //02.06.2018 00:00:00 CET 
        ChefPrice = 0.0001 * 1 ether;
        minimumInvestment=0.2 * 1 ether;
        maximumInvestment = 100 * 1 ether;
        Chef = ChefToken(ChefAddress);
    }


//------------------------------------------
//function thet is trigerred on every payment. It stores data about paid amount
// and stops ICO if hard cap is reached.
//------------------------------------------
    function () public payable {
        require(!crowdsaleClosed && !hardCapReached);
        uint amount = msg.value;
        require(amount>=minimumInvestment && balanceOf[msg.sender]<maximumInvestment);
        
        if(hardCap >= Add(totalAmount,amount))
        {
            hardCapReached=true;
            crowdsaleClosed = true;
            emit ChefICOSucceed(recipient, hardCap);
            
             if(hardCap > Add(totalAmount,amount)){
                uint returnAmount=Sub(Add(totalAmount,amount),hardCap);
                msg.sender.transfer(returnAmount);
                emit ChefICOTransfer(msg.sender, returnAmount, false);
                amount= Sub(amount,returnAmount);    
             }
        }
        
        if(maximumInvestment>Add(balanceOf[msg.sender],amount))
        {
          uint overMaxAmount=Sub(Add(balanceOf[msg.sender],amount),maximumInvestment);
          msg.sender.transfer(overMaxAmount);
          emit ChefICOTransfer(msg.sender, overMaxAmount, false);
          amount= Sub(amount,overMaxAmount);
        }
        
        
        balanceOf[msg.sender] =Add(balanceOf[msg.sender] ,amount);
        totalAmount =Add(totalAmount, amount);
        
        //give 5% bonuse if payment was made before bonusDeadline
        if (now <= bonusDeadline) {
            ChefBalanceOf[msg.sender]=Div(Mul(amount, 1.05 ether), ChefPrice);
        }
        else
        {
            ChefBalanceOf[msg.sender]=Div(amount, ChefPrice);
        }
        
        emit ChefICOTransfer(msg.sender, amount, true);
        
        if (totalAmount >= softCap && softCapReached==false ){
        softCapReached= true;
        emit ChefICOSucceed(recipient, totalAmount);
        }
    }

//------------------------------------------
//modifier that checks ICO deadline
//------------------------------------------
    modifier afterICOdeadline() { if (now >= ICOdeadline || now >= hardCapReachedDeadline) _; }


//------------------------------------------
//closes crowdsale, on a defined deadline,
// if soft cap is reached
//------------------------------------------
    function checkGoalReached() public afterICOdeadline {
        if (totalAmount >= softCap){
           crowdsaleClosed = true;
        }
        
    }

//------------------------------------------
//if hadr cap is reached, this function sets the date on which
//contributors can withdrow their chef tokens. It can only be executed by 
//ChefOwner address 
//------------------------------------------
function setHardCapReachedDeadline (uint withdrawalDate) public 
{
    if (msg.sender == ChefOwner){
    hardCapReachedDeadline=withdrawalDate;
    }
}

//------------------------------------------
// function for fund withdrawals. if soft cap is not reached, 
// function returns ETH amount to contributors.
// If soft/hard cap is reached, and time limit passed,
// function sends Chef tokens to contributor and ETH to ChefOwner address
//------------------------------------------
  
    function safeWithdrawal() public afterICOdeadline  {
        uint amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        if (amount > 0) {
            if (!softCapReached) {
                    msg.sender.transfer(amount);
                    emit ChefICOTransfer(msg.sender, amount, false);
            }
            
            if (softCapReached && recipient != msg.sender) {
                Chef.transferFromCroudsale(msg.sender, ChefBalanceOf[msg.sender]);
                emit  ChefICOTransfer(msg.sender, ChefBalanceOf[msg.sender], true);
            }
    
            if (softCapReached && recipient == msg.sender) {
                recipient.transfer(totalAmount);
                emit  ChefICOTransfer(recipient, totalAmount, false);
                
            }
        }
    }
}
