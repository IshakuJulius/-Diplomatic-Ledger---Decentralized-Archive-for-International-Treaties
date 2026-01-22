(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-validator (err u103))
(define-constant err-max-annotations (err u104))
(define-constant err-invalid-parent (err u105))

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
        validator: principal,
        version: uint,
        parent-treaty-id: (optional uint),
        amendment-reason: (string-ascii 200),
        expiration: (optional uint)
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

(define-map treaty-versions
    uint
    (list 20 uint)
)

(define-map treaty-ratifications
    uint
    (list 10 principal)
)

(define-map treaty-tags
    uint
    (list 20 (string-ascii 50))
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
                validator: tx-sender,
                version: u1,
                parent-treaty-id: none,
                amendment-reason: "",
                expiration: none
            }
        )
        (map-set treaty-versions treaty-id (list treaty-id))
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

(define-public (create-treaty-amendment
    (parent-treaty-id uint)
    (title (string-ascii 100))
    (countries (list 10 principal))
    (ipfs-hash (string-ascii 64))
    (amendment-reason (string-ascii 200)))
    (let
        ((parent-treaty (unwrap! (map-get? treaties parent-treaty-id) err-not-found))
         (parent-version (get version parent-treaty))
         (current-versions (default-to (list) (map-get? treaty-versions parent-treaty-id)))
         (new-treaty-id (var-get next-treaty-id)))
        (asserts! (is-validator tx-sender) err-invalid-validator)
        (asserts! (is-eq (get status parent-treaty) "active") err-invalid-parent)
        (asserts! (< (len current-versions) u20) err-max-annotations)
        (map-set treaties new-treaty-id
            {
                title: title,
                countries: countries,
                timestamp: burn-block-height,
                ipfs-hash: ipfs-hash,
                status: "active",
                validator: tx-sender,
                version: (+ parent-version u1),
                parent-treaty-id: (some parent-treaty-id),
                amendment-reason: amendment-reason,
                expiration: none
            }
        )
        (map-set treaty-versions parent-treaty-id
            (unwrap! (as-max-len? (append current-versions new-treaty-id) u20) err-max-annotations)
        )
        (map-set treaty-versions new-treaty-id (list new-treaty-id))
        (map-set treaties parent-treaty-id
            (merge parent-treaty { status: "superseded" })
        )
        (var-set next-treaty-id (+ new-treaty-id u1))
        (ok new-treaty-id)
    )
)

(define-public (ratify-treaty (treaty-id uint))
    (let
        ((treaty (unwrap! (map-get? treaties treaty-id) err-not-found))
         (countries (get countries treaty))
         (current-ratifications (default-to (list) (map-get? treaty-ratifications treaty-id))))
        (asserts! (is-some (index-of countries tx-sender)) err-invalid-validator)
        (asserts! (not (is-some (index-of current-ratifications tx-sender))) err-already-exists)
        (map-set treaty-ratifications
            treaty-id
            (unwrap! (as-max-len? (append current-ratifications tx-sender) u10) err-max-annotations)
        )
        (ok true)
    )
)

(define-read-only (get-treaty-versions (treaty-id uint))
    (ok (default-to (list) (map-get? treaty-versions treaty-id)))
)

(define-read-only (get-latest-treaty-version (treaty-id uint))
    (let
        ((versions (default-to (list) (map-get? treaty-versions treaty-id))))
        (if (> (len versions) u0)
            (ok (unwrap-panic (element-at versions (- (len versions) u1))))
            err-not-found
        )
    )
)

(define-read-only (get-treaty-version-history (treaty-id uint))
    (let
        ((versions (default-to (list) (map-get? treaty-versions treaty-id))))
        (ok (map get-treaty-basic-info versions))
    )
)

(define-read-only (get-treaty-basic-info (treaty-id uint))
    (match (map-get? treaties treaty-id)
        treaty-data {
            id: treaty-id,
            title: (get title treaty-data),
            version: (get version treaty-data),
            timestamp: (get timestamp treaty-data),
            status: (get status treaty-data),
            amendment-reason: (get amendment-reason treaty-data)
        }
        {
            id: treaty-id,
            title: "",
            version: u0,
            timestamp: u0,
            status: "",
            amendment-reason: ""
        }
    )
)

(define-read-only (get-treaty-ratifications (treaty-id uint))
    (ok (default-to (list) (map-get? treaty-ratifications treaty-id)))
)
(define-public (set-treaty-expiration
    (treaty-id uint)
    (expiration-block uint))
    (let
        ((treaty (unwrap! (map-get? treaties treaty-id) err-not-found)))
        (asserts! (is-validator tx-sender) err-invalid-validator)
        (asserts! (> expiration-block burn-block-height) err-invalid-parent)
        (map-set treaties treaty-id
            (merge treaty { expiration: (some expiration-block) })
        )
        (ok true)
    )
)

(define-read-only (is-treaty-expired (treaty-id uint))
    (let
        ((treaty (unwrap! (map-get? treaties treaty-id) err-not-found))
         (expiration (get expiration treaty)))
        (match expiration
            exp-block (ok (> burn-block-height exp-block))
            (ok false)
        )
    )
)

(define-public (add-treaty-tags
    (treaty-id uint)
    (tags (list 10 (string-ascii 50))))
    (let
        ((current-tags (default-to (list) (map-get? treaty-tags treaty-id))))
        (asserts! (is-validator tx-sender) err-invalid-validator)
        (asserts! (<= (+ (len current-tags) (len tags)) u20) err-max-annotations)
        (map-set treaty-tags
            treaty-id
            (unwrap! (as-max-len? (concat current-tags tags) u20) err-max-annotations)
        )
        (ok true)
    )
)

(define-read-only (get-treaty-tags (treaty-id uint))
    (ok (default-to (list) (map-get? treaty-tags treaty-id)))
)

