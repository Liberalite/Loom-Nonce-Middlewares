pragma solidity 0.5.7;

import "./SafeMath.sol";
import "./ERC223Interface.sol";
import "./ERC223ReceivingContract.sol";

contract ERC223Token is ERC223Interface {
    using SafeMath for uint256;
    address private _owner;
    
    string  public  constant name = "ERC223";
    string  public  constant symbol = "ERC223";
    uint8   public  constant decimals = 18;
    uint256 private _totalSupply = 0 * (uint256(10) ** decimals);
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    mapping(address => uint) private _redeemTokens;
    
    constructor() public {
        _owner = msg.sender;
        emit Transfer(address(0), _owner, _totalSupply);
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return _balances[owner];
    }
    
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     * @param _data  Transaction metadata.
     */
    function transfer(address _to, uint _value, bytes memory _data) public returns (bool success) {
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }   
    
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      This function works the same with the previous one
     *      but doesn't contain `_data` param.
     *      Added due to backwards compatibility reasons.
     *
     * @param _to    Receiver address.
     * @param _value Amount of tokens that will be transferred.
     */
    function transfer(address _to, uint _value) public returns (bool success) {
        uint codeLength;
        bytes memory empty;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value, empty);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(to != address(0));
        require(value <= _balances[from]);
        require(value <= _allowed[from][msg.sender]);

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool success) {
        _allowed[msg.sender][spender] = _allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool success) {
        uint256 oldValue = _allowed[msg.sender][spender];
        if (subtractedValue > oldValue) {
            _allowed[msg.sender][spender] = 0;
        } else {
            _allowed[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    
    // -------------------------------------------------------------------------------------------
    // Players that have less than 100 balance can request 1000 Test Tokens every 10 seconds
    // -------------------------------------------------------------------------------------------
    function getFreeTokens() public {
        require(_balances[msg.sender] <= 100000000000000000000); // 100 tokens
        require(now > _redeemTokens[msg.sender]);
        
        uint reward = 1000 * (uint256(10) ** decimals);
        _balances[msg.sender] = _balances[msg.sender].add(reward);
        _redeemTokens[msg.sender] = now.add(10 seconds);
        _totalSupply = _totalSupply.add(reward);

        emit SentFreeTokens(msg.sender, reward) ;
    }
    
    function rescueERC20Tokens(address tokenAddress, uint256 tokens) public returns (bool success) {
        require(msg.sender == _owner);
        return ERC223Interface(tokenAddress).transfer(_owner, tokens);
    }

    function selfDestruct() public {
        selfdestruct(msg.sender);
    }
    
    function () external payable {
        revert("This contract does not accept ETH");
    }

    event SentFreeTokens(address, uint);
    
}