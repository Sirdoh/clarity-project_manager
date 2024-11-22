# Clarity Project Manager  

![Stacks](https://img.shields.io/badge/Stacks-Smart_Contract-563d7c?logo=blockstack)  
![License](https://img.shields.io/badge/License-MIT-green)

## Table of Contents  
- [Overview](#overview)  
- [Features](#features)  
- [Access Levels](#access-levels)  
- [Smart Contract Functions](#smart-contract-functions)  
  - [Repository Management](#repository-management)  
  - [Access Control](#access-control)  
- [Error Handling](#error-handling)  
- [Security Considerations](#security-considerations)  
- [Deployment Requirements](#deployment-requirements)  
- [Usage Example](#usage-example)  
- [Limitations](#limitations)  
- [Contributing](#contributing)  
- [License](#license)  
- [Author](#author)  
- [FAQs](#faqs)  
- [Further Reading](#further-reading)

---

## Overview  

The **Clarity Project Manager** is a decentralized smart contract designed to manage code repositories with robust access control mechanisms on the **Stacks blockchain**. It ensures secure, transparent, and flexible handling of repositories with hierarchical user permissions.

---

## Features  

### Repository Management  
- Create, modify, and remove repositories  
- Track repository count with precision  
- Manage repository metadata, including:  
  - Name  
  - Description  
  - Contributors (up to 10)  

### Advanced Access Control  
- Granular permissions with multi-level access rights  
- Easily grant and revoke permissions  

---

## Access Levels  

| Level | Access Rights                |  
|-------|------------------------------|  
| 0     | No access                    |  
| 1     | Read-only                    |  
| 2     | Contributor (read + write)   |  
| 3     | Delete permissions           |  
| 4     | Full management access (owner) |  

---

## Smart Contract Functions  

### Repository Management  

#### `create-new-repo`  
- **Description**: Creates a new repository.  
- **Parameters**:  
  - Repository name  
  - Size (bytes)  
  - Description  
  - Contributors (list)  
- **Validations**: Ensures valid inputs, assigns ownership to the transaction sender, and grants full access to the creator.  

#### `modify-repo`  
- **Description**: Updates repository details.  
- **Access Level**: Requires write permissions.  

#### `remove-repo`  
- **Description**: Deletes a repository.  
- **Access Level**: Requires delete permissions.  

### Access Control  

#### `grant-access-rights`  
- Assigns granular permissions to a user.  
- **Conditions**: Only repository owners or managers can grant rights.  

#### `revoke-access-rights`  
- Removes access rights from a user, except for owners.  

#### `check-access-level`  
- Queries the current access level of a user for a specific repository.  

---

## Error Handling  

The contract includes error codes for clear debugging:  

| Code  | Description                       |  
|-------|-----------------------------------|  
| 301   | Repository not found              |  
| 302   | Repository already exists         |  
| 303   | Invalid repository name           |  
| 304   | Invalid repository size           |  
| 305   | Unauthorized access               |  
| 306   | Invalid recipient specified       |  
| 307   | Invalid access permissions        |  
| 308   | Access denied                     |  

---

## Security Considerations  

- **Full Owner Control**: The owner has complete authority over repositories.  
- **Strict Validations**: Protects against invalid inputs and unauthorized actions.  

---

## Deployment Requirements  

- Stacks blockchain environment  
- Compatible with **Clarity 2.0** and above  

---

## Usage Example  

```clarity  
;; Create a new repository  
(create-new-repo "my-project" u1000 "Sample project repository" (list user1 user2))  

;; Grant read access to a user  
(grant-access-rights project-id user3 u1)  

;; Modify repository details  
(modify-repo project-id "updated-name" u1500 "Updated description" (list user1 user2 user3))  
```

---

## Limitations  

| Constraint            | Limit                          |  
|------------------------|-------------------------------|  
| Contributors per repo  | 10                            |  
| Repository size        | 1,000,000,000 units           |  
| Repository name length | 64 characters                |  
| Description length     | 128 characters               |  

---

## Contributing  

1. **Review Code**: Understand the smart contract implementation.  
2. **Test Thoroughly**: Use a local Stacks environment.  
3. **Submit Pull Requests**: Include detailed test cases and explanations.  

---

## License  

This project is licensed under the **MIT License**.  

---

## Author  

[Miracle Sado, sadomiracleofure@gmail.com]  

---

## FAQs  

### **How can I test this contract?**  
Use the [Clarinet](https://docs.hiro.so/clarinet) testing framework to test this contract locally.  

### **What is the purpose of access levels?**  
To ensure secure and hierarchical management of repository permissions.  

---

## Further Reading  

- [Stacks Blockchain Documentation](https://docs.stacks.co/)  
- [Clarity Language Reference](https://docs.hiro.so/clarity-language)  
- [Clarinet Testing Framework](https://docs.hiro.so/clarinet/testing)  
