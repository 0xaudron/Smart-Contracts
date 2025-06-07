// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    /////////////////    STATE VARIABLES    /////////////////
    address private admin;
    struct Candidate {
        string name;
        uint256 voteCount;
    }
    Candidate[] public candidates;                  //candidates stored in array
    mapping(address => bool) public hasVoted;       //check if candidate has voted, prevents double voting
    mapping(string => bool) public candidateExists; //check if candidate exists or not, prevents double storage
    uint public currentWinnerIndex;                 //current winner index to keep indexes in track, to reduce DoS and gas cost
    uint public highestVoteCount;                   //used for calculating winner

    /////////////////    EVENTS    /////////////////
    event CandidateAdded(string name);
    event VoteCast(address voter, uint candidateIndex);
    event WinnerDeclared(string winnerName);

    //Constructor function which sets the deployer as admin
    constructor() {
        admin = msg.sender;
    }
    
    /////////////////    MODIFERS    /////////////////
    //onlyOwner modifier to check if the address calling the contract is owner/admin
    modifier onlyOwner() {
        require(msg.sender == admin);
        _;
    }

    // Modifier to check if candidate index is valid
    modifier validCandidate(uint candidateIndex) {
        require(candidateIndex < candidates.length, "Invalid candidate index");
        _;
    }


    /////////////////    STATE CHANGING FUNCTIONS    /////////////////
    // addCandidate(string memory name)
    function addCandidate(string memory name) public onlyOwner {
        require(bytes(name).length > 0, "Candidate name cannot be empty");
        require(!candidateExists[name], "Candidate already exists");
        candidateExists[name] = true;

        //
        candidates.push(Candidate({
            name: name,
            voteCount: 0
        }));
        emit CandidateAdded(name);
    }

    // vote(uint candidateIndex)
    function vote(uint candidateIndex) public validCandidate(candidateIndex) {
        //Checks
        require(!hasVoted[msg.sender], "You have already voted");
        require(candidates.length > 0, "No candidates available");
        
        //Effects
        hasVoted[msg.sender] = true;
        candidates[candidateIndex].voteCount++;

        // Update winner if this candidate now has the most votes
        if(candidates[candidateIndex].voteCount > highestVoteCount) {
            highestVoteCount = candidates[candidateIndex].voteCount;
            currentWinnerIndex = candidateIndex;
        }

        emit VoteCast(msg.sender, candidateIndex);

    }

    /////////////////    VIEW FUNCTIONS    /////////////////

    // returns candidates list
    function  getCandidates() public view returns (Candidate[] memory){
        return candidates;
    }
    // returns winner, prone to change since no time based terminologies was provided in scope of test so haven't implemented any
    function getWinner() public returns (string memory name){
        require(candidates.length > 0, "No candidates available");
        require(highestVoteCount > 0, "No votes have been cast yet");
        emit WinnerDeclared(candidates[currentWinnerIndex].name);
        return candidates[currentWinnerIndex].name;
    }
}
