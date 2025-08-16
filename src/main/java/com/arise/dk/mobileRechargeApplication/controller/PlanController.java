package com.arise.dk.mobileRechargeApplication.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.arise.dk.mobileRechargeApplication.exception.ResourceNotFoundException;
import com.arise.dk.mobileRechargeApplication.model.Plan;
import com.arise.dk.mobileRechargeApplication.service.PlanService;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "http://127.0.0.1:5500") 
public class PlanController {

    private final PlanService planService;

    public PlanController(PlanService planService) {
        this.planService = planService;
    }

	@PreAuthorize("hasAuthority('CUSTOMER') or hasAuthority('ADMIN')")
    @GetMapping("/both/plans/{planId}")
    public ResponseEntity<Plan> getPlanById(@PathVariable Long planId) {
        Plan plan = planService.getPlanById(planId)
                .orElseThrow(() -> new ResourceNotFoundException("Plan with ID " + planId + " not found"));
        return ResponseEntity.ok(plan);
    }

	@PreAuthorize("hasAuthority('CUSTOMER') or hasAuthority('ADMIN')")
    @GetMapping("/both/plans/category/{categoryName}")
    public ResponseEntity<List<Plan>> getPlansByCategory(@PathVariable String categoryName) {
        List<Plan> plans = planService.getPlansByCategory(categoryName);
        if (plans.isEmpty()) {
            throw new ResourceNotFoundException("No plans found for category: " + categoryName);
        }
        return ResponseEntity.ok(plans);
    }

	@PreAuthorize("hasAuthority('ADMIN')")
    @PostMapping("/admin/plans/add/category/{categoryName}")
    public ResponseEntity<Plan> addPlan(@PathVariable String categoryName, @RequestBody Plan plan) {
        return ResponseEntity.ok(planService.addPlan(categoryName, plan));
    }

	@PreAuthorize("hasAuthority('ADMIN')")
    @PutMapping("/admin/plans/update/{category}/{planId}")
    public ResponseEntity<Plan> updatePlan(@PathVariable Long planId, @PathVariable String category, @RequestBody Plan plan) {
        return ResponseEntity.ok(planService.updatePlan(planId, category, plan));
    }

	@PreAuthorize("hasAuthority('ADMIN')")
    @DeleteMapping("/admin/plans/delete/{planId}")
    public ResponseEntity<String> deletePlan(@PathVariable Long planId) {
        planService.deletePlan(planId);
        return ResponseEntity.ok("Plan deleted successfully");
    }
	 
	@PreAuthorize("hasAuthority('ADMIN')")
	@DeleteMapping("/admin/deleteByCategory/{categoryId}")
    public ResponseEntity<String> deletePlansByCategory(@PathVariable Long categoryId) {
        planService.deletePlanByCategoryId(categoryId);
        return ResponseEntity.ok("Plans deleted successfully for category ID: " + categoryId);
    }
}
