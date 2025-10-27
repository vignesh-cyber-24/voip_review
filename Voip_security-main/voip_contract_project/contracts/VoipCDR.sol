// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract VoipCDR {
    struct Record {
        uint256 id;
        string caller;
        string callee;
        uint256 duration;
        string status;
        string timestamp;
        string hash;
    }

    Record[] public records;

    function storeCDR(
        string memory caller,
        string memory callee,
        uint256 duration,
        string memory status,
        string memory timestamp,
        string memory hash
    ) public {
        records.push(Record(records.length, caller, callee, duration, status, timestamp, hash));
    }

    function recordCount() public view returns (uint256) {
        return records.length;
    }

    function getCDR(uint256 idx) public view returns (
        string memory caller,
        string memory callee,
        uint256 duration,
        string memory status,
        string memory timestamp,
        string memory hash
    ) {
        Record memory r = records[idx];
        return (r.caller, r.callee, r.duration, r.status, r.timestamp, r.hash);
    }
}
