// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.25;

import {FHE, ebool, euint8, euint32, Euint8} from "@luxfi/contracts/fhe/FHE.sol";

contract FHVoting {
    string public query;

    string[] public options;
    euint8[] internal encOptions;

    uint32 MAX_INT = 2 ** 32 - 1;
    uint8 MAX_OPTIONS = 5;

    mapping(address => euint8) internal votes;
    mapping(uint8 => euint32) internal tally;

    // Decrypted tally results
    uint32[] public decryptedTally;
    bool public tallyDecryptionComplete;

    constructor(string memory q, string[] memory optList) {
        require(optList.length <= MAX_OPTIONS, "too many options!");

        query = q;
        options = optList;
    }

    function init() public {
        for (uint8 i = 0; i < options.length; i++) {
            tally[i] = FHE.asEuint32(0);
            encOptions.push(FHE.asEuint8(i));
        }
    }

    function vote(Euint8 calldata encOption) public {
        euint8 option = FHE.asEuint8(encOption);

        // Note: Option validation removed - this FHE library version doesn't support req()
        // The tally logic below handles invalid options gracefully (they add 0 to all tallies)

        // If already voted - first revert the old vote
        if (FHE.isInitialized(votes[msg.sender])) {
            addToTally(votes[msg.sender], FHE.asEuint32(MAX_INT)); // Adding MAX_INT is effectively `.sub(1)`
        }

        votes[msg.sender] = option;
        addToTally(option, FHE.asEuint32(1));
    }

    /// @notice Decrypt all tally values synchronously
    function decryptTally() public {
        delete decryptedTally;
        // First, initiate all decryptions
        for (uint8 i = 0; i < encOptions.length; i++) {
            FHE.decrypt(tally[i]);
        }
        // Then, get all results
        for (uint8 i = 0; i < encOptions.length; i++) {
            decryptedTally.push(FHE.reveal(tally[i]));
        }
        tallyDecryptionComplete = true;
    }

    /// @notice Get the decrypted tally (after decryption is complete)
    function getDecryptedTally() public view returns (uint32[] memory) {
        require(tallyDecryptionComplete, "Decryption not complete");
        return decryptedTally;
    }

    function addToTally(euint8 option, euint32 amount) internal {
        for (uint8 i = 0; i < encOptions.length; i++) {
            ebool isMatch = FHE.eq(option, encOptions[i]);
            euint32 toAdd = FHE.select(isMatch, amount, FHE.asEuint32(0));
            tally[i] = FHE.add(tally[i], toAdd);
        }
    }
}
