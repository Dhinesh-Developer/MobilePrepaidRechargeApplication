package com.arise.dk.mobileRechargeApplication.service;

import com.arise.dk.mobileRechargeApplication.model.UserCurrentPlanDetails;
import com.arise.dk.mobileRechargeApplication.model.Plan;
import com.arise.dk.mobileRechargeApplication.model.Transaction;
import com.arise.dk.mobileRechargeApplication.model.User;
import com.arise.dk.mobileRechargeApplication.repository.PlanRepository;
import com.arise.dk.mobileRechargeApplication.repository.TransactionRepository;
import com.arise.dk.mobileRechargeApplication.repository.UserCurrentPlanRepository;
import com.arise.dk.mobileRechargeApplication.repository.UserRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class UserCurrentPlanService {
    private final UserCurrentPlanRepository userCurrentPlanRepository;
    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PlanRepository planRepository;

    @Autowired
    private TransactionRepository transactionRepository;

   
    public UserCurrentPlanService(UserCurrentPlanRepository userCurrentPlanRepository) {
        this.userCurrentPlanRepository = userCurrentPlanRepository;
    } 
    
    public List<UserCurrentPlanDetails> getUsersWithExpiringPlans(String name) {
    	if(name.equals("All")) {
    		return userCurrentPlanRepository.findByPlanExpiryDateBefore(LocalDate.now().plusDays(300));
    	}
        return userCurrentPlanRepository.findByPlanExpiryDateBefore(LocalDate.now().plusDays(300)).stream().filter(user -> user.getUsername().toLowerCase().contains(name.toLowerCase())).toList();
    }

    public UserCurrentPlanDetails saveOrUpdateUserPlan(UserCurrentPlanDetails userPlanDetails) {
        // Fetch User from DB to avoid detached entity issue
        User user = userRepository.findById(userPlanDetails.getUser().getUserId())
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Fetch Plan from DB
        Plan plan = planRepository.findById(userPlanDetails.getPlan().getPlanId())
                .orElseThrow(() -> new RuntimeException("Plan not found"));

        // Fetch Transaction from DB
        Transaction transaction = transactionRepository.findById(userPlanDetails.getTransaction().getTransactionId())
                .orElseThrow(() -> new RuntimeException("Transaction not found"));
        
        Optional<UserCurrentPlanDetails> existingPlan = userCurrentPlanRepository.findById(user.getUserId());

        if (existingPlan.isPresent()) {
            // Update the existing record
            UserCurrentPlanDetails userPlan = existingPlan.get();
            userPlan.setUser(user);
            userPlan.setPlan(plan);
            userPlan.setTransaction(transaction);
            userPlan.setDataUsage(userPlanDetails.getDataUsage());

            return userCurrentPlanRepository.save(userPlan);
        } else {
            // Create a new record
            userPlanDetails.setUser(user);
            userPlanDetails.setPlan(plan);
            userPlanDetails.setTransaction(transaction);
            return userCurrentPlanRepository.save(userPlanDetails);
        }
    }


    public Optional<UserCurrentPlanDetails> getUserCurrentPlan(Long userId) {
        return userCurrentPlanRepository.findById(userId);
    }

}
