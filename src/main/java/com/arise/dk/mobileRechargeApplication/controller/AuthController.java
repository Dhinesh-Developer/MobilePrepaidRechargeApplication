package com.arise.dk.mobileRechargeApplication.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import com.arise.dk.mobileRechargeApplication.model.RevokedToken;
import com.arise.dk.mobileRechargeApplication.model.User;
import com.arise.dk.mobileRechargeApplication.repository.RevokedTokenRepository;
import com.arise.dk.mobileRechargeApplication.repository.UserRepository;
import com.arise.dk.mobileRechargeApplication.security.JwtUtil;

import jakarta.annotation.security.PermitAll;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/auth")
@CrossOrigin(origins = "http://127.0.0.1:5500")
public class AuthController {

    private JwtUtil jwtUtil;
    private UserRepository userRepository;
    private RevokedTokenRepository revokedTokenRepository;
    private PasswordEncoder passwordEncoder;

    @Autowired
    public void setJwtUtil(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    @Autowired
    public void setUserRepository(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Autowired
    public void setRevokedTokenRepository(RevokedTokenRepository revokedTokenRepository) {
        this.revokedTokenRepository = revokedTokenRepository;
    }

    @Autowired
    public void setPasswordEncoder(PasswordEncoder passwordEncoder) {
        this.passwordEncoder = passwordEncoder;
    }

    @PermitAll
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> credentials) {
        String identifier = credentials.get("username");
        String password = credentials.get("password");

        Optional<User> userOptional;

        if (identifier.matches("\\d+")) { 
            userOptional = userRepository.findByUserPhonenumber(identifier);
            if (userOptional.isPresent()) {
            User user = userOptional.get();
            return ResponseEntity.ok(Map.of(
                    "accessToken", jwtUtil.generateToken(identifier, user.getRole().getRoleName().name()),
                    "refreshToken", jwtUtil.generateRefreshToken(identifier)
            ));
            }
        } else {
            userOptional = userRepository.findByUsername(identifier);
        }

        if (userOptional.isPresent() && passwordEncoder.matches(password, userOptional.get().getPassword())) {
            User user = userOptional.get();
            return ResponseEntity.ok(Map.of(
                    "accessToken", jwtUtil.generateToken(identifier, user.getRole().getRoleName().name()),
                    "refreshToken", jwtUtil.generateRefreshToken(identifier)
            ));
        }

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid credentials");
    }

    @PermitAll
    @PostMapping("/logout")
    public ResponseEntity<String> logout(@RequestHeader("Authorization") String token,
                                         @RequestBody Map<String, String> request) {
        token = token.substring(7); 

        revokedTokenRepository.save(new RevokedToken(token));

        String refreshToken = request.get("refreshToken");
        if (refreshToken != null) {
            revokedTokenRepository.save(new RevokedToken(refreshToken));
        }
        return ResponseEntity.status(HttpStatus.OK).body("Logged out successfully");
    }


    @PermitAll
    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(@RequestBody Map<String, String> request) {
        String refreshToken = request.get("refreshToken");

        if (refreshToken == null || jwtUtil.isTokenExpired(refreshToken)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid or expired refresh token.");
        }
        

        String identifier = jwtUtil.getUsernameFromToken(refreshToken);
        String role ="";
        Optional<User> userOptional;
        if (identifier.matches("\\d+")) { // If identifier is numeric, assume it's a phone number
            userOptional = userRepository.findByUserPhonenumber(identifier);
            if (userOptional.isPresent()) {
                User user = userOptional.get();
                role= user.getRole().getRoleName().name();
            }
        } else {
            userOptional = userRepository.findByUsername(identifier);
            if (userOptional.isPresent()) {
                User user = userOptional.get();
                role = user.getRole().getRoleName().name();
            }
        }

        return ResponseEntity.ok(Map.of("accessToken", jwtUtil.generateToken(identifier, role)));
    }
}

