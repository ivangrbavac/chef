//------------------------------------------
// za investitore se rezerviraju sredstva kada bude sasvim izgledno da će ugovor o investiraju biti potpisan.
// minimalna uplata je za sada postavljena na 10 ETH, ali će se vjerojatno povećati
// iznos chef tokena i bonusa se ne računa u ovom smart contractu jer spada u poslovnu tajnu definiranu ugovorom.
// u slučaju neuspiješnog ICO-a, platitelju se vraćaju sredstva (funkcija safeWithdrawal), 
// dok u slučaju uspješnog ICO-a vlasnik smart contracta može na svoju adresu prebaciti ETH (funkcija chefOwnerWithdrawal). 
//------------------------------------------ 
  
  pragma solidity 0.4.23;
  import "github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol";

contract ChefICOInvestors {
    
    using SafeMath for uint256;
    
    uint256 public totalAmount;
    uint256 public reservedAmount;
    uint256 public minimumInvestment;
        
    uint256 public icoStart;
    uint256 public icoEnd;
    address public chefOwner;
    
    bool public softCapReached = false;

    mapping(address => uint256) public balanceOf;

    event ChefICOTransfer(address indexed tokenHolder, uint value, bool isContribution);

    function ChefICOInvestors() public {
        totalAmount = 0;
        reservedAmount = 0;
        minimumInvestment = 10 ether;
        icoStart = 1525471200;
        icoEnd = 1530396000;
        chefOwner = msg.sender;
    }
    
    
    function balanceOf(address _contributor) public view returns (uint256 balance) {
        return balanceOf[_contributor];
    }
    
    
    function reservedAmount(uint256 _value) public onlyOwner returns (bool success) {
        reservedAmount = _value * 1 ether;
        return true;    
    }
    
    
    modifier onlyOwner() {
        require(msg.sender == chefOwner);
        _;
    }
    
    
    modifier afterICOdeadline() { 
        require(now >= icoEnd );
            _; 
        }
       
        
     modifier beforeICOdeadline() { 
        require(now <= icoEnd );
            _; 
        }
    
 
    function () public payable beforeICOdeadline {
        uint256 amount = msg.value;
        require(amount >= minimumInvestment && reservedAmount>= totalAmount.add(amount));
        
        totalAmount = totalAmount.add(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        emit ChefICOTransfer(msg.sender, amount, true);
    }
    
    
    function setSoftCapStatus (bool _value) public onlyOwner {
	softCapReached = _value;
	}    


   function safeWithdrawal() public afterICOdeadline {
        if (!softCapReached) {
	    uint256 amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                msg.sender.transfer(amount);
                emit ChefICOTransfer(msg.sender, amount, false);
            }
        }
    }
        
    
    function chefOwnerWithdrawal() public afterICOdeadline onlyOwner {    
        if (softCapReached) {
            chefOwner.transfer(totalAmount);
            emit ChefICOTransfer(chefOwner, totalAmount, false);
        }
    }
}
