// SPDX-License-Identifier: MIT
//• ▌ ▄ ·.  ▄· ▄▌▄▄▄▄▄ ▄ .▄▪   ▄▄·      ▄▄· ▄▄▄  ▄▄▄ .▄▄▄ . ▄▄▄·.▄▄ · 
//·██ ▐███▪▐█▪██▌•██  ██▪▐███ ▐█ ▌▪    ▐█ ▌▪▀▄ █·▀▄.▀·▀▄.▀·▐█ ▄█▐█ ▀. 
//▐█ ▌▐▌▐█·▐█▌▐█▪ ▐█.▪██▀▐█▐█·██ ▄▄    ██ ▄▄▐▀▀▄ ▐▀▀▪▄▐▀▀▪▄ ██▀·▄▀▀▀█▄
//██ ██▌▐█▌ ▐█▀·. ▐█▌·██▌▐▀▐█▌▐███▌    ▐███▌▐█•█▌▐█▄▄▌▐█▄▄▌▐█▪·•▐█▄▪▐█
//▀▀  █▪▀▀▀  ▀ •  ▀▀▀ ▀▀▀ ·▀▀▀·▀▀▀     ·▀▀▀ .▀  ▀ ▀▀▀  ▀▀▀ .▀    ▀▀▀▀ 
// NFT Battle Contract for $MYTHIC v2.0
// A Deflationary MEME & NFT Gaming experiment on Binance Smart Chain 🧙
//https://mythic.finance
//https://twitter.com/wizard_deVv
//https://t.me/mythicfinance

pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/GSN/Context.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.2.0/contracts/token/ERC721/ERC721Burnable.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract CREEPSv2 is Context, AccessControl, ERC721Burnable {
    
    struct Monster {
        string name;
        uint level;
    }

    Monster[] public monsters;
    
    address public gameOwner;
    uint private winner;
    uint private loser;
    uint public mintCost;
    uint public mintCostBNB;
    uint public mintCostStaking;
    uint public rollStats;
    uint public dividendRate;
    uint public maxBetValue;
    bool public fundingEvent;
    string public seasonID;
    string public stakingID;
    string public fundingID;


    // EVENTS
    event Battle(uint winner, uint loser, uint attackAmount, uint defenseAmount);
    
    
    // MAPS
    mapping (address => bool) public allowed;
    mapping (address => bool) public allowedStaking;
    
    constructor(string memory name, string memory symbol) public ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setBaseURI('https://wizard-deVv.github.io/v2/');
        gameOwner = msg.sender;
        mintCost = 4;
        mintCostStaking = 16;
        rollStats = 20;
        maxBetValue = 5;
        dividendRate = 100000;
        mintCostBNB = 4;
        fundingEvent = false;
        seasonID = 'galaxy';
    }

     
     modifier onlyOwnerOf(uint _monsterId) {
        require(ownerOf(_monsterId) == msg.sender, "Must be owner of monster to battle");
        _;
    }
    
    function battleStats(uint restriction) private view returns (uint) {
        return ((uint256(keccak256(abi.encodePacked(block.timestamp*block.number*restriction)))%rollStats +1));
    }  
    
    function lucky(uint restriction) private view returns (uint) {
        return ((uint256(keccak256(abi.encodePacked(block.timestamp*block.number*restriction)))%500));
    }  
    
    function findBattle(uint restriction) private view returns (uint) {
        return ((uint256(keccak256(abi.encodePacked(block.timestamp*block.number*restriction)))%monsters.length));
    }       
    
    function battle(uint _attackingMonster) external payable onlyOwnerOf(_attackingMonster) {
        require(msg.value <= (address(this).balance) / 10000 * maxBetValue, "Bet must be less than or equal to 0.25% of pool");
        require(msg.value > 0, "Bet Must be Greater than 0");
        ////////////////////////////////////////////////
        //find total monsters and draw random number to battle
        ////////////////////////////////////////////////
        uint luck = lucky(12);
        uint _defendingMonster = findBattle(luck);

        if (_attackingMonster == _defendingMonster) {
            if (_attackingMonster == monsters.length) {
                _defendingMonster -= 1;
            }
            else {
                _defendingMonster += 1;
            }
        }
        
        Monster storage attacker = monsters[_attackingMonster];
        Monster storage defender = monsters[_defendingMonster];

        //Normal Stats
        uint luckAttack = lucky(4);
        uint attackAmount = battleStats(luckAttack);
        uint luckDefense = lucky(5);
        uint defenseAmount = battleStats(luckDefense);

        ////////////////////////////////////////////////
        // Battle Logic
        ////////////////////////////////////////////////
        if (attackAmount > defenseAmount) {
            //Atacker Won
            winner = _attackingMonster;
            loser = _defendingMonster;
            
            if (attacker.level < 100000) {
                attacker.level += 1;
            }
            msg.sender.transfer(msg.value * 2);
            emit Battle(winner, loser, attackAmount, defenseAmount);
            }
        else{
            //Denfending Wins and get x% of bet the rest goes to the pool for winnings based on monster level.
            winner = _defendingMonster;
            loser = _attackingMonster;
            address payable defenderWin = address(uint160(ownerOf(_defendingMonster)));
            uint _value = ((msg.value / dividendRate) * defender.level);
            defenderWin.transfer(_value);
            emit Battle(winner, loser, attackAmount, defenseAmount);
            }
    }
    

    ////////////////////////////////////////////////
    //Owner only Mint function for Airdrops
    ////////////////////////////////////////////////
    function mintMonster(string memory _name, address _to, uint _level, string memory _uri) public {
        require(msg.sender == gameOwner, "Only game owner can mint new monsters");
        uint id = monsters.length;
        monsters.push(Monster(_name, _level));
        _safeMint(_to, id);
        _setTokenURI(id, _uri);
    }

    function createMonster(string memory _name, address _to, address _token, uint256 amount, string memory _uri) public {
        require(allowed[_token], "Token must be allowed to be deposited"); 
        require(amount >= (mintCost/4 * (10 ** 18)), "Must deposit token minimums");
        require(keccak256(bytes(seasonID)) == keccak256(bytes(_uri)));
        uint id = monsters.length;
        monsters.push(Monster(_name, 1));
        _safeMint(_to, id);
        _setTokenURI(id, _uri);
        IERC20(_token).transferFrom(msg.sender, address(gameOwner), amount); 
    }
    
    function createMonsterStaking(string memory _name, address _to, address _token, uint256 amount, string memory _uri) public {
        require(allowedStaking[_token], "Token must be allowed to be deposited"); 
        require(amount >= (mintCostStaking/4 * (10 ** 18)), "Must deposit token minimums");
        require(keccak256(bytes(stakingID)) == keccak256(bytes(_uri)));
        uint id = monsters.length;
        monsters.push(Monster(_name, 1));
        _safeMint(_to, id);
        _setTokenURI(id, _uri);
        IERC20(_token).transferFrom(msg.sender, address(gameOwner), amount); 
    }
    
    function createMonsterBNB(string memory _name, address _to, string memory _uri) external payable {
        require(msg.value >= (mintCostBNB/4), "BNB does not meet minimum mint cost"); 
        require(fundingEvent == true);
        require(keccak256(bytes(fundingID)) == keccak256(bytes(_uri)));
        uint id = monsters.length;
        monsters.push(Monster(_name, 1));
        _safeMint(_to, id);
        _setTokenURI(id, _uri);
    }

    ////////////////////////////////////////////////
    // GAME MODIFERS for Balancing & Mint Cost
    ////////////////////////////////////////////////
    function setAllowed(address token, bool allow) public {
        require(msg.sender == gameOwner, "Only game owner can set allowed tokens");
        allowed[token] = allow; 
    }
    
    function setAllowedStaking(address token, bool allow) public {
        require(msg.sender == gameOwner, "Only game owner can set allowed tokens");
        allowedStaking[token] = allow; 
    }
    
    function setMintCost(uint _mintCost) public {
        require(msg.sender == gameOwner, "Only game owner can set allowed tokens");
        mintCost = _mintCost;
    }
    
    function setMintCostStaking(uint _mintCostStaking) public {
        require(msg.sender == gameOwner, "Only game owner can set allowed tokens");
        mintCostStaking = _mintCostStaking;
    }
    
    function enableFundingEvent(bool _eventBool) public {
        require(msg.sender == gameOwner, "Only game owner can set allowed tokens");
        fundingEvent = _eventBool;
    }
    
    function setMintCostBNB(uint _mintCostBNB) public {
        require(msg.sender == gameOwner, "Only game owner can set allowed tokens");
        mintCostBNB = _mintCostBNB;
    }
    
    function setDividendRate(uint _dividendRate) public {
        require(msg.sender == gameOwner, "Only game owner can set allowed tokens");
        dividendRate = _dividendRate;
    }
    
    function setMaxBet(uint _maxBetValue) public {
        require(msg.sender == gameOwner, "Only game owner can set allowed tokens");
        maxBetValue = _maxBetValue;
    }
    
    
    function setStatLuck(uint _rollStats) public {
        require(msg.sender == gameOwner, "Only game owner can set allowed tokens");
        rollStats = _rollStats;
    }  
    
    function setBaseURI(string memory baseURI) public {
        require(msg.sender == gameOwner, "Only game owner can set allowed tokens");
        _setBaseURI(baseURI);
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI) public {
        require(msg.sender == gameOwner, "Only game owner can set allowed tokens");
        _setTokenURI(tokenId, tokenURI);
    }
    
    
    function levelCreep(uint256 tokenId, uint _levels) public {
        require(msg.sender == gameOwner, "Only game owner can set allowed tokens");
        Monster storage creeper = monsters[tokenId];
        creeper.level += _levels;

    }
    
    
    function setstakingID(string memory _stakingID) public {
        require(msg.sender == gameOwner, "Only game owner can set allowed tokens");
        stakingID = _stakingID;
    }
    
    function setfundingID(string memory _fundingID) public {
        require(msg.sender == gameOwner, "Only game owner can set allowed tokens");
        fundingID = _fundingID;
    }
    
    
    
    ////////////////////////////////////////////////
    //external Functions
    ////////////////////////////////////////////////

    function maxBet() public view returns (uint) {
        return (address(this).balance/10000) * maxBetValue;
    }
    
    function deposit() public payable{
    }
    
    function withdraw(uint amount) public {
        require(msg.sender == gameOwner, "Only game owner can withdraw BNB");
        msg.sender.transfer(amount);
    }
    
    
}
