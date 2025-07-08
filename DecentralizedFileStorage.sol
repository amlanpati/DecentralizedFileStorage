// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract DecentralizedFileStorage {
    struct File {
        string fileHash;
        string fileName;
        address owner;
        mapping(address => uint256) accessExpiry;
        uint256 accessFee;
    }

    mapping(bytes32 => File) private files;
    mapping(address => bytes32[]) private userFiles;

    event FileUploaded(bytes32 fileId, address indexed owner, string fileName);
    event AccessGranted(bytes32 fileId, address indexed grantee, uint256 expiry);
    event AccessRevoked(bytes32 fileId, address indexed grantee);
    event PaymentReceived(address indexed payer, uint256 amount);

    modifier onlyOwner(bytes32 fileId) {
        require(files[fileId].owner == msg.sender, "Not the owner of the file");
        _;
    }

    modifier hasAccess(bytes32 fileId) {
        require(
            files[fileId].owner == msg.sender || files[fileId].accessExpiry[msg.sender] > block.timestamp,
            "Access denied"
        );
        _;
    }

    
    function uploadFile(string calldata fileHash, string calldata fileName, uint256 accessFee) external {
        bytes32 fileId = keccak256(abi.encodePacked(fileHash, msg.sender, block.timestamp));
        File storage file = files[fileId];
        file.fileHash = fileHash;
        file.fileName = fileName;
        file.owner = msg.sender;
        file.accessFee = accessFee;
        userFiles[msg.sender].push(fileId);

        emit FileUploaded(fileId, msg.sender, fileName);
    }

    
    function grantAccess(bytes32 fileId, address grantee, uint256 duration) external onlyOwner(fileId) {
        files[fileId].accessExpiry[grantee] = block.timestamp + duration;
        emit AccessGranted(fileId, grantee, block.timestamp + duration);
    }

    
    function requestAccess(bytes32 fileId) external payable {
        File storage file = files[fileId];
        require(msg.value >= file.accessFee, "Insufficient payment");
        file.accessExpiry[msg.sender] = block.timestamp + 30 days;
        payable(file.owner).transfer(msg.value);
        emit PaymentReceived(msg.sender, msg.value);
    }


    function revokeAccess(bytes32 fileId, address grantee) external onlyOwner(fileId) {
        files[fileId].accessExpiry[grantee] = 0;
        emit AccessRevoked(fileId, grantee);
    }


    function checkAccess(bytes32 fileId, address user) public view returns (bool) {
        File storage file = files[fileId];
        if (file.owner == address(0)) {
            return false;
        }
        return block.timestamp <= file.accessExpiry[user];
    }

    
    function getFile(bytes32 fileId) external view hasAccess(fileId) returns (string memory fileHash, string memory fileName) {
        File storage file = files[fileId];
        return (file.fileHash, file.fileName);
    }

    
    function getUserFiles() external view returns (bytes32[] memory) {
        return userFiles[msg.sender];
    }
}

// 10000000000000000
// FileID123
// ABC.pdf

// 40000000000000000
// File456ID
// PQR.mkv