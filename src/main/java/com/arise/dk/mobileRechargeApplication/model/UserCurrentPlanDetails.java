package com.arise.dk.mobileRechargeApplication.model;


import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.ToString;
import java.math.BigDecimal;
import java.time.LocalDate;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

@Entity
@Table(name = "UserCurrentPlanDetails")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString(exclude = {"user", "plan", "transaction"})
public class UserCurrentPlanDetails {
    @Id
    private Long userId;
    
    @OneToOne
    @MapsId
    @JoinColumn(name = "user_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private User user;
    
    @ManyToOne
    @JoinColumn(name = "plan_id", nullable = false , unique=false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private Plan plan;
    
    @OneToOne
    @JoinColumn(name = "transaction_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private Transaction transaction;
    
    @Column
    private String username;
    
    @Column
    private String userEmail;
    
    @Column(length = 15)
    private String phoneNumber;
    
    @Column(nullable = false)
    private BigDecimal currentPlanPrice;
    
    @Column(nullable = false)
    private Integer validity;
    
    @Column(precision = 10, scale = 2)
    private BigDecimal data;
    
    @Column(length = 50)
    private String voice;
    
    private Integer sms;
    
    @Column(precision = 5, scale = 2)
    private BigDecimal dataUsage = BigDecimal.ZERO;
    
    @Column(nullable = false)
    private LocalDate planExpiryDate;
    
    @Column(nullable = false)
    private LocalDate rechargedDate;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PlanStatus planStatus = PlanStatus.active;
    
    public enum PlanStatus {
        active, expired
    }
    
    public int getPlanOverallData() {
        return this.data.multiply(BigDecimal.valueOf(this.validity)).intValue();
    }
    @PrePersist
    @PreUpdate
    private void populatePlanAndTransactionDetails() {
        if (user != null) {
            this.phoneNumber = user.getUserPhonenumber();
            this.userId = user.getUserId();
            this.username = user.getUserFname() + " " + user.getUserLname();
            this.userEmail = user.getUserEmail();
        }

        if (plan != null) {
            this.currentPlanPrice = plan.getPlanPrice();
            this.validity = plan.getPlanValidityInDays();
            this.data = plan.getPlanOverallData() != null ? BigDecimal.valueOf(plan.getPlanOverallData()) : BigDecimal.ZERO;
            this.voice = plan.getPlanVoiceValidity();
            this.sms = plan.getPlanSmsValidity();
        }

        if (transaction != null) {
            if (transaction.getTransactionStatus() == Transaction.TransactionStatus.SUCCESS) {
                this.rechargedDate = transaction.getTransactionDate().toLocalDate();
                this.planExpiryDate = this.rechargedDate.plusDays(this.validity != null ? this.validity : 0);
                this.planStatus = LocalDate.now().isAfter(this.planExpiryDate) ? PlanStatus.expired : PlanStatus.active;
            }
        }
    }

}