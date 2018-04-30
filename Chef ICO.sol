/*
**U zadnjoj izmjeni dva ICO smart contracta su spojena u jedan - ovaj koji je bio namijenjen za opću publiku. 
Promjene su takve da je limit za uplatu je dignut na 250ETH, a definirani su i bonusi za veće uplate. Bonusi su opisani pred kraj komentara.
Maknute su funkcije koje su omogućavale ručno spuštanje har cap-a te upravljanje sa varijabolom koja indicira da je foct cap dosegnut.

 kratki opis značajnijih funkcija:
--setFinalBonus funcija služi da bi se u zadnjem periodu ICO-a mogao povećati bonus s 0% na neku veću razinu ako se za takav korak odluči uprava
--safeWithdrawal funkcija služi da bi osoba u slučaju neuspješnog ICO-a mogla povući ETH natrag na svoj račun. 
--chefOwnerWithdrawal funkcija služi da bi vlasnik tokena u slučaju uspješnog ICO-a mogao povući ETH na svoj račun. Isplata tokena sudionicima ICO-a će se raditi ručno
    nakon što se provjeri KYC za svaku osobu te nakon što se pokuša provjeriti da pojedina osoba nije s više adresa uplatila iznos veći od 10 000 eura. 
    
Funkcija za uplatu ETH ima sljedeće karakteristike:
- nije moguće raditi uplate nakon što je skupljen hardCap
- osoba ne može raditi uplate nakon što je uplatila više od 250 ETH
- moguće je uplaćivati ETH samo prije 01.07.2018 i to iznose ne manje od 0.2 ETH
- ako je osoba uplatila određeni iznos s kojim je pređen hardCap, iznos preko hardCap-a će biti vraćen osobi
- ako je osoba uplatila ili zadnjom uplatom prešla preko 250ETH, inos preko 250 ETH će joj biti vraćen
- ako je osoba uplatila iznos manji od 10 ETH ostvaruje osnovne bonuse definirane vremenom
- osnovni bonusi su :
    *za uplatu u prvih 10 dana ICO-a osoba ostvaruje 20% bonusa
    *za uplatu u narednih 10 dana ICO-a osoba ostvaruje 15% bonusa
    *za uplatu u narednih 10 dana ICO-a osoba ostvaruje 10% bonusa
    *za uplatu u narednih 10 dana ICO-a osoba ostvaruje 5% bonusa
- bonusi za velike uplate su :
    * za uplatu veću od 100 ETH 40%
    * za uplatu između 50 ETH i 100 ETH 35%
    * za uplatu između 25 ETH i 50 ETH 30%
    * za uplatu između 10 ETH i 25 ETH 25%
*/

  pragma solidity 0.4.23;
  import "github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol";

contract ChefICO {
    
    using SafeMath for uint256;
    
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public totalAmount;
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
        totalAmount = 0;
        chefPrice = 0.0001 * 1 ether;
        minimumInvestment = 1 ether / 5;
        maximumInvestment = 250 * 1 ether;
       
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
    
   
    function () public payable beforeICOdeadline {
        uint256 amount = msg.value;
        require(!hardCapReached);
        require(amount >= minimumInvestment && balanceOf[msg.sender] < maximumInvestment);
        
        if(hardCap <= totalAmount.add(amount)) {
            hardCapReached = true;
            emit ChefICOSucceed(chefOwner, hardCap);
            
             if(hardCap < totalAmount.add(amount)) {
                uint256 returnAmount = totalAmount.add(amount).sub(hardCap);
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
        

       
        if (amount >= 10 ether) {
            if (amount >= 150 ether) {
                chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(140).div(100));
            }
            else if (amount >= 70 ether) {
                chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(135).div(100));
            }
            else if (amount >= 25 ether) {
                chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(130).div(100));
            }
            else {
                chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(125).div(100));
            }
        }
        else if (now <= icoStart.add(10 days)) {
            chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(120).div(100));
        }
        else if (now <= icoStart.add(20 days)) {
            chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(115).div(100));
        }
        else if (now <= icoStart.add(30 days)) {
            chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(110).div(100));
        }
        else if (now <= icoStart.add(40 days)) {
            chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice).mul(105).div(100));
        }
        else {
            chefBalanceOf[msg.sender] = chefBalanceOf[msg.sender].add(amount.div(chefPrice));
        }
        
        emit ChefICOTransfer(msg.sender, amount, true);
        
        if (totalAmount >= softCap && softCapReached == false ){
        softCapReached = true;
        emit ChefICOSucceed(chefOwner, totalAmount);
        }
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
