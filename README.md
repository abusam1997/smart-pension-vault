# SmartPensionVault.clar

A decentralized pension savings vault built on the Stacks blockchain using Clarity smart contracts.

## Overview

SmartPensionVault enables employers and employees to manage pension accounts in a secure, transparent, and decentralized manner. The contract allows for account registration, deposits, standard withdrawals after retirement, and admin-approved early withdrawals (e.g., for emergencies).

## Features

- **Account Registration:** Employees can register their pension accounts with a name and retirement block height.
- **Deposits:** Employers can deposit STX into employee pension accounts.
- **Withdrawals:** Employees can withdraw their pension balance after reaching the retirement block.
- **Admin Withdrawals:** Admin can approve early withdrawals for employees in special cases.
- **Role Management:** Admin role can be transferred securely.
- **Event Logging:** Key actions are logged for transparency.

## Error Codes

| Code | Meaning                    |
|------|----------------------------|
| 100  | Not authorized             |
| 101  | Account already exists     |
| 102  | No account found           |
| 103  | Not eligible               |
| 104  | Insufficient funds         |
| 105  | No deposit provided        |

## Contract Functions

### Admin Functions

- `transfer-admin(new-admin)`  
  Transfer admin rights to another principal.

### Employee Functions

- `register-account(name, retire-block)`  
  Register a new pension account.

- `withdraw()`  
  Withdraw pension funds after reaching the retirement block.

### Employer/Admin Functions

- `deposit(employee, amount)`  
  Deposit STX into an employee's pension account.

- `admin-withdraw(employee, amount)`  
  Admin can approve early withdrawal for an employee.

## Events

- `account-created`  
- `deposit-made`  
- `withdrawn`  
- `early-withdrawal-approved`  

Events are logged using the `print` function for off-chain monitoring.

## Usage
1. **Deploy the contract** to the Stacks blockchain.
2. **Register accounts** for employees.
3. **Deposit funds** into employee accounts.
4. **Withdraw funds** after retirement or via admin approval.

## Security

- Only the admin can approve early withdrawals and transfer admin rights.
- All state changes are validated and checked for eligibility and sufficient funds.
