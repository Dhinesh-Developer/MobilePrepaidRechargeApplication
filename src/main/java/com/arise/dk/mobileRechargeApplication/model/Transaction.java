package com.arise.dk.mobileRechargeApplication.model;


import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.ToString;
import java.time.LocalDateTime;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import com.fasterxml.jackson.annotation.JsonProperty;

@Entity
@Table(name = "Transactions")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString(exclude = {"plan", "user"})
public class Transaction {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long transactionId;
    
    @ManyToOne
    @JoinColumn(name = "plan_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private Plan plan;
    
    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    @OnDelete(action = OnDeleteAction.CASCADE)
    private User user;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TransactionMode transactionMode;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TransactionStatus transactionStatus = TransactionStatus.PENDING;
    
    @Column(nullable = false, updatable = false)
    private LocalDateTime transactionDate = LocalDateTime.now();
    
    public enum TransactionMode {
        @JsonProperty("upi")
        upi, 
        
        @JsonProperty("credit_debit_card")
        credit_debit_card, 
        
        @JsonProperty("empty")
        empty
    }
    
    public enum TransactionStatus {
    	@JsonProperty("success")
        SUCCESS,
        
        @JsonProperty("pending")
    	PENDING, 
    	
    	@JsonProperty("failure")
    	FAILURE
    }
}