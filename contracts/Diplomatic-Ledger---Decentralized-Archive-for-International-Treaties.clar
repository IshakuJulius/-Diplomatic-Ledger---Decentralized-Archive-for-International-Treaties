(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-validator (err u103))
(define-constant err-max-annotations (err u104))

(define-data-var next-treaty-id uint u1)
(define-data-var next-validator-id uint u1)

(define-map treaties
    uint 
    {
        title: (string-ascii 100),
        countries: (list 10 principal),
        timestamp: uint,
        ipfs-hash: (string-ascii 64),
        status: (string-ascii 20),
        validator: principal
    }
)

(define-map validators
    principal
    {
        id: uint,
        role: (string-ascii 20),
        reputation: uint,
        active: bool
    }
)

(define-map treaty-annotations
    uint
    (list 50 {
        annotator: principal,
        content: (string-ascii 500),
        timestamp: uint
    })
)

(define-public (register-treaty
    (title (string-ascii 100))
    (countries (list 10 principal))
    (ipfs-hash (string-ascii 64)))
    (let
        ((treaty-id (var-get next-treaty-id)))
        (asserts! (is-validator tx-sender) err-invalid-validator)
        (map-set treaties treaty-id
            {
                title: title,
                countries: countries,
                timestamp: burn-block-height,
                ipfs-hash: ipfs-hash,
                status: "active",
                validator: tx-sender
            }
        )
        (var-set next-treaty-id (+ treaty-id u1))
        (ok treaty-id)
    )
)

(define-public (add-validator 
    (validator-address principal)
    (role (string-ascii 20)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (not (is-validator validator-address)) err-already-exists)
        (let
            ((validator-id (var-get next-validator-id)))
            (map-set validators validator-address
                {
                    id: validator-id,
                    role: role,
                    reputation: u100,
                    active: true
                }
            )
            (var-set next-validator-id (+ validator-id u1))
            (ok validator-id)
        )
    )
)

(define-public (add-annotation
    (treaty-id uint)
    (content (string-ascii 500)))
    (let
        ((current-annotations (default-to (list) (map-get? treaty-annotations treaty-id))))
        (asserts! (is-validator tx-sender) err-invalid-validator)
        (asserts! (< (len current-annotations) u50) err-max-annotations)
        (map-set treaty-annotations
            treaty-id
            (unwrap! (as-max-len? (append 
                current-annotations 

                {
                    annotator: tx-sender,
                    content: content,
                    timestamp: burn-block-height

                }
            ) u50) err-max-annotations)
        )
        (ok true)
    )
)

(define-read-only (get-treaty (treaty-id uint))
    (ok (unwrap! (map-get? treaties treaty-id) err-not-found))
)

(define-read-only (get-treaty-annotations (treaty-id uint))
    (ok (default-to (list) (map-get? treaty-annotations treaty-id)))
)

(define-read-only (is-validator (address principal))
    (is-some (map-get? validators address))
)

(define-read-only (get-validator-info (address principal))
    (ok (unwrap! (map-get? validators address) err-not-found))
)

(define-public (update-treaty-status
    (treaty-id uint)
    (new-status (string-ascii 20)))
    (let
        ((treaty (unwrap! (map-get? treaties treaty-id) err-not-found)))
        (asserts! (is-validator tx-sender) err-invalid-validator)
        (map-set treaties treaty-id
            (merge treaty { status: new-status })
        )
        (ok true)
    )
)