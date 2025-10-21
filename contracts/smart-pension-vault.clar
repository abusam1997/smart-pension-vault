;; -----------------------------------------------------------------------------
;; SmartPensionVault.clar
;; A decentralized pension savings vault on Stacks blockchain
;; -----------------------------------------------------------------------------

;; Error constants
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-ACCOUNT-EXISTS u101)
(define-constant ERR-NO-ACCOUNT u102)
(define-constant ERR-NOT-ELIGIBLE u103)
(define-constant ERR-INSUFFICIENT-FUNDS u104)
(define-constant ERR-NO-DEPOSIT u105)

;; Admin variable
(define-data-var admin principal tx-sender)

;; Pension accounts: each employee's data
(define-map pension-accounts
  { owner: principal }
  {
    name: (string-ascii 64),
    retirement-block: uint,
    balance: uint,
    active: bool
  }
)

;; -------------------------------
;; Helper Functions
;; -------------------------------

(define-read-only (is-admin (p principal))
  (ok (is-eq p (var-get admin)))
)

;; -------------------------------
;; Admin Functions
;; -------------------------------

(define-public (transfer-admin (new-admin principal))
  (let ((current-admin (var-get admin)))
    (begin
      (asserts! (is-eq tx-sender current-admin) (err ERR-NOT-AUTHORIZED))
      (asserts! (not (is-eq new-admin current-admin)) (err ERR-NOT-AUTHORIZED))
      (var-set admin new-admin)
      (ok true))))

;; Helper function to create account data
(define-private (create-account-data (name (string-ascii 64)) 
                                   (retire-block uint) 
                                   (balance uint) 
                                   (is-active bool))
  { name: name,
    retirement-block: retire-block,
    balance: balance,
    active: is-active })

;; Helper function to validate account state
(define-private (validate-account-state (account-data {
    name: (string-ascii 64),
    retirement-block: uint,
    balance: uint,
    active: bool }))
  (and (not (is-eq (get name account-data) ""))
       (>= (get retirement-block account-data) burn-block-height)
       (get active account-data)))

;; Register a pension account
(define-public (register-account (name (string-ascii 64)) (retire-block uint))
  (begin
    (asserts! (not (is-eq name "")) (err ERR-NOT-ELIGIBLE))
    (asserts! (>= retire-block burn-block-height) (err ERR-NOT-ELIGIBLE))
    (match (map-get? pension-accounts { owner: tx-sender })
      existing-account 
        (err ERR-ACCOUNT-EXISTS)
      (let ((new-account (create-account-data name retire-block u0 true)))
        (begin 
          (map-set pension-accounts { owner: tx-sender } new-account)
          (print { event: "account-created", 
                  owner: tx-sender, 
                  name: name, 
                  retirement-block: retire-block })
          (ok tx-sender))))))

;; Deposit into an employee's pension account
(define-public (deposit (employee principal) (amount uint))
  (begin
    (asserts! (> amount u0) (err ERR-NO-DEPOSIT))
    (asserts! (not (is-eq employee tx-sender)) (err ERR-NOT-AUTHORIZED))
    (match (map-get? pension-accounts { owner: employee })
      account-data
        (let ((current-name (get name account-data))
              (current-retire-block (get retirement-block account-data))
              (current-balance (get balance account-data))
              (current-active (get active account-data)))
          (begin
            (asserts! (validate-account-state account-data) (err ERR-NOT-ELIGIBLE))
            (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
            (let ((updated-data 
                    { name: current-name,
                      retirement-block: current-retire-block,
                      balance: (+ current-balance amount),
                      active: current-active }))
              (begin
                (map-set pension-accounts { owner: employee } updated-data)
                (print { event: "deposit-made", 
                        from: tx-sender, 
                        to: employee, 
                        amount: amount })
                (ok (+ current-balance amount))))))
      (err ERR-NO-ACCOUNT))))

;; -------------------------------
;; Withdrawals
;; -------------------------------

;; Standard withdrawal after retirement
(define-public (withdraw)
  (match (map-get? pension-accounts { owner: tx-sender })
    data
      (if (>= burn-block-height (get retirement-block data))
        (if (> (get balance data) u0)
          (match (stx-transfer? (get balance data) tx-sender tx-sender)
            success
              (begin
                (map-set pension-accounts { owner: tx-sender }
                  { name: (get name data),
                    retirement-block: (get retirement-block data),
                    balance: u0,
                    active: false })
                (print { event: "withdrawn", owner: tx-sender, amount: (get balance data) })
                (ok (get balance data)))
            error (err ERR-INSUFFICIENT-FUNDS))
          (err ERR-INSUFFICIENT-FUNDS))
        (err ERR-NOT-ELIGIBLE))
    (err ERR-NO-ACCOUNT)))

;; Admin-Approved Early Withdrawal (e.g., medical emergencies)
(define-public (admin-withdraw (employee principal) (amount uint))
  (if (is-eq tx-sender (var-get admin))
    (match (map-get? pension-accounts { owner: employee })
      data
        (if (>= (get balance data) amount)
          (match (stx-transfer? amount tx-sender employee)
            success
              (begin
                (map-set pension-accounts { owner: employee }
                  { name: (get name data),
                    retirement-block: (get retirement-block data),
                    balance: (- (get balance data) amount),
                    active: (get active data) })
                (print { event: "early-withdrawal-approved", owner: employee, amount: amount })
                (ok amount))
            error (err ERR-INSUFFICIENT-FUNDS))
          (err ERR-INSUFFICIENT-FUNDS))
      (err ERR-NO-ACCOUNT))
    (err ERR-NOT-AUTHORIZED)))
