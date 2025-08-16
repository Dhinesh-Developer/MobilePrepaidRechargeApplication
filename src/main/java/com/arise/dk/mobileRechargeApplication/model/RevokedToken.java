package com.arise.dk.mobileRechargeApplication.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.*;

import java.util.Date;

@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RevokedToken {
    @Id
    private String token;
    private Date revokedAt;

    public RevokedToken(String token) {
        this.token = token;
        this.revokedAt = new Date();
    }
}
