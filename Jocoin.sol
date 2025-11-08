// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Jocoin {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    address public votingContract; // contrato autorizado a atualizar totalSupply

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        _name = "Jocoin";
        _symbol = "JC";
        _decimals = 8;
        _totalSupply = 1000000;
        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    // --- ERC20 Methods ---
    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function decimals() public view returns (uint8) { return _decimals; }
    function totalSupply() public view returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view returns (uint256) { return _balances[account]; }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(_balances[msg.sender] >= amount, "Saldo insuficiente");
        require(recipient != address(0), "Endereco invalido");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // --- Only voting contract can update supply ---
    function setVotingContract(address _voting) external {
        require(votingContract == address(0), "Ja definido");
        votingContract = _voting;
    }

    function setTotalSupply(uint256 newSupply) external {
        require(msg.sender == votingContract, "Nao autorizado");
        _totalSupply = newSupply;
        // Opcional: redefinir balances logicamente
        // Aqui mantemos apenas atualização do totalSupply
    }
}
