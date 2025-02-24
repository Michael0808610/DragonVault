;; DragonVault: Secure Asset Management Protocol with Guardian System and Time-Lock Security

;; Constants
(define-constant protocol-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-not-found (err u101))
(define-constant err-access-denied (err u102))
(define-constant err-vault-exists (err u103))
(define-constant err-inactive (err u104))
(define-constant err-insufficient-guardians (err u105))
(define-constant err-vault-capacity (err u106))
(define-constant err-cooldown-active (err u107))
(define-constant err-message-limit (err u108))
(define-constant err-early-refresh (err u109))

;; Data Maps
(define-map vaults
  { dragon: principal }
  {
    assets: (list 100 principal),
    successors: (list 5 principal),
    inactivity-period: uint,
    last-activity: uint,
    guardian-threshold: uint,
    check-period: uint,
    last-check: uint,
    last-refresh: uint
  }
)

(define-map vault-guardians
  { dragon: principal, guardian: principal }
  { active: bool }
)

(define-map transfer-requests
  { dragon: principal }
  {
    initiated: uint,
    confirmations: (list 5 principal)
  }
)

(define-map secure-messages
  { dragon: principal }
  { messages: (list 10 (string-utf8 1024)) }
)

;; Private Functions
(define-private (is-owner (entity principal))
  (is-eq tx-sender entity)
)

(define-private (get-current-time)
  (unwrap-panic (get-block-info? time u0))
)

(define-private (check-inactive (vault-data {
                               assets: (list 100 principal),
                               successors: (list 5 principal),
                               inactivity-period: uint,
                               last-activity: uint,
                               guardian-threshold: uint,
                               check-period: uint,
                               last-check: uint,
                               last-refresh: uint
                             }))
  (> (- (get-current-time) (get last-activity vault-data)) (get inactivity-period vault-data))
)

(define-private (check-due (vault-data {
                                     assets: (list 100 principal),
                                     successors: (list 5 principal),
                                     inactivity-period: uint,
                                     last-activity: uint,
                                     guardian-threshold: uint,
                                     check-period: uint,
                                     last-check: uint,
                                     last-refresh: uint
                                   }))
  (> (- (get-current-time) (get last-check vault-data)) (get check-period vault-data))
)

;; Public Functions
(define-public (create-vault (successors (list 5 principal)) (inactivity-period uint) (guardian-threshold uint) (check-period uint))
  (let ((vault-data {
          assets: (list ),
          successors: successors,
          inactivity-period: inactivity-period,
          last-activity: (get-current-time),
          guardian-threshold: guardian-threshold,
          check-period: check-period,
          last-check: (get-current-time),
          last-refresh: (get-current-time)
        }))
    (asserts! (is-none (map-get? vaults { dragon: tx-sender })) (err err-vault-exists))
    (asserts! (>= check-period u86400) (err err-cooldown-active))
    (ok (map-set vaults { dragon: tx-sender } vault-data))
  )
)

(define-public (deposit-asset (asset principal))
  (let ((vault (unwrap! (map-get? vaults { dragon: tx-sender }) (err err-not-found))))
    (let ((updated-assets (unwrap! (as-max-len? (append (get assets vault) asset) u100) (err err-vault-capacity))))
      (ok (map-set vaults
        { dragon: tx-sender }
        (merge vault {
          assets: updated-assets,
          last-activity: (get-current-time)
        })
      ))
    )
  )
)

(define-public (log-activity)
  (let ((vault (unwrap! (map-get? vaults { dragon: tx-sender }) (err err-not-found))))
    (ok (map-set vaults
      { dragon: tx-sender }
      (merge vault { 
        last-activity: (get-current-time),
        last-check: (get-current-time)
      })
    ))
  )
)

(define-public (assign-guardian (guardian principal))
  (let ((vault (unwrap! (map-get? vaults { dragon: tx-sender }) (err err-not-found))))
    (ok (map-set vault-guardians
      { dragon: tx-sender, guardian: guardian }
      { active: true }
    ))
  )
)

(define-public (initiate-transfer (dragon principal))
  (let ((vault (unwrap! (map-get? vaults { dragon: dragon }) (err err-not-found))))
    (asserts! (check-inactive vault) (err err-access-denied))
    (ok (map-set transfer-requests
      { dragon: dragon }
      {
        initiated: (get-current-time),
        confirmations: (list tx-sender)
      }
    ))
  )
)

(define-public (confirm-transfer (dragon principal))
  (let (
    (vault (unwrap! (map-get? vaults { dragon: dragon }) (err err-not-found)))
    (request (unwrap! (map-get? transfer-requests { dragon: dragon }) (err err-not-found)))
    (guardian-status (default-to { active: false } (map-get? vault-guardians { dragon: dragon, guardian: tx-sender })))
  )
    (asserts! (get active guardian-status) (err err-access-denied))
    (asserts! (check-inactive vault) (err err-access-denied))
    (let ((updated-confirmations (unwrap! (as-max-len? (append (get confirmations request) tx-sender) u5) (err err-insufficient-guardians))))
      (ok (map-set transfer-requests
        { dragon: dragon }
        (merge request { confirmations: updated-confirmations })
      ))
    )
  )
)

(define-public (execute-transfer (dragon principal))
  (let (
    (vault (unwrap! (map-get? vaults { dragon: dragon }) (err err-not-found)))
    (request (unwrap! (map-get? transfer-requests { dragon: dragon }) (err err-not-found)))
  )
    (asserts! (check-inactive vault) (err err-access-denied))
    (asserts! (>= (len (get confirmations request)) (get guardian-threshold vault)) (err err-insufficient-guardians))
    (map-delete vaults { dragon: dragon })
    (map-delete transfer-requests { dragon: dragon })
    (ok true)
  )
)

(define-public (store-message (message (string-utf8 1024)))
  (let (
    (vault (unwrap! (map-get? vaults { dragon: tx-sender }) (err err-not-found)))
    (current-messages (default-to { messages: (list ) } (map-get? secure-messages { dragon: tx-sender })))
  )
    (let ((new-messages (unwrap! (as-max-len? (append (get messages current-messages) message) u10) (err err-message-limit))))
      (ok (map-set secure-messages
        { dragon: tx-sender }
        { messages: new-messages }
      ))
    )
  )
)

(define-public (read-messages (dragon principal))
  (let (
    (vault (unwrap! (map-get? vaults { dragon: dragon }) (err err-not-found)))
    (messages (unwrap! (map-get? secure-messages { dragon: dragon }) (err err-not-found)))
  )
    (asserts! (or (is-eq tx-sender dragon) (is-some (index-of (get successors vault) tx-sender))) (err err-access-denied))
    (asserts! (or (is-eq tx-sender dragon) (check-inactive vault)) (err err-access-denied))
    (ok messages)
  )
)

;; Read-only Functions
(define-read-only (get-vault-info (dragon principal))
  (ok (unwrap! (map-get? vaults { dragon: dragon }) (err err-not-found)))
)

(define-read-only (get-transfer-request (dragon principal))
  (ok (unwrap! (map-get? transfer-requests { dragon: dragon }) (err err-not-found)))
)

(define-read-only (next-check-due (dragon principal))
  (let ((vault (unwrap! (map-get? vaults { dragon: dragon }) (err err-not-found))))
    (ok (- (+ (get last-check vault) (get check-period vault)) (get-current-time)))
  )
)

(define-read-only (next-refresh-due (dragon principal))
  (let ((vault (unwrap! (map-get? vaults { dragon: dragon }) (err err-not-found))))
    (ok (- (+ (get last-refresh vault) u604800) (get-current-time)))
  )
)
