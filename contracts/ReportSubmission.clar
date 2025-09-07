(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-HASH (err u101))
(define-constant ERR-INVALID-DESCRIPTION (err u102))
(define-constant ERR-INVALID-SEVERITY (err u103))
(define-constant ERR-INVALID-LOCATION (err u104))
(define-constant ERR-REPORT-ALREADY-EXISTS (err u105))
(define-constant ERR-INVALID-REPORT-ID (err u106))
(define-constant ERR-REPORT-NOT-FOUND (err u107))
(define-constant ERR-INVALID-TIMESTAMP (err u108))
(define-constant ERR-REPORTER-NOT-VERIFIED (err u109))
(define-constant ERR-LOCATION-OUT-OF-BOUNDS (err u110))
(define-constant ERR-INVALID-BOUNDARIES (err u111))
(define-constant ERR-REPORT-UPDATE-NOT-ALLOWED (err u112))
(define-constant ERR-INVALID-UPDATE-HASH (err u113))
(define-constant ERR-MAX-REPORTS-EXCEEDED (err u114))
(define-constant ERR-INVALID-CATEGORY (err u115))
(define-constant ERR-INVALID-EVIDENCE-COUNT (err u116))
(define-constant ERR-INVALID-IMPACT-LEVEL (err u117))
(define-constant ERR-INVALID-WEATHER-IMPACT (err u118))
(define-constant ERR-INVALID-AFFECTED-POPULATION (err u119))
(define-constant ERR-INVALID-EMERGENCY-LEVEL (err u120))
(define-constant ERR-INVALID-STATUS (err u121))
(define-constant ERR-FEE-NOT-PAID (err u122))
(define-constant ERR-INVALID-EVIDENCE-HASH (err u123))
(define-constant ERR-DUPLICATE-EVIDENCE (err u124))
(define-constant ERR-INVALID-UPDATE-DESCRIPTION (err u125))
(define-constant ERR-INVALID-UPDATE-SEVERITY (err u126))

(define-data-var next-report-id uint u0)
(define-data-var max-reports uint u10000)
(define-data-var submission-fee uint u500)
(define-data-var token-contract principal 'SP3K8BC0PPEVCV7NZ6QSRWPQ2JE9E5B6N3PA0KBR9.token-alex)
(define-data-var validator-contract (optional principal) none)

(define-map reports
  uint
  {
    hash: (buff 32),
    description: (string-utf8 1000),
    severity: uint,
    location: { lat: int, lon: int },
    boundaries: { min-lat: int, max-lat: int, min-lon: int, max-lon: int },
    timestamp: uint,
    reporter: principal,
    category: (string-utf8 50),
    evidence-hashes: (list 10 (buff 32)),
    impact-level: uint,
    weather-impact: (string-utf8 100),
    affected-population: uint,
    emergency-level: uint,
    status: (string-utf8 20)
  }
)

(define-map reports-by-hash
  (buff 32)
  uint)

(define-map report-updates
  uint
  {
    update-hash: (buff 32),
    update-description: (string-utf8 1000),
    update-severity: uint,
    update-timestamp: uint,
    updater: principal
  }
)

(define-read-only (get-report (id uint))
  (map-get? reports id)
)

(define-read-only (get-report-updates (id uint))
  (map-get? report-updates id)
)

(define-read-only (is-report-registered (h (buff 32)))
  (is-some (map-get? reports-by-hash h))
)

(define-read-only (get-report-count)
  (ok (var-get next-report-id))
)

(define-read-only (check-report-existence (hash (buff 32)))
  (ok (is-report-registered hash))
)

(define-private (validate-hash (h (buff 32)))
  (if (is-eq (len h) u32)
      (ok true)
      ERR-INVALID-HASH)
)

(define-private (validate-description (desc (string-utf8 1000)))
  (if (> (len desc) u0)
      (ok true)
      ERR-INVALID-DESCRIPTION)
)

(define-private (validate-severity (sev uint))
  (if (or (<= sev u0) (> sev u10))
      ERR-INVALID_SEVERITY
      (ok true))
)

(define-private (validate-location (loc { lat: int, lon: int }))
  (let ((lat (get lat loc))
        (lon (get lon loc)))
    (if (and (>= lat -90000000) (<= lat 90000000)
             (>= lon -180000000) (<= lon 180000000))
        (ok true)
        ERR-LOCATION-OUT-OF-BOUNDS))
)

(define-private (validate-boundaries (bounds { min-lat: int, max-lat: int, min-lon: int, max-lon: int }))
  (let ((min-lat (get min-lat bounds))
        (max-lat (get max-lat bounds))
        (min-lon (get min-lon bounds))
        (max-lon (get max-lon bounds)))
    (if (and (<= min-lat max-lat)
             (<= min-lon max-lon))
        (ok true)
        ERR-INVALID-BOUNDARIES))
)

(define-private (validate-timestamp (ts uint))
  (if (>= ts block-height)
      (ok true)
      ERR-INVALID-TIMESTAMP)
)

(define-private (validate-category (cat (string-utf8 50)))
  (if (or (is-eq cat u"natural-disaster") (is-eq cat u"conflict") (is-eq cat u"public-emergency") (is-eq cat u"health-crisis"))
      (ok true)
      ERR-INVALID-CATEGORY)
)

(define-private (validate-evidence-hashes (evs (list 10 (buff 32))))
  (if (and (>= (len evs) u1) (<= (len evs) u10))
      (fold check-unique-evidence evs (ok true))
      ERR-INVALID-EVIDENCE-COUNT)
)

(define-private (check-unique-evidence (ev (buff 32)) (acc (response bool uint)))
  (match acc
    ok-val (if (is-some (index-of? evs ev))
               ERR-DUPLICATE-EVIDENCE
               (ok true))
    err-val acc)
)

(define-private (validate-impact-level (imp uint))
  (if (or (<= imp u0) (> imp u5))
      ERR-INVALID-IMPACT-LEVEL
      (ok true))
)

(define-private (validate-weather-impact (wi (string-utf8 100)))
  (if (or (is-eq wi u"none") (is-eq wi u"mild") (is-eq wi u"severe"))
      (ok true)
      ERR-INVALID_WEATHER-IMPACT)
)

(define-private (validate-affected-population (ap uint))
  (if (<= ap u10000000)
      (ok true)
      ERR-INVALID_AFFECTED_POPULATION)
)

(define-private (validate-emergency-level (el uint))
  (if (or (<= el u0) (> el u3))
      ERR-INVALID_EMERGENCY_LEVEL
      (ok true))
)

(define-private (validate-status (st (string-utf8 20)))
  (if (or (is-eq st u"pending") (is-eq st u"validated") (is-eq st u"rejected"))
      (ok true)
      ERR-INVALID_STATUS)
)

(define-public (set-validator-contract (contract-principal principal))
  (begin
    (asserts! (is-none (var-get validator-contract)) ERR-REPORTER-NOT-VERIFIED)
    (var-set validator-contract (some contract-principal))
    (ok true))
)

(define-public (set-max-reports (new-max uint))
  (begin
    (asserts! (is-some (var-get validator-contract)) ERR_REPORTER-NOT-VERIFIED)
    (var-set max-reports new-max)
    (ok true))
)

(define-public (set-submission-fee (new-fee uint))
  (begin
    (asserts! (is-some (var-get validator-contract)) ERR_REPORTER-NOT-VERIFIED)
    (var-set submission-fee new-fee)
    (ok true))
)

(define-public (submit-report
  (report-hash (buff 32))
  (description (string-utf8 1000))
  (severity uint)
  (location { lat: int, lon: int })
  (boundaries { min-lat: int, max-lat: int, min-lon: int, max-lon: int })
  (category (string-utf8 50))
  (evidence-hashes (list 10 (buff 32)))
  (impact-level uint)
  (weather-impact (string-utf8 100))
  (affected-population uint)
  (emergency-level uint))
  (let (
        (next-id (var-get next-report-id))
        (current-max (var-get max-reports))
        (fee (var-get submission-fee))
        (token-principal (var-get token-contract))
      )
    (asserts! (< next-id current-max) ERR-MAX-REPORTS-EXCEEDED)
    (try! (validate-hash report-hash))
    (try! (validate-description description))
    (try! (validate-severity severity))
    (try! (validate-location location))
    (try! (validate-boundaries boundaries))
    (try! (validate-category category))
    (try! (validate-evidence-hashes evidence-hashes))
    (try! (validate-impact-level impact-level))
    (try! (validate-weather-impact weather-impact))
    (try! (validate-affected-population affected-population))
    (try! (validate-emergency-level emergency-level))
    (asserts! (is-none (map-get? reports-by-hash report-hash)) ERR-REPORT-ALREADY-EXISTS)
    (try! (as-contract (contract-call? token-principal transfer fee tx-sender (as-contract tx-sender) none)))
    (map-set reports next-id
      {
        hash: report-hash,
        description: description,
        severity: severity,
        location: location,
        boundaries: boundaries,
        timestamp: block-height,
        reporter: tx-sender,
        category: category,
        evidence-hashes: evidence-hashes,
        impact-level: impact-level,
        weather-impact: weather-impact,
        affected-population: affected-population,
        emergency-level: emergency-level,
        status: u"pending"
      })
    (map-set reports-by-hash report-hash next-id)
    (var-set next-report-id (+ next-id u1))
    (print { event: "report-submitted", id: next-id })
    (ok next-id))
)

(define-public (update-report
  (report-id uint)
  (update-hash (buff 32))
  (update-description (string-utf8 1000))
  (update-severity uint))
  (let (
        (report (map-get? reports report-id))
      )
    (match report
      r
        (begin
          (asserts! (is-eq (get reporter r) tx-sender) ERR-NOT-AUTHORIZED)
          (try! (validate-hash update-hash))
          (try! (validate-description update-description))
          (try! (validate-severity update-severity))
          (let ((existing (map-get? reports-by-hash update-hash)))
            (asserts!
              (or (is-none existing)
                  (is-eq (unwrap! existing ERR-INVALID_REPORT-ID) report-id))
              ERR-REPORT-ALREADY-EXISTS))
          (let ((old-hash (get hash r)))
            (map-delete reports-by-hash old-hash)
            (map-set reports-by-hash update-hash report-id))
          (map-set reports report-id
            (merge r {
              hash: update-hash,
              description: update-description,
              severity: update-severity,
              timestamp: block-height
            }))
          (map-set report-updates report-id
            {
              update-hash: update-hash,
              update-description: update-description,
              update-severity: update-severity,
              update-timestamp: block-height,
              updater: tx-sender
            })
          (print { event: "report-updated", id: report-id })
          (ok true))
      ERR-REPORT-NOT-FOUND))
)