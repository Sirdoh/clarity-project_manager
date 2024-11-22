;; Contract Name: Clarity Project Manager
;; File Name: project_hub.clar
;; Description: A decentralized system to manage code repositories. It enables users to create, modify, delete, and manage ownership and contributors for code repositories.

;; -------------------------------
;; Storage Variables and Data Maps
;; -------------------------------

;; Counter for the total number of repositories created.
(define-data-var project-count uint u0)

;; Map to store repository details.
;; Key: { project-id: uint }
;; Value: (tuple containing repository metadata)
(define-map code-repositories
  { project-id: uint }
  (tuple
    (repo-name (string-ascii 64))        ;; Name of the repository (max 64 characters).
    (repo-owner principal)              ;; Owner of the repository.
    (repo-size uint)                    ;; Size of the repository in bytes.
    (creation-time uint)                ;; Timestamp of repository creation.
    (description (string-ascii 128))    ;; Description of the repository (max 128 characters).
    (contributors (list 10 principal))  ;; List of contributors (max 10).
  )
)

;; Map to manage access permissions.
;; Key: { project-id: uint, user: principal }
;; Value: (tuple containing collaboration rights)
(define-map access-rights
  { project-id: uint, user: principal }
  (tuple (can-collaborate bool))
)

;; -------------------------------
;; Error Constants
;; -------------------------------

;; Error codes for contract functions.
(define-constant error-repo-not-found (err u301))        ;; Repository does not exist.
(define-constant error-repo-exists (err u302))           ;; Repository already exists.
(define-constant error-name-invalid (err u303))          ;; Invalid repository name.
(define-constant error-size-invalid (err u304))          ;; Invalid repository size.
(define-constant error-not-authorized (err u305))        ;; Unauthorized access.
(define-constant error-invalid-recipient (err u306))     ;; Invalid recipient specified.
(define-constant error-admin-only (err u300))            ;; Admin-only access.
(define-constant error-invalid-access (err u307))        ;; Invalid access permissions.
(define-constant error-access-denied (err u308))         ;; Access denied.

;; Constant to identify the admin user.
(define-constant admin-identity tx-sender)

;; -------------------------------
;; Private Helper Functions
;; -------------------------------

;; Check if a repository exists for a given project ID.
(define-private (does-repo-exist (project-id uint))
  (is-some (map-get? code-repositories { project-id: project-id }))
)

;; Validate if a given user is the owner of the repository.
(define-private (check-repo-owner (project-id uint) (owner principal))
  (match (map-get? code-repositories { project-id: project-id })
    repo-details (is-eq (get repo-owner repo-details) owner)
    false
  )
)

;; Retrieve the size of a repository for a given project ID.
(define-private (retrieve-repo-size (project-id uint))
  (default-to u0 
    (get repo-size 
      (map-get? code-repositories { project-id: project-id })
    )
  )
)

;; Validate the list of contributors (max 10).
(define-private (validate-contributors (contributors (list 10 principal)))
  (and 
    (> (len contributors) u0)
    (<= (len contributors) u10)
  )
)

;; -------------------------------
;; Public Functions
;; -------------------------------

;; Create a new repository.
;; Parameters:
;; - repo-name: Name of the repository.
;; - repo-size: Size of the repository in bytes.
;; - description: Description of the repository.
;; - contributors: List of contributors.
(define-public (create-new-repo (repo-name (string-ascii 64)) (repo-size uint) (description (string-ascii 128)) (contributors (list 10 principal)))
  (let
    (
      (project-id (+ (var-get project-count) u1))
    )
    (asserts! (> (len repo-name) u0) error-name-invalid)
    (asserts! (< (len repo-name) u65) error-name-invalid)
    (asserts! (> repo-size u0) error-size-invalid)
    (asserts! (< repo-size u1000000000) error-size-invalid)
    (asserts! (> (len description) u0) error-name-invalid)
    (asserts! (< (len description) u129) error-name-invalid)
    (asserts! (validate-contributors contributors) error-name-invalid)

    (map-insert code-repositories
      { project-id: project-id }
      (tuple
        (repo-name repo-name)
        (repo-owner tx-sender)
        (repo-size repo-size)
        (creation-time block-height)
        (description description)
        (contributors contributors)
      )
    )

    (map-insert access-rights
      { project-id: project-id, user: tx-sender }
      (tuple (can-collaborate true))
    )

    (var-set project-count project-id)
    (ok project-id)
  )
)

;; Transfer ownership of a repository to a new owner.
(define-public (change-repo-owner (project-id uint) (new-owner principal))
  (let
    (
      (repo-data (unwrap! (map-get? code-repositories { project-id: project-id }) error-repo-not-found))
    )
    (asserts! (does-repo-exist project-id) error-repo-not-found)
    (asserts! (is-eq (get repo-owner repo-data) tx-sender) error-not-authorized)
    (map-set code-repositories
      { project-id: project-id }
      (merge repo-data { repo-owner: new-owner })
    )
    (ok true)
  )
)

;; Modify repository details.
(define-public (modify-repo (project-id uint) (new-name (string-ascii 64)) (new-size uint) (new-description (string-ascii 128)) (new-contributors (list 10 principal)))
  (let
    (
      (repo-data (unwrap! (map-get? code-repositories { project-id: project-id }) error-repo-not-found))
    )
    (asserts! (does-repo-exist project-id) error-repo-not-found)
    (asserts! (is-eq (get repo-owner repo-data) tx-sender) error-not-authorized)
    (asserts! (> (len new-name) u0) error-name-invalid)
    (asserts! (< (len new-name) u65) error-name-invalid)
    (asserts! (> new-size u0) error-size-invalid)
    (asserts! (< new-size u1000000000) error-size-invalid)
    (asserts! (> (len new-description) u0) error-name-invalid)
    (asserts! (< (len new-description) u129) error-name-invalid)
    (asserts! (validate-contributors new-contributors) error-name-invalid)

    (map-set code-repositories
      { project-id: project-id }
      (merge repo-data { repo-name: new-name, repo-size: new-size, description: new-description, contributors: new-contributors })
    )
    (ok true)
  )
)

;; Remove a repository from the system.
(define-public (remove-repo (project-id uint))
  (let
    (
      (repo-data (unwrap! (map-get? code-repositories { project-id: project-id }) error-repo-not-found))
    )
    (asserts! (does-repo-exist project-id) error-repo-not-found)
    (asserts! (is-eq (get repo-owner repo-data) tx-sender) error-not-authorized)
    (map-delete code-repositories { project-id: project-id })
    (ok true)
  )
)

;; New Functionality: Retrieve repository details.
(define-public (get-repo-details (project-id uint))
  (let
    (
      (repo-data (unwrap! (map-get? code-repositories { project-id: project-id }) error-repo-not-found))
    )
    (ok repo-data)
  )
)
