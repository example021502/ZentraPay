package com.zentrapay.backend.service.loan;

import com.zentrapay.backend.dto.loan.LoanDTOs.*;
import com.zentrapay.backend.entity.LoanModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.entity.UserProfileModel;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.LoanRepository;
import com.zentrapay.backend.repository.UserProfileRepository;
import com.zentrapay.backend.repository.UserRepository;
import com.zentrapay.backend.service.common.Datatypes;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Micro-loans: who may borrow, how much, and the application itself.
 *
 * <p>The rules follow the usual digital-lending practice:
 * <ul>
 *   <li><b>KYC level gates access.</b> Only a fully verified user (Level 2: ID
 *       document, selfie, address and occupation on file) can borrow. Levels 0
 *       and 1 are told exactly what is still missing.</li>
 *   <li><b>Risk grade sets the terms.</b> Grade A (low risk) gets a higher limit,
 *       a longer term and a lower rate than Grade B (medium / unrated). High-risk
 *       users, and anyone flagged or under review by compliance, are declined.</li>
 *   <li><b>One open loan at a time</b> - and none while a loan is overdue.</li>
 *   <li><b>Affordability.</b> Existing monthly obligations plus the new
 *       instalment may not exceed {@value #MAX_DEBT_TO_INCOME_PERCENT}% of the
 *       stated monthly income.</li>
 *   <li><b>Consent.</b> The credit check and the terms must be accepted.</li>
 * </ul>
 * A successful application is stored as PENDING for review; nothing is paid out
 * from here.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class LoanService {

    private static final String CURRENCY = "GHS";
    private static final BigDecimal MIN_AMOUNT = new BigDecimal("50");
    private static final int MAX_DEBT_TO_INCOME_PERCENT = 40;

    // Grade A: low risk. Grade B: medium risk or unrated.
    private static final BigDecimal GRADE_A_MAX = new BigDecimal("5000");
    private static final int GRADE_A_MAX_TERM = 12;
    private static final BigDecimal GRADE_A_RATE = new BigDecimal("0.1200");
    private static final BigDecimal GRADE_B_MAX = new BigDecimal("2000");
    private static final int GRADE_B_MAX_TERM = 6;
    private static final BigDecimal GRADE_B_RATE = new BigDecimal("0.1800");

    private static final Set<String> OPEN_STATUSES = Set.of("PENDING", "APPROVED", "ACTIVE");
    private static final Set<String> PURPOSES =
            Set.of("BUSINESS", "EDUCATION", "MEDICAL", "RENT", "EMERGENCY", "PERSONAL", "OTHER");
    private static final Set<String> EMPLOYMENT_STATUSES =
            Set.of("EMPLOYED", "SELF_EMPLOYED", "STUDENT", "RETIRED", "UNEMPLOYED");
    private static final Set<String> NEEDS_EMPLOYER = Set.of("EMPLOYED", "SELF_EMPLOYED");

    private final LoanRepository loanRepository;
    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;

    /** The user's loans and applications, newest first. */
    @Transactional(readOnly = true)
    public List<LoanDTO> myLoans(UUID userId) {
        return loanRepository.findByUserIdOrderByAppliedAtDesc(userId).stream()
                .map(LoanService::toDTO)
                .toList();
    }

    /** What the user may borrow right now, or exactly what stands in the way. */
    @Transactional(readOnly = true)
    public LoanEligibilityDTO eligibility(UUID userId) {
        return evaluate(loadUser(userId), userProfileRepository.getBtUserId(userId),
                loanRepository.findByUserIdOrderByAppliedAtDesc(userId));
    }

    @Transactional
    public LoanDTO apply(UUID userId, LoanApplicationRequestDTO request) {
        log.info("Loan application from user {}", userId);
        UserModel user = loadUser(userId);
        LoanEligibilityDTO eligibility = evaluate(user, userProfileRepository.getBtUserId(userId),
                loanRepository.findByUserIdOrderByAppliedAtDesc(userId));
        if (!eligibility.eligible()) {
            throw new IllegalArgumentException(eligibility.requirements().get(0));
        }

        validate(request, eligibility);

        BigDecimal amount = request.amount().setScale(2, RoundingMode.HALF_UP);
        int term = request.termMonths();
        BigDecimal totalRepayable = totalRepayable(amount, eligibility.interestRate(), term);
        BigDecimal installment = totalRepayable.divide(BigDecimal.valueOf(term), 2, RoundingMode.HALF_UP);

        BigDecimal income = request.monthlyIncome();
        BigDecimal obligations = request.monthlyObligations() == null ? BigDecimal.ZERO : request.monthlyObligations();
        BigDecimal affordable = income.multiply(BigDecimal.valueOf(MAX_DEBT_TO_INCOME_PERCENT))
                .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        if (obligations.add(installment).compareTo(affordable) > 0) {
            throw new IllegalArgumentException(
                    "This amount is more than your income can comfortably repay. "
                            + "Try a smaller amount or a longer term.");
        }

        LoanModel loan = new LoanModel();
        loan.setUserId(userId);
        loan.setCurrencyCode(CURRENCY);
        loan.setPrincipalAmount(amount);
        loan.setInterestRate(eligibility.interestRate());
        loan.setTermMonths((short) term);
        loan.setOutstandingBalance(totalRepayable);
        loan.setStatus("PENDING");
        loan.setPurpose(request.purpose().trim().toUpperCase());
        loan.setEmploymentStatus(request.employmentStatus().trim().toUpperCase());
        loan.setEmployerName(clean(request.employerName()));
        loan.setJobTitle(clean(request.jobTitle()));
        loan.setMonthlyIncome(income);
        loan.setMonthlyObligations(obligations);
        loan.setNextOfKinName(clean(request.nextOfKinName()));
        loan.setNextOfKinRelationship(clean(request.nextOfKinRelationship()));
        loan.setNextOfKinPhone(clean(request.nextOfKinPhone()));
        loan.setCreditCheckConsent(true);
        loan.setTermsAccepted(true);
        loan.setRiskGrade(eligibility.grade());
        loan.setDecisionNote("Submitted for review");
        return toDTO(loanRepository.save(loan));
    }

    // ------------------------------------------------------------------ rules

    private LoanEligibilityDTO evaluate(UserModel user, UserProfileModel profile, List<LoanModel> loans) {
        List<String> blockers = new ArrayList<>();
        int tier = user.getKycTier();

        if (user.getStatus() != Datatypes.UserStatus.ACTIVE) {
            blockers.add("Your account must be active to apply for a loan.");
        }
        if (tier < 2) {
            blockers.add(tier == 0
                    ? "Verify your identity (KYC Level 2) to unlock loans. Add your ID, address and a selfie in your profile."
                    : "Finish your identity verification (KYC Level 2) to unlock loans. Upload the remaining documents in your profile.");
        }
        if (profile != null) {
            String kycStatus = lower(profile.getKYCStatus());
            if (kycStatus.equals("rejected") || kycStatus.equals("expired")) {
                blockers.add("Your identity verification needs to be updated before you can borrow.");
            }
            String aml = lower(profile.getAntiMoneyLaunderingStatus());
            if (aml.equals("flagged") || aml.equals("pending_review")) {
                blockers.add("Your account is under review. Please contact support.");
            }
            if (lower(profile.getRiskScoreLevel()).equals("high")) {
                blockers.add("We can't offer you a loan right now.");
            }
        }
        for (LoanModel loan : loans) {
            if (loan.getStatus().equals("DEFAULTED")) {
                blockers.add("Please clear your overdue loan before applying for another.");
                break;
            }
            if (OPEN_STATUSES.contains(loan.getStatus())) {
                blockers.add("You already have a loan that is still open.");
                break;
            }
        }

        boolean gradeA = profile != null && lower(profile.getRiskScoreLevel()).equals("low");
        boolean eligible = blockers.isEmpty();
        return new LoanEligibilityDTO(
                eligible,
                tier,
                eligible ? (gradeA ? "A" : "B") : null,
                CURRENCY,
                MIN_AMOUNT,
                gradeA ? GRADE_A_MAX : GRADE_B_MAX,
                gradeA ? GRADE_A_MAX_TERM : GRADE_B_MAX_TERM,
                gradeA ? GRADE_A_RATE : GRADE_B_RATE,
                blockers);
    }

    private void validate(LoanApplicationRequestDTO r, LoanEligibilityDTO limits) {
        if (r.amount() == null || r.amount().compareTo(limits.minAmount()) < 0) {
            throw new IllegalArgumentException("The smallest loan is " + CURRENCY + " " + limits.minAmount().toPlainString() + ".");
        }
        if (r.amount().compareTo(limits.maxAmount()) > 0) {
            throw new IllegalArgumentException("You can borrow up to " + CURRENCY + " " + limits.maxAmount().toPlainString() + " right now.");
        }
        if (r.currencyCode() != null && !r.currencyCode().isBlank() && !CURRENCY.equalsIgnoreCase(r.currencyCode().trim())) {
            throw new IllegalArgumentException("Loans are only available in " + CURRENCY + " at the moment.");
        }
        if (r.termMonths() == null || r.termMonths() < 1 || r.termMonths() > limits.maxTermMonths()) {
            throw new IllegalArgumentException("Choose a repayment period of 1 to " + limits.maxTermMonths() + " months.");
        }
        if (r.purpose() == null || !PURPOSES.contains(r.purpose().trim().toUpperCase())) {
            throw new IllegalArgumentException("Tell us what the loan is for.");
        }
        String employment = r.employmentStatus() == null ? "" : r.employmentStatus().trim().toUpperCase();
        if (!EMPLOYMENT_STATUSES.contains(employment)) {
            throw new IllegalArgumentException("Select your employment status.");
        }
        if (NEEDS_EMPLOYER.contains(employment) && clean(r.employerName()) == null) {
            throw new IllegalArgumentException(employment.equals("EMPLOYED")
                    ? "Enter your employer's name." : "Enter your business name.");
        }
        if (r.monthlyIncome() == null || r.monthlyIncome().signum() <= 0) {
            throw new IllegalArgumentException("Enter the income you receive each month. A regular income is needed to repay a loan.");
        }
        if (r.monthlyObligations() != null && r.monthlyObligations().signum() < 0) {
            throw new IllegalArgumentException("Monthly commitments can't be negative.");
        }
        if (clean(r.nextOfKinName()) == null || clean(r.nextOfKinRelationship()) == null) {
            throw new IllegalArgumentException("Add a next of kin we can contact.");
        }
        String phone = r.nextOfKinPhone() == null ? "" : r.nextOfKinPhone().replaceAll("[^0-9]", "");
        if (phone.length() < 7 || phone.length() > 15) {
            throw new IllegalArgumentException("Enter a valid phone number for your next of kin.");
        }
        if (!Boolean.TRUE.equals(r.creditCheckConsent())) {
            throw new IllegalArgumentException("You need to agree to the credit check to continue.");
        }
        if (!Boolean.TRUE.equals(r.termsAccepted())) {
            throw new IllegalArgumentException("You need to accept the loan terms to continue.");
        }
    }

    // --------------------------------------------------------------- helpers

    /** Principal plus simple interest for the term, e.g. 1000 at 12% for 6 months = 1060. */
    private static BigDecimal totalRepayable(BigDecimal principal, BigDecimal annualRate, int termMonths) {
        BigDecimal interest = principal.multiply(annualRate)
                .multiply(BigDecimal.valueOf(termMonths))
                .divide(BigDecimal.valueOf(12), 2, RoundingMode.HALF_UP);
        return principal.add(interest).setScale(2, RoundingMode.HALF_UP);
    }

    private UserModel loadUser(UUID userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private static String clean(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private static String lower(String value) {
        return value == null ? "" : value.trim().toLowerCase();
    }

    private static LoanDTO toDTO(LoanModel l) {
        BigDecimal installment = l.getTermMonths() > 0
                ? totalRepayable(l.getPrincipalAmount(), l.getInterestRate(), l.getTermMonths())
                        .divide(BigDecimal.valueOf(l.getTermMonths()), 2, RoundingMode.HALF_UP)
                : null;
        return new LoanDTO(l.getLoanId(), l.getCurrencyCode(), l.getPrincipalAmount(), l.getInterestRate(),
                (int) l.getTermMonths(), l.getOutstandingBalance(), installment, l.getStatus(), l.getPurpose(),
                l.getDueDate(), l.getAppliedAt(), l.getDecisionNote());
    }
}
