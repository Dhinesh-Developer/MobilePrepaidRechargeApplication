package com.arise.dk.mobileRechargeApplication.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import com.fasterxml.jackson.annotation.JsonBackReference;

@Entity
@Table(name = "Plans")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Plan {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long planId;
 
    @Column(nullable = false)
    private BigDecimal planPrice;
    
    @Column(precision = 5, scale = 2)
    private BigDecimal planDataPerDay;
    
    @Column(precision = 10, scale = 2)
    private BigDecimal planTalkTime;
    
    private Integer planOverallData;
    private Integer planValidityInDays;
    private String planVoiceValidity;
    private Integer planSmsValidity;
    
    @Column(length = 255)
    private String planOttOffers;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "plan_category_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE) 
    @JsonBackReference 
    private PlanCategory planCategory;
    
    @Column(nullable = false, updatable = false)
    private LocalDateTime planCreationDate = LocalDateTime.now();
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PlanStatus planStatus = PlanStatus.ACTIVE;
    
    @PrePersist
    public void calculateTalkTime() {
        if (this.planPrice != null) {
            this.planTalkTime = this.planPrice.subtract(new BigDecimal("2.340"));
        } else {
            this.planTalkTime = new BigDecimal("0.0");
        }
        
        if (this.planDataPerDay != null && this.planValidityInDays != null) {
            this.planOverallData = this.planDataPerDay.multiply(new BigDecimal(this.planValidityInDays)).intValue();
        }
    }
    
    public enum PlanStatus {
        ACTIVE, EXPIRED
    }
}