;; Contract Name: Clarity Project Manager MVP
;; Description: A basic decentralized system to manage code repositories.
;; -------------------------------
;; Storage Variables and Data Maps
;; -------------------------------
;; Counter for the total number of repositories created.
(define-data-var project-count uint u0)
;; Map to store repository details.
(define-map code-repositories
  { project-id: uint }
  (tuple
    (repo-name (string-ascii 64))  ;; Name of the repository.
    (repo-owner principal)        ;; Owner of the repository.
  )
)
;; -------------------------------
;; Error Constants
;; -------------------------------
(define-constant error-repo-not-found (err u301))  ;; Repository does not exist.
(define-constant error-not-authorized (err u305))  ;; Unauthorized access.
(define-constant error-invalid-project-id (err u306))  ;; Invalid project ID
;; -------------------------------
;; Private Functions
;; -------------------------------
;; Validate project ID exists
(define-private (validate-project-id (project-id uint))
  (match (map-get? code-repositories { project-id: project-id })
    repo-data true
    false)
)
;; -------------------------------
;; Public Functions
;; -------------------------------
;; Create a new repository.
(define-public (create-new-repo (repo-name (string-ascii 64)))
  (let
    (
      (project-id (+ (var-get project-count) u1))
    )
    (asserts! (> (len repo-name) u0) (err u303))  ;; Name should not be empty.
    (map-insert code-repositories
      { project-id: project-id }
      (tuple
        (repo-name repo-name)
        (repo-owner tx-sender)
      )
    )
    (var-set project-count project-id)
    (ok project-id)
  )
)
;; Transfer ownership of a repository.
(define-public (change-repo-owner (project-id uint) (new-owner principal))
  (let
    (
      (repo-data (unwrap! (map-get? code-repositories { project-id: project-id }) error-repo-not-found))
    )
    ;; Validate project ID first
    (asserts! (validate-project-id project-id) error-invalid-project-id)
    
    ;; Check authorization
    (asserts! (is-eq (get repo-owner repo-data) tx-sender) error-not-authorized)
    
    ;; Update repository owner
    (map-set code-repositories
      { project-id: project-id }
      (merge repo-data { repo-owner: new-owner })
    )
    (ok true)
  )
)
;; Remove a repository.
(define-public (remove-repo (project-id uint))
  (let
    (
      (repo-data (unwrap! (map-get? code-repositories { project-id: project-id }) error-repo-not-found))
    )
    ;; Validate project ID first
    (asserts! (validate-project-id project-id) error-invalid-project-id)
    
    ;; Check authorization
    (asserts! (is-eq (get repo-owner repo-data) tx-sender) error-not-authorized)
    
    ;; Delete repository
    (map-delete code-repositories { project-id: project-id })
    (ok true)
  )
)