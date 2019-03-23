pragma solidity 0.5.6;

contract DPOS {

    struct Votes {
        bool initialized;
        uint count;
        mapping(address => bool) users;
    }

    mapping (address => bool) public voting;
    mapping (address => Votes) public votes;

    uint8 constant public oraclesCount = 3;
    address[] public oracles;

    constructor() public {
        oracles = new address[](oraclesCount);
    }

    modifier notVoted {
        require(!voting[msg.sender], "You've already voted");
        _;
    }

    modifier haveVoted(address candidate) {
        require(votes[candidate].users[msg.sender], "You've not voted for this candidate");
        _;
    }

    modifier notCandidateToOracles {
        require(!votes[msg.sender].initialized, "You're already candidate to oracles");
        _;
    }

    modifier isCandidateToOracles(address _address) {
        require(votes[_address].initialized, "You're not candidate to oracles");
        _;
    }

    modifier isOracle {
        require(isValidOracle(msg.sender), "You're not oracle");
        _;
    }

    function becameCandidateToOracles() external notCandidateToOracles returns(bool) {
        votes[msg.sender] = Votes(true, 0);
        return true;
    }

    function vote(address candidate) external notVoted isCandidateToOracles(candidate) returns(bool) {
        voting[msg.sender] = true;
        votes[candidate].count++;
        votes[candidate].users[msg.sender] = true;

        if (!isValidOracle(msg.sender)) updateOreaclesList(candidate);
        return true;
    }

    function unvote(address candidate) external isCandidateToOracles(candidate) haveVoted(candidate) returns(bool) {
        voting[msg.sender] = false;
        votes[candidate].count--;
        votes[candidate].users[msg.sender] = false;

        updateOreaclesList(candidate);
        return true;
    }

    function updateOreaclesList(address updatedAddress) private returns(bool) {
        uint worstId = getWorstOracle();
        if (votes[oracles[worstId]].count < votes[updatedAddress].count) {
            oracles[worstId] = updatedAddress;
        }
        
        return true;
    }

    function getWorstOracle() private view returns (uint id) {
        uint worstId = 0;
        uint worstResult = votes[oracles[worstId]].count;

        for (uint i = 1; i < oraclesCount; i++) {
            uint oracleVotesCount = votes[oracles[i]].count;
            if (oracleVotesCount == 0) return i;
            
            if (oracleVotesCount < worstResult) {
                worstResult = oracleVotesCount;
                worstId = i;
            }
        }

        return worstId;
    }

    function isValidOracle(address oracle) private view returns(bool) {
        for (uint i = 0; i < oraclesCount; i++) {
            if (oracles[i] == oracle) return true;
        }
        return false;
    }
}
