package com.arise.dk.mobileRechargeApplication.controller;

import com.arise.dk.mobileRechargeApplication.exception.ResourceNotFoundException;
import com.arise.dk.mobileRechargeApplication.model.UserCurrentPlanDetails;
import com.arise.dk.mobileRechargeApplication.service.UserCurrentPlanService;

import java.util.List;
import java.util.Optional;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "http://127.0.0.1:5500")
public class UserCurrentPlanController {

    private final UserCurrentPlanService userCurrentPlanService;

    public UserCurrentPlanController(UserCurrentPlanService userCurrentPlanService) {
        this.userCurrentPlanService = userCurrentPlanService;
    }
    
    @PreAuthorize("hasAuthority('ADMIN')")
    @GetMapping("/admin/currentPlan/expiring/{name}")
    public ResponseEntity<?> getExpiringUsers(@PathVariable String name) {
        List<UserCurrentPlanDetails> users = userCurrentPlanService.getUsersWithExpiringPlans(name);
        if (users.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NO_CONTENT).body("No users with expiring plans found");
        }
        return ResponseEntity.ok(users);
    }

	@PreAuthorize("hasAuthority('CUSTOMER')")
    @PostMapping("/customer/currentPlan/saveOrUpdate")
    public ResponseEntity<?> saveOrUpdateUserPlan(@RequestBody UserCurrentPlanDetails userPlanDetails) {
        UserCurrentPlanDetails savedPlan = userCurrentPlanService.saveOrUpdateUserPlan(userPlanDetails);
        return ResponseEntity.status(HttpStatus.CREATED).body(savedPlan);
    }

	@PreAuthorize("hasAuthority('CUSTOMER') or hasAuthority('ADMIN')")
    @GetMapping("/both/currentPlan/{userId}")
    public ResponseEntity<?> getUserCurrentPlan(@PathVariable Long userId) {
        Optional<UserCurrentPlanDetails> userPlan = userCurrentPlanService.getUserCurrentPlan(userId);
        return userPlan.map(ResponseEntity::ok)
                .orElseThrow(() -> new ResourceNotFoundException("User plan not found for ID: " + userId));
    }
}
