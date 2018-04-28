/*
 kratki opis značajnijih funkcija:
--reservedAmount funkcija prima iznos u ETH koji će se rezervirati za uplatu većih investitora u posebnom smart contractu. 
    Navedeni iznos se odbija od hardCap-a definiranog u ovom ugovoru kako bi se smartcontract mogao automatski zaustaviti u slučaju dolaska do hardCap-a.
--setSoftCapStatus je funkcija koja će se morati pozvati ako se uplata iz ugovora s Velikim investitorom nije ostvarila,
    a zbog nje je definirano da je probijen softCap ili u obrnutom slučaju.
--setFinalBonus funcija služi da bi se u zadnjem periodu ICO-a mogao povećati bonus s 0% na neku veću razinu ako se za takav korak odluči uprava
--safeWithdrawal funkcija služi da bi osoba u slučaju neuspješnog ICO-a mogla povući ETH natrag na svoj račun. 
--chefOwnerWithdrawal funkcija služi da bi vlasnik tokena u slučaju uspješnog ICO-a mogao povući ETH na svoj račun. Isplata tokena sudionicima ICO-a će se raditi ručno
    nakon što se provjeri KYC za svaku osobu te nakon što se pokuša provjeriti da pojedina osoba nije s više adresa uplatila iznos veći od 10 000 eura. 
    
Funkcija za uplatu ETH ima sljedeće karakteristike:
- nije moguće raditi uplate nakon što je skupljen hardCap
- osoba ne može raditi uplate nakon što je uplatila više od 100 ETH
- moguće je uplaćivati ETH samo prije 01.07.2018 i to iznose ne manje od 0.2 ETH
- ako je osoba uplatila određeni iznos s kojim je pređen hardCap, iznos preko hardCap-a će biti vraćen osobi
- ako je osoba uplatila ili zadnjom uplatom prešla preko 100ETH, inos preko 100 ETH će joj biti vraćen
- ako je osoba napravila cjelovitu uplatu od 10ETH ili više, ostvaruje 15% bonusa koji se pribraja osnovnom bonusu
- osnovni bonusi su :
    *za uplatu u prvih 10 dana ICO-a osoba ostvaruje 20% bonusa
    *za uplatu u narednih 10 dana ICO-a osoba ostvaruje 15% bonusa
    *za uplatu u narednih 10 dana ICO-a osoba ostvaruje 10% bonusa
    *za uplatu u narednih 10 dana ICO-a osoba ostvaruje 5% bonusa
*/

  pragma solidity 0.4.23;
  import "github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol";

contract ChefICO {
    
    using SafeMath for uint256;
    
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public tempHardCap;
    uint256 public totalAmount;
    uint256 public reservedAmount;
    uint256 public chefPrice;
    uint256 public minimumInvestment;
    uint256 public maximumInvestment;
    uint256 public finalBonus;
    
    uint256 public icoStart;
    uint256 public icoEnd;
    address public chefOwner;

    bool public softCapReached = false;
    bool public hardCapReached = false;

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public chefBalanceOf;

    event ChefICOSucceed(address indexed recipient, uint totalAmount);
    event ChefICOTransfer(address indexed tokenHolder, uint value, bool isContribution);


    function ChefICO() public {
        softCap = 7000 * 1 ether;
        hardCap = 22500 * 1 ether;
        tempHardCap = 22500 * 1 ether;
        totalAmount = 0;
        reservedAmount = 0;
        chefPrice = 0.0001 * 1 ether;
        minimumInvestment = 1 ether / 5;
        maximumInvestment = 100 * 1 ether;
        finalBonus = 100;

        icoStart = 1525471200;
        icoEnd = 1530396000;
        chefOwner = msg.sender;
    }
    
    
    function balanceOf(address _contributor) public view returns (uint256 balance) {
        return balanceOf[_contributor];
    }
    
    
    function chefBalanceOf(address _contributor) public view returns (uint256 balance) {
        return chefBalanceOf[_contributor];
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
    
   
    function setFinalBonus(uint256 _value) public onlyOwner returns (bool success) {
        finalBonus = _value;
        return true;    
    }


    function () public payable beforeICOdeadline {
        uint256 amount = msg.value;
        require(!hardCapReached);
        require(amount >= minimumInvestment && balanceOf[msg.sender] < maximumInvestment);
        
        if(tempHardCap <= totalAmount.add(amount)) {
            hardCapReached = true;
            emit ChefICOSucceed(chefOwner, hardCap);
            
             if(tempHardCap < totalAmount.add(amount)) {
                uint256 returnAmount = totalAmount.add(amount).sub(tempHardCap);
                msg.sender.transfer(returnAmount);
                emit ChefICOTransfer(msg.sender, returnAmount, false);
                amount = amount.sub(returnAmount);    
             }
        }
        
        if(maximumInvestment < balanceOf[msg.sender].add(amount)) {
          uint overMaxAmount = balanceOf[msg.sender].add(amount).sub(maximumInvestment);
          msg.sender.transfer(overMaxAmount);
          emit ChefICOTransfer(msg.sender, overMaxAmount, false);
          amount = amount.sub(overMaxAmount);
        }

        totalAmount = totalAmount.add(amount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        

        uint256 additionalBonus = 0;
        if (amount >= 10 ether) {
            additionalBonus=15;
        }
                
        if (now <= icoStart.add(10 days)) {
            chefBalanceOf[msg.sender] = amount.div(chefPrice).mul(120 + additionalBonus).div(100);
        }
        else if (now <= icoStart.add(20 days)) {
            chefBalanceOf[msg.sender] = amount.div(chefPrice).mul(115 + additionalBonus).div(100);
        }
        else if (now <= icoStart.add(30 days)) {
            chefBalanceOf[msg.sender] = amount.div(chefPrice).mul(110 + additionalBonus).div(100);
        }
        else if (now <= icoStart.add(40 days)) {
            chefBalanceOf[msg.sender] = amount.div(chefPrice).mul(105 + additionalBonus).div(100);
        }
        else {
            chefBalanceOf[msg.sender] = amount.div(chefPrice).mul(finalBonus + additionalBonus).div(100);
        }
        
        emit ChefICOTransfer(msg.sender, amount, true);
        
        if (totalAmount >= softCap && softCapReached == false ){
        softCapReached = true;
        emit ChefICOSucceed(chefOwner, totalAmount);
        }
    }

    
    function reservedAmount(uint256 _value) public onlyOwner {
	_value = _value * 1 ether;
        require(totalAmount.add(_value) <= hardCap);
        reservedAmount = _value;
        tempHardCap = hardCap.sub(_value);
    }
    
    
   function setSoftCapStatus (bool _value) public onlyOwner beforeICOdeadline {
        require(hardCap > totalAmount.add(reservedAmount));
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
