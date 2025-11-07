# 🌍 Diplomatic Ledger - Decentralized Archive for International Treaties

A blockchain-based solution for preserving and managing international diplomatic records and peace agreements.

## 🎯 Features

- 📜 Immutable treaty registration
- 👥 DAO-based validation system
- 🔍 Public treaty lookup
- ✍️ Verified annotations system
- 🌐 Multi-country support
- ⏰ Treaty expiration management

## 🚀 Getting Started

### Prerequisites

- Clarinet
- Stacks wallet

### Contract Functions

#### For Validators

```clarity
(register-treaty title countries ipfs-hash)
(add-annotation treaty-id content)
(update-treaty-status treaty-id new-status)
(set-treaty-expiration treaty-id expiration-block)
```

#### For Administrators

```clarity
(add-validator validator-address role)
```

#### Read-Only Functions

```clarity
(get-treaty treaty-id)
(get-treaty-annotations treaty-id)
(get-validator-info address)
(is-treaty-expired treaty-id)
```

## 🔐 Security

All treaty operations require validator authentication to ensure data integrity.

## 🤝 Contributing

Contributions are welcome! Please submit a PR with your proposed changes.
```

Git commit message:
```
feat: implement MVP for Diplomatic Ledger smart contract with treaty registration and validation
```

PR Title:
```
✨ MVP: Diplomatic Ledger Smart Contract Implementation
```

PR Description:
```
This PR introduces the initial MVP for the Diplomatic Ledger project, including:

- Core treaty registration system
- Validator management
- Annotation functionality
- Treaty status updates
- Read-only query functions

The implementation focuses on essential features while maintaining security and scalability. Ready for initial testing and feedback.

Testing completed:
- ✅ Treaty registration
- ✅ Validator management
- ✅ Annotation system
- ✅ Access control
## 🏷️ Treaty Tagging System

Enhance treaty discoverability with a flexible tagging mechanism that allows validators to assign relevant keywords and categories to treaties. This feature enables efficient searching and categorization of diplomatic documents, improving accessibility for researchers and policymakers.

### Key Benefits:
- 🔍 **Advanced Search**: Quickly locate treaties by topics, regions, or themes
- 📊 **Data Analytics**: Enable trend analysis and pattern recognition in international relations
- 🏷️ **Semantic Organization**: Support structured metadata for better treaty management
- 🌍 **Global Insights**: Facilitate cross-border research and comparative studies

### Implementation Details:
The tagging system introduces a new map for storing treaty tags and provides functions for adding, removing, and querying tags. Tags are stored as a list of strings per treaty, with validation to prevent duplicate tags and enforce maximum limits.

### New Functions:
```clarity
(add-treaty-tags treaty-id tags)
(remove-treaty-tag treaty-id tag)
(get-treaty-tags treaty-id)
```

This enhancement transforms the Diplomatic Ledger into a more powerful research tool, bridging traditional diplomacy with modern data-driven approaches. By enabling semantic tagging, the platform supports advanced analytics and knowledge discovery in international treaty data. 🚀 #BlockchainDiplomacy #SmartContracts #InternationalRelations

