// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IAlligator} from "../interfaces/IAlligator.sol";
import {IENSReverseRegistrar} from "../interfaces/IENSReverseRegistrar.sol";
import {INounsDAOData} from "../interfaces/INounsDAOData.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

contract ProxySign is IERC1271 {
    address internal immutable alligator;
    address internal immutable governor;
    address internal immutable nounsDAOData;

    constructor(address _governor, address _nounsDAOData) {
        alligator = msg.sender;
        governor = _governor;
        nounsDAOData = _nounsDAOData;
    }

    function isValidSignature(bytes32 hash, bytes calldata signature) external view override returns (bytes4) {
        return IAlligator(alligator).isValidProxySignature(address(this), hash, signature);
    }

    function setENSReverseRecord(string calldata name) external {
        require(msg.sender == alligator);
        IENSReverseRegistrar(0x084b1c3C81545d370f3634392De611CaaBFf8148).setName(name);
    }

    fallback() external payable {
        require(msg.sender == alligator);
        // TODO: Check this condition is correct
        address addr = bytes4(msg.data) == INounsDAOData.addSignature.selector ? nounsDAOData : governor;

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := call(gas(), addr, callvalue(), 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // If funds are received from the governor, send them back to the caller.
    receive() external payable {
        require(msg.sender == governor);
        (bool success, ) = payable(tx.origin).call{value: msg.value}("");
        require(success);
    }
}
