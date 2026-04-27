// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Token {
    string public name = "Wrapped ETH Token";
    string public symbol = "WET";
    uint8 public decimals = 18;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    // Lista de holders
    address[] public holders;
    mapping(address => bool) internal isHolder;

    // Dividendos acumulados por endereço
    mapping(address => uint256) public dividends;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed user, uint256 amount);
    event Burn(address indexed user, uint256 amount);
    event DividendAssigned(uint256 totalAmount);

    // =========================
    // MINT (deposit ETH)
    // =========================
    function mint() external payable {
        require(msg.value > 0, "Zero ETH");

        if (!isHolder[msg.sender]) {
            holders.push(msg.sender);
            isHolder[msg.sender] = true;
        }

        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;

        emit Mint(msg.sender, msg.value);
        emit Transfer(address(0), msg.sender, msg.value);
    }

    // =========================
    // BURN (withdraw ETH)
    // =========================
    function burn(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;

        payable(msg.sender).transfer(amount);

        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    // =========================
    // TRANSFER
    // =========================
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        require(to != address(0), "Invalid address");

        balanceOf[msg.sender] -= amount;

        if (!isHolder[to]) {
            holders.push(to);
            isHolder[to] = true;
        }

        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // =========================
    // DISTRIBUIR DIVIDENDOS
    // =========================
    function distributeDividends() external payable {
        require(totalSupply > 0, "No supply");
        require(msg.value > 0, "No ETH sent");

        uint256 amount = msg.value;

        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];
            uint256 holderBalance = balanceOf[holder];

            if (holderBalance > 0) {
                uint256 share = (amount * holderBalance) / totalSupply;
                dividends[holder] += share;
            }
        }

        emit DividendAssigned(amount);
    }

    // =========================
    // CLAIM DIVIDENDS
    // =========================
    function claimDividends() external {
        uint256 amount = dividends[msg.sender];
        require(amount > 0, "No dividends");

        dividends[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // =========================
    // GET HOLDERS COUNT (helper p/ testes)
    // =========================
    function getHoldersCount() external view returns (uint256) {
        return holders.length;
    }

    // =========================
    // RECEIVE ETH (fallback)
    // =========================
    receive() external payable {}
}