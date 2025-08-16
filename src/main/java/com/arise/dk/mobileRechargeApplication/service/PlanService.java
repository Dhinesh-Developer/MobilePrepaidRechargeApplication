package com.arise.dk.mobileRechargeApplication.service;

import com.arise.dk.mobileRechargeApplication.model.Plan;
import com.arise.dk.mobileRechargeApplication.model.PlanCategory;
import com.arise.dk.mobileRechargeApplication.repository.PlanRepository;
import com.arise.dk.mobileRechargeApplication.repository.PlanCategoryRepository;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

@Service
public class PlanService {
    private final PlanRepository planRepository;
    private final PlanCategoryRepository planCategoryRepository;

    public PlanService(PlanRepository planRepository, PlanCategoryRepository planCategoryRepository) {
        this.planRepository = planRepository;
        this.planCategoryRepository = planCategoryRepository;
    }

    public List<Plan> getPlansByCategory(String categoryName) {
        return planRepository.findByPlanCategory_CategoryName(categoryName);  // ✅ Uses categoryName
    }

    public Plan addPlan(String categoryName, Plan plan) {
        PlanCategory category = planCategoryRepository.findByCategoryName(categoryName)
                .orElseThrow(() -> new RuntimeException("Category not found"));
        plan.setPlanCategory(category);
        return planRepository.save(plan);
    }
    
    public void deletePlanByCategoryId(Long categoryId) {
        planRepository.deleteByPlanCategoryId(categoryId);
    }


    public Plan updatePlan(Long planId, String categoryName, Plan planDetails) {
        return planRepository.findById(planId).map(plan -> {
            PlanCategory category = planCategoryRepository.findByCategoryName(categoryName)
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Category not found"));

            plan.setPlanCategory(category);
            plan.setPlanPrice(planDetails.getPlanPrice());
            plan.setPlanValidityInDays(planDetails.getPlanValidityInDays());
            plan.setPlanSmsValidity(planDetails.getPlanSmsValidity());

            // Apply updates based on category type
            switch (categoryName) {
                case "TopupPlans":
                    plan.setPlanTalkTime(planDetails.getPlanTalkTime());
                    break;
                case "VoiceOnlyPlans":
                    plan.setPlanVoiceValidity(planDetails.getPlanVoiceValidity());
                    plan.setPlanSmsValidity(planDetails.getPlanSmsValidity());
                    break;
                case "DataPlans":
                    plan.setPlanOverallData(planDetails.getPlanOverallData());
                    plan.setPlanDataPerDay(planDetails.getPlanDataPerDay());
                    break;
                default: // OTT Plans (default)
                    plan.setPlanDataPerDay(planDetails.getPlanDataPerDay());
                    plan.setPlanOttOffers(planDetails.getPlanOttOffers());
                    break;
            }

            return planRepository.save(plan);
        }).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Plan not found"));
    }
    public void deletePlan(Long planId) {
        planRepository.deleteById(planId);
    }
    
    public Optional<Plan> getPlanById(Long planId) {
        return planRepository.findById(planId);
    }
}
