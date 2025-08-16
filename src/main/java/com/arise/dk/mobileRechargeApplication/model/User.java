package com.arise.dk.mobileRechargeApplication.model;


import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import lombok.ToString;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "Users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString(exclude = "role")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long userId;
    
    @Column(nullable = false, length = 50)
    private String userFname;
    
    @Column(nullable = false, length = 50)
    private String userLname;
    
    @Column(nullable = false, unique = true, length = 100)
    private String userEmail;
    
    @Column(nullable = false, unique = true, length = 15)
    private String userPhonenumber;
    
    @Column(length = 15)
    private String userAlternatePhonenumber;
    
    private LocalDate userDateOfBirth;
    
    @Column(length = 255)
    private String userAddress;
    
    @Column(length = 20)
    private String userDistrict;
    
    @Column(length = 30)
    private String userState;
    
    @Column(length = 6)
    private String userPincode;
    
    @Column(nullable = true)
    private String username;
    
    @Column(nullable = true)
    private String password;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AccountStatus userAccountStatus = AccountStatus.ACTIVE;
    
    @Column(nullable = false, updatable = false)
    private LocalDateTime userAccountCreationDate = LocalDateTime.now();
    
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "role_id", nullable = false)
    private Role role;
    
    @Lob
    @Column(columnDefinition = "LONGBLOB")
    private byte[] userImage; 
    
    public enum AccountStatus {
        ACTIVE, INACTIVE
    }
}