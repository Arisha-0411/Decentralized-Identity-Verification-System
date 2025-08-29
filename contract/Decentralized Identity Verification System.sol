// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Decentralized Identity Verification System
 * @dev A smart contract for managing decentralized identity verification
 * @author Your Name
 */
 contract Project {
    
    // Struct to store identity information
    struct Identity {
        string name;
        string email;
        uint256 verificationLevel; // 0 = unverified, 1 = basic, 2 = advanced
        bool isActive;
        uint256 createdAt;
        address verifiedBy;
    }
    
    // Struct for verification authorities
    struct Authority {
        string name;
        bool isActive;
        uint256 authorityLevel; // 1 = basic verifier, 2 = advanced verifier
        uint256 registeredAt;
    }
    
    // State variables
    mapping(address => Identity) public identities;
    mapping(address => Authority) public authorities;
    mapping(address => mapping(string => bool)) public verifiedClaims; // user => claim => verified
    
    address public owner;
    uint256 public totalIdentities;
    uint256 public totalAuthorities;
    
    // Events
    event IdentityRegistered(address indexed user, string name, uint256 timestamp);
    event IdentityVerified(address indexed user, address indexed authority, uint256 verificationLevel);
    event AuthorityRegistered(address indexed authority, string name, uint256 authorityLevel);
    event ClaimVerified(address indexed user, string claim, address indexed authority);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyAuthority() {
        require(authorities[msg.sender].isActive, "Only active authorities can perform this action");
        _;
    }
    
    modifier identityExists(address user) {
        require(identities[user].isActive, "Identity does not exist or is inactive");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        totalIdentities = 0;
        totalAuthorities = 0;
    }
    
    /**
     * @dev Core Function 1: Register a new identity
     * @param _name Full name of the user
     * @param _email Email address of the user
     */
    function registerIdentity(string memory _name, string memory _email) external {
        require(!identities[msg.sender].isActive, "Identity already registered");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_email).length > 0, "Email cannot be empty");
        
        identities[msg.sender] = Identity({
            name: _name,
            email: _email,
            verificationLevel: 0,
            isActive: true,
            createdAt: block.timestamp,
            verifiedBy: address(0)
        });
        
        totalIdentities++;
        emit IdentityRegistered(msg.sender, _name, block.timestamp);
    }
    
    /**
     * @dev Core Function 2: Verify an identity (only authorities can call this)
     * @param _user Address of the user to verify
     * @param _verificationLevel Level of verification (1 = basic, 2 = advanced)
     */
    function verifyIdentity(address _user, uint256 _verificationLevel) external onlyAuthority identityExists(_user) {
        require(_verificationLevel >= 1 && _verificationLevel <= 2, "Invalid verification level");
        require(authorities[msg.sender].authorityLevel >= _verificationLevel, "Authority level insufficient");
        require(identities[_user].verificationLevel < _verificationLevel, "Identity already verified at this level or higher");
        
        identities[_user].verificationLevel = _verificationLevel;
        identities[_user].verifiedBy = msg.sender;
        
        emit IdentityVerified(_user, msg.sender, _verificationLevel);
    }
    
    /**
     * @dev Core Function 3: Register a verification authority (only owner can call this)
     * @param _authority Address of the authority
     * @param _name Name of the authority organization
     * @param _authorityLevel Level of authority (1 = basic, 2 = advanced)
     */
    function registerAuthority(address _authority, string memory _name, uint256 _authorityLevel) external onlyOwner {
        require(!authorities[_authority].isActive, "Authority already registered");
        require(_authorityLevel >= 1 && _authorityLevel <= 2, "Invalid authority level");
        require(bytes(_name).length > 0, "Authority name cannot be empty");
        
        authorities[_authority] = Authority({
            name: _name,
            isActive: true,
            authorityLevel: _authorityLevel,
            registeredAt: block.timestamp
        });
        
        totalAuthorities++;
        emit AuthorityRegistered(_authority, _name, _authorityLevel);
    }
    
    // Additional utility functions
    
    /**
     * @dev Verify a specific claim for a user
     * @param _user Address of the user
     * @param _claim The claim to verify (e.g., "email", "phone", "address")
     */
    function verifyClaim(address _user, string memory _claim) external onlyAuthority identityExists(_user) {
        verifiedClaims[_user][_claim] = true;
        emit ClaimVerified(_user, _claim, msg.sender);
    }
    
    /**
     * @dev Get identity information
     * @param _user Address of the user
     * @return Identity struct information
     */
    function getIdentity(address _user) external view returns (Identity memory) {
        require(identities[_user].isActive, "Identity does not exist");
        return identities[_user];
    }
    
    /**
     * @dev Check if a claim is verified for a user
     * @param _user Address of the user
     * @param _claim The claim to check
     * @return Boolean indicating if claim is verified
     */
    function isClaimVerified(address _user, string memory _claim) external view returns (bool) {
        return verifiedClaims[_user][_claim];
    }
    
    /**
     * @dev Deactivate an authority (only owner)
     * @param _authority Address of the authority to deactivate
     */
    function deactivateAuthority(address _authority) external onlyOwner {
        require(authorities[_authority].isActive, "Authority is not active");
        authorities[_authority].isActive = false;
    }
    
    /**
     * @dev Get contract statistics
     * @return Total identities and authorities count
     */
    function getStats() external view returns (uint256, uint256) {
        return (totalIdentities, totalAuthorities);
    }
}
