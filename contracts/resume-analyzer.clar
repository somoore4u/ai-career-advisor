;; Resume Analyzer Smart Contract
;; Analyzes resumes and highlights skill gaps for career development

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_PROFILE (err u101))
(define-constant ERR_PROFILE_NOT_FOUND (err u102))
(define-constant ERR_SKILL_NOT_FOUND (err u103))
(define-constant ERR_INVALID_SKILL_LEVEL (err u104))
(define-constant ERR_RECOMMENDATION_NOT_FOUND (err u105))

;; Data structures
(define-map user-profiles
  principal
  {
    name: (string-ascii 64),
    email: (string-ascii 128),
    experience-years: uint,
    current-role: (string-ascii 64),
    industry: (string-ascii 64),
    created-at: uint,
    last-updated: uint,
    profile-active: bool
  }
)

(define-map user-skills
  { user: principal, skill-id: uint }
  {
    skill-name: (string-ascii 64),
    skill-level: uint, ;; 1-10 scale
    years-experience: uint,
    certified: bool,
    last-used: uint
  }
)

(define-map skill-gaps
  { user: principal, gap-id: uint }
  {
    missing-skill: (string-ascii 64),
    required-level: uint,
    priority: uint, ;; 1-5 scale
    market-demand: uint, ;; 1-10 scale
    identified-at: uint
  }
)

(define-map career-recommendations
  { user: principal, recommendation-id: uint }
  {
    target-role: (string-ascii 64),
    confidence-score: uint, ;; 1-100 percentage
    required-skills: (list 10 (string-ascii 64)),
    estimated-timeline: uint, ;; months
    salary-range-min: uint,
    salary-range-max: uint,
    created-at: uint
  }
)

(define-map learning-paths
  { user: principal, path-id: uint }
  {
    skill-target: (string-ascii 64),
    course-name: (string-ascii 128),
    provider: (string-ascii 64),
    duration-weeks: uint,
    cost-estimate: uint,
    completion-status: (string-ascii 16) ;; "not-started", "in-progress", "completed"
  }
)

;; Data variables
(define-data-var next-skill-id uint u1)
(define-data-var next-gap-id uint u1)
(define-data-var next-recommendation-id uint u1)
(define-data-var next-path-id uint u1)
(define-data-var total-profiles uint u0)
(define-data-var contract-active bool true)

;; Public functions

;; Create user profile
(define-public (create-profile (name (string-ascii 64)) (email (string-ascii 128)) 
                              (experience-years uint) (current-role (string-ascii 64)) 
                              (industry (string-ascii 64)))
  (let ((profile-exists (is-some (map-get? user-profiles tx-sender))))
    (asserts! (not profile-exists) ERR_INVALID_PROFILE)
    (asserts! (> (len name) u0) ERR_INVALID_PROFILE)
    (asserts! (> (len email) u0) ERR_INVALID_PROFILE)
    (map-set user-profiles tx-sender {
      name: name,
      email: email,
      experience-years: experience-years,
      current-role: current-role,
      industry: industry,
      created-at: burn-block-height,
      last-updated: burn-block-height,
      profile-active: true
    })
    (var-set total-profiles (+ (var-get total-profiles) u1))
    (ok "Profile created successfully")
  )
)

;; Update profile information
(define-public (update-profile (name (string-ascii 64)) (email (string-ascii 128)) 
                              (experience-years uint) (current-role (string-ascii 64)) 
                              (industry (string-ascii 64)))
  (let ((existing-profile (unwrap! (map-get? user-profiles tx-sender) ERR_PROFILE_NOT_FOUND)))
    (map-set user-profiles tx-sender {
      name: name,
      email: email,
      experience-years: experience-years,
      current-role: current-role,
      industry: industry,
      created-at: (get created-at existing-profile),
      last-updated: burn-block-height,
      profile-active: true
    })
    (ok "Profile updated successfully")
  )
)

;; Add skill to user profile
(define-public (add-skill (skill-name (string-ascii 64)) (skill-level uint) 
                         (years-experience uint) (certified bool))
  (let ((skill-id (var-get next-skill-id)))
    (asserts! (is-some (map-get? user-profiles tx-sender)) ERR_PROFILE_NOT_FOUND)
    (asserts! (and (>= skill-level u1) (<= skill-level u10)) ERR_INVALID_SKILL_LEVEL)
    (asserts! (> (len skill-name) u0) ERR_INVALID_SKILL_LEVEL)
    (map-set user-skills { user: tx-sender, skill-id: skill-id } {
      skill-name: skill-name,
      skill-level: skill-level,
      years-experience: years-experience,
      certified: certified,
      last-used: burn-block-height
    })
    (var-set next-skill-id (+ skill-id u1))
    (ok skill-id)
  )
)

;; Update skill level
(define-public (update-skill-level (skill-id uint) (new-level uint) (certified bool))
  (let ((skill-key { user: tx-sender, skill-id: skill-id }))
    (let ((existing-skill (unwrap! (map-get? user-skills skill-key) ERR_SKILL_NOT_FOUND)))
      (asserts! (and (>= new-level u1) (<= new-level u10)) ERR_INVALID_SKILL_LEVEL)
      (map-set user-skills skill-key {
        skill-name: (get skill-name existing-skill),
        skill-level: new-level,
        years-experience: (get years-experience existing-skill),
        certified: certified,
        last-used: burn-block-height
      })
      (ok "Skill updated successfully")
    )
  )
)

;; Identify skill gaps
(define-public (identify-skill-gap (missing-skill (string-ascii 64)) (required-level uint) 
                                  (priority uint) (market-demand uint))
  (let ((gap-id (var-get next-gap-id)))
    (asserts! (is-some (map-get? user-profiles tx-sender)) ERR_PROFILE_NOT_FOUND)
    (asserts! (and (>= required-level u1) (<= required-level u10)) ERR_INVALID_SKILL_LEVEL)
    (asserts! (and (>= priority u1) (<= priority u5)) ERR_INVALID_SKILL_LEVEL)
    (asserts! (and (>= market-demand u1) (<= market-demand u10)) ERR_INVALID_SKILL_LEVEL)
    (map-set skill-gaps { user: tx-sender, gap-id: gap-id } {
      missing-skill: missing-skill,
      required-level: required-level,
      priority: priority,
      market-demand: market-demand,
      identified-at: burn-block-height
    })
    (var-set next-gap-id (+ gap-id u1))
    (ok gap-id)
  )
)

;; Generate career recommendations
(define-public (generate-recommendation (target-role (string-ascii 64)) (confidence-score uint)
                                       (required-skills (list 10 (string-ascii 64)))
                                       (estimated-timeline uint) (salary-range-min uint)
                                       (salary-range-max uint))
  (let ((recommendation-id (var-get next-recommendation-id)))
    (asserts! (is-some (map-get? user-profiles tx-sender)) ERR_PROFILE_NOT_FOUND)
    (asserts! (and (>= confidence-score u1) (<= confidence-score u100)) ERR_INVALID_SKILL_LEVEL)
    (asserts! (> (len target-role) u0) ERR_INVALID_SKILL_LEVEL)
    (map-set career-recommendations { user: tx-sender, recommendation-id: recommendation-id } {
      target-role: target-role,
      confidence-score: confidence-score,
      required-skills: required-skills,
      estimated-timeline: estimated-timeline,
      salary-range-min: salary-range-min,
      salary-range-max: salary-range-max,
      created-at: burn-block-height
    })
    (var-set next-recommendation-id (+ recommendation-id u1))
    (ok recommendation-id)
  )
)

;; Create learning path
(define-public (create-learning-path (skill-target (string-ascii 64)) (course-name (string-ascii 128))
                                    (provider (string-ascii 64)) (duration-weeks uint)
                                    (cost-estimate uint))
  (let ((path-id (var-get next-path-id)))
    (asserts! (is-some (map-get? user-profiles tx-sender)) ERR_PROFILE_NOT_FOUND)
    (asserts! (> (len skill-target) u0) ERR_INVALID_SKILL_LEVEL)
    (asserts! (> (len course-name) u0) ERR_INVALID_SKILL_LEVEL)
    (map-set learning-paths { user: tx-sender, path-id: path-id } {
      skill-target: skill-target,
      course-name: course-name,
      provider: provider,
      duration-weeks: duration-weeks,
      cost-estimate: cost-estimate,
      completion-status: "not-started"
    })
    (var-set next-path-id (+ path-id u1))
    (ok path-id)
  )
)

;; Update learning path status
(define-public (update-learning-progress (path-id uint) (status (string-ascii 16)))
  (let ((path-key { user: tx-sender, path-id: path-id }))
    (let ((existing-path (unwrap! (map-get? learning-paths path-key) ERR_RECOMMENDATION_NOT_FOUND)))
      (map-set learning-paths path-key {
        skill-target: (get skill-target existing-path),
        course-name: (get course-name existing-path),
        provider: (get provider existing-path),
        duration-weeks: (get duration-weeks existing-path),
        cost-estimate: (get cost-estimate existing-path),
        completion-status: status
      })
      (ok "Learning progress updated")
    )
  )
)

;; Read-only functions

;; Get user profile
(define-read-only (get-profile (user principal))
  (map-get? user-profiles user)
)

;; Get user skill
(define-read-only (get-skill (user principal) (skill-id uint))
  (map-get? user-skills { user: user, skill-id: skill-id })
)

;; Get skill gap
(define-read-only (get-skill-gap (user principal) (gap-id uint))
  (map-get? skill-gaps { user: user, gap-id: gap-id })
)

;; Get career recommendation
(define-read-only (get-recommendation (user principal) (recommendation-id uint))
  (map-get? career-recommendations { user: user, recommendation-id: recommendation-id })
)

;; Get learning path
(define-read-only (get-learning-path (user principal) (path-id uint))
  (map-get? learning-paths { user: user, path-id: path-id })
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-profiles: (var-get total-profiles),
    next-skill-id: (var-get next-skill-id),
    next-gap-id: (var-get next-gap-id),
    next-recommendation-id: (var-get next-recommendation-id),
    next-path-id: (var-get next-path-id),
    contract-active: (var-get contract-active)
  }
)

;; Admin functions

;; Toggle contract status (owner only)
(define-public (toggle-contract-status)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set contract-active (not (var-get contract-active)))
    (ok (var-get contract-active))
  )
)

;; Emergency pause function (owner only)
(define-public (emergency-pause)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set contract-active false)
    (ok "Contract paused for maintenance")
  )
)
