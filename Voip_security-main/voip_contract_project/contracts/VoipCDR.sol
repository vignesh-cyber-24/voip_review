// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract VoipCDR {
    struct Record {
        uint256 id;
        string caller;
        string callee;
        uint256 duration;
    }

    Record[] public records;

    function addRecord(string memory caller, string memory callee, uint256 duration) public {
        records.push(Record(records.length, caller, callee, duration));
    }

    function recordCount() public view returns (uint256) {
        return records.length;
    }
}
