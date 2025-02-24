# DragonVault

DragonVault is a secure asset management protocol implemented in Clarity for the Stacks blockchain. It provides a robust system for digital asset protection with built-in succession planning, activity monitoring, and secure messaging capabilities.

## Features

### Core Functionality
- **Secure Asset Storage**: Store and manage digital assets in a protected vault
- **Succession Planning**: Designate successors who can claim assets after a period of inactivity
- **Guardian System**: Appoint trusted guardians to oversee vault transitions
- **Activity Monitoring**: Automated tracking of vault activity with configurable check periods
- **Secure Messaging**: Built-in system for storing and retrieving encrypted messages

### Security Measures
- **Time-Lock Security**: Configurable inactivity periods before succession can begin
- **Multi-Guardian Consensus**: Require multiple guardians to approve succession
- **Activity Verification**: Regular check-ins required to maintain active status
- **Access Controls**: Strict permission system for all sensitive operations

## Technical Specifications

### Storage
- Maximum of 100 assets per vault
- Up to 5 successors per vault
- Maximum of 5 guardians for consensus
- Up to 10 secure messages per vault
- Message size limit: 1024 bytes

### Time Constants
- Minimum check period: 86400 seconds (24 hours)
- Refresh period: 604800 seconds (7 days)

## Usage Guide

### Creating a Vault
```clarity
(contract-call? .dragon-vault create-vault 
    successors          ;; List of up to 5 successor principals
    inactivity-period   ;; Time before vault is considered inactive
    guardian-threshold  ;; Number of guardians required for consensus
    check-period       ;; Time between required activity checks
)
```

### Managing Assets
```clarity
;; Deposit an asset
(contract-call? .dragon-vault deposit-asset asset-principal)

;; Log activity to prevent inactivity timeout
(contract-call? .dragon-vault log-activity)
```

### Guardian Management
```clarity
;; Assign a new guardian
(contract-call? .dragon-vault assign-guardian guardian-principal)
```

### Succession Process
1. **Initiation**:
```clarity
(contract-call? .dragon-vault initiate-transfer vault-owner-principal)
```

2. **Guardian Confirmation**:
```clarity
(contract-call? .dragon-vault confirm-transfer vault-owner-principal)
```

3. **Execution**:
```clarity
(contract-call? .dragon-vault execute-transfer vault-owner-principal)
```

### Secure Messaging
```clarity
;; Store a message
(contract-call? .dragon-vault store-message "encrypted-message")

;; Read messages (vault owner or eligible successor only)
(contract-call? .dragon-vault read-messages vault-owner-principal)
```

### Monitoring
```clarity
;; Check vault details
(contract-call? .dragon-vault get-vault-info vault-owner-principal)

;; Check time until next required check
(contract-call? .dragon-vault next-check-due vault-owner-principal)

;; Check time until next refresh is available
(contract-call? .dragon-vault next-refresh-due vault-owner-principal)
```

## Error Codes

- `u100`: Unauthorized - Operation restricted to authorized users
- `u101`: Not Found - Requested vault or data doesn't exist
- `u102`: Access Denied - Insufficient permissions for operation
- `u103`: Vault Exists - Attempt to create duplicate vault
- `u104`: Inactive - Vault must be inactive for operation
- `u105`: Insufficient Guardians - Not enough guardian confirmations
- `u106`: Vault Capacity - Vault storage limit reached
- `u107`: Cooldown Active - Operation attempted too soon
- `u108`: Message Limit - Maximum message count reached
- `u109`: Early Refresh - Refresh attempted before cooling period

## Security Considerations

1. **Vault Creation**
   - Choose successors carefully
   - Set appropriate inactivity periods
   - Select reliable guardians
   - Configure reasonable check periods

2. **Operation**
   - Maintain regular activity to prevent unintended succession
   - Keep guardian list updated
   - Monitor succession requests
   - Regularly verify vault status

3. **Succession**
   - Guardians should verify inactive status
   - Confirm successor identity before approval
   - Follow proper succession sequence

## Development

### Prerequisites
- Clarity CLI
- Stacks blockchain development environment
- Understanding of Clarity smart contracts

### Testing
Standard test cases should cover:
- Vault creation and management
- Asset handling
- Guardian operations
- Succession processes
- Message system functionality
- Security constraints
- Error conditions

## Contributing

Contributions are welcome! Please read the contributing guidelines before submitting pull requests.