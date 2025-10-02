;; Job Matcher Smart Contract
;; Recommends job opportunities based on user profiles and calculates compatibility scores

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u200))
(define-constant ERR_INVALID_JOB (err u201))
(define-constant ERR_JOB_NOT_FOUND (err u202))
(define-constant ERR_APPLICATION_NOT_FOUND (err u203))
(define-constant ERR_INVALID_SALARY (err u204))
(define-constant ERR_INVALID_SCORE (err u205))
(define-constant ERR_DUPLICATE_APPLICATION (err u206))

;; Data structures
(define-map job-listings
  uint
  {
    employer: principal,
    title: (string-ascii 64),
    company: (string-ascii 64),
    description: (string-ascii 256),
    required-skills: (list 10 (string-ascii 64)),
    experience-level: uint, ;; 1-5 scale (entry to senior)
    salary-min: uint,
    salary-max: uint,
    location: (string-ascii 64),
    remote-ok: bool,
    job-type: (string-ascii 32), ;; "full-time", "part-time", "contract", "internship"
    posted-at: uint,
    expires-at: uint,
    status: (string-ascii 16), ;; "active", "closed", "filled"
    applications-count: uint
  }
)

(define-map user-preferences
  principal
  {
    preferred-roles: (list 5 (string-ascii 64)),
    preferred-location: (string-ascii 64),
    remote-preference: bool,
    salary-expectation-min: uint,
    salary-expectation-max: uint,
    job-type-preference: (string-ascii 32),
    experience-level: uint,
    skills-priority: (list 10 (string-ascii 64)),
    last-updated: uint
  }
)

(define-map job-applications
  { user: principal, job-id: uint }
  {
    applied-at: uint,
    status: (string-ascii 16), ;; "submitted", "reviewing", "interviewed", "rejected", "accepted"
    compatibility-score: uint, ;; 0-100 percentage
    cover-letter: (string-ascii 512),
    interview-scheduled: bool,
    feedback: (string-ascii 256)
  }
)

(define-map compatibility-scores
  { user: principal, job-id: uint }
  {
    overall-score: uint, ;; 0-100 percentage
    skills-match: uint,
    experience-match: uint,
    salary-match: uint,
    location-match: uint,
    calculated-at: uint
  }
)

(define-map employer-profiles
  principal
  {
    company-name: (string-ascii 64),
    industry: (string-ascii 64),
    company-size: uint,
    location: (string-ascii 64),
    website: (string-ascii 128),
    verified: bool,
    jobs-posted: uint,
    created-at: uint
  }
)

;; Data variables
(define-data-var next-job-id uint u1)
(define-data-var total-jobs uint u0)
(define-data-var total-applications uint u0)
(define-data-var total-employers uint u0)
(define-data-var contract-active bool true)
(define-data-var platform-fee uint u0) ;; Future feature

;; Public functions

;; Create employer profile
(define-public (create-employer-profile (company-name (string-ascii 64)) (industry (string-ascii 64))
                                       (company-size uint) (location (string-ascii 64))
                                       (website (string-ascii 128)))
  (let ((employer-exists (is-some (map-get? employer-profiles tx-sender))))
    (asserts! (not employer-exists) ERR_INVALID_JOB)
    (asserts! (> (len company-name) u0) ERR_INVALID_JOB)
    (map-set employer-profiles tx-sender {
      company-name: company-name,
      industry: industry,
      company-size: company-size,
      location: location,
      website: website,
      verified: false,
      jobs-posted: u0,
      created-at: burn-block-height
    })
    (var-set total-employers (+ (var-get total-employers) u1))
    (ok "Employer profile created")
  )
)

;; Post job listing
(define-public (post-job (title (string-ascii 64)) (description (string-ascii 256))
                        (required-skills (list 10 (string-ascii 64))) (experience-level uint)
                        (salary-min uint) (salary-max uint) (location (string-ascii 64))
                        (remote-ok bool) (job-type (string-ascii 32)) (expires-in-days uint))
  (let ((job-id (var-get next-job-id))
        (employer-profile (unwrap! (map-get? employer-profiles tx-sender) ERR_NOT_AUTHORIZED)))
    (asserts! (> (len title) u0) ERR_INVALID_JOB)
    (asserts! (and (>= experience-level u1) (<= experience-level u5)) ERR_INVALID_JOB)
    (asserts! (< salary-min salary-max) ERR_INVALID_SALARY)
    (asserts! (> expires-in-days u0) ERR_INVALID_JOB)
    (map-set job-listings job-id {
      employer: tx-sender,
      title: title,
      company: (get company-name employer-profile),
      description: description,
      required-skills: required-skills,
      experience-level: experience-level,
      salary-min: salary-min,
      salary-max: salary-max,
      location: location,
      remote-ok: remote-ok,
      job-type: job-type,
      posted-at: burn-block-height,
      expires-at: (+ burn-block-height (* expires-in-days u144)), ;; Approximate blocks per day
      status: "active",
      applications-count: u0
    })
    (map-set employer-profiles tx-sender {
      company-name: (get company-name employer-profile),
      industry: (get industry employer-profile),
      company-size: (get company-size employer-profile),
      location: (get location employer-profile),
      website: (get website employer-profile),
      verified: (get verified employer-profile),
      jobs-posted: (+ (get jobs-posted employer-profile) u1),
      created-at: (get created-at employer-profile)
    })
    (var-set next-job-id (+ job-id u1))
    (var-set total-jobs (+ (var-get total-jobs) u1))
    (ok job-id)
  )
)

;; Set user job preferences
(define-public (set-preferences (preferred-roles (list 5 (string-ascii 64)))
                               (preferred-location (string-ascii 64)) (remote-preference bool)
                               (salary-min uint) (salary-max uint) (job-type (string-ascii 32))
                               (experience-level uint) (skills-priority (list 10 (string-ascii 64))))
  (begin
    (asserts! (< salary-min salary-max) ERR_INVALID_SALARY)
    (asserts! (and (>= experience-level u1) (<= experience-level u5)) ERR_INVALID_JOB)
    (map-set user-preferences tx-sender {
      preferred-roles: preferred-roles,
      preferred-location: preferred-location,
      remote-preference: remote-preference,
      salary-expectation-min: salary-min,
      salary-expectation-max: salary-max,
      job-type-preference: job-type,
      experience-level: experience-level,
      skills-priority: skills-priority,
      last-updated: burn-block-height
    })
    (ok "Preferences updated")
  )
)

;; Calculate compatibility score
(define-public (calculate-compatibility-score (job-id uint) (user principal))
  (let ((job (unwrap! (map-get? job-listings job-id) ERR_JOB_NOT_FOUND))
        (preferences (map-get? user-preferences user)))
    (let ((skills-match (calculate-skills-match (get required-skills job) user))
          (experience-match (calculate-experience-match (get experience-level job) user))
          (salary-match (calculate-salary-match job preferences))
          (location-match (calculate-location-match job preferences)))
      (let ((overall-score (/ (+ skills-match experience-match salary-match location-match) u4)))
        (map-set compatibility-scores { user: user, job-id: job-id } {
          overall-score: overall-score,
          skills-match: skills-match,
          experience-match: experience-match,
          salary-match: salary-match,
          location-match: location-match,
          calculated-at: burn-block-height
        })
        (ok overall-score)
      )
    )
  )
)

;; Apply for job
(define-public (apply-for-job (job-id uint) (cover-letter (string-ascii 512)))
  (let ((job (unwrap! (map-get? job-listings job-id) ERR_JOB_NOT_FOUND))
        (existing-application (map-get? job-applications { user: tx-sender, job-id: job-id })))
    (asserts! (is-none existing-application) ERR_DUPLICATE_APPLICATION)
    (asserts! (is-eq (get status job) "active") ERR_JOB_NOT_FOUND)
    (asserts! (< burn-block-height (get expires-at job)) ERR_JOB_NOT_FOUND)
    (unwrap! (calculate-compatibility-score job-id tx-sender) ERR_INVALID_SCORE)
    (let ((score-data (unwrap! (map-get? compatibility-scores { user: tx-sender, job-id: job-id }) ERR_INVALID_SCORE)))
      (map-set job-applications { user: tx-sender, job-id: job-id } {
        applied-at: burn-block-height,
        status: "submitted",
        compatibility-score: (get overall-score score-data),
        cover-letter: cover-letter,
        interview-scheduled: false,
        feedback: ""
      })
      (map-set job-listings job-id {
        employer: (get employer job),
        title: (get title job),
        company: (get company job),
        description: (get description job),
        required-skills: (get required-skills job),
        experience-level: (get experience-level job),
        salary-min: (get salary-min job),
        salary-max: (get salary-max job),
        location: (get location job),
        remote-ok: (get remote-ok job),
        job-type: (get job-type job),
        posted-at: (get posted-at job),
        expires-at: (get expires-at job),
        status: (get status job),
        applications-count: (+ (get applications-count job) u1)
      })
      (var-set total-applications (+ (var-get total-applications) u1))
      (ok "Application submitted")
    )
  )
)

;; Update application status (employer only)
(define-public (update-application-status (user principal) (job-id uint) 
                                         (new-status (string-ascii 16)) (feedback (string-ascii 256)))
  (let ((job (unwrap! (map-get? job-listings job-id) ERR_JOB_NOT_FOUND))
        (application (unwrap! (map-get? job-applications { user: user, job-id: job-id }) ERR_APPLICATION_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get employer job)) ERR_NOT_AUTHORIZED)
    (map-set job-applications { user: user, job-id: job-id } {
      applied-at: (get applied-at application),
      status: new-status,
      compatibility-score: (get compatibility-score application),
      cover-letter: (get cover-letter application),
      interview-scheduled: (if (is-eq new-status "interviewed") true (get interview-scheduled application)),
      feedback: feedback
    })
    (ok "Application status updated")
  )
)

;; Close job listing (employer only)
(define-public (close-job (job-id uint))
  (let ((job (unwrap! (map-get? job-listings job-id) ERR_JOB_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get employer job)) ERR_NOT_AUTHORIZED)
    (map-set job-listings job-id {
      employer: (get employer job),
      title: (get title job),
      company: (get company job),
      description: (get description job),
      required-skills: (get required-skills job),
      experience-level: (get experience-level job),
      salary-min: (get salary-min job),
      salary-max: (get salary-max job),
      location: (get location job),
      remote-ok: (get remote-ok job),
      job-type: (get job-type job),
      posted-at: (get posted-at job),
      expires-at: (get expires-at job),
      status: "closed",
      applications-count: (get applications-count job)
    })
    (ok "Job listing closed")
  )
)

;; Private functions for scoring calculations
(define-private (calculate-skills-match (required-skills (list 10 (string-ascii 64))) (user principal))
  ;; Simplified scoring - in real implementation would check against user skills
  u75
)

(define-private (calculate-experience-match (required-level uint) (user principal))
  ;; Simplified scoring - in real implementation would compare against user experience
  u80
)

(define-private (calculate-salary-match (job { employer: principal, title: (string-ascii 64), 
                                             company: (string-ascii 64), description: (string-ascii 256),
                                             required-skills: (list 10 (string-ascii 64)), experience-level: uint,
                                             salary-min: uint, salary-max: uint, location: (string-ascii 64),
                                             remote-ok: bool, job-type: (string-ascii 32), posted-at: uint,
                                             expires-at: uint, status: (string-ascii 16), applications-count: uint })
                                       (preferences (optional { preferred-roles: (list 5 (string-ascii 64)),
                                                              preferred-location: (string-ascii 64), remote-preference: bool,
                                                              salary-expectation-min: uint, salary-expectation-max: uint,
                                                              job-type-preference: (string-ascii 32), experience-level: uint,
                                                              skills-priority: (list 10 (string-ascii 64)), last-updated: uint })))
  (match preferences
    some-prefs (if (and (>= (get salary-max job) (get salary-expectation-min some-prefs))
                       (<= (get salary-min job) (get salary-expectation-max some-prefs)))
                  u90
                  u40)
    u70
  )
)

(define-private (calculate-location-match (job { employer: principal, title: (string-ascii 64), 
                                               company: (string-ascii 64), description: (string-ascii 256),
                                               required-skills: (list 10 (string-ascii 64)), experience-level: uint,
                                               salary-min: uint, salary-max: uint, location: (string-ascii 64),
                                               remote-ok: bool, job-type: (string-ascii 32), posted-at: uint,
                                               expires-at: uint, status: (string-ascii 16), applications-count: uint })
                                         (preferences (optional { preferred-roles: (list 5 (string-ascii 64)),
                                                                preferred-location: (string-ascii 64), remote-preference: bool,
                                                                salary-expectation-min: uint, salary-expectation-max: uint,
                                                                job-type-preference: (string-ascii 32), experience-level: uint,
                                                                skills-priority: (list 10 (string-ascii 64)), last-updated: uint })))
  (match preferences
    some-prefs (if (or (get remote-ok job) 
                      (is-eq (get location job) (get preferred-location some-prefs)))
                  u95
                  u50)
    u70
  )
)

;; Read-only functions

;; Get job listing
(define-read-only (get-job (job-id uint))
  (map-get? job-listings job-id)
)

;; Get user preferences
(define-read-only (get-user-preferences (user principal))
  (map-get? user-preferences user)
)

;; Get application details
(define-read-only (get-application (user principal) (job-id uint))
  (map-get? job-applications { user: user, job-id: job-id })
)

;; Get compatibility score
(define-read-only (get-compatibility-score (user principal) (job-id uint))
  (map-get? compatibility-scores { user: user, job-id: job-id })
)

;; Get employer profile
(define-read-only (get-employer-profile (employer principal))
  (map-get? employer-profiles employer)
)

;; Get platform statistics
(define-read-only (get-platform-stats)
  {
    total-jobs: (var-get total-jobs),
    total-applications: (var-get total-applications),
    total-employers: (var-get total-employers),
    next-job-id: (var-get next-job-id),
    contract-active: (var-get contract-active)
  }
)

;; Admin functions

;; Verify employer (admin only)
(define-public (verify-employer (employer principal))
  (let ((employer-profile (unwrap! (map-get? employer-profiles employer) ERR_NOT_AUTHORIZED)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (map-set employer-profiles employer {
      company-name: (get company-name employer-profile),
      industry: (get industry employer-profile),
      company-size: (get company-size employer-profile),
      location: (get location employer-profile),
      website: (get website employer-profile),
      verified: true,
      jobs-posted: (get jobs-posted employer-profile),
      created-at: (get created-at employer-profile)
    })
    (ok "Employer verified")
  )
)

;; Toggle contract status (admin only)
(define-public (toggle-contract-status)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set contract-active (not (var-get contract-active)))
    (ok (var-get contract-active))
  )
)
