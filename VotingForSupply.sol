// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Importar o contrato Jocoin
import "./Jocoin.sol";

contract VotingForSupply {
    address public owner;
    Jocoin public token;

    enum Phase { Init, Voting, Ended }
    Phase public phase;

    uint256[3] public proposals;      // propostas de totalSupply
    uint256[3] private voteCounts;    // contagem de votos para cada proposta
    mapping(address => bool) public registered;
    mapping(address => bool) public voted;

    event VoterRegistered(address voter);
    event VoteCast(address voter, uint8 proposalIndex);
    event PhaseChanged(Phase newPhase);
    event VotingFinalized(uint8 winningProposalIndex, uint256 winningSupply);

    modifier onlyOwner() { require(msg.sender == owner, "Somente owner"); _; }
    modifier inPhase(Phase p) { require(phase == p, "Fase incorreta"); _; }

    constructor(address _token, uint256 p0, uint256 p1, uint256 p2) {
        owner = msg.sender;
        token = Jocoin(_token);
        proposals[0] = p0;
        proposals[1] = p1;
        proposals[2] = p2;
        phase = Phase.Init;
        emit PhaseChanged(phase);

        // autoriza este contrato a atualizar o token
        token.setVotingContract(address(this));
    }

    // --- Owner controls ---
    function startVoting() external onlyOwner inPhase(Phase.Init) {
        phase = Phase.Voting;
        emit PhaseChanged(phase);
    }

    function endVoting() external onlyOwner inPhase(Phase.Voting) {
        phase = Phase.Ended;
        emit PhaseChanged(phase);
    }

    // --- Voter registration ---
    function registerVoter() external inPhase(Phase.Voting) {
        require(!registered[msg.sender], "Ja registrado");
        registered[msg.sender] = true;
        emit VoterRegistered(msg.sender);
    }

    // --- Vote ---
    // proposalIndex: 0, 1 ou 2
    function vote(uint8 proposalIndex) external inPhase(Phase.Voting) {
        require(registered[msg.sender], "Nao registrado");
        require(!voted[msg.sender], "Ja votou");
        require(proposalIndex < 3, "Proposta invalida");

        voted[msg.sender] = true;
        voteCounts[proposalIndex] += 1;

        emit VoteCast(msg.sender, proposalIndex);
    }

    // --- Finalize voting ---
    function finalizeVoting() external onlyOwner inPhase(Phase.Ended) {
        // encontra a proposta vencedora
        uint8 winningIndex = 0;
        uint256 maxVotes = 0;
        for (uint8 i = 0; i < 3; i++) {
            if (voteCounts[i] > maxVotes) {
                maxVotes = voteCounts[i];
                winningIndex = i;
            }
        }

        uint256 winningSupply = proposals[winningIndex];
        token.setTotalSupply(winningSupply);

        emit VotingFinalized(winningIndex, winningSupply);
    }

    // --- Views ---
    function getVoteCounts() external view returns (uint256[3] memory) {
        return voteCounts;
    }

    function getProposals() external view returns (uint256[3] memory) {
        return proposals;
    }
}
