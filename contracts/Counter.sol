// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.25;

import {FHE, euint32, Euint32} from "@luxfi/contracts/fhe/FHE.sol";

contract Counter {
    euint32 private counter;

    // Store the decrypted result
    uint32 public lastDecryptedValue;
    // Flag to check if decryption is complete
    bool public decryptionComplete;

    function add(Euint32 calldata encryptedValue) public {
        euint32 value = FHE.asEuint32(encryptedValue);
        counter = FHE.add(counter, value);
    }

    /// @notice Decrypt the counter synchronously
    function decryptCounter() public {
        FHE.decrypt(counter);
        lastDecryptedValue = FHE.reveal(counter);
        decryptionComplete = true;
    }

    /// @notice Get the last decrypted value (after decryption is complete)
    function getDecryptedValue() public view returns (uint32) {
        require(decryptionComplete, "Decryption not complete");
        return lastDecryptedValue;
    }
}
