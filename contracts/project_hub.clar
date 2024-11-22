;; Contract Name: Clarity Project Manager
;; File Name: project_hub.clar
;; Description: A decentralized system to manage code repositories with enhanced access control.

;; -------------------------------
;; Storage Variables and Data Maps
;; -------------------------------

;; Counter for the total number of repositories created.
(define-data-var project-count uint u0)

;; Map to store repository details.
(define-map code-repositories
  { project-id: uint }
  (tuple
    (repo-name (string-ascii 64))
    (repo-owner principal)
    (repo-size uint)
    (creation-time uint)
    (description (string-ascii 128))
    (contributors (list 10 principal))
  )
)

;; Enhanced access rights map with multiple permission levels
(define-map access-rights
  { project-id: uint, user: principal }
  {
    can-read: bool,
    can-write: bool,
    can-delete: bool,
    can-manage-access: bool,
    access-level: uint  ;; 0: No access, 1: Reader, 2: Contributor, 3: Manager, 4: Owner
  }
)

;; -------------------------------
;; Error Constants
;; -------------------------------

(define-constant error-repo-not-found (err u301))
(define-constant error-repo-exists (err u302))
(define-constant error-name-invalid (err u303))
(define-constant error-size-invalid (err u304))
(define-constant error-not-authorized (err u305))
(define-constant error-invalid-recipient (err u306))
(define-constant error-admin-only (err u300))
(define-constant error-invalid-access (err u307))
(define-constant error-access-denied (err u308))
(define-constant error-invalid-access-level (err u309))
(define-constant error-invalid-project-id (err u310))
(define-constant error-invalid-user (err u311))

;; Constant to identify the admin user.
(define-constant admin-identity tx-sender)

;; -------------------------------
;; Private Helper Functions
;; -------------------------------

;; Validate project ID
(define-private (validate-project-id (project-id uint))
  (and 
    (> project-id u0)
    (<= project-id (var-get project-count))
  )
)

;; Validate user principal
(define-private (validate-user (user principal))
  (and 
    (not (is-eq user admin-identity))
    (not (is-eq user tx-sender))
  )
)

;; Check if a repository exists
(define-private (does-repo-exist (project-id uint))
  (is-some (map-get? code-repositories { project-id: project-id }))
)

;; Validate if a given user is the owner
(define-private (check-repo-owner (project-id uint) (owner principal))
  (match (map-get? code-repositories { project-id: project-id })
    repo-details (is-eq (get repo-owner repo-details) owner)
    false
  )
)

;; Get repository size
(define-private (retrieve-repo-size (project-id uint))
  (default-to u0 
    (get repo-size 
      (map-get? code-repositories { project-id: project-id })
    )
  )
)

;; Validate contributors list
(define-private (validate-contributors (contributors (list 10 principal)))
  (and 
    (> (len contributors) u0)
    (<= (len contributors) u10)
  )
)

;; Get user's access rights
(define-private (get-user-access-rights (project-id uint) (user principal))
  (if (and (validate-project-id project-id) (validate-user user))
    (default-to 
      {
        can-read: false,
        can-write: false,
        can-delete: false,
        can-manage-access: false,
        access-level: u0
      }
      (map-get? access-rights { project-id: project-id, user: user })
    )
    {
      can-read: false,
      can-write: false,
      can-delete: false,
      can-manage-access: false,
      access-level: u0
    }
  )
)

;; Check specific permission
(define-private (has-permission (project-id uint) (user principal) (permission (string-ascii 20)))
  (let
    (
      (access-data (get-user-access-rights project-id user))
    )
    (if (is-eq permission "read")
      (get can-read access-data)
      (if (is-eq permission "write")
        (get can-write access-data)
        (if (is-eq permission "delete")
          (get can-delete access-data)
          (if (is-eq permission "manage")
            (get can-manage-access access-data)
            false))))
  )
)

;; -------------------------------
;; Access Control Functions
;; -------------------------------

;; Grant access rights
(define-public (grant-access-rights 
    (project-id uint)
    (user principal)
    (access-level uint)
  )
  (begin
    (asserts! (validate-project-id project-id) error-invalid-project-id)
    (asserts! (validate-user user) error-invalid-user)
    (let
      (
        (repo-data (unwrap! (map-get? code-repositories { project-id: project-id }) error-repo-not-found))
        (current-user-rights (get-user-access-rights project-id tx-sender))
      )
      (asserts! (does-repo-exist project-id) error-repo-not-found)
      (asserts! (or 
        (is-eq (get repo-owner repo-data) tx-sender)
        (get can-manage-access current-user-rights)
      ) error-not-authorized)
      (asserts! (<= access-level u4) error-invalid-access-level)
      
      (map-set access-rights
        { project-id: project-id, user: user }
        {
          can-read: (>= access-level u1),
          can-write: (>= access-level u2),
          can-delete: (>= access-level u3),
          can-manage-access: (>= access-level u4),
          access-level: access-level
        }
      )
      (ok true)
    )
  )
)

;; Revoke access rights
(define-public (revoke-access-rights (project-id uint) (user principal))
  (begin
    (asserts! (validate-project-id project-id) error-invalid-project-id)
    (asserts! (validate-user user) error-invalid-user)
    (let
      (
        (repo-data (unwrap! (map-get? code-repositories { project-id: project-id }) error-repo-not-found))
        (current-user-rights (get-user-access-rights project-id tx-sender))
      )
      (asserts! (does-repo-exist project-id) error-repo-not-found)
      (asserts! (or 
        (is-eq (get repo-owner repo-data) tx-sender)
        (get can-manage-access current-user-rights)
      ) error-not-authorized)
      (asserts! (not (is-eq user (get repo-owner repo-data))) error-not-authorized)
      
      (map-delete access-rights { project-id: project-id, user: user })
      (ok true)
    )
  )
)

;; Check access level
(define-public (check-access-level (project-id uint) (user principal))
  (begin
    (asserts! (validate-project-id project-id) error-invalid-project-id)
    (asserts! (validate-user user) error-invalid-user)
    (ok (get access-level (get-user-access-rights project-id user)))
  )
)

;; -------------------------------
;; Public Functions with Access Control
;; -------------------------------

;; Create new repository
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

    (map-set access-rights
      { project-id: project-id, user: tx-sender }
      {
        can-read: true,
        can-write: true,
        can-delete: true,
        can-manage-access: true,
        access-level: u4
      }
    )

    (var-set project-count project-id)
    (ok project-id)
  )
)

;; Modify repository
(define-public (modify-repo (project-id uint) (new-name (string-ascii 64)) (new-size uint) (new-description (string-ascii 128)) (new-contributors (list 10 principal)))
  (begin
    (asserts! (validate-project-id project-id) error-invalid-project-id)
    (let
      (
        (repo-data (unwrap! (map-get? code-repositories { project-id: project-id }) error-repo-not-found))
        (access-data (get-user-access-rights project-id tx-sender))
      )
      (asserts! (does-repo-exist project-id) error-repo-not-found)
      (asserts! (get can-write access-data) error-not-authorized)
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
)

;; Remove repository
(define-public (remove-repo (project-id uint))
  (begin
    (asserts! (validate-project-id project-id) error-invalid-project-id)
    (let
      (
        (repo-data (unwrap! (map-get? code-repositories { project-id: project-id }) error-repo-not-found))
        (access-data (get-user-access-rights project-id tx-sender))
      )
      (asserts! (does-repo-exist project-id) error-repo-not-found)
      (asserts! (get can-delete access-data) error-not-authorized)
      (map-delete code-repositories { project-id: project-id })
      (ok true)
    )
  )
)

;; Get repository details
(define-public (get-repo-details (project-id uint))
  (begin
    (asserts! (validate-project-id project-id) error-invalid-project-id)
    (let
      (
        (repo-data (unwrap! (map-get? code-repositories { project-id: project-id }) error-repo-not-found))
        (access-data (get-user-access-rights project-id tx-sender))
      )
      (asserts! (get can-read access-data) error-access-denied)
      (ok repo-data)
    )
  )
)
